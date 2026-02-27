# ---------- builder ----------
FROM node:20-alpine AS builder

# ① 创建系统组 + 普通用户（Alpine 原生）
# 对于 **非常老的 Alpine (<3.13)** 请去掉 -S
RUN addgroup -S appgroup && \
    adduser -S -G appgroup -u 1000 appuser

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build   # 你的构建命令

# ---------- runtime ----------
FROM node:20-alpine AS runtime

# 把已经创建的 /etc/passwd /etc/group 复制进来（保持 UID/GID）
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group  /etc/group

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# ② 运行时使用普通用户
USER appuser

EXPOSE 8080
CMD ["node", "dist/index.js"]
