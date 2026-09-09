param()

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

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" }
function Write-Fail([string]$Message) { Write-Host "[ERROR] $Message" }

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ -and $_.Trim() }) -join ';'
}

function Get-UninstallEntries {
    $keys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($key in $keys) {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    }
}

function Find-VSCodeCli {
    Refresh-ProcessPath
    foreach ($name in @('code.cmd', 'code')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { return $cmd.Source }
    }

    $entries = Get-UninstallEntries | Where-Object { $_.DisplayName -like 'Microsoft Visual Studio Code*' }
    foreach ($entry in $entries) {
        if ($entry.InstallLocation) {
            $candidate = Join-Path $entry.InstallLocation 'bin\code.cmd'
            if (Test-Path $candidate) { return $candidate }
        }
        if ($entry.DisplayIcon) {
            $icon = ([string]$entry.DisplayIcon -replace ',\d+$', '').Trim('"')
            if ($icon -and (Test-Path $icon)) {
                $candidate = Join-Path (Split-Path $icon -Parent) 'bin\code.cmd'
                if (Test-Path $candidate) { return $candidate }
            }
        }
    }

    $fallbacks = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($pf86) { $fallbacks += Join-Path $pf86 'Microsoft VS Code\bin\code.cmd' }

    foreach ($candidate in $fallbacks) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

try {
    $root = Split-Path $PSScriptRoot -Parent
    $packageJson = Join-Path $root 'auto-comment-extension\package.json'
    $bootstrap = Join-Path $PSScriptRoot 'bootstrap.ps1'

    if (-not (Test-Path $packageJson)) { throw "package.json was not found: $packageJson" }
    if (-not (Test-Path $bootstrap)) { throw "bootstrap.ps1 was not found: $bootstrap" }

    $package = Get-Content -Raw -LiteralPath $packageJson | ConvertFrom-Json
    $version = [string]$package.version
    if (-not $version) { throw 'Extension version could not be read from package.json.' }

    Write-Host '===================================================='
    Write-Host "[Auto Comment] Portable installer v$version"
    Write-Host '===================================================='
    Write-Info 'Checking the VS Code host...'

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Components VSCode
    if ($LASTEXITCODE -ne 0) {
        throw "Dependency bootstrap failed (exit code $LASTEXITCODE)."
    }

    Refresh-ProcessPath
    $code = Find-VSCodeCli
    if (-not $code) { throw 'VS Code CLI could not be resolved after bootstrap.' }
    Write-Ok "VS Code CLI resolved: $code"

    $expected = "local.auto-comment-after-run@$version"
    $installedBefore = & $code --list-extensions --show-versions 2>&1

    if ($LASTEXITCODE -eq 0 -and ($installedBefore | Where-Object { $_.Trim() -ieq $expected })) {
        Write-Ok "Already installed: $expected"
        Write-Host '[READY] Auto Comment is already up to date.'
        exit 0
    }

    $fileName = "auto-comment-after-run-$version.vsix"
    $downloadDir = Join-Path ([IO.Path]::GetTempPath()) ("auto-comment-installer\" + $version)
    $vsix = Join-Path $downloadDir $fileName
    $url = "https://github.com/anemd3117/c-auto-comment/releases/download/v$version/$fileName"

    New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
    if (Test-Path $vsix) { Remove-Item -Force $vsix }

    Write-Info "Downloading prebuilt VSIX: $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $downloaded = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $vsix -UseBasicParsing
            $downloaded = $true
            break
        }
        catch {
            if ($attempt -eq 6) { throw }
            Write-Info "Release asset is not ready yet. Retrying in 5 seconds ($attempt/6)..."
            Start-Sleep -Seconds 5
        }
    }

    if (-not $downloaded -or -not (Test-Path $vsix)) {
        throw 'VSIX download did not create the expected file.'
    }

    $size = (Get-Item $vsix).Length
    if ($size -lt 1024) { throw "Downloaded VSIX is unexpectedly small ($size bytes)." }
    Write-Ok "VSIX downloaded: $vsix"

    Write-Info 'Installing the extension into VS Code...'
    & $code --install-extension $vsix --force
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code extension installation failed (exit code $LASTEXITCODE)."
    }

    $installed = & $code --list-extensions --show-versions 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code extension verification failed (exit code $LASTEXITCODE)."
    }

    if (-not ($installed | Where-Object { $_.Trim() -ieq $expected })) {
        throw "Installation command completed, but $expected was not found in the installed extension list."
    }

    Write-Ok "Verified extension: $expected"
    Write-Host '[READY] Auto Comment installation completed successfully.'
    Write-Info 'Restart VS Code or run "Developer: Reload Window".'
    exit 0
}
catch {
    Write-Fail $_.Exception.Message
    Write-Host '[FAILED] Installation did not complete.'
    exit 1
}
