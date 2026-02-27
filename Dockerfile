# -------------------------------------------------
# 1️⃣ Build stage – 编译/打包
# -------------------------------------------------
FROM node:20-alpine AS builder

# ---- 环境变量 -------------------------------------------------
ENV PNPM_VERSION=10.30.2      # 与 .github/workflows 中的版本保持一致
ENV NODE_ENV=production

# ---- 安装 pnpm -------------------------------------------------
RUN npm i -g pnpm@${PNPM_VERSION}

# ---- 工作目录 -------------------------------------------------
WORKDIR /app

# ---- 复制依赖声明（只复制 package 相关文件，提升缓存命中率）----
COPY package.json pnpm-lock.yaml ./
# 如果你还有 workspace / monorepo，记得把根目录的 pnpm-workspace.yaml 一起复制
# COPY pnpm-workspace.yaml ./

# ---- 安装依赖 -------------------------------------------------
RUN pnpm install --frozen-lockfile --prod false   # 需要 devDeps 进行打包

# ---- 复制源码 -------------------------------------------------
COPY . .

# ---- 编译/打包 -------------------------------------------------
# 这里的 script 与你项目里 `pnpm package:release` 完全相同
RUN pnpm package:release

# -------------------------------------------------
# 2️⃣ Runtime stage – 仅保留运行时必需文件
# -------------------------------------------------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production
WORKDIR /app

# ---- 创建非 root 用户 -------------------------------------------------
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# ---- 只复制运行所需的东西 -------------------------------------------------
# 复制 package.json、pnpm-lock.yaml（供 pnpm 检查）以及已经编译好的 node_modules
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
COPY --from=builder /app/node_modules ./node_modules

# 复制核心产物（四个平台可执行文件）以及源码中需要运行的部分
COPY --from=builder /app/core/dist ./core/dist
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config   # 如果你有 config 目录
COPY --from=builder /app/public ./public   # 如果你有 static 资源

# ---- 切换到非 root 用户 -------------------------------------------------
USER appuser

# ---- 暴露端口（如果你有 HTTP 接口，可以自行修改） ----------------------
EXPOSE 8080

# ---- 默认启动命令 -------------------------------------------------
# 根据你项目的入口，这里默认运行 `node ./src/index.js`
# 如果你是通过已经生成的可执行文件运行，则改成对应文件
# 例如：CMD ["./core/dist/qq-farm-bot-linux-x64"]
CMD ["node", "./src/index.js"]
