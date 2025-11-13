# 使用Node.js官方镜像作为基础镜像 
FROM node:20.10.0 

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json（如果存在）
COPY package*.json ./
COPY .env ./
# 安装依赖（使用 npm install 因为可能没有 package-lock.json）
RUN npm install

# 复制应用代码
COPY . .

# 注意：.env 文件不会被复制到镜像中（已在 .gitignore 中）
# 环境变量通过 docker run -e 或 --env-file 传递

# 暴露端口
EXPOSE 8848

# 设置环境变量

# 启动命令
CMD ["node", "app.js"]

