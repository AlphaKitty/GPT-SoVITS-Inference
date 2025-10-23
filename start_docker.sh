#!/bin/bash

# GPT-SoVITS Docker Compose 启动脚本
# 适用于 Ubuntu 系统

# 注意: 不在开头使用 set -e，因为需要处理某些命令的失败情况

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

# 检测系统类型
detect_os() {
    # 优先检查 /etc/os-release 文件
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_TYPE=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
        print_info "检测到系统: $NAME $VERSION"
        return 0
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS_TYPE=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$DISTRIB_RELEASE
        OS_NAME=$DISTRIB_DESCRIPTION
        print_info "检测到系统: $DISTRIB_DESCRIPTION"
        return 0
    else
        print_warning "无法从配置文件检测系统类型"
        # 尝试使用 uname
        OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(uname -r)
        OS_NAME="$OS_TYPE $OS_VERSION"
        print_info "系统信息: $OS_NAME"
        return 1
    fi
}

# 安装 Docker
install_docker() {
    print_info "开始安装 Docker..."

    # 检测系统类型
    detect_os

    # 检查是否有 apt-get 或 apt（Ubuntu/Debian 的包管理器）
    HAS_APT=false

    if command -v apt-get >/dev/null 2>&1; then
        HAS_APT=true
        print_success "检测到 apt-get: $(command -v apt-get)"
    elif command -v apt >/dev/null 2>&1; then
        HAS_APT=true
        print_success "检测到 apt: $(command -v apt)"
    elif which apt-get >/dev/null 2>&1; then
        HAS_APT=true
        print_success "检测到 apt-get (使用 which): $(which apt-get)"
    elif which apt >/dev/null 2>&1; then
        HAS_APT=true
        print_success "检测到 apt (使用 which): $(which apt)"
    fi

    if [ "$HAS_APT" = false ]; then
        print_error "此脚本仅支持 Ubuntu/Debian 系统（需要 apt/apt-get）"
        if [ "$OS_TYPE" != "unknown" ]; then
            print_info "检测到的系统类型: $OS_TYPE"
        fi
        print_info "请检查您的 PATH 环境变量: $PATH"
        print_info "如果您使用的是 Ubuntu/Debian，请确保已安装 apt 或 apt-get"
        exit 1
    fi

    print_success "系统检查通过，开始安装 Docker..."

    # 更新包索引
    print_info "更新系统包索引..."
    sudo apt-get update

    # 安装必要的依赖
    print_info "安装依赖包..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 使用官方安装脚本安装 Docker
    print_info "下载并执行 Docker 官方安装脚本..."
    curl -fsSL https://get.docker.com | sudo bash

    # 将当前用户添加到 docker 组
    print_info "将当前用户添加到 docker 组..."
    sudo usermod -aG docker $USER

    # 启动 Docker 服务
    print_info "启动 Docker 服务..."
    sudo systemctl enable docker
    sudo systemctl start docker

    print_success "Docker 安装完成: $(docker --version)"
    print_warning "重要: 需要重新登录以使 docker 组权限生效"
    echo ""
    print_info "请选择以下方式之一应用权限:"
    echo "  1. 重新登录系统（推荐）"
    echo "  2. 运行: newgrp docker"
    echo "  3. 继续运行（可能需要 sudo）"
    echo ""
}

# 安装 Docker Compose
install_docker_compose() {
    print_info "开始安装 Docker Compose..."

    # 更新包索引
    sudo apt-get update

    # 安装 Docker Compose 插件
    print_info "安装 Docker Compose 插件..."
    sudo apt-get install -y docker-compose-plugin

    print_success "Docker Compose 安装完成"
}

# 检查 Docker 是否安装
check_docker() {
    print_info "检查 Docker 是否安装..."
    if ! command -v docker &> /dev/null; then
        print_warning "Docker 未安装"

        # 询问是否自动安装
        read -p "是否自动安装 Docker? (y/n, 默认 y): " install
        install=${install:-y}

        if [ "$install" = "y" ] || [ "$install" = "Y" ]; then
            install_docker

            # 验证安装
            if ! command -v docker &> /dev/null; then
                print_error "Docker 安装失败"
                exit 1
            fi
            print_success "Docker 已安装: $(docker --version)"
        else
            print_error "Docker 是必需的，无法继续"
            print_info "手动安装命令: curl -fsSL https://get.docker.com | bash"
            exit 1
        fi
    else
        print_success "Docker 已安装: $(docker --version)"
    fi
}

# 检查 Docker Compose 是否安装
check_docker_compose() {
    print_info "检查 Docker Compose 是否安装..."
    if ! command -v docker compose &> /dev/null; then
        print_warning "Docker Compose 未安装"

        # 询问是否自动安装
        read -p "是否自动安装 Docker Compose? (y/n, 默认 y): " install
        install=${install:-y}

        if [ "$install" = "y" ] || [ "$install" = "Y" ]; then
            install_docker_compose

            # 验证安装
            if ! command -v docker compose &> /dev/null; then
                print_error "Docker Compose 安装失败"
                exit 1
            fi
            print_success "Docker Compose 已安装: $(docker compose version)"
        else
            print_error "Docker Compose 是必需的，无法继续"
            print_info "手动安装命令: sudo apt-get install docker-compose-plugin"
            exit 1
        fi
    else
        print_success "Docker Compose 已安装: $(docker compose version)"
    fi
}

# 安装 NVIDIA Container Toolkit
install_nvidia_toolkit() {
    print_info "开始安装 NVIDIA Container Toolkit..."

    # 检查是否已安装 NVIDIA 驱动
    if ! command -v nvidia-smi &> /dev/null; then
        print_error "未检测到 NVIDIA 驱动，请先安装 NVIDIA 驱动"
        print_info "安装 NVIDIA 驱动: sudo apt-get install nvidia-driver-535"
        return 1
    fi

    # 配置 NVIDIA 仓库
    print_info "配置 NVIDIA 仓库..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    # 添加 GPG 密钥
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    # 添加仓库
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    # 更新包索引
    sudo apt-get update

    # 安装 NVIDIA Container Toolkit
    print_info "安装 NVIDIA Container Toolkit..."
    sudo apt-get install -y nvidia-container-toolkit

    # 配置 Docker 运行时
    print_info "配置 Docker 运行时..."
    sudo nvidia-ctk runtime configure --runtime=docker

    # 重启 Docker 服务
    print_info "重启 Docker 服务..."
    sudo systemctl restart docker

    print_success "NVIDIA Container Toolkit 安装完成"

    # 验证安装
    print_info "验证 GPU 在 Docker 中可用..."
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi &> /dev/null; then
        print_success "GPU 在 Docker 中可用"
        return 0
    else
        print_warning "GPU 验证失败，但工具包已安装"
        return 1
    fi
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
            print_warning "NVIDIA Container Toolkit 未配置"

            # 询问是否安装 NVIDIA Container Toolkit
            read -p "是否安装 NVIDIA Container Toolkit 以启用 GPU 支持? (y/n, 默认 y): " install_nvidia
            install_nvidia=${install_nvidia:-y}

            if [ "$install_nvidia" = "y" ] || [ "$install_nvidia" = "Y" ]; then
                if install_nvidia_toolkit; then
                    USE_GPU=true
                else
                    print_warning "将使用 CPU 模式"
                    USE_GPU=false
                fi
            else
                print_warning "将使用 CPU 模式"
                print_info "手动安装命令: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
                USE_GPU=false
            fi
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
