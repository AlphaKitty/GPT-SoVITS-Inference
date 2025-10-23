#!/bin/bash

# 独立的依赖安装脚本
# 如果 start_docker.sh 的自动安装有问题，可以手动运行此脚本

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
echo "  GPT-SoVITS 依赖安装脚本"
echo "======================================"
echo ""

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then
    print_warning "请不要使用 root 用户运行此脚本"
    print_info "使用普通用户运行，脚本会在需要时使用 sudo"
    exit 1
fi

# 安装 Docker
install_docker() {
    print_info "=== 安装 Docker ==="
    echo ""

    print_info "更新系统包..."
    sudo apt-get update

    print_info "安装依赖包..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    print_info "使用官方脚本安装 Docker..."
    curl -fsSL https://get.docker.com | sudo bash

    print_info "启动 Docker 服务..."
    sudo systemctl enable docker
    sudo systemctl start docker

    print_info "将用户 $USER 添加到 docker 组..."
    sudo usermod -aG docker $USER

    print_success "Docker 安装完成！"
    echo ""
    docker --version
    echo ""

    print_warning "重要: Docker 组权限需要重新登录后才能生效"
    print_info "请在安装完成后:"
    echo "  1. 退出当前终端会话"
    echo "  2. 重新登录"
    echo "  3. 或运行: newgrp docker"
    echo ""
}

# 安装 Docker Compose
install_docker_compose() {
    print_info "=== 安装 Docker Compose ==="
    echo ""

    print_info "更新包索引..."
    sudo apt-get update

    print_info "安装 Docker Compose Plugin..."
    sudo apt-get install -y docker-compose-plugin

    print_success "Docker Compose 安装完成！"
    echo ""
    docker compose version
    echo ""
}

# 安装 NVIDIA Container Toolkit
install_nvidia_toolkit() {
    print_info "=== 安装 NVIDIA Container Toolkit ==="
    echo ""

    # 检查 NVIDIA 驱动
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        print_error "未检测到 NVIDIA 驱动"
        print_info "请先安装 NVIDIA 驱动:"
        print_info "  sudo apt-get install nvidia-driver-535"
        return 1
    fi

    print_success "检测到 NVIDIA 驱动"
    nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    echo ""

    print_info "配置 NVIDIA 仓库..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    print_info "更新包索引..."
    sudo apt-get update

    print_info "安装 NVIDIA Container Toolkit..."
    sudo apt-get install -y nvidia-container-toolkit

    print_info "配置 Docker 运行时..."
    sudo nvidia-ctk runtime configure --runtime=docker

    print_info "重启 Docker 服务..."
    sudo systemctl restart docker

    print_success "NVIDIA Container Toolkit 安装完成！"
    echo ""

    print_info "验证 GPU 可用性..."
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi >/dev/null 2>&1; then
        print_success "GPU 在 Docker 中可用"
    else
        print_warning "GPU 验证失败，请检查配置"
    fi
    echo ""
}

# 主菜单
main_menu() {
    while true; do
        echo ""
        echo "======================================"
        echo "  请选择要安装的组件"
        echo "======================================"
        echo "1) 安装 Docker"
        echo "2) 安装 Docker Compose"
        echo "3) 安装 NVIDIA Container Toolkit (需要 NVIDIA GPU)"
        echo "4) 安装全部 (Docker + Docker Compose)"
        echo "5) 安装全部 (包括 NVIDIA Toolkit)"
        echo "6) 检查当前状态"
        echo "0) 退出"
        echo ""

        read -p "请选择 (0-6): " choice

        case $choice in
            1)
                install_docker
                ;;
            2)
                install_docker_compose
                ;;
            3)
                install_nvidia_toolkit
                ;;
            4)
                install_docker
                install_docker_compose
                print_success "所有基础组件安装完成！"
                echo ""
                print_warning "重要: 请重新登录或运行 'newgrp docker' 以应用 docker 组权限"
                ;;
            5)
                install_docker
                install_docker_compose
                install_nvidia_toolkit
                print_success "所有组件安装完成！"
                echo ""
                print_warning "重要: 请重新登录或运行 'newgrp docker' 以应用 docker 组权限"
                ;;
            6)
                check_status
                ;;
            0)
                print_info "退出安装程序"
                exit 0
                ;;
            *)
                print_error "无效选择，请重试"
                ;;
        esac

        echo ""
        read -p "按 Enter 键继续..."
    done
}

# 检查状态
check_status() {
    echo ""
    print_info "=== 检查当前状态 ==="
    echo ""

    # Docker
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker: 已安装"
        echo "  版本: $(docker --version)"
        if systemctl is-active --quiet docker; then
            echo "  状态: 运行中"
        else
            print_warning "  状态: 未运行"
        fi
    else
        print_warning "Docker: 未安装"
    fi
    echo ""

    # Docker Compose
    if docker compose version >/dev/null 2>&1; then
        print_success "Docker Compose: 已安装"
        echo "  版本: $(docker compose version)"
    else
        print_warning "Docker Compose: 未安装"
    fi
    echo ""

    # NVIDIA GPU
    if command -v nvidia-smi >/dev/null 2>&1; then
        print_success "NVIDIA 驱动: 已安装"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | nl -w2 -s'. '
        echo ""

        # NVIDIA Container Toolkit
        if command -v nvidia-ctk >/dev/null 2>&1; then
            print_success "NVIDIA Container Toolkit: 已安装"
        else
            print_warning "NVIDIA Container Toolkit: 未安装"
        fi
    else
        print_info "NVIDIA GPU: 未检测到"
    fi
    echo ""

    # Docker 组权限
    if groups | grep -q docker; then
        print_success "Docker 组权限: 已配置"
    else
        print_warning "Docker 组权限: 未配置"
        echo "  运行: sudo usermod -aG docker $USER"
        echo "  然后重新登录或运行: newgrp docker"
    fi
    echo ""
}

# 运行主菜单
main_menu
