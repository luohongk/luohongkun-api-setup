#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   bash setup-claude-xixu.sh your_api_key
# 或:
#   ANTHROPIC_AUTH_TOKEN=your_api_key bash setup-claude-xixu.sh

API_KEY="${1:-${ANTHROPIC_AUTH_TOKEN:-}}"

if [[ -z "$API_KEY" ]]; then
  read -rsp "请输入 API Key: " API_KEY
  echo
fi

SETTINGS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

mkdir -p "$SETTINGS_DIR"

python3 - "$SETTINGS_FILE" "$API_KEY" <<'PY'
import json
import os
import sys

settings_file = sys.argv[1]
api_key = sys.argv[2]

data = {}
if os.path.exists(settings_file):
    with open(settings_file, "r", encoding="utf-8") as f:
        content = f.read().strip()
        if content:
            data = json.loads(content)

if not isinstance(data, dict):
    raise SystemExit("settings.json 顶层必须是 JSON 对象")

env = data.get("env")
if env is None:
    env = {}
elif not isinstance(env, dict):
    raise SystemExit("settings.json 中 env 必须是 JSON 对象")

env.update({
    "ANTHROPIC_AUTH_TOKEN": api_key,
    "ANTHROPIC_BASE_URL": "https://api.xi-xu.me",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gpt-5.4",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.4",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_SUBAGENT_MODEL": "gpt-5.4"
})

data["env"] = env

if os.path.exists(settings_file):
    backup_file = settings_file + ".bak"
    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

with open(settings_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"已更新: {settings_file}")
PY

echo "完成。"
echo "你可以执行以下命令查看结果："
echo "cat \"$SETTINGS_FILE\""
