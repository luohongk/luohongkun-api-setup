param(
    [string]$ApiKey
)

function ConvertTo-Hashtable {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $table = @{}
        foreach ($key in $InputObject.Keys) {
            $table[$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return $table
    }

    if (
        $InputObject -is [System.Collections.IEnumerable] -and
        -not ($InputObject -is [string])
    ) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ,(ConvertTo-Hashtable $item)
        }
        return $items
    }

    if ($InputObject -is [psobject]) {
        $table = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $table[$property.Name] = ConvertTo-Hashtable $property.Value
        }
        return $table
    }

    return $InputObject
}

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

$SettingsDir = if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) {
    Join-Path $HOME ".claude"
} else {
    $env:CLAUDE_CONFIG_DIR
}
$SettingsFile = Join-Path $SettingsDir "settings.json"

New-Item -ItemType Directory -Force -Path $SettingsDir | Out-Null

$data = @{}

if (Test-Path $SettingsFile) {
    $raw = Get-Content $SettingsFile -Raw -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $parsed = $raw | ConvertFrom-Json
        $data = ConvertTo-Hashtable $parsed
    }
}

if ($data.ContainsKey("env") -and $data["env"] -is [System.Collections.IDictionary]) {
    $envTable = @{}
    foreach ($key in $data["env"].Keys) {
        $envTable[$key] = $data["env"][$key]
    }
} else {
    $envTable = @{}
}

$envTable["ANTHROPIC_AUTH_TOKEN"] = $ApiKey
$envTable["ANTHROPIC_BASE_URL"] = "https://api.xi-xu.me"
$envTable["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = "gpt-5.4"
$envTable["ANTHROPIC_DEFAULT_OPUS_MODEL"] = "gpt-5.4"
$envTable["ANTHROPIC_DEFAULT_SONNET_MODEL"] = "gpt-5.4"
$envTable["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
$envTable["CLAUDE_CODE_SUBAGENT_MODEL"] = "gpt-5.4"

$data["env"] = $envTable

if (Test-Path $SettingsFile) {
    Copy-Item $SettingsFile "$SettingsFile.bak" -Force
}

$json = $data | ConvertTo-Json -Depth 100
Set-Content -Path $SettingsFile -Value $json -Encoding UTF8

Write-Host "已更新: $SettingsFile"
Write-Host "完成。"
Write-Host "你可以执行以下命令查看结果："
Write-Host "Get-Content $SettingsFile"
