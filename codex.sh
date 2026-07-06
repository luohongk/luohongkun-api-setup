#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   bash setup-xixu.sh your_api_key
# 或:
#   XIXU_API_KEY=your_api_key bash setup-xixu.sh

API_KEY="${1:-${XIXU_API_KEY:-}}"

if [[ -z "$API_KEY" ]]; then
  read -rsp "请输入 API Key: " API_KEY
  echo
fi

CONFIG_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CONFIG_DIR/config.toml"

mkdir -p "$CONFIG_DIR"
touch "$CONFIG_FILE"

TMP_FILE="$(mktemp)"

awk '
BEGIN {
  in_xixu = 0
}
{
  if (in_xixu) {
    if ($0 ~ /^\[.*\][[:space:]]*$/) {
      in_xixu = 0
    } else {
      next
    }
  }

  if ($0 ~ /^[[:space:]]*model_provider[[:space:]]*=/) {
    next
  }

  if ($0 ~ /^\[model_providers\.xixu\][[:space:]]*$/) {
    in_xixu = 1
    next
  }

  if (body_count == 0 && $0 ~ /^[[:space:]]*($|#)/) {
    lead[++lead_count] = $0
  } else {
    body[++body_count] = $0
  }
}
END {
  for (i = 1; i <= lead_count; i++) {
    print lead[i]
  }

  if (lead_count > 0 && lead[lead_count] !~ /^[[:space:]]*$/) {
    print ""
  }

  print "model_provider = \"xixu\""

  if (body_count > 0 && body[1] !~ /^[[:space:]]*$/) {
    print ""
  }

  for (i = 1; i <= body_count; i++) {
    print body[i]
  }

  print ""
  print "[model_providers.xixu]"
  print "name = \"Xi Xu'\''s AI Inference\""
  print "base_url = \"https://api.xi-xu.me/v1\""
  print "env_key = \"XIXU_API_KEY\""
}
' "$CONFIG_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"

export XIXU_API_KEY="$API_KEY"

SHELL_NAME="$(basename "${SHELL:-bash}")"
if [[ "$SHELL_NAME" == "zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
else
  RC_FILE="$HOME/.bashrc"
fi

touch "$RC_FILE"

if grep -q '^export XIXU_API_KEY=' "$RC_FILE"; then
  sed -i.bak "s|^export XIXU_API_KEY=.*$|export XIXU_API_KEY=\"$API_KEY\"|" "$RC_FILE"
else
  {
    echo ""
    echo "# Added for Xi Xu Codex provider"
    echo "export XIXU_API_KEY=\"$API_KEY\""
  } >> "$RC_FILE"
fi

echo "已完成："
echo "1. 更新 $CONFIG_FILE"
echo "2. 设置当前会话环境变量 XIXU_API_KEY"
echo "3. 持久化到 $RC_FILE"
echo
echo "可执行：source \"$RC_FILE\""
