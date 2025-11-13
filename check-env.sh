#!/bin/bash

# 检查 .env 文件格式的脚本

echo "检查 .env 文件格式..."

if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在"
    exit 1
fi

echo ""
echo "当前 .env 文件内容:"
echo "===================="
cat .env
echo "===================="
echo ""

# 检查常见问题
echo "检查常见问题:"
echo ""

# 检查是否有等号
if ! grep -q "=" .env; then
    echo "❌ 错误: .env 文件中没有找到 '=' 符号"
    echo "   正确格式: KEY=value"
fi

# 检查是否有引号（可能导致问题）
if grep -q '".*=' .env || grep -q "'.*=" .env; then
    echo "⚠️  警告: .env 文件中包含引号，可能导致问题"
    echo "   建议格式: KEY=value (不要使用引号)"
fi

# 检查是否有空格
if grep -q " = " .env || grep -q "= " .env || grep -q " =" .env; then
    echo "⚠️  警告: .env 文件中的值前后可能有空格"
    echo "   建议格式: KEY=value (等号前后不要有空格)"
fi

# 检查必需变量
echo ""
echo "检查必需的环境变量:"
echo ""

REQUIRED_VARS=("API_KEY" "NOTIFY_BOT_CHAT_ID" "NOTIFY_BOT_URL")
for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^${var}=" .env; then
        value=$(grep "^${var}=" .env | cut -d'=' -f2-)
        if [ -z "$value" ] || [ "$value" = "your-chat-id-here" ] || [ "$value" = "<your-bot-token>" ]; then
            echo "❌ ${var}: 未设置或使用默认值"
        else
            echo "✅ ${var}: 已设置"
        fi
    else
        echo "❌ ${var}: 未找到"
    fi
done

echo ""
echo "正确的 .env 文件格式示例:"
echo "API_KEY=your-actual-api-key"
echo "NOTIFY_BOT_CHAT_ID=123456789"
echo "NOTIFY_BOT_URL=https://api.telegram.org/bot123456789:ABCdefGHIjklMNOpqrsTUVwxyz/"

