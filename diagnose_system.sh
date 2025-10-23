#!/bin/bash

# 系统诊断脚本
# 用于诊断 start_docker.sh 脚本的兼容性问题

echo "======================================"
echo "  GPT-SoVITS 系统诊断工具"
echo "======================================"
echo ""

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo "1. 检查系统信息"
echo "-----------------------------------"

# 检查 /etc/os-release
if [ -f /etc/os-release ]; then
    print_success "找到 /etc/os-release 文件"
    . /etc/os-release
    echo "  系统名称: $NAME"
    echo "  系统版本: $VERSION"
    echo "  系统 ID: $ID"
    echo "  版本 ID: $VERSION_ID"
else
    print_warning "未找到 /etc/os-release 文件"
fi
echo ""

# 检查 /etc/lsb-release
if [ -f /etc/lsb-release ]; then
    print_success "找到 /etc/lsb-release 文件"
    . /etc/lsb-release
    echo "  发行版 ID: $DISTRIB_ID"
    echo "  发行版描述: $DISTRIB_DESCRIPTION"
    echo "  发行版版本: $DISTRIB_RELEASE"
else
    print_warning "未找到 /etc/lsb-release 文件"
fi
echo ""

# 使用 uname 获取系统信息
print_info "内核信息:"
echo "  内核名称: $(uname -s)"
echo "  主机名: $(uname -n)"
echo "  内核版本: $(uname -r)"
echo "  硬件架构: $(uname -m)"
echo ""

echo "2. 检查包管理器"
echo "-----------------------------------"

# 检查 apt-get
if command -v apt-get &> /dev/null; then
    print_success "apt-get 命令可用"
    echo "  路径: $(which apt-get)"
    echo "  版本: $(apt-get --version | head -n 1)"
else
    print_error "apt-get 命令不可用"
fi
echo ""

# 检查 apt
if command -v apt &> /dev/null; then
    print_success "apt 命令可用"
    echo "  路径: $(which apt)"
    echo "  版本: $(apt --version | head -n 1)"
else
    print_error "apt 命令不可用"
fi
echo ""

echo "3. 检查 Docker"
echo "-----------------------------------"

# 检查 Docker
if command -v docker &> /dev/null; then
    print_success "Docker 已安装"
    echo "  路径: $(which docker)"
    echo "  版本: $(docker --version)"

    # 检查 Docker 服务状态
    if systemctl is-active --quiet docker; then
        print_success "Docker 服务正在运行"
    else
        print_warning "Docker 服务未运行"
    fi
else
    print_warning "Docker 未安装"
fi
echo ""

# 检查 Docker Compose
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    print_success "Docker Compose 已安装"
    echo "  版本: $(docker compose version)"
elif command -v docker-compose &> /dev/null; then
    print_success "Docker Compose (standalone) 已安装"
    echo "  版本: $(docker-compose --version)"
else
    print_warning "Docker Compose 未安装"
fi
echo ""

echo "4. 检查 NVIDIA GPU"
echo "-----------------------------------"

# 检查 nvidia-smi
if command -v nvidia-smi &> /dev/null; then
    print_success "NVIDIA 驱动已安装"
    echo "  驱动版本: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)"
    echo ""
    echo "  GPU 信息:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | nl -w2 -s'. '

    # 检查 NVIDIA Container Toolkit
    if command -v nvidia-ctk &> /dev/null; then
        print_success "NVIDIA Container Toolkit 已安装"
    else
        print_warning "NVIDIA Container Toolkit 未安装"
    fi
else
    print_info "未检测到 NVIDIA GPU 或驱动未安装"
fi
echo ""

echo "5. 检查用户权限"
echo "-----------------------------------"

# 检查当前用户
print_info "当前用户: $USER (UID: $UID)"

# 检查是否在 docker 组
if groups | grep -q docker; then
    print_success "用户已在 docker 组中"
else
    print_warning "用户不在 docker 组中"
    echo "  运行以下命令将用户添加到 docker 组:"
    echo "  sudo usermod -aG docker $USER"
    echo "  然后重新登录或运行: newgrp docker"
fi
echo ""

# 检查 sudo 权限
if sudo -n true 2>/dev/null; then
    print_success "sudo 权限可用（无需密码）"
elif sudo -v 2>/dev/null; then
    print_success "sudo 权限可用（需要密码）"
else
    print_warning "sudo 权限不可用"
fi
echo ""

echo "6. 检查网络连接"
echo "-----------------------------------"

# 检查互联网连接
if ping -c 1 8.8.8.8 &> /dev/null; then
    print_success "互联网连接正常"
else
    print_warning "互联网连接可能有问题"
fi

# 检查 Docker Hub 连接
if ping -c 1 hub.docker.com &> /dev/null; then
    print_success "可以访问 Docker Hub"
else
    print_warning "无法访问 Docker Hub（可能需要配置代理或镜像）"
fi
echo ""

echo "7. 检查磁盘空间"
echo "-----------------------------------"

# 检查当前目录磁盘空间
df -h . | tail -n 1 | awk '{print "  可用空间: "$4" (总空间: "$2", 已用: "$3", 使用率: "$5")"}'

# 检查是否有足够空间
AVAILABLE=$(df -BG . | tail -n 1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 20 ]; then
    print_success "磁盘空间充足"
else
    print_warning "磁盘空间可能不足（推荐至少 20GB）"
fi
echo ""

echo "8. 检查必要的命令"
echo "-----------------------------------"

# 检查必要命令
for cmd in curl wget git systemctl; do
    if command -v $cmd &> /dev/null; then
        print_success "$cmd 命令可用"
    else
        print_warning "$cmd 命令不可用"
    fi
done
echo ""

echo "======================================"
echo "  诊断完成"
echo "======================================"
echo ""

# 生成建议
echo "💡 建议："
echo ""

if ! command -v docker &> /dev/null; then
    echo "1. Docker 未安装，运行 start_docker.sh 将自动安装"
fi

if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null 2>&1; then
    echo "2. Docker Compose 未安装，运行 start_docker.sh 将自动安装"
fi

if ! groups | grep -q docker; then
    echo "3. 建议将用户添加到 docker 组以避免权限问题"
fi

if command -v nvidia-smi &> /dev/null && ! command -v nvidia-ctk &> /dev/null; then
    echo "4. 检测到 NVIDIA GPU，建议安装 NVIDIA Container Toolkit"
fi

if [ "$AVAILABLE" -lt 20 ]; then
    echo "5. 建议清理磁盘空间或使用更大的磁盘"
fi

echo ""
echo "📚 如果遇到问题，请将此诊断结果保存并提交 Issue"
echo ""
