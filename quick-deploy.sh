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

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在！"
    echo "请先复制 env.example 到 .env 并配置："
    echo "  cp env.example .env"
    echo "  nano .env"
    exit 1
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

# 读取 .env 文件中的环境变量
echo "📖 读取环境变量..."
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在"
    exit 1
fi

# 解析 .env 文件
while IFS='=' read -r key value || [ -n "$key" ]; do
    # 跳过注释和空行
    case "$key" in
        \#*|"") continue ;;
    esac
    # 移除空格
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs | sed "s/^['\"]//;s/['\"]$//")
    # 只导出非空值
    if [ -n "$key" ] && [ -n "$value" ]; then
        export "$key=$value"
    fi
done < .env

# 显示读取的环境变量（隐藏敏感信息）
echo "读取到的环境变量:"
if [ -n "$API_KEY" ]; then
    API_KEY_PREVIEW=$(echo "$API_KEY" | cut -c1-10)
    echo "  API_KEY: ${API_KEY_PREVIEW}***"
else
    echo "  API_KEY: (未设置)"
fi
echo "  NOTIFY_BOT_CHAT_ID: ${NOTIFY_BOT_CHAT_ID:-未设置}"
echo "  NOTIFY_BOT_URL: ${NOTIFY_BOT_URL:-未设置}"
echo ""

# 运行容器（直接传递环境变量）
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
