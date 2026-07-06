param(
    [string]$ApiKey
)

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $secure = Read-Host "请输入 API Key" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

$ConfigDir = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    Join-Path $HOME ".codex"
} else {
    $env:CODEX_HOME
}
$ConfigFile = Join-Path $ConfigDir "config.toml"

New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
if (-not (Test-Path $ConfigFile)) {
    New-Item -ItemType File -Force -Path $ConfigFile | Out-Null
}

$content = Get-Content $ConfigFile -Raw -ErrorAction SilentlyContinue
if ($null -eq $content) {
    $content = ""
}

$content = $content -replace "`r`n", "`n"
$lines = [System.Collections.Generic.List[string]]::new()
if ($content.Length -gt 0) {
    foreach ($line in ($content -split "`n")) {
        $lines.Add($line)
    }
}

$filteredLines = [System.Collections.Generic.List[string]]::new()
$inXixuBlock = $false

foreach ($line in $lines) {
    if ($inXixuBlock) {
        if ($line -match '^\[.*\][ \t]*$') {
            $inXixuBlock = $false
        } else {
            continue
        }
    }

    if ($line -match '^[ \t]*model_provider[ \t]*=') {
        continue
    }

    if ($line -match '^\[model_providers\.xixu\][ \t]*$') {
        $inXixuBlock = $true
        continue
    }

    $filteredLines.Add($line)
}

$insertIndex = 0
while (
    $insertIndex -lt $filteredLines.Count -and (
        $filteredLines[$insertIndex].Trim().Length -eq 0 -or
        $filteredLines[$insertIndex].TrimStart().StartsWith("#")
    )
) {
    $insertIndex++
}

$outputLines = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $insertIndex; $i++) {
    $outputLines.Add($filteredLines[$i])
}

if ($outputLines.Count -gt 0 -and $outputLines[$outputLines.Count - 1].Trim().Length -ne 0) {
    $outputLines.Add("")
}

$outputLines.Add('model_provider = "xixu"')

if ($insertIndex -lt $filteredLines.Count -and $filteredLines[$insertIndex].Trim().Length -ne 0) {
    $outputLines.Add("")
}

for ($i = $insertIndex; $i -lt $filteredLines.Count; $i++) {
    $outputLines.Add($filteredLines[$i])
}

while ($outputLines.Count -gt 0 -and $outputLines[$outputLines.Count - 1].Trim().Length -eq 0) {
    $outputLines.RemoveAt($outputLines.Count - 1)
}

if ($outputLines.Count -gt 0) {
    $outputLines.Add("")
}

$outputLines.Add('[model_providers.xixu]')
$outputLines.Add('name = "Xi Xu''s AI Inference"')
$outputLines.Add('base_url = "https://api.xi-xu.me/v1"')
$outputLines.Add('env_key = "XIXU_API_KEY"')

$content = [string]::Join("`r`n", $outputLines) + "`r`n"

Set-Content -Path $ConfigFile -Value $content -Encoding UTF8

$env:XIXU_API_KEY = $ApiKey
[System.Environment]::SetEnvironmentVariable("XIXU_API_KEY", $ApiKey, "User")

Write-Host "已完成："
Write-Host "1. 更新 $ConfigFile"
Write-Host "2. 设置当前会话环境变量 XIXU_API_KEY"
Write-Host "3. 持久化为用户级环境变量"
Write-Host ""
Write-Host '重新打开 PowerShell 后会自动生效。当前会话已可直接使用。'
