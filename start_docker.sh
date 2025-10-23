#!/bin/bash

# GPT-SoVITS Docker Compose 启动脚本
# 适用于 Ubuntu 系统

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
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

# 检查是否为 root 或 sudo 用户
check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "检测到使用 root 用户运行，建议使用普通用户并配置 Docker 用户组权限"
    fi
}

# 检查 Docker 是否安装
check_docker() {
    print_info "检查 Docker 是否安装..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        print_info "安装命令: curl -fsSL https://get.docker.com | bash"
        exit 1
    fi
    print_success "Docker 已安装: $(docker --version)"
}

# 检查 Docker Compose 是否安装
check_docker_compose() {
    print_info "检查 Docker Compose 是否安装..."
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        print_info "安装命令: sudo apt-get install docker-compose-plugin"
        exit 1
    fi
    print_success "Docker Compose 已安装: $(docker compose version)"
}

# 检查 NVIDIA Docker 支持（用于 GPU）
check_nvidia_docker() {
    print_info "检查 NVIDIA Docker 支持..."
    if command -v nvidia-smi &> /dev/null; then
        print_success "检测到 NVIDIA GPU"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

        # 检查 NVIDIA Container Toolkit
        if docker info 2>/dev/null | grep -q "nvidia"; then
            print_success "NVIDIA Container Toolkit 已配置"
            USE_GPU=true
        else
            print_warning "NVIDIA Container Toolkit 未配置，将使用 CPU 模式"
            print_info "安装 NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
            USE_GPU=false
        fi
    else
        print_warning "未检测到 NVIDIA GPU，将使用 CPU 模式"
        USE_GPU=false
    fi
}

# 检查 docker-compose.yaml 是否存在
check_compose_file() {
    print_info "检查 docker-compose.yaml 文件..."
    if [ ! -f "docker-compose.yaml" ]; then
        print_error "docker-compose.yaml 文件不存在"
        exit 1
    fi
    print_success "docker-compose.yaml 文件存在"
}

# 选择服务版本
select_service() {
    print_info "请选择要启动的服务版本:"
    echo "1) GPT-SoVITS-CU128 (CUDA 12.8 完整版)"
    echo "2) GPT-SoVITS-CU128-Lite (CUDA 12.8 轻量版)"
    echo "3) GPT-SoVITS-CU126 (CUDA 12.6 完整版)"
    echo "4) GPT-SoVITS-CU126-Lite (CUDA 12.6 轻量版)"

    read -p "请输入选项 (1-4, 默认为 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            SERVICE="GPT-SoVITS-CU128"
            ;;
        2)
            SERVICE="GPT-SoVITS-CU128-Lite"
            ;;
        3)
            SERVICE="GPT-SoVITS-CU126"
            ;;
        4)
            SERVICE="GPT-SoVITS-CU126-Lite"
            ;;
        *)
            print_error "无效的选项"
            exit 1
            ;;
    esac

    print_success "已选择服务: $SERVICE"
}

# 拉取 Docker 镜像
pull_image() {
    print_info "拉取 Docker 镜像 (这可能需要一些时间)..."
    if docker compose pull "$SERVICE"; then
        print_success "镜像拉取成功"
    else
        print_error "镜像拉取失败"
        exit 1
    fi
}

# 启动服务
start_service() {
    print_info "启动 $SERVICE 服务..."

    # 如果没有 GPU 支持，则不使用 GPU
    if [ "$USE_GPU" = false ]; then
        print_warning "在没有 GPU 的情况下启动服务"
    fi

    if docker compose up -d "$SERVICE"; then
        print_success "$SERVICE 服务启动成功"
    else
        print_error "服务启动失败"
        exit 1
    fi
}

# 显示服务状态
show_status() {
    print_info "服务状态:"
    docker compose ps

    echo ""
    print_info "服务访问地址:"
    echo "  - WebUI: http://localhost:8000"
    echo "  - Port 9871: http://localhost:9871"
    echo "  - Port 9872: http://localhost:9872"
    echo "  - Port 9873: http://localhost:9873"
    echo "  - Port 9874: http://localhost:9874"
    echo "  - Port 9880: http://localhost:9880"

    echo ""
    print_info "查看日志: docker compose logs -f $SERVICE"
    print_info "停止服务: docker compose down"
    print_info "重启服务: docker compose restart $SERVICE"
}

# 询问是否查看日志
ask_view_logs() {
    echo ""
    read -p "是否查看实时日志? (y/n, 默认 n): " view_logs
    view_logs=${view_logs:-n}

    if [ "$view_logs" = "y" ] || [ "$view_logs" = "Y" ]; then
        print_info "查看实时日志 (按 Ctrl+C 退出)..."
        docker compose logs -f "$SERVICE"
    fi
}

# 主函数
main() {
    echo "=================================="
    echo "  GPT-SoVITS Docker 启动脚本"
    echo "=================================="
    echo ""

    # 检查环境
    check_user
    check_docker
    check_docker_compose
    check_nvidia_docker
    check_compose_file

    echo ""

    # 选择服务
    select_service

    echo ""

    # 询问是否拉取最新镜像
    read -p "是否拉取最新镜像? (y/n, 默认 y): " pull_latest
    pull_latest=${pull_latest:-y}

    if [ "$pull_latest" = "y" ] || [ "$pull_latest" = "Y" ]; then
        pull_image
    fi

    echo ""

    # 启动服务
    start_service

    echo ""

    # 显示状态
    show_status

    # 询问是否查看日志
    ask_view_logs

    echo ""
    print_success "脚本执行完成"
}

# 运行主函数
main
