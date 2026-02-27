# -------------------------------------------------
# 1️⃣ Build stage – 编译 / 打包
# -------------------------------------------------
FROM node:20-alpine AS builder

# ----- PNPM 与 Node 环境变量 -----------------------------------------------
ENV PNPM_VERSION=10.30.2 \
    NODE_ENV=production

# ----- 安装 pnpm ---------------------------------------------------------
RUN npm i -g pnpm@${PNPM_VERSION}

# ----- 工作目录 -----------------------------------------------------------
WORKDIR /app

# ----- 只复制 lockfile / package.json（利用缓存） -------------------------
COPY package.json pnpm-lock.yaml ./
# 若是 monorepo，还需要复制 pnpm-workspace.yaml
# COPY pnpm-workspace.yaml ./

# ----- 安装所有依赖（包括 devDeps） --------------------------------------
RUN pnpm install --frozen-lockfile --prod false

# ----- 复制源码 -----------------------------------------------------------
COPY . .

# ----- 执行你已有的构建脚本（会生成 core/dist/*） -----------------------
RUN pnpm package:release

# -------------------------------------------------
# 2️⃣ Runtime stage – 只保留运行时必要文件
# -------------------------------------------------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production
WORKDIR /app

# ----- 创建非 root 用户 ----------------------------------------------------
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# ----- 只复制运行时需要的内容 --------------------------------------------
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
COPY --from=builder /app/node_modules ./node_modules

# 核心二进制（已为 Linux 构建）——仅保留运行时需要的
COPY --from=builder /app/core/dist ./core/dist
# 业务代码、配置等
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public   # 若有 static 资源

# ----- 切换到非 root 用户 -------------------------------------------------
USER appuser

# ----- 可选：暴露端口（如果你的 bot 提供 http 接口） --------------------
EXPOSE 8080

# ----- LABEL（使用 JSON 形式，最安全） ------------------------------------
LABEL \
  "org.opencontainers.image.title"="qq-farm-bot" \
  "org.opencontainers.image.description"="QQ 农场机器人 (Node + pnpm)" \
  "org.opencontainers.image.source"="https://github.com/kk7469/qq-farm-bot" \
  "org.opencontainers.image.revision"="${GITHUB_SHA}" \
  "org.opencontainers.image.version"="${VERSION:-latest}"

# ----- 默认启动命令 ------------------------------------------------------
# 如果你想直接运行编译好的二进制，请改为对应路径，例如：
# CMD ["./core/dist/qq-farm-bot-linux-x64"]
CMD ["node", "./src/index.js"]
