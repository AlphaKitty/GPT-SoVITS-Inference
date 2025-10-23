#!/bin/bash

echo "🚀 一键部署 AlphaKitty/GPT-SoVITS-Inference（适配 docker compose / docker-compose）"
echo "【准备阶段】"

# ---------- 1. 安装docker ----------
if ! command -v docker &> /dev/null; then
  echo "🔧 安装 Docker..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  sudo systemctl start docker
  sudo systemctl enable docker
fi

# ---------- 2. 安装 aria2c (用于模型下载) ----------
if ! command -v aria2c &> /dev/null; then
  echo "🔧 安装 aria2c..."
  sudo apt-get update
  sudo apt-get install -y aria2
  echo "✅ aria2c 安装完成"
else
  echo "✅ aria2c 已安装，跳过"
fi

# ---------- 3. 安装 NVIDIA Container Toolkit (用于Docker GPU支持) ----------
if command -v nvidia-smi &> /dev/null; then
  echo "🎮 检测到 NVIDIA GPU，正在安装 nvidia-container-toolkit..."

  # 检查是否已安装
  if ! command -v nvidia-container-toolkit &> /dev/null && ! dpkg -l | grep -q nvidia-container-toolkit; then
    echo "📦 添加 NVIDIA Docker 源..."

    # 添加 NVIDIA 容器工具包的 GPG 密钥
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    # 添加 NVIDIA 容器工具包的仓库
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    # 安装 nvidia-container-toolkit
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    # 配置 Docker 使用 NVIDIA runtime
    sudo nvidia-ctk runtime configure --runtime=docker

    echo "🔄 重启 Docker 服务以应用 GPU 配置..."
    sudo systemctl restart docker
    sleep 3

    echo "✅ nvidia-container-toolkit 安装完成"

    # 测试 GPU 是否可用
    echo "🧪 测试 Docker GPU 支持..."
    if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
      echo "✅ Docker GPU 支持已启用，可以使用 GPU 加速！"
    else
      echo "⚠️  Docker GPU 测试失败，请检查配置"
    fi
  else
    echo "✅ nvidia-container-toolkit 已安装，跳过"
  fi
else
  echo "ℹ️  未检测到 NVIDIA GPU，跳过 nvidia-container-toolkit 安装"
  echo "   (如果是 CPU 版本，可以忽略此消息)"
fi

# ---------- 4. Docker 镜像加速配置 ----------
DAEMON_JSON_PATH="/etc/docker/daemon.json"
MIRROR_JSON='{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://hub-mirror.c.163.com"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}'
NEED_UPDATE=1

if [ -f $DAEMON_JSON_PATH ]; then
  EXIST_JSON=$(sudo cat $DAEMON_JSON_PATH)
  if echo "$EXIST_JSON" | grep -q "registry.docker-cn.com" && echo "$EXIST_JSON" | grep -q "hub-mirror.c.163.com"; then
    NEED_UPDATE=0
    echo "✅ 已检测到国内加速配置，无需重复写入。"
  else
    echo "⚠️ 覆盖写入 /etc/docker/daemon.json（备份到 daemon.json.bak）"
    sudo cp $DAEMON_JSON_PATH ${DAEMON_JSON_PATH}.bak
  fi
else
  echo "⚠️ 初始化写入 /etc/docker/daemon.json"
fi
if [ $NEED_UPDATE -eq 1 ]; then
  echo "$MIRROR_JSON" | sudo tee $DAEMON_JSON_PATH > /dev/null
  echo "🔄 重启 Docker 服务以应用加速配置..."
  sudo systemctl restart docker
  sleep 3
fi

# ---------- 5. 用户组设置（建议重新登录shell生效） ----------
if groups $USER | grep -vwq "docker"; then
  echo "🔧 当前用户未添加到docker组，正在添加（需手动重新登录shell再生效）..."
  sudo usermod -aG docker $USER
  echo "⚠️ 你需要退出当前终端或重启电脑，重新进来后才能免sudo使用docker"
fi

# ---------- 6. 克隆/拉取代码 ----------
WORKDIR="./GPT-SoVITS-Inference"
if [ ! -d "$WORKDIR" ]; then
  echo "📦 克隆项目..."
  git clone https://github.com/AlphaKitty/GPT-SoVITS-Inference.git "$WORKDIR"
else
  echo "✅ 发现本地已有项目目录，拉取最新代码"
  cd "$WORKDIR" && git pull
fi
cd "$WORKDIR"

# ---------- 7. 检测并适配 docker compose / docker-compose ----------
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE_RUN="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_RUN="docker-compose"
else
    echo "🔧 尝试安装 Docker Compose 插件版..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_RUN="docker compose"
    else
        echo "🔧 安装 Docker Compose 旧版二进制..."
        sudo apt-get install -y docker-compose
        COMPOSE_RUN="docker-compose"
    fi
fi

echo "✅ 选用的 compose 命令为: $COMPOSE_RUN"

# ---------- 8. 拉取镜像 ----------
echo "📦 拉取 Docker 镜像及依赖"
$COMPOSE_RUN pull

# ---------- 9. 启动工程 ----------
echo "🚀 启动服务（$COMPOSE_RUN up -d）"
# $COMPOSE_RUN up -d --device CU128
$COMPOSE_RUN up -d

# ---------- 10. 获取公网IP与端口 ----------
IP=$(curl -s http://ipinfo.io/ip)
PORT=$(grep -m1 -A2 'ports:' docker-compose.yaml | grep -o '[0-9]\{4,5\}:[0-9]\{4,5\}' | head -n1 | awk -F: '{print $1}')
if [ -z "$PORT" ]; then
  PORT=8000
fi

echo "=============================================="
echo "🎉 启动成功！"
echo "【公网访问地址】http://${IP}:${PORT}/"
echo "【本机访问地址】http://localhost:${PORT}/"
echo "=============================================="

# ---------- 11. 实时日志监控 ----------
echo "----- 实时监控 compose 日志 -----"
$COMPOSE_RUN logs -f

