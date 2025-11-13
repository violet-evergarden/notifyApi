#!/bin/bash

# 验证容器中的环境变量脚本

CONTAINER_NAME="notify-api"

echo "🔍 验证容器中的环境变量..."
echo ""

if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ 容器 $CONTAINER_NAME 未运行"
    exit 1
fi

echo "容器中的环境变量:"
echo "===================="
docker exec $CONTAINER_NAME env | grep -E "(API_KEY|NOTIFY_BOT|PORT|NODE_ENV)" | sort
echo "===================="
echo ""

echo "检查 .env 文件内容:"
echo "===================="
if [ -f ".env" ]; then
    cat .env | grep -v "^#" | grep -v "^$"
    echo ""
    echo "检查 .env 文件路径:"
    echo "  $(pwd)/.env"
else
    echo "❌ .env 文件不存在"
fi
echo "===================="
echo ""
echo "💡 如果环境变量不匹配，请："
echo "  1. 停止容器: docker stop $CONTAINER_NAME"
echo "  2. 删除容器: docker rm $CONTAINER_NAME"
echo "  3. 重新运行部署脚本: ./quick-deploy.sh"

