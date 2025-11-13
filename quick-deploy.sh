#!/bin/sh

# 快速部署脚本（适用于已配置好 .env 的情况）
# 使用方法: ./quick-deploy.sh

set -e

# 配置
PROJECT_DIR="notifyApi"
IMAGE_NAME="notify-api"
CONTAINER_NAME="notify-api"
PORT="8848"

echo "🚀 快速部署 Notify API..."

# 进入项目目录
if [ -d "$PROJECT_DIR" ]; then
    cd $PROJECT_DIR
elif [ -f "package.json" ] && [ -f "app.js" ]; then
    echo "📁 当前目录即为项目目录"
else
    echo "❌ 项目目录不存在，请先运行 deploy.sh"
    exit 1
fi

# 更新代码（如果存在 .git 目录）
if [ -d ".git" ]; then
    echo "📥 更新代码..."
    git pull || echo "⚠️  Git pull 失败，继续使用现有代码"
fi

# 停止旧容器
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 停止旧容器..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# 构建镜像
echo "🔨 构建镜像..."
docker build -t $IMAGE_NAME .

# 运行容器（使用 --env-file 读取 .env 文件）
echo "▶️  启动容器..."
docker run -d \
    -p ${PORT}:${PORT} \
    --env-file .env \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    $IMAGE_NAME

sleep 2

# 检查状态
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ 部署成功！"
    echo ""
    echo "📊 容器信息:"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "📝 常用命令:"
    echo "  查看日志: docker logs -f $CONTAINER_NAME"
    echo "  停止容器: docker stop $CONTAINER_NAME"
    echo "  重启容器: docker restart $CONTAINER_NAME"
else
    echo "❌ 部署失败，查看日志:"
    docker logs $CONTAINER_NAME 2>/dev/null || echo "容器未启动，请检查错误信息"
    exit 1
fi
