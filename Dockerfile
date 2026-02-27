# ==============================
# 1️⃣ 基础镜像 + 系统依赖
# ==============================
FROM node:20-slim AS base

# 安装常用系统依赖（根据实际需求增删）
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ffmpeg \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# ==============================
# 2️⃣ 工作目录 & non‑root 用户
# ==============================
WORKDIR /app

# 创建一个非 root 用户（id 1000），并切换到该用户
RUN groupadd -r appgroup && useradd -r -g appgroup -u 1000 appuser
USER appuser

# ==============================
# 3️⃣ 安装依赖（缓存层）
# ==============================
# 只拷贝 package.json / package-lock.json（或 yarn.lock）进行依赖安装
COPY --chown=appuser:appgroup package*.json ./
RUN npm ci --only=production

# ==============================
# 4️⃣ 拷贝源码 & 构建（如果有编译步骤）
# ==============================
COPY --chown=appuser:appgroup . .
# 若项目使用 TypeScript/ Babel 等需要编译，取消下面这行注释
# RUN npm run build

# ==============================
# 5️⃣ 运行时配置
# ==============================
# 环境变量（可在运行容器时 override）
ENV NODE_ENV=production \
    TZ=Asia/Shanghai

# 暴露的端口（如果 Bot 需要 WebHook/HTTP 服务）
EXPOSE 3000

# ==============================
# 6️⃣ 启动入口
# ==============================
# 推荐使用一个轻量的启动脚本（entrypoint.sh）来做 “先跑迁移/检查配置 -> 再启动 Bot”
ENTRYPOINT ["tini", "--", "/app/entrypoint.sh"]
