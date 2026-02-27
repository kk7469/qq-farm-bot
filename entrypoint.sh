#!/usr/bin/env bash
set -euo pipefail

# ---- 1️⃣ 读取/校验环境变量 ----
# 下面的值仅作示例，请依据项目实际需要自行增删
: "${QQ_BOT_API_TOKEN:?need to set QQ_BOT_API_TOKEN}"
: "${QQ_GROUP_ID:?need to set QQ_GROUP_ID}"
: "${CONFIG_DIR:=/app/config}"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# ---- 2️⃣ 自动生成 config.json（如果不存在）----
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "⚙️ 生成默认配置文件 ${CONFIG_FILE}"
  mkdir -p "${CONFIG_DIR}"
  cat > "${CONFIG_FILE}" <<EOF
{
  "botToken": "${QQ_BOT_API_TOKEN}",
  "groupId": "${QQ_GROUP_ID}",
  "logLevel": "info"
}
EOF
fi

# ---- 3️⃣ 可选：执行一次性迁移/初始化脚本 ----
# if [[ -x "./scripts/migrate.sh" ]]; then
#   ./scripts/migrate.sh
# fi

# ---- 4️⃣ 最后启动 Bot ----
# 这里使用 npm start（或 node ./dist/index.js）
exec npm start "$@"
