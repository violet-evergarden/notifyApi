#!/bin/bash

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

# 停止并删除旧容器（如果存在）
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "🛑 停止并删除旧容器..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

# 构建镜像
echo "🔨 构建 Docker 镜像..."
docker build -t $IMAGE_NAME .

# 检查 .env 文件
ENV_FILE_PATH=".env"
if [ ! -f "$ENV_FILE_PATH" ]; then
    echo "❌ .env 文件不存在！"
    exit 1
fi

echo "📋 检查 .env 文件..."
echo "✅ .env 文件存在: $(pwd)/$ENV_FILE_PATH"
echo "环境变量配置:"
grep -v "^#" "$ENV_FILE_PATH" | grep -v "^$" | sed 's/=.*/=***/' || echo "  (无有效配置)"
echo ""

# 验证 .env 文件格式
echo "验证 .env 文件格式..."
if grep -q "your-chat-id-here\|<your-bot-token>" "$ENV_FILE_PATH"; then
    echo "⚠️  警告: .env 文件中包含模板值，请确保已替换为实际值"
fi

# 读取 .env 文件中的环境变量
echo "📖 读取环境变量..."
source "$ENV_FILE_PATH" 2>/dev/null || true

# 验证环境变量是否读取成功
if [ -z "$API_KEY" ] || [ -z "$NOTIFY_BOT_CHAT_ID" ] || [ -z "$NOTIFY_BOT_URL" ]; then
    echo "⚠️  警告: 从 .env 文件读取环境变量失败，尝试直接解析..."
    # 直接解析 .env 文件
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # 移除引号和空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | sed "s/^['\"]//;s/['\"]$//")
        export "$key=$value"
    done < "$ENV_FILE_PATH"
fi

# 显示读取的环境变量（隐藏敏感信息）
echo "读取到的环境变量:"
echo "  API_KEY: ${API_KEY:0:10}***"
echo "  NOTIFY_BOT_CHAT_ID: $NOTIFY_BOT_CHAT_ID"
echo "  NOTIFY_BOT_URL: $NOTIFY_BOT_URL"
echo ""

# 运行容器（直接传递环境变量，而不是使用 --env-file）
echo "▶️  启动容器..."
docker run -d \
    -p ${PORT}:${PORT} \
    -e API_KEY="$API_KEY" \
    -e NOTIFY_BOT_CHAT_ID="$NOTIFY_BOT_CHAT_ID" \
    -e NOTIFY_BOT_URL="$NOTIFY_BOT_URL" \
    -e PORT="${PORT:-8848}" \
    -e NODE_ENV="${NODE_ENV:-production}" \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    $IMAGE_NAME

echo "✅ 容器已启动，环境变量已通过 -e 参数传递"

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
