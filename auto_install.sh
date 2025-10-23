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

# ---------- 2. 安装 aria2c 和 git-lfs (用于模型下载) ----------
echo "🔧 检查模型下载工具..."

if ! command -v aria2c &> /dev/null; then
  echo "📦 安装 aria2c..."
  sudo apt-get update
  sudo apt-get install -y aria2
  echo "✅ aria2c 安装完成"
else
  echo "✅ aria2c 已安装，跳过"
fi

if ! command -v git-lfs &> /dev/null; then
  echo "📦 安装 git-lfs..."
  sudo apt-get update
  sudo apt-get install -y git-lfs
  git lfs install
  echo "✅ git-lfs 安装完成"
else
  echo "✅ git-lfs 已安装，跳过"
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

# ---------- 6. 更新当前工程代码 ----------
echo "📦 检查并更新当前工程..."
if [ -d ".git" ]; then
  echo "✅ 检测到 git 仓库，拉取最新代码"
  git pull
else
  echo "⚠️  当前目录不是 git 仓库，跳过代码更新"
  echo "   提示：建议通过 git clone 下载项目后再运行此脚本"
fi

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

# ---------- 8. 下载预训练模型 ----------
echo ""
echo "=========================================="
echo "📦 检查预训练模型"
echo "=========================================="

MODELS_DIR="GPT_SoVITS/pretrained_models"
NEED_DOWNLOAD=0

# 检查模型是否存在
if [ ! -f "$MODELS_DIR/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" ] || \
   [ ! -f "$MODELS_DIR/gsv-v2final-pretrained/s2G2333k.pth" ] || \
   [ ! -f "$MODELS_DIR/gsv-v2final-pretrained/s2D2333k.pth" ] || \
   [ ! -d "$MODELS_DIR/chinese-roberta-wwm-ext-large" ] || \
   [ ! -d "$MODELS_DIR/chinese-hubert-base" ]; then
    NEED_DOWNLOAD=1
fi

if [ $NEED_DOWNLOAD -eq 1 ]; then
    echo "⚠️  检测到缺少预训练模型 (约2.8GB)"
    echo ""
    echo "📋 这些模型是音色克隆和TTS功能的必要组件:"
    echo "   1. GPT-SoVITS 基础模型 (~1.2GB) - 文本理解和语音生成"
    echo "   2. 中文 BERT 模型 (~1.2GB) - 中文语义理解"
    echo "   3. 中文 HuBERT 模型 (~400MB) - 音色特征提取"
    echo ""

    read -p "是否现在下载? (y/n): " download_confirm
    if [ "$download_confirm" = "y" ]; then
        # 创建目录
        mkdir -p $MODELS_DIR/gsv-v2final-pretrained
        mkdir -p $MODELS_DIR/chinese-roberta-wwm-ext-large
        mkdir -p $MODELS_DIR/chinese-hubert-base

        echo ""
        echo "选择下载方式:"
        echo "  1) HuggingFace 镜像 (国外网络快)"
        echo "  2) ModelScope 镜像 (国内网络快) ⭐推荐"
        echo "  3) 跳过，稍后手动下载"
        echo ""
        read -p "请选择 [1-3]: " download_method

        cd $MODELS_DIR

        if [ "$download_method" = "1" ]; then
            # HuggingFace 下载
            echo "📥 从 HuggingFace 下载模型..."

            if [ ! -f "gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" ]; then
                echo "[1/3] 下载 GPT-SoVITS 基础模型..."
                rm -rf gsv-v2final-pretrained
                git clone https://huggingface.co/lj1995/GPT-SoVITS gsv-v2final-pretrained
                echo "✅ GPT-SoVITS 基础模型下载完成"
            else
                echo "✅ [1/3] GPT-SoVITS 基础模型已存在，跳过"
            fi

            if [ ! -f "chinese-roberta-wwm-ext-large/config.json" ]; then
                echo "[2/3] 下载中文 BERT 模型..."
                rm -rf chinese-roberta-wwm-ext-large
                git clone https://huggingface.co/hfl/chinese-roberta-wwm-ext-large
                echo "✅ 中文 BERT 模型下载完成"
            else
                echo "✅ [2/3] 中文 BERT 模型已存在，跳过"
            fi

            if [ ! -f "chinese-hubert-base/config.json" ]; then
                echo "[3/3] 下载中文 HuBERT 模型..."
                rm -rf chinese-hubert-base
                git clone https://huggingface.co/TencentGameMate/chinese-hubert-base
                echo "✅ 中文 HuBERT 模型下载完成"
            else
                echo "✅ [3/3] 中文 HuBERT 模型已存在，跳过"
            fi

            echo ""
            echo "✅ 所有模型下载完成!"

        elif [ "$download_method" = "2" ]; then
            # ModelScope 下载
            echo "📥 从 ModelScope 下载模型..."

            DOWNLOAD_CMD=""
            if command -v aria2c &> /dev/null; then
                DOWNLOAD_CMD="aria2c -x 16 -s 16 -k 1M"
                echo "✅ 使用 aria2c 多线程下载"
            elif command -v wget &> /dev/null; then
                DOWNLOAD_CMD="wget -c"
                echo "✅ 使用 wget 下载"
            else
                echo "❌ 未检测到 aria2c 或 wget"
                exit 1
            fi

            # 下载 GPT-SoVITS 基础模型
            echo "📦 [1/5] 下载 GPT 模型 checkpoint (~600MB)..."
            cd gsv-v2final-pretrained
            if [ ! -f "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" ]; then
                $DOWNLOAD_CMD -o s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt \
                    "https://www.modelscope.cn/api/v1/models/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt"
                echo "✅ GPT 模型下载完成"
            else
                echo "✅ GPT 模型已存在，跳过"
            fi

            echo "📦 [2/5] 下载 SoVITS Generator 模型 (~300MB)..."
            if [ ! -f "s2G2333k.pth" ]; then
                $DOWNLOAD_CMD -o s2G2333k.pth \
                    "https://www.modelscope.cn/api/v1/models/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s2G2333k.pth"
                echo "✅ SoVITS Generator 下载完成"
            else
                echo "✅ SoVITS Generator 已存在，跳过"
            fi

            echo "📦 [3/5] 下载 SoVITS Discriminator 模型 (~300MB)..."
            if [ ! -f "s2D2333k.pth" ]; then
                $DOWNLOAD_CMD -o s2D2333k.pth \
                    "https://www.modelscope.cn/api/v1/models/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s2D2333k.pth"
                echo "✅ SoVITS Discriminator 下载完成"
            else
                echo "✅ SoVITS Discriminator 已存在，跳过"
            fi
            cd ..

            # 下载 BERT 模型
            echo "📦 [4/5] 下载中文 BERT 模型 (~1.2GB)..."
            if [ ! -f "chinese-roberta-wwm-ext-large/config.json" ]; then
                rm -rf chinese-roberta-wwm-ext-large
                if command -v git &> /dev/null; then
                    git clone https://www.modelscope.cn/tiansz/chinese-roberta-wwm-ext-large.git chinese-roberta-wwm-ext-large
                    echo "✅ 中文 BERT 模型下载完成"
                else
                    echo "⚠️  需要 git 来克隆 BERT 模型"
                fi
            else
                echo "✅ 中文 BERT 模型已存在，跳过"
            fi

            # 下载 HuBERT 模型
            echo "📦 [5/5] 下载中文 HuBERT 模型 (~400MB)..."
            if [ ! -f "chinese-hubert-base/config.json" ]; then
                rm -rf chinese-hubert-base
                if command -v git &> /dev/null; then
                    git clone https://www.modelscope.cn/TencentGameMate/chinese-hubert-base.git chinese-hubert-base
                    echo "✅ 中文 HuBERT 模型下载完成"
                else
                    echo "⚠️  需要 git 来克隆 HuBERT 模型"
                fi
            else
                echo "✅ 中文 HuBERT 模型已存在，跳过"
            fi

            echo ""
            echo "✅ 所有模型下载完成!"

        elif [ "$download_method" = "3" ]; then
            echo ""
            echo "⚠️  已跳过模型下载"
            echo "   请稍后运行: bash download_pretrained_models.sh"
            echo ""
        else
            echo "❌ 无效选择"
            exit 1
        fi

        # 返回项目根目录
        cd ../..
    else
        echo "⚠️  已跳过模型下载，Docker 启动时可能会报错"
        echo "   稍后可运行: bash download_pretrained_models.sh"
    fi
else
    echo "✅ 预训练模型已存在，跳过下载"
fi

# ---------- 9. 拉取镜像 ----------
echo ""
echo "📦 拉取 Docker 镜像及依赖"
$COMPOSE_RUN pull

# ---------- 10. 启动工程 ----------
echo ""
echo "🚀 启动服务（$COMPOSE_RUN up -d）"
$COMPOSE_RUN up -d

# ---------- 11. 获取公网IP与端口 ----------
IP=$(curl -s http://ipinfo.io/ip)
PORT=$(grep -m1 -A2 'ports:' docker-compose.yaml | grep -o '[0-9]\{4,5\}:[0-9]\{4,5\}' | head -n1 | awk -F: '{print $1}')
if [ -z "$PORT" ]; then
  PORT=8000
fi

echo "=============================================="
echo "🎉 启动成功！"
echo "【公网访问地址】http://${IP}:${PORT}/"
echo "【本机访问地址】http://localhost:${PORT}/"
echo ""
echo "📋 功能说明:"
echo "   - WebUI 界面: http://localhost:${PORT}/"
echo "   - API 文档: http://localhost:${PORT}/docs"
echo "   - 音色克隆测试: 打开 tts_test.html"
echo ""
echo "💡 快速开始音色克隆:"
echo "   1. 准备几秒钟的参考音频"
echo "   2. 在 tts_test.html 中上传音频"
echo "   3. 输入参考文本和目标文本"
echo "   4. 生成克隆音色的语音"
echo "==============================================="

# ---------- 12. 实时日志监控 ----------
echo ""
echo "----- 实时监控 compose 日志 -----"
$COMPOSE_RUN logs -f

