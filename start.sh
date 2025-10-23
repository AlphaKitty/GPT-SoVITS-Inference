#!/bin/bash
# GPT-SoVITS 一键启动脚本 - 最简版本

set -e

echo "======================================"
echo "  GPT-SoVITS 启动"
echo "======================================"
echo ""

# 默认服务
SERVICE="GPT-SoVITS-CU128"

# 检查是否传入服务名参数
if [ -n "$1" ]; then
    SERVICE="$1"
fi

echo "服务: $SERVICE"
echo ""

# 拉取镜像
echo "拉取镜像..."
docker compose pull "$SERVICE" 2>/dev/null || echo "跳过镜像拉取"

# 启动服务
echo "启动服务..."
docker compose up -d "$SERVICE"

# 显示状态
echo ""
docker compose ps
echo ""
echo "✓ 完成！访问: http://localhost:8000"
echo ""
