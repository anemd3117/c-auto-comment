param(
    [ValidateSet('All', 'Toolchain', 'Node', 'VSCode')]
    [string[]]$Components = @('All')
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

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" }
function Write-Missing([string]$Message) { Write-Host "[MISSING] $Message" }
function Write-Fail([string]$Message) { Write-Host "[ERROR] $Message" }

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($machine, $user) | Where-Object { $_ -and $_.Trim() }
    $env:Path = ($parts -join ';')
}

function Find-OnPath([string]$Name) {
    Refresh-ProcessPath
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd -and $cmd.Source) { return $cmd.Source }
    return $null
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
    foreach ($name in @('code.cmd', 'code')) {
        $cmd = Find-OnPath $name
        if ($cmd -and (Test-Path $cmd)) { return $cmd }
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

function Find-NodeExe {
    $node = Find-OnPath 'node.exe'
    if (-not $node) { $node = Find-OnPath 'node' }
    if ($node -and (Test-Path $node)) { return $node }

    $entries = Get-UninstallEntries | Where-Object { $_.DisplayName -like 'Node.js*' }
    foreach ($entry in $entries) {
        if ($entry.InstallLocation) {
            $candidate = Join-Path $entry.InstallLocation 'node.exe'
            if (Test-Path $candidate) { return $candidate }
        }
    }

    $candidate = Join-Path $env:ProgramFiles 'nodejs\node.exe'
    if (Test-Path $candidate) { return $candidate }
    return $null
}

function Find-MSYS2Root {
    if ($env:MSYS2_ROOT) {
        $candidate = [Environment]::ExpandEnvironmentVariables($env:MSYS2_ROOT)
        if (Test-Path (Join-Path $candidate 'usr\bin\bash.exe')) {
            return (Resolve-Path $candidate).Path
        }
    }

    foreach ($name in @('pacman.exe', 'bash.exe', 'pacman', 'bash')) {
        $cmd = Find-OnPath $name
        if ($cmd -and (Test-Path $cmd)) {
            $bin = Split-Path $cmd -Parent
            $usr = Split-Path $bin -Parent
            $root = Split-Path $usr -Parent
            if (Test-Path (Join-Path $root 'usr\bin\bash.exe')) { return $root }
        }
    }

    $entries = Get-UninstallEntries | Where-Object { $_.DisplayName -like 'MSYS2*' }
    foreach ($entry in $entries) {
        $roots = @()
        if ($entry.InstallLocation) { $roots += [string]$entry.InstallLocation }
        if ($entry.DisplayIcon) {
            $icon = ([string]$entry.DisplayIcon -replace ',\d+$', '').Trim('"')
            if ($icon) { $roots += Split-Path $icon -Parent }
        }
        foreach ($root in $roots) {
            if ($root -and (Test-Path (Join-Path $root 'usr\bin\bash.exe'))) {
                return (Resolve-Path $root).Path
            }
        }
    }

    $parents = @("$env:SystemDrive\", $env:ProgramFiles, (Join-Path $env:LOCALAPPDATA 'Programs'))
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($pf86) { $parents += $pf86 }

    foreach ($parent in $parents) {
        if (-not $parent -or -not (Test-Path $parent)) { continue }
        $dirs = Get-ChildItem -Path $parent -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'msys*' }
        foreach ($dir in $dirs) {
            if (Test-Path (Join-Path $dir.FullName 'usr\bin\bash.exe')) { return $dir.FullName }
        }
    }
    return $null
}

function Find-Compiler([string]$Name) {
    $compiler = Find-OnPath ($Name + '.exe')
    if (-not $compiler) { $compiler = Find-OnPath $Name }
    if ($compiler -and (Test-Path $compiler)) { return $compiler }

    $root = Find-MSYS2Root
    if ($root) {
        $candidate = Join-Path $root ("ucrt64\bin\" + $Name + '.exe')
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Require-Winget {
    $winget = Find-OnPath 'winget.exe'
    if (-not $winget) { $winget = Find-OnPath 'winget' }
    if (-not $winget) {
        throw 'Windows Package Manager (winget) is required for automatic installation. Install Microsoft App Installer and retry.'
    }
    return $winget
}

function Install-WingetPackage([string]$Id) {
    $winget = Require-Winget
    Write-Info "Installing package: $Id"
    & $winget install --id $Id --exact --silent --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install $Id (exit code $LASTEXITCODE)."
    }
    Refresh-ProcessPath
}

function Add-UserPath([string]$Directory) {
    if (-not $Directory -or -not (Test-Path $Directory)) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ -and $_.Trim() })
    $exists = $false
    foreach ($part in $parts) {
        if ($part.TrimEnd('\') -ieq $Directory.TrimEnd('\')) {
            $exists = $true
            break
        }
    }
    if (-not $exists) {
        $newPath = (($parts + $Directory) | Select-Object -Unique) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Ok "Added to user PATH: $Directory"
    }
    Refresh-ProcessPath
}

function Ensure-Toolchain {
    $gcc = Find-Compiler 'gcc'
    $gxx = Find-Compiler 'g++'
    if ($gcc -and $gxx) {
        Add-UserPath (Split-Path $gcc -Parent)
        Write-Ok "GCC toolchain detected: $gcc"
        return
    }

    Write-Missing 'GCC/G++ toolchain'
    $root = Find-MSYS2Root
    if (-not $root) {
        Install-WingetPackage 'MSYS2.MSYS2'
        $root = Find-MSYS2Root
    }
    if (-not $root) {
        throw 'MSYS2 was installed but its installation directory could not be discovered.'
    }

    $bash = Join-Path $root 'usr\bin\bash.exe'
    if (-not (Test-Path $bash)) {
        throw "MSYS2 bash was not found under the discovered installation: $root"
    }

    Write-Info "MSYS2 detected: $root"
    Write-Info 'Installing the MSYS2 UCRT64 GCC toolchain...'
    & $bash -lc 'pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc'
    if ($LASTEXITCODE -ne 0) {
        throw "pacman failed to install the GCC toolchain (exit code $LASTEXITCODE)."
    }

    $ucrtBin = Join-Path $root 'ucrt64\bin'
    Add-UserPath $ucrtBin

    $gcc = Find-Compiler 'gcc'
    $gxx = Find-Compiler 'g++'
    if (-not $gcc -or -not $gxx) {
        throw 'GCC installation finished, but gcc/g++ could not be resolved.'
    }
    Write-Ok "GCC toolchain installed: $gcc"
}

function Ensure-Node {
    $node = Find-NodeExe
    if ($node) {
        Add-UserPath (Split-Path $node -Parent)
        Write-Ok "Node.js detected: $node"
        return
    }
    Write-Missing 'Node.js'
    Install-WingetPackage 'OpenJS.NodeJS.LTS'
    $node = Find-NodeExe
    if (-not $node) {
        throw 'Node.js installation finished, but node.exe could not be resolved.'
    }
    Write-Ok "Node.js installed: $node"
}

function Ensure-VSCode {
    $code = Find-VSCodeCli
    if ($code) {
        Write-Ok "VS Code CLI detected: $code"
        return
    }
    Write-Missing 'Visual Studio Code CLI'
    Install-WingetPackage 'Microsoft.VisualStudioCode'
    $code = Find-VSCodeCli
    if (-not $code) {
        throw 'VS Code installation finished, but code.cmd could not be resolved.'
    }
    Write-Ok "VS Code CLI installed: $code"
}

try {
    Refresh-ProcessPath
    $all = $Components -contains 'All'
    Write-Info "Bootstrap components: $($Components -join ', ')"
    if ($all -or $Components -contains 'Toolchain') { Ensure-Toolchain }
    if ($all -or $Components -contains 'Node') { Ensure-Node }
    if ($all -or $Components -contains 'VSCode') { Ensure-VSCode }
    Write-Host '[READY] Development environment is ready.'
    exit 0
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}
