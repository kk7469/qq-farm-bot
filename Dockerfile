# ---------- builder ----------
FROM node:20-alpine AS builder

# 1️⃣ 创建普通用户（Alpine 原生的 addgroup/adduser）
RUN addgroup -S appgroup && \
    adduser -S -G appgroup -u 1000 appuser

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build   # 你的构建命令

# ---------- runtime ----------
FROM node:20-alpine AS runtime

# 把在 builder 阶段创建的 /etc/passwd /etc/group 带进来
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group  /etc/group

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# 2️⃣ 使用普通用户运行容器
USER appuser

EXPOSE 8080
CMD ["node", "dist/index.js"]
