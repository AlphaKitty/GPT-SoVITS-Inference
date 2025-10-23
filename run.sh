#!/bin/bash

# GPT-SoVITS 超简单启动脚本
# 不做任何安装，只检查基本环境并启动服务

set -e

# 颜色
G='\033[0;32m' # 绿色
Y='\033[1;33m' # 黄色
R='\033[0;31m' # 红色
N='\033[0m'    # 无色

echo "======================================"
echo "  GPT-SoVITS Docker 启动"
echo "======================================"
echo ""

# 检查 docker 命令
if ! command -v docker &>/dev/null; then
    echo -e "${R}错误: 未找到 docker 命令${N}"
    echo ""
    echo "请先安装 Docker:"
    echo "  curl -fsSL https://get.docker.com | sudo bash"
    exit 1
fi

# 检查 docker compose
if ! docker compose version &>/dev/null; then
    echo -e "${R}错误: docker compose 不可用${N}"
    echo ""
    echo "请安装 Docker Compose:"
    echo "  sudo apt-get install docker-compose-plugin"
    exit 1
fi

# 检查配置文件
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${R}错误: 未找到 docker-compose.yaml${N}"
    exit 1
fi

# 选择服务
echo "选择服务:"
echo "  1) GPT-SoVITS-CU128 (推荐)"
echo "  2) GPT-SoVITS-CU128-Lite"
echo "  3) GPT-SoVITS-CU126"
echo "  4) GPT-SoVITS-CU126-Lite"
echo ""
read -p "输入序号 [1]: " choice
choice=${choice:-1}

case $choice in
    1) SVC="GPT-SoVITS-CU128" ;;
    2) SVC="GPT-SoVITS-CU128-Lite" ;;
    3) SVC="GPT-SoVITS-CU126" ;;
    4) SVC="GPT-SoVITS-CU126-Lite" ;;
    *) echo -e "${R}无效选择${N}"; exit 1 ;;
esac

echo ""
echo -e "${G}启动 $SVC...${N}"

# 拉取镜像
read -p "拉取最新镜像? (y/n) [y]: " pull
pull=${pull:-y}
if [[ "$pull" =~ ^[Yy]$ ]]; then
    docker compose pull "$SVC" || {
        echo -e "${R}镜像拉取失败${N}"
        echo "继续使用本地镜像..."
    }
fi

# 启动
docker compose up -d "$SVC"

echo ""
echo -e "${G}✓ 服务已启动${N}"
echo ""
echo "访问: http://localhost:8000"
echo ""
echo "查看日志: docker compose logs -f $SVC"
echo "停止服务: docker compose down"
echo ""
