param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    [string]$WorkspaceFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    chcp.com 65001 > $null
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [Console]::InputEncoding = $utf8
    [Console]::OutputEncoding = $utf8
    $OutputEncoding = $utf8
} catch {}

$env:LANG = 'C.UTF-8'
$env:LC_ALL = 'C.UTF-8'

if (-not $WorkspaceFolder) { $WorkspaceFolder = (Get-Location).Path }

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ -and $_.Trim() }) -join ';'
}

function Find-Tool([string]$Name) {
    Refresh-Path
    foreach ($candidateName in @($Name + '.exe', $Name)) {
        $cmd = Get-Command $candidateName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { return $cmd.Source }
    }
    return $null
}

$ext = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
$headerExts = @('.h', '.hpp', '.hxx')
$cppExts = @('.cpp', '.hpp', '.hxx')
$compilerName = if ($cppExts -contains $ext) { 'g++' } else { 'gcc' }

Write-Host "[BUILD] Target: $FilePath"

$compiler = Find-Tool $compilerName
if (-not $compiler) {
    Write-Host "[MISSING] $compilerName"
    $bootstrap = Join-Path $WorkspaceFolder 'scripts\bootstrap.ps1'
    if (-not (Test-Path $bootstrap)) { throw "Bootstrap script not found: $bootstrap" }

    Write-Host '[INFO] Installing the missing compiler toolchain...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Components Toolchain
    if ($LASTEXITCODE -ne 0) { throw "Toolchain bootstrap failed (exit code $LASTEXITCODE)." }

    $compiler = Find-Tool $compilerName
    if (-not $compiler) { throw "$compilerName is still unavailable after bootstrap." }
}

Write-Host "[OK] Compiler: $compiler"

if ($headerExts -contains $ext) {
    Write-Host '[BUILD] Header syntax check (-fsyntax-only)'
    & $compiler -fsyntax-only -finput-charset=UTF-8 -fexec-charset=UTF-8 $FilePath
    $compileExit = $LASTEXITCODE
}
else {
    $outDir = Join-Path $WorkspaceFolder 'output'
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $outExe = Join-Path $outDir "$baseName.exe"
    Write-Host "[BUILD] Output: $outExe"
    & $compiler -Wall -Wextra -g -finput-charset=UTF-8 -fexec-charset=UTF-8 $FilePath -o $outExe
    $compileExit = $LASTEXITCODE
}

if ($compileExit -ne 0) {
    Write-Host "[ERROR] Compilation failed (exit code $compileExit)."
    exit $compileExit
}

Write-Host '[OK] Compilation succeeded.'
$commentScript = Join-Path $WorkspaceFolder 'scripts\auto_comment.js'
if (-not (Test-Path $commentScript)) {
    Write-Host "[WARN] Auto-comment script not found: $commentScript"
    exit 0
}

$node = Find-Tool 'node'
if (-not $node) {
    $bootstrap = Join-Path $WorkspaceFolder 'scripts\bootstrap.ps1'
    Write-Host '[MISSING] Node.js. Installing Node.js LTS...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Components Node
    if ($LASTEXITCODE -ne 0) { throw "Node.js bootstrap failed (exit code $LASTEXITCODE)." }
    $node = Find-Tool 'node'
}

if (-not $node) { throw 'Node.js is unavailable, so automatic comments cannot be generated.' }

Write-Host '[COMMENT] Adding beginner-friendly Korean learning comments...'
& $node $commentScript $FilePath
exit $LASTEXITCODE
