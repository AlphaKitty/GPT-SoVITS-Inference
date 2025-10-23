#!/bin/bash

# GPT-SoVITS Docker Compose 简化启动脚本
# 移除了所有复杂的检测逻辑，直接启动

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "======================================"
echo "  GPT-SoVITS Docker 简化启动脚本"
echo "======================================"
echo ""

# 1. 检查 Docker
print_info "检查 Docker..."
if command -v docker >/dev/null 2>&1; then
    print_success "Docker 已安装: $(docker --version)"
else
    print_error "Docker 未安装"
    print_info "安装命令: curl -fsSL https://get.docker.com | sudo bash"
    exit 1
fi

# 2. 检查 Docker Compose
print_info "检查 Docker Compose..."
if docker compose version >/dev/null 2>&1; then
    print_success "Docker Compose 已安装: $(docker compose version)"
else
    print_error "Docker Compose 未安装"
    print_info "安装命令: sudo apt-get install docker-compose-plugin"
    exit 1
fi

# 3. 检查 docker-compose.yaml
print_info "检查 docker-compose.yaml..."
if [ -f "docker-compose.yaml" ]; then
    print_success "配置文件存在"
else
    print_error "docker-compose.yaml 文件不存在"
    exit 1
fi

# 4. 选择服务
echo ""
print_info "可用的服务版本:"
echo "1) GPT-SoVITS-CU128 (CUDA 12.8 完整版) - 推荐"
echo "2) GPT-SoVITS-CU128-Lite (CUDA 12.8 轻量版)"
echo "3) GPT-SoVITS-CU126 (CUDA 12.6 完整版)"
echo "4) GPT-SoVITS-CU126-Lite (CUDA 12.6 轻量版)"
echo ""

read -p "请选择 (1-4, 默认 1): " choice
choice=${choice:-1}

case $choice in
    1) SERVICE="GPT-SoVITS-CU128" ;;
    2) SERVICE="GPT-SoVITS-CU128-Lite" ;;
    3) SERVICE="GPT-SoVITS-CU126" ;;
    4) SERVICE="GPT-SoVITS-CU126-Lite" ;;
    *)
        print_error "无效选择"
        exit 1
        ;;
esac

print_success "已选择: $SERVICE"
echo ""

# 5. 拉取镜像
read -p "是否拉取最新镜像? (y/n, 默认 y): " pull
pull=${pull:-y}

if [ "$pull" = "y" ] || [ "$pull" = "Y" ]; then
    print_info "拉取 Docker 镜像..."
    docker compose pull "$SERVICE" || {
        print_error "镜像拉取失败"
        exit 1
    }
    print_success "镜像拉取成功"
fi

echo ""

# 6. 启动服务
print_info "启动 $SERVICE 服务..."
docker compose up -d "$SERVICE" || {
    print_error "服务启动失败"
    exit 1
}

print_success "服务启动成功！"
echo ""

# 7. 显示状态
print_info "服务状态:"
docker compose ps
echo ""

print_success "访问地址: http://localhost:8000"
echo ""
print_info "常用命令:"
echo "  查看日志: docker compose logs -f $SERVICE"
echo "  停止服务: docker compose down"
echo "  重启服务: docker compose restart $SERVICE"
echo ""

# 8. 询问是否查看日志
read -p "是否查看实时日志? (y/n, 默认 n): " logs
logs=${logs:-n}

if [ "$logs" = "y" ] || [ "$logs" = "Y" ]; then
    print_info "查看实时日志 (按 Ctrl+C 退出)..."
    docker compose logs -f "$SERVICE"
fi

print_success "完成！"
