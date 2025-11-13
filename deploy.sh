#!/bin/sh

# Notify API 一键部署脚本
# 使用方法: ./deploy.sh

set -e

# 配置变量
GIT_REPO="https://github.com/violet-evergarden/notifyApi.git"
PROJECT_DIR="notifyApi"
IMAGE_NAME="notify-api"
CONTAINER_NAME="notify-api"
PORT="8848"

echo "🚀 开始部署 Notify API..."

# 克隆或更新代码
if [ -d "$PROJECT_DIR" ]; then
    echo "📁 项目目录已存在，更新代码..."
    cd $PROJECT_DIR
    git pull || echo "⚠️  Git pull 失败，继续使用现有代码"
else
    echo "📥 克隆代码仓库..."
    git clone $GIT_REPO $PROJECT_DIR
    cd $PROJECT_DIR
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "⚠️  .env 文件不存在，从 env.example 复制..."
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "请编辑 .env 文件，填入你的配置："
        echo "  - API_KEY"
        echo "  - NOTIFY_BOT_CHAT_ID"
        echo "  - NOTIFY_BOT_URL"
        echo ""
        read -p "按 Enter 键继续（请确保已配置 .env 文件）..."
    else
        echo "❌ env.example 文件不存在！"
        exit 1
    fi
fi

# 停止并删除旧容器
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 停止并删除旧容器..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    echo "✅ 旧容器已删除"
fi

# 删除旧镜像
if docker images --format '{{.Repository}}' 2>/dev/null | grep -q "^${IMAGE_NAME}$"; then
    echo "🗑️  删除旧镜像..."
    docker rmi $IMAGE_NAME 2>/dev/null || true
    echo "✅ 旧镜像已删除"
fi

# 构建新镜像
echo "🔨 构建 Docker 镜像..."
docker build -t $IMAGE_NAME .

# 运行容器（使用当前目录的 .env 文件）
echo "▶️  启动容器..."
CURRENT_DIR=$(pwd)
ENV_FILE="$CURRENT_DIR/.env"
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在: $ENV_FILE"
    exit 1
fi
echo "当前目录: $CURRENT_DIR"
echo "使用环境变量文件: $ENV_FILE"

docker run -d \
    -p ${PORT}:${PORT} \
    --network notify-net \
    --env-file "$ENV_FILE" \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    $IMAGE_NAME

# 等待容器启动
sleep 2

# 检查容器状态
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
    echo ""
    echo "🧪 测试 API:"
    echo "  curl -X POST http://localhost:${PORT}/sendBot \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -H 'X-API-Key: YOUR_API_KEY' \\"
    echo "    -d '{\"message\": \"测试消息\"}'"
else
    echo "❌ 部署失败，查看日志:"
    docker logs $CONTAINER_NAME 2>/dev/null || echo "容器未启动，请检查错误信息"
    exit 1
fi

