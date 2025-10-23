#!/bin/bash

# GPT-SoVITS Docker Compose 停止脚本
# 适用于 Ubuntu 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=================================="
echo "  GPT-SoVITS Docker 停止脚本"
echo "=================================="
echo ""

print_info "检查运行中的容器..."
docker compose ps

echo ""
read -p "是否停止所有服务? (y/n, 默认 y): " confirm
confirm=${confirm:-y}

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    print_info "停止服务..."
    docker compose down
    print_success "所有服务已停止"
else
    print_info "取消操作"
fi

echo ""
read -p "是否删除容器和相关资源? (y/n, 默认 n): " cleanup
cleanup=${cleanup:-n}

if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ]; then
    print_warning "删除容器、网络和卷..."
    docker compose down -v
    print_success "已清理所有资源"
fi
