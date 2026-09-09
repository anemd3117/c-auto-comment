param(
    [ValidateSet('All', 'Toolchain', 'Node', 'VSCode')]
    [string[]]$Components = @('All')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    chcp.com 65001 > $null
    $utf8 = [System.Text.UTF8Encoding]::new()
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
    $extra = @(
        'C:\msys64\ucrt64\bin',
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "$env:ProgramFiles\Microsoft VS Code\bin",
        "$env:ProgramFiles\nodejs"
    )
    $env:Path = (($machine, $user) + $extra | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Find-CommandPath([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }

    $known = @()
    switch ($Name.ToLowerInvariant()) {
        'gcc' { $known += 'C:\msys64\ucrt64\bin\gcc.exe' }
        'g++' { $known += 'C:\msys64\ucrt64\bin\g++.exe' }
        'node' { $known += "$env:ProgramFiles\nodejs\node.exe" }
        'code' {
            $known += "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
            $known += "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
        }
    }

    foreach ($candidate in $known) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

function Require-Winget {
    $winget = Find-CommandPath 'winget'
    if (-not $winget) {
        throw 'Windows Package Manager (winget) is required for automatic dependency installation. Install Microsoft App Installer and retry.'
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
    if (-not (Test-Path $Directory)) { return }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ })
    if ($parts -notcontains $Directory) {
        $newPath = (($parts + $Directory) | Select-Object -Unique) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Ok "Added to user PATH: $Directory"
    }
    Refresh-ProcessPath
}

function Ensure-Toolchain {
    Refresh-ProcessPath
    $gcc = Find-CommandPath 'gcc'
    $gxx = Find-CommandPath 'g++'

    if ($gcc -and $gxx) {
        Write-Ok "GCC toolchain detected: $gcc"
        return
    }

    Write-Missing 'GCC/G++ toolchain'
    $bash = 'C:\msys64\usr\bin\bash.exe'
    if (-not (Test-Path $bash)) {
        Install-WingetPackage 'MSYS2.MSYS2'
    }

    if (-not (Test-Path $bash)) {
        throw 'MSYS2 installation completed but C:\msys64\usr\bin\bash.exe was not found.'
    }

    Write-Info 'Installing the MSYS2 UCRT64 GCC toolchain...'
    & $bash -lc 'pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc'
    if ($LASTEXITCODE -ne 0) {
        throw "pacman failed to install the GCC toolchain (exit code $LASTEXITCODE)."
    }

    Add-UserPath 'C:\msys64\ucrt64\bin'
    $gcc = Find-CommandPath 'gcc'
    $gxx = Find-CommandPath 'g++'
    if (-not $gcc -or -not $gxx) {
        throw 'GCC installation finished, but gcc/g++ could not be detected.'
    }
    Write-Ok "GCC toolchain installed: $gcc"
}

function Ensure-Node {
    Refresh-ProcessPath
    $node = Find-CommandPath 'node'
    if ($node) {
        Write-Ok "Node.js detected: $node"
        return
    }

    Write-Missing 'Node.js'
    Install-WingetPackage 'OpenJS.NodeJS.LTS'
    $node = Find-CommandPath 'node'
    if (-not $node) {
        throw 'Node.js installation finished, but node could not be detected.'
    }
    Write-Ok "Node.js installed: $node"
}

function Ensure-VSCode {
    Refresh-ProcessPath
    $code = Find-CommandPath 'code'
    if ($code) {
        Write-Ok "VS Code CLI detected: $code"
        return
    }

    Write-Missing 'Visual Studio Code CLI'
    Install-WingetPackage 'Microsoft.VisualStudioCode'
    Add-UserPath "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
    Add-UserPath "$env:ProgramFiles\Microsoft VS Code\bin"
    $code = Find-CommandPath 'code'
    if (-not $code) {
        throw 'VS Code installation finished, but the code command could not be detected. Restart the terminal and retry.'
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
