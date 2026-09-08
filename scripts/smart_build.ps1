param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    [string]$WorkspaceFolder
)

try {
    $utf8 = [System.Text.UTF8Encoding]::new()
    [Console]::InputEncoding = $utf8
    [Console]::OutputEncoding = $utf8
    $OutputEncoding = $utf8
} catch {}

if (-not $WorkspaceFolder) {
    $WorkspaceFolder = (Get-Location).Path
}

$ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

Write-Host "[스마트 빌드] 대상 파일: $FilePath"

$headerExts = @('.h', '.hpp', '.hxx')
if ($headerExts -contains $ext) {
    Write-Host "[스마트 빌드] 헤더 파일 문법 검증 (-fsyntax-only)..."
    & gcc -fsyntax-only -finput-charset=UTF-8 -fexec-charset=UTF-8 "$FilePath"
} else {
    $outDir = Join-Path $WorkspaceFolder "output"
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    $outExe = Join-Path $outDir "$baseName.exe"
    Write-Host "[스마트 빌드] C/C++ 파일 빌드 -> $outExe"
    & gcc -Wall -Wextra -g -finput-charset=UTF-8 -fexec-charset=UTF-8 "$FilePath" -o "$outExe"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "[스마트 빌드] 컴파일 성공! 학습용 한글 주석을 추가합니다..."
    $commentScript = Join-Path $WorkspaceFolder "scripts\auto_comment.js"
    if (Test-Path $commentScript) {
        & node "$commentScript" "$FilePath"
    }
} else {
    Write-Host "[스마트 빌드] 컴파일 에러 발생 (코드: $LASTEXITCODE)"
}
