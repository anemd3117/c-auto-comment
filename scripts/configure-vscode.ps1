param(
    [Parameter(Mandatory=$true)]
    [string]$CodePath
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

$env:PYTHONUTF8 = '1'

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" }

function Get-InstalledExtensions {
    $items = & $CodePath --list-extensions 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "VS Code extension listing failed (exit code $LASTEXITCODE)."
    }

    return @($items | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
}

function Ensure-Extension([string]$Id) {
    $installed = Get-InstalledExtensions
    if ($installed -contains $Id.ToLowerInvariant()) {
        Write-Ok "VS Code extension already installed: $Id"
        return
    }

    Write-Info "Installing VS Code extension: $Id"
    & $CodePath --install-extension $Id
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install VS Code extension $Id (exit code $LASTEXITCODE)."
    }
    Write-Ok "Installed VS Code extension: $Id"
}

function Remove-ExtensionIfPresent([string]$Id) {
    $installed = Get-InstalledExtensions
    if ($installed -notcontains $Id.ToLowerInvariant()) {
        return
    }

    Write-Info "Removing unsupported or failing VS Code extension: $Id"
    & $CodePath --uninstall-extension $Id
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to remove VS Code extension $Id (exit code $LASTEXITCODE)."
    }
    Write-Ok "Removed VS Code extension: $Id"
}

function Remove-JsoncBooleanProperty {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$PropertyName
    )

    if (-not (Test-Path $FilePath)) { return }

    $text = [IO.File]::ReadAllText($FilePath)
    $escaped = [Regex]::Escape($PropertyName)
    $pattern = '(?m)^[ \t]*"' + $escaped + '"[ \t]*:[ \t]*(?:true|false)[ \t]*,?[ \t]*\r?\n'
    $newText = [Regex]::Replace($text, $pattern, '')

    if ($newText -ne $text) {
        [IO.File]::WriteAllText($FilePath, $newText, [Text.UTF8Encoding]::new($false))
        Write-Ok "Removed obsolete setting: $PropertyName"
    }
}

function Remove-JsoncStringProperty {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$PropertyName
    )

    if (-not (Test-Path $FilePath)) { return }

    $text = [IO.File]::ReadAllText($FilePath)
    $escaped = [Regex]::Escape($PropertyName)
    $pattern = '(?m)^[ \t]*"' + $escaped + '"[ \t]*:[ \t]*"(?:\\.|[^"\\])*"[ \t]*,?[ \t]*\r?\n'
    $newText = [Regex]::Replace($text, $pattern, '')

    if ($newText -ne $text) {
        [IO.File]::WriteAllText($FilePath, $newText, [Text.UTF8Encoding]::new($false))
        Write-Ok "Removed obsolete setting: $PropertyName"
    }
}

function Set-JsoncStringProperty {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$PropertyName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )

    $dir = Split-Path $FilePath -Parent
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if (-not (Test-Path $FilePath)) {
        [IO.File]::WriteAllText($FilePath, "{`r`n}`r`n", [Text.UTF8Encoding]::new($false))
    }

    $text = [IO.File]::ReadAllText($FilePath)
    $escapedName = [Regex]::Escape($PropertyName)
    $escapedValue = $Value.Replace('\', '\\').Replace('"', '\"')
    $replacement = '"' + $PropertyName + '": "' + $escapedValue + '"'
    $pattern = '"' + $escapedName + '"\s*:\s*"(?:\\.|[^"\\])*"'

    if ([Regex]::IsMatch($text, $pattern)) {
        $text = [Regex]::Replace($text, $pattern, $replacement, 1)
    }
    else {
        $index = $text.LastIndexOf('}')
        if ($index -lt 0) {
            throw "VS Code settings file does not contain a root closing brace: $FilePath"
        }

        $before = $text.Substring(0, $index).TrimEnd()
        $after = $text.Substring($index)
        $needsComma = -not ($before.EndsWith('{') -or $before.EndsWith(','))
        $insert = if ($needsComma) { ",`r`n    $replacement`r`n" } else { "`r`n    $replacement`r`n" }
        $text = $before + $insert + $after
    }

    [IO.File]::WriteAllText($FilePath, $text, [Text.UTF8Encoding]::new($false))
}

function Test-PythonLauncher {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Launcher,
        [string[]]$PrefixArgs = @()
    )

    if (-not $Launcher -or -not (Test-Path $Launcher)) { return $null }

    try {
        $args = @()
        $args += $PrefixArgs
        $args += @('-c', 'import sys; print(sys.executable)')

        $output = & $Launcher @args 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $output) { return $null }

        $resolved = ([string]($output | Select-Object -Last 1)).Trim()
        if ($resolved -and (Test-Path $resolved)) {
            return (Resolve-Path $resolved).Path
        }
    }
    catch {}

    return $null
}

function Find-PythonInterpreter {
    $candidates = @()

    foreach ($item in @(
        @{ Name = 'pymanager.exe'; Prefix = @('exec') },
        @{ Name = 'pymanager'; Prefix = @('exec') },
        @{ Name = 'py.exe'; Prefix = @() },
        @{ Name = 'py'; Prefix = @() },
        @{ Name = 'python.exe'; Prefix = @() },
        @{ Name = 'python'; Prefix = @() },
        @{ Name = 'python3.exe'; Prefix = @() },
        @{ Name = 'python3'; Prefix = @() }
    )) {
        $cmd = Get-Command $item.Name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            $candidates += [PSCustomObject]@{ Launcher = $cmd.Source; Prefix = @($item.Prefix) }
        }
    }

    if ($env:LOCALAPPDATA) {
        $known = @(
            [PSCustomObject]@{ Launcher = (Join-Path $env:LOCALAPPDATA 'Programs\Python\Launcher\py.exe'); Prefix = @() },
            [PSCustomObject]@{ Launcher = (Join-Path $env:LOCALAPPDATA 'Programs\Python\Launcher\pymanager.exe'); Prefix = @('exec') },
            [PSCustomObject]@{ Launcher = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pymanager.exe'); Prefix = @('exec') },
            [PSCustomObject]@{ Launcher = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\py.exe'); Prefix = @() },
            [PSCustomObject]@{ Launcher = (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\python.exe'); Prefix = @() }
        )
        foreach ($candidate in $known) {
            if (Test-Path $candidate.Launcher) { $candidates += $candidate }
        }

        $pythonRoot = Join-Path $env:LOCALAPPDATA 'Programs\Python'
        if (Test-Path $pythonRoot) {
            Get-ChildItem -Path $pythonRoot -Filter 'python.exe' -File -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $candidates += [PSCustomObject]@{ Launcher = $_.FullName; Prefix = @() }
                }
        }
    }

    foreach ($root in @($env:ProgramFiles, [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))) {
        if (-not $root -or -not (Test-Path $root)) { continue }
        Get-ChildItem -Path $root -Directory -Filter 'Python*' -ErrorAction SilentlyContinue |
            ForEach-Object {
                $candidate = Join-Path $_.FullName 'python.exe'
                if (Test-Path $candidate) {
                    $candidates += [PSCustomObject]@{ Launcher = $candidate; Prefix = @() }
                }
            }
    }

    $seen = @{}
    foreach ($candidate in $candidates) {
        $key = ($candidate.Launcher + '|' + ($candidate.Prefix -join ' ')).ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $interpreter = Test-PythonLauncher -Launcher $candidate.Launcher -PrefixArgs $candidate.Prefix
        if ($interpreter) { return $interpreter }
    }

    return $null
}

try {
    if (-not (Test-Path $CodePath)) {
        throw "VS Code CLI was not found: $CodePath"
    }

    Write-Info 'Repairing VS Code support extensions...'

    Remove-ExtensionIfPresent 'Gruntfuggly.todo-tree'
    Remove-ExtensionIfPresent 'TabNine.tabnine-vscode'
    Remove-ExtensionIfPresent 'VisualStudioExptTeam.intellicode-api-usage-examples'
    Remove-ExtensionIfPresent 'VisualStudioExptTeam.vscodeintellicode'

    Ensure-Extension 'FanaticPythoner.better-todo-tree'
    Ensure-Extension 'ms-python.python'
    Ensure-Extension 'ms-python.vscode-pylance'

    $settingsFile = Join-Path $env:APPDATA 'Code\User\settings.json'

    if (Test-Path $settingsFile) {
        $backup = "$settingsFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $settingsFile -Destination $backup -Force
        Write-Ok "VS Code settings backup created: $backup"
    }

    Remove-JsoncStringProperty -FilePath $settingsFile -PropertyName 'todo-tree.ripgrep.ripgrep'
    Remove-JsoncStringProperty -FilePath $settingsFile -PropertyName 'todo-tree.ripgrep'
    Remove-JsoncStringProperty -FilePath $settingsFile -PropertyName 'better-todo-tree.ripgrep.ripgrep'
    Remove-JsoncBooleanProperty -FilePath $settingsFile -PropertyName 'tabnine.experimentalAutoImports'

    $python = Find-PythonInterpreter
    if (-not $python) {
        throw 'A verified Python interpreter could not be resolved after Python bootstrap.'
    }

    Set-JsoncStringProperty -FilePath $settingsFile -PropertyName 'python.defaultInterpreterPath' -Value $python

    Write-Ok "VS Code Python interpreter configured: $python"
    Write-Ok 'Better Todo Tree will use its packaged ripgrep binary by default.'
    Write-Host '[READY] VS Code support repair completed.'
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
