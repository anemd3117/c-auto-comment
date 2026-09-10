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

    Write-Ok 'Better Todo Tree will use its packaged ripgrep binary by default.'
    Write-Host '[READY] VS Code support repair completed.'
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    exit 1
}
