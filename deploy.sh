#!/bin/bash

# Notify API 一键部署脚本
# 使用方法: ./deploy.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
GIT_REPO="https://github.com/violet-evergarden/notifyApi.git"
PROJECT_DIR="notifyApi"
IMAGE_NAME="notify-api"
CONTAINER_NAME="notify-api"
PORT="8848"

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 $1"
        exit 1
    fi
}

# 检查 Docker 是否运行
check_docker() {
    # 检查 docker 命令是否存在（包括 sudo docker）
    if ! command -v docker &> /dev/null && ! command -v sudo &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 尝试直接运行 docker info
    if docker info > /dev/null 2>&1; then
        return 0
    fi
    
    # 如果失败，尝试使用 sudo
    if command -v sudo &> /dev/null && sudo docker info > /dev/null 2>&1; then
        print_warn "检测到需要使用 sudo 运行 docker 命令"
        # 修改后续的 docker 命令为 sudo docker
        DOCKER_CMD="sudo docker"
        return 0
    fi
    
    # 都失败了
    print_error "Docker 未运行或无权限访问"
    print_warn "提示:"
    print_warn "  1. 确保 Docker 已安装: curl -fsSL https://get.docker.com | sh"
    print_warn "  2. 确保 Docker 服务运行: sudo systemctl start docker"
    print_warn "  3. 或添加用户到 docker 组: sudo usermod -aG docker $USER"
    exit 1
}

# 主函数
main() {
    print_info "开始部署 Notify API..."
    
    # 检查必要的命令
    print_info "检查依赖..."
    check_command "docker"
    check_command "git"
    check_docker
    
    # 克隆或更新代码
    if [ -d "$PROJECT_DIR" ]; then
        print_warn "项目目录已存在，更新代码..."
        cd $PROJECT_DIR
        git pull || print_warn "Git pull 失败，继续使用现有代码"
    else
        print_info "克隆代码仓库..."
        git clone $GIT_REPO $PROJECT_DIR
        cd $PROJECT_DIR
    fi
    
    # 检查 .env 文件
    if [ ! -f ".env" ]; then
        print_warn ".env 文件不存在，从 env.example 复制..."
        if [ -f "env.example" ]; then
            cp env.example .env
            print_warn "请编辑 .env 文件，填入你的配置："
            print_warn "  - API_KEY"
            print_warn "  - NOTIFY_BOT_CHAT_ID"
            print_warn "  - NOTIFY_BOT_URL"
            print_warn ""
            read -p "按 Enter 键继续（请确保已配置 .env 文件）..."
        else
            print_error "env.example 文件不存在！"
            exit 1
        fi
    else
        print_info ".env 文件已存在"
    fi
    
    # 设置 docker 命令（如果检测到需要 sudo）
    DOCKER_CMD=${DOCKER_CMD:-docker}
    
    # 停止并删除旧容器（如果存在）
    if $DOCKER_CMD ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
        print_info "停止并删除旧容器..."
        $DOCKER_CMD stop $CONTAINER_NAME 2>/dev/null || true
        $DOCKER_CMD rm $CONTAINER_NAME 2>/dev/null || true
    fi
    
    # 构建镜像
    print_info "构建 Docker 镜像..."
    $DOCKER_CMD build -t $IMAGE_NAME .
    
    # 运行容器
    print_info "启动容器..."
    $DOCKER_CMD run -d \
        -p ${PORT}:${PORT} \
        --env-file .env \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        $IMAGE_NAME
    
    # 等待容器启动
    sleep 2
    
    # 检查容器状态
    if $DOCKER_CMD ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
        print_info "✅ 部署成功！"
        print_info "容器名称: $CONTAINER_NAME"
        print_info "端口: $PORT"
        print_info ""
        print_info "查看日志: $DOCKER_CMD logs -f $CONTAINER_NAME"
        print_info "停止容器: $DOCKER_CMD stop $CONTAINER_NAME"
        print_info "重启容器: $DOCKER_CMD restart $CONTAINER_NAME"
        print_info ""
        print_info "测试 API:"
        print_info "  curl -X POST http://localhost:${PORT}/sendBot \\"
        print_info "    -H 'Content-Type: application/json' \\"
        print_info "    -H 'X-API-Key: YOUR_API_KEY' \\"
        print_info "    -d '{\"message\": \"测试消息\"}'"
    else
        print_error "容器启动失败，请检查日志: $DOCKER_CMD logs $CONTAINER_NAME"
        exit 1
    fi
}

# 执行主函数
main

