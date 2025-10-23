#!/bin/bash

# GPT-SoVITS Docker 启动脚本 - 简单可靠版本
# 原则：简单、直接、不过度检测

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

echo "======================================"
echo "  GPT-SoVITS Docker 启动"
echo "======================================"
echo ""

# ==================== 1. 检查 Docker ====================
info "检查 Docker..."

if [ -x "$(command -v docker)" ]; then
    success "Docker 已安装: $(docker --version 2>/dev/null || echo '版本未知')"
else
    error "Docker 未安装"
    echo ""
    echo "请手动安装 Docker:"
    echo "  curl -fsSL https://get.docker.com | sudo bash"
    echo "  sudo usermod -aG docker \$USER"
    echo ""
    echo "然后重新登录并运行此脚本"
    exit 1
fi

# 测试 Docker 是否可用
if docker ps >/dev/null 2>&1; then
    success "Docker 运行正常"
elif sudo docker ps >/dev/null 2>&1; then
    warning "需要使用 sudo 运行 Docker"
    warning "建议将用户添加到 docker 组: sudo usermod -aG docker $USER"
    warning "然后重新登录"
    echo ""
    read -p "是否使用 sudo 继续? (y/n): " use_sudo
    if [[ ! "$use_sudo" =~ ^[Yy]$ ]]; then
        exit 1
    fi
    DOCKER="sudo docker"
else
    error "Docker 无法运行，请检查安装"
    exit 1
fi

DOCKER=${DOCKER:-docker}

echo ""

# ==================== 2. 检查 Docker Compose ====================
info "检查 Docker Compose..."

if $DOCKER compose version >/dev/null 2>&1; then
    success "Docker Compose 已安装: $($DOCKER compose version --short 2>/dev/null || echo '版本未知')"
else
    error "Docker Compose 未安装"
    echo ""
    echo "请手动安装 Docker Compose:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install docker-compose-plugin"
    echo ""
    exit 1
fi

echo ""

# ==================== 3. 检查 GPU（可选）====================
info "检查 GPU 支持..."

if command -v nvidia-smi >/dev/null 2>&1; then
    success "检测到 NVIDIA GPU:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | sed 's/^/  /' || true

    if $DOCKER info 2>/dev/null | grep -qi nvidia; then
        success "NVIDIA Container Toolkit 已配置"
    else
        warning "NVIDIA Container Toolkit 未配置"
        warning "GPU 将不可用，建议安装:"
        echo "  distribution=\$(. /etc/os-release;echo \$ID\$VERSION_ID)"
        echo "  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
        echo "  curl -s -L https://nvidia.github.io/libnvidia-container/\$distribution/libnvidia-container.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
        echo "  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
        echo "  sudo nvidia-ctk runtime configure --runtime=docker"
        echo "  sudo systemctl restart docker"
    fi
else
    info "未检测到 NVIDIA GPU"
fi

echo ""

# ==================== 4. 检查配置文件 ====================
info "检查配置文件..."

if [ ! -f "docker-compose.yaml" ]; then
    error "docker-compose.yaml 文件不存在"
    error "请确保在项目根目录运行此脚本"
    exit 1
fi

success "配置文件存在"

echo ""

# ==================== 5. 选择服务 ====================
info "可用服务:"
echo "  1) GPT-SoVITS-CU128      (CUDA 12.8 完整版) - 推荐"
echo "  2) GPT-SoVITS-CU128-Lite (CUDA 12.8 轻量版)"
echo "  3) GPT-SoVITS-CU126      (CUDA 12.6 完整版)"
echo "  4) GPT-SoVITS-CU126-Lite (CUDA 12.6 轻量版)"
echo ""

read -p "选择服务 (1-4) [默认: 1]: " choice
choice=${choice:-1}

case $choice in
    1) SERVICE="GPT-SoVITS-CU128" ;;
    2) SERVICE="GPT-SoVITS-CU128-Lite" ;;
    3) SERVICE="GPT-SoVITS-CU126" ;;
    4) SERVICE="GPT-SoVITS-CU126-Lite" ;;
    *)
        error "无效选择"
        exit 1
        ;;
esac

success "已选择: $SERVICE"

echo ""

# ==================== 6. 拉取镜像 ====================
read -p "是否拉取最新镜像? (y/n) [默认: y]: " pull
pull=${pull:-y}

if [[ "$pull" =~ ^[Yy]$ ]]; then
    info "拉取镜像 (首次运行可能需要较长时间)..."
    if $DOCKER compose pull "$SERVICE"; then
        success "镜像拉取成功"
    else
        error "镜像拉取失败"
        error "可能是网络问题，请检查网络连接或配置 Docker 镜像加速器"
        exit 1
    fi
fi

echo ""

# ==================== 7. 启动服务 ====================
info "启动服务: $SERVICE"

if $DOCKER compose up -d "$SERVICE"; then
    success "服务启动成功"
else
    error "服务启动失败"
    echo ""
    echo "查看日志："
    echo "  $DOCKER compose logs $SERVICE"
    exit 1
fi

echo ""

# ==================== 8. 显示状态 ====================
info "服务状态:"
$DOCKER compose ps

echo ""
echo "======================================"
success "启动完成！"
echo "======================================"
echo ""
echo "📍 访问地址: http://localhost:8000"
echo ""
echo "📝 常用命令:"
echo "  查看日志: $DOCKER compose logs -f $SERVICE"
echo "  停止服务: $DOCKER compose down"
echo "  重启服务: $DOCKER compose restart $SERVICE"
echo ""

# ==================== 9. 查看日志（可选）====================
read -p "是否查看实时日志? (y/n) [默认: n]: " show_logs
show_logs=${show_logs:-n}

if [[ "$show_logs" =~ ^[Yy]$ ]]; then
    info "实时日志 (Ctrl+C 退出)..."
    echo ""
    $DOCKER compose logs -f "$SERVICE"
fi
