# 使用Node.js官方镜像作为基础镜像 
FROM node:20.10.0 

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json（如果存在）
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8848

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=8848

# 启动命令
CMD ["node", "app.js"]

