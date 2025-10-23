#!/bin/bash

# GPT-SoVITS Docker 启动脚本 - 最终优化版
# 功能：检测并安装依赖，然后启动服务

set -euo pipefail  # 严格模式，但只在主流程中

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# 错误处理
trap 'print_error "脚本执行失败，请查看错误信息"; exit 1' ERR

echo "======================================"
echo "  GPT-SoVITS Docker 启动脚本"
echo "======================================"
echo ""

# 全局变量
NEED_RELOGIN=false

# ==================== 检查函数 ====================

# 检查 Docker
check_docker() {
    print_info "检查 Docker..."
    if command -v docker &>/dev/null; then
        if docker ps &>/dev/null; then
            print_success "Docker 已安装并可用: $(docker --version)"
            return 0
        else
            print_warning "Docker 已安装但无权限，可能需要 sudo 或重新登录"
            if groups | grep -q docker; then
                print_info "您已在 docker 组中，但权限未生效"
                print_warning "请运行: newgrp docker 或重新登录"
                NEED_RELOGIN=true
            else
                print_warning "您不在 docker 组中"
            fi
            return 1
        fi
    else
        print_warning "Docker 未安装"
        return 1
    fi
}

# 检查 Docker Compose
check_docker_compose() {
    print_info "检查 Docker Compose..."
    if docker compose version &>/dev/null; then
        print_success "Docker Compose 已安装: $(docker compose version --short)"
        return 0
    else
        print_warning "Docker Compose 未安装"
        return 1
    fi
}

# 检查 NVIDIA GPU
check_nvidia() {
    print_info "检查 NVIDIA GPU..."
    if command -v nvidia-smi &>/dev/null; then
        print_success "检测到 NVIDIA GPU"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || true

        # 检查 Container Toolkit
        if docker info 2>/dev/null | grep -qi nvidia; then
            print_success "NVIDIA Container Toolkit 已配置"
            return 0
        else
            print_warning "NVIDIA Container Toolkit 未配置"
            return 1
        fi
    else
        print_info "未检测到 NVIDIA GPU"
        return 2
    fi
}

# ==================== 安装函数 ====================

# 安装 Docker
install_docker() {
    print_info "开始安装 Docker..."

    # 更新包索引
    print_info "更新系统包索引..."
    sudo apt-get update -qq

    # 安装依赖
    print_info "安装依赖包..."
    sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release

    # 使用官方脚本安装
    print_info "使用官方脚本安装 Docker..."
    curl -fsSL https://get.docker.com | sudo bash

    # 配置服务
    sudo systemctl enable docker --now

    # 添加到 docker 组
    print_info "配置用户权限..."
    sudo usermod -aG docker "$USER"

    print_success "Docker 安装完成"
    NEED_RELOGIN=true
}

# 安装 Docker Compose
install_docker_compose() {
    print_info "开始安装 Docker Compose..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-compose-plugin
    print_success "Docker Compose 安装完成"
}

# 安装 NVIDIA Container Toolkit
install_nvidia_toolkit() {
    print_info "开始安装 NVIDIA Container Toolkit..."

    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    # 添加 GPG 密钥
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    # 添加仓库
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

    # 安装
    sudo apt-get update -qq
    sudo apt-get install -y -qq nvidia-container-toolkit

    # 配置
    sudo nvidia-ctk runtime configure --runtime=docker >/dev/null
    sudo systemctl restart docker

    print_success "NVIDIA Container Toolkit 安装完成"
}

# ==================== 主流程 ====================

# 1. 检查并安装 Docker
if ! check_docker; then
    read -p "是否安装 Docker? (y/n, 默认 y): " install
    install=${install:-y}
    if [[ "$install" =~ ^[Yy]$ ]]; then
        install_docker
    else
        print_error "Docker 是必需的，无法继续"
        exit 1
    fi
fi

echo ""

# 2. 检查并安装 Docker Compose
if ! check_docker_compose; then
    read -p "是否安装 Docker Compose? (y/n, 默认 y): " install
    install=${install:-y}
    if [[ "$install" =~ ^[Yy]$ ]]; then
        install_docker_compose
    else
        print_error "Docker Compose 是必需的，无法继续"
        exit 1
    fi
fi

echo ""

# 3. 检查并安装 NVIDIA Toolkit（可选）
nvidia_status=$(check_nvidia; echo $?)
if [ "$nvidia_status" -eq 1 ]; then
    # 有 GPU 但未配置
    read -p "是否安装 NVIDIA Container Toolkit? (y/n, 默认 y): " install
    install=${install:-y}
    if [[ "$install" =~ ^[Yy]$ ]]; then
        install_nvidia_toolkit || print_warning "NVIDIA Toolkit 安装失败，将继续使用 CPU 模式"
    fi
fi

echo ""

# 4. 检查是否需要重新登录
if [ "$NEED_RELOGIN" = true ]; then
    print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_warning "重要: Docker 组权限需要重新登录才能生效"
    print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "请选择:"
    echo "  1. 现在退出，重新登录后运行此脚本"
    echo "  2. 使用 sudo 继续（不推荐）"
    echo "  3. 尝试 newgrp docker（可能有问题）"
    echo ""
    read -p "请选择 (1-3, 默认 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            print_info "请重新登录后运行: ./docker_start.sh"
            exit 0
            ;;
        2)
            USE_SUDO=true
            print_warning "将使用 sudo 运行 Docker 命令"
            ;;
        3)
            print_info "尝试应用权限..."
            exec newgrp docker <<EOF
bash "$0" --skip-check
EOF
            exit 0
            ;;
    esac
fi

echo ""

# 5. 检查 docker-compose.yaml
print_info "检查配置文件..."
if [ ! -f "docker-compose.yaml" ]; then
    print_error "docker-compose.yaml 文件不存在"
    exit 1
fi
print_success "配置文件存在"

echo ""

# 6. 选择服务
print_info "可用的服务版本:"
echo "  1) GPT-SoVITS-CU128 (CUDA 12.8 完整版) - 推荐"
echo "  2) GPT-SoVITS-CU128-Lite (CUDA 12.8 轻量版)"
echo "  3) GPT-SoVITS-CU126 (CUDA 12.6 完整版)"
echo "  4) GPT-SoVITS-CU126-Lite (CUDA 12.6 轻量版)"
echo ""

read -p "请选择 (1-4, 默认 1): " choice
choice=${choice:-1}

case $choice in
    1) SERVICE="GPT-SoVITS-CU128" ;;
    2) SERVICE="GPT-SoVITS-CU128-Lite" ;;
    3) SERVICE="GPT-SoVITS-CU126" ;;
    4) SERVICE="GPT-SoVITS-CU126-Lite" ;;
    *) print_error "无效选择"; exit 1 ;;
esac

print_success "已选择: $SERVICE"
echo ""

# 7. 拉取镜像
read -p "是否拉取最新镜像? (y/n, 默认 y): " pull
pull=${pull:-y}

DOCKER_CMD="docker"
[ "${USE_SUDO:-false}" = true ] && DOCKER_CMD="sudo docker"

if [[ "$pull" =~ ^[Yy]$ ]]; then
    print_info "拉取 Docker 镜像（可能需要较长时间）..."
    $DOCKER_CMD compose pull "$SERVICE"
    print_success "镜像拉取成功"
fi

echo ""

# 8. 启动服务
print_info "启动 $SERVICE 服务..."
$DOCKER_CMD compose up -d "$SERVICE"
print_success "服务启动成功"

echo ""

# 9. 显示状态
print_info "服务状态:"
$DOCKER_CMD compose ps

echo ""
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "  服务已成功启动！"
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 访问地址: http://localhost:8000"
echo ""
echo "📚 常用命令:"
echo "  查看日志: docker compose logs -f $SERVICE"
echo "  停止服务: docker compose down"
echo "  重启服务: docker compose restart $SERVICE"
echo ""

# 10. 询问是否查看日志
read -p "是否查看实时日志? (y/n, 默认 n): " logs
logs=${logs:-n}

if [[ "$logs" =~ ^[Yy]$ ]]; then
    print_info "查看实时日志 (按 Ctrl+C 退出)..."
    echo ""
    $DOCKER_CMD compose logs -f "$SERVICE"
fi

print_success "完成！"
