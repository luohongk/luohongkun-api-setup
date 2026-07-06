# Provider Setup

用于一键配置 Codex 和 Claude Code 接入 `https://api.xi-xu.me`。

## 功能

### Codex

会自动完成以下操作：

- 写入 Codex 配置文件
- 设置 provider 为 `xixu`
- 配置 `XIXU_API_KEY` 环境变量

### Claude Code

会自动完成以下操作：

- 写入 Claude Code 配置文件
- 配置 `ANTHROPIC_AUTH_TOKEN`
- 配置 `ANTHROPIC_BASE_URL`
- 配置默认模型为 `gpt-5.4`

## Codex

### Linux/macOS

```bash
bash <(curl -fsSL https://github.com/xixu-me/provider-setup/raw/refs/heads/main/codex.sh)
```

### Windows PowerShell

```powershell
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://github.com/xixu-me/provider-setup/raw/refs/heads/main/codex.ps1').Content))"
```

## Claude Code

### Linux/macOS

```bash
bash <(curl -fsSL https://github.com/xixu-me/provider-setup/raw/refs/heads/main/claude.sh)
```

### Windows PowerShell

```powershell
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://github.com/xixu-me/provider-setup/raw/refs/heads/main/claude.ps1').Content))"
```

## 配置内容

### Codex

写入：

```toml
model_provider = "xixu"

[model_providers.xixu]
name = "Xi Xu's AI Inference"
base_url = "https://api.xi-xu.me/v1"
env_key = "XIXU_API_KEY"
```

### Claude Code

写入到目标 `settings.json` 的 `env`：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_API_KEY",
    "ANTHROPIC_BASE_URL": "https://api.xi-xu.me",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.4",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_SUBAGENT_MODEL": "gpt-5.4"
  }
}
```

## 说明

### 路径规则

- Codex 使用 `CODEX_HOME/config.toml`；若未设置 `CODEX_HOME`，则回退到 `~/.codex/config.toml`
- Claude Code 使用 `CLAUDE_CONFIG_DIR/settings.json`；若未设置 `CLAUDE_CONFIG_DIR`，则回退到 `~/.claude/settings.json`

### 其他说明

- 脚本默认会提示输入 API Key
- 若对应配置文件已存在，会在保留其他配置的基础上更新目标字段
- Windows 下用户级环境变量会持久化保存
- Linux/macOS 下会写入当前 shell 配置文件以便后续生效

## 验证

### Codex

#### Linux/macOS

```bash
cat "${CODEX_HOME:-$HOME/.codex}/config.toml"
echo $XIXU_API_KEY
```

#### Windows PowerShell

```powershell
Get-Content (Join-Path $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }) "config.toml")
$env:XIXU_API_KEY
[System.Environment]::GetEnvironmentVariable("XIXU_API_KEY","User")
```

### Claude Code

#### Linux/macOS

```bash
python3 -c "import json, os, pathlib; config_dir = pathlib.Path(os.environ.get('CLAUDE_CONFIG_DIR', str(pathlib.Path.home() / '.claude'))); settings_file = config_dir / 'settings.json'; data = json.loads(settings_file.read_text(encoding='utf-8')); env = data.get('env', {}); keys = ['ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL', 'ANTHROPIC_DEFAULT_OPUS_MODEL', 'ANTHROPIC_DEFAULT_SONNET_MODEL', 'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC', 'CLAUDE_CODE_SUBAGENT_MODEL']; print(settings_file); [print(f'{key}={env.get(key)}') for key in keys]"
```

#### Windows PowerShell

```powershell
$settingsFile = Join-Path $(if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }) "settings.json"
$envConfig = (Get-Content $settingsFile -Raw | ConvertFrom-Json).env
$settingsFile
"ANTHROPIC_AUTH_TOKEN=$($envConfig.ANTHROPIC_AUTH_TOKEN)"
"ANTHROPIC_BASE_URL=$($envConfig.ANTHROPIC_BASE_URL)"
"ANTHROPIC_DEFAULT_HAIKU_MODEL=$($envConfig.ANTHROPIC_DEFAULT_HAIKU_MODEL)"
"ANTHROPIC_DEFAULT_OPUS_MODEL=$($envConfig.ANTHROPIC_DEFAULT_OPUS_MODEL)"
"ANTHROPIC_DEFAULT_SONNET_MODEL=$($envConfig.ANTHROPIC_DEFAULT_SONNET_MODEL)"
"CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=$($envConfig.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)"
"CLAUDE_CODE_SUBAGENT_MODEL=$($envConfig.CLAUDE_CODE_SUBAGENT_MODEL)"
```

## License

MIT. See [LICENSE](LICENSE).
