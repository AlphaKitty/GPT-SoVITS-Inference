#!/bin/bash

# GPT-SoVITS Docker Compose 快速启动脚本
# 适用于 Ubuntu 系统
# 使用默认配置快速启动 CUDA 12.8 完整版服务

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo "=================================="
echo "  GPT-SoVITS 快速启动"
echo "=================================="
echo ""

# 默认使用 GPT-SoVITS-CU128
SERVICE="GPT-SoVITS-CU128"

print_info "使用默认配置启动 $SERVICE..."
docker compose up -d "$SERVICE"

echo ""
print_success "服务已启动"
echo ""
echo "访问地址:"
echo "  - WebUI: http://localhost:8000"
echo ""
echo "常用命令:"
echo "  - 查看日志: docker compose logs -f $SERVICE"
echo "  - 停止服务: docker compose down"
echo "  - 重启服务: docker compose restart $SERVICE"
echo ""
