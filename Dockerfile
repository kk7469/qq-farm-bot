# ---------- builder ----------
FROM node:20-slim AS builder

# 安装 passwd（提供 groupadd/useradd）并创建用户
RUN apt-get update && apt-get install -y --no-install-recommends passwd && \
    groupadd -r appgroup && useradd -r -g appgroup -u 1000 appuser && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build

# ---------- runtime ----------
FROM node:20-slim AS runtime

# 把用户信息复制进来（保持 UID/GID）
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group  /etc/group

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

USER appuser
EXPOSE 3000
CMD ["node", "dist/index.js"]
