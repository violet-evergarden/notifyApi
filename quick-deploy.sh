#!/bin/bash

# 快速部署脚本（适用于已配置好 .env 的情况）
# 使用方法: ./quick-deploy.sh

set -e

# 配置
PROJECT_DIR="notifyApi"
IMAGE_NAME="notify-api"
CONTAINER_NAME="notify-api"
PORT="8848"

echo "🚀 快速部署 Notify API..."

# 检查 Docker
if ! docker info &> /dev/null; then
    echo "❌ Docker 未运行"
    exit 1
fi

# 进入项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在，请先运行 deploy.sh"
    exit 1
fi

cd $PROJECT_DIR

# 更新代码
echo "📥 更新代码..."
git pull || echo "⚠️  Git pull 失败，继续使用现有代码"

# 停止旧容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 停止旧容器..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# 构建镜像
echo "🔨 构建镜像..."
docker build -t $IMAGE_NAME .

# 运行容器
echo "▶️  启动容器..."
docker run -d \
    -p ${PORT}:${PORT} \
    --env-file .env \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    $IMAGE_NAME

sleep 2

# 检查状态
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ 部署成功！"
    echo ""
    echo "查看日志: docker logs -f $CONTAINER_NAME"
else
    echo "❌ 部署失败，查看日志: docker logs $CONTAINER_NAME"
    exit 1
fi

