#!/bin/bash

echo "🚀 GPT-SoVITS 预训练模型下载脚本"
echo "=========================================="

# 创建目录
mkdir -p GPT_SoVITS/pretrained_models/gsv-v2final-pretrained
mkdir -p GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large
mkdir -p GPT_SoVITS/pretrained_models/chinese-hubert-base

echo ""
echo "📁 目录结构已创建"
echo ""
echo "📋 需要下载的模型文件:"
echo ""
echo "1. GPT模型 (Text2Semantic):"
echo "   - s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt (~600MB)"
echo ""
echo "2. SoVITS模型 (语音合成):"
echo "   - s2G2333k.pth (~300MB)"
echo "   - s2D2333k.pth (~300MB)"
echo ""
echo "3. 中文BERT模型:"
echo "   - chinese-roberta-wwm-ext-large (~1.2GB)"
echo ""
echo "4. 中文HuBERT模型:"
echo "   - chinese-hubert-base (~400MB)"
echo ""
echo "总大小约: 2.8GB"
echo ""

read -p "是否开始下载? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 已取消下载"
    exit 1
fi

# 切换到项目目录
cd GPT_SoVITS/pretrained_models

echo ""
echo "=========================================="
echo "📦 方式1: 从 HuggingFace 下载 (国外快)"
echo "=========================================="
echo ""
echo "1. GPT-SoVITS 基础模型:"
echo "   https://huggingface.co/lj1995/GPT-SoVITS"
echo ""
echo "2. 中文 BERT 模型:"
echo "   https://huggingface.co/hfl/chinese-roberta-wwm-ext-large"
echo ""
echo "3. 中文 HuBERT 模型:"
echo "   https://huggingface.co/TencentGameMate/chinese-hubert-base"
echo ""
echo "=========================================="
echo "📦 方式2: 从国内镜像下载 (国内快)"
echo "=========================================="
echo ""
echo "ModelScope 镜像 (推荐国内用户):"
echo "https://www.modelscope.cn/models/damo/speech_sovits_tts/summary"
echo ""
echo "=========================================="
echo "📦 方式3: 百度云/阿里云盘分享"
echo "=========================================="
echo ""
echo "请访问项目 README 获取最新的分享链接"
echo ""
echo "=========================================="
echo ""

# 选择下载方式
echo ""
read -p "选择下载方式 [1=HuggingFace镜像(国外), 2=ModelScope(国内), 3=手动]: " download_method

if [ "$download_method" == "1" ]; then
    # 方式1: 使用 git-lfs 从 HuggingFace 下载
    if command -v git &> /dev/null && command -v git-lfs &> /dev/null; then
        echo "📥 正在从 HuggingFace 克隆模型..."

        # 1. GPT-SoVITS 基础模型
        if [ ! -d "gsv-v2final-pretrained" ]; then
            echo "下载 GPT-SoVITS 基础模型..."
            git clone https://huggingface.co/lj1995/GPT-SoVITS gsv-v2final-pretrained
        fi

        # 2. 中文 BERT
        if [ ! -d "chinese-roberta-wwm-ext-large" ]; then
            echo "下载中文 BERT 模型..."
            git clone https://huggingface.co/hfl/chinese-roberta-wwm-ext-large
        fi

        # 3. 中文 HuBERT
        if [ ! -d "chinese-hubert-base" ]; then
            echo "下载中文 HuBERT 模型..."
            git clone https://huggingface.co/TencentGameMate/chinese-hubert-base
        fi

        echo "✅ 下载完成!"
    else
        echo "❌ 未检测到 git-lfs, 请先安装: sudo apt-get install git-lfs"
        exit 1
    fi

elif [ "$download_method" == "2" ]; then
    # 方式2: 使用 aria2c 或 wget 从 ModelScope 下载
    echo "📥 正在从 ModelScope 下载模型..."

    DOWNLOAD_CMD=""
    if command -v aria2c &> /dev/null; then
        DOWNLOAD_CMD="aria2c -x 16 -s 16 -k 1M"
        echo "✅ 使用 aria2c 多线程下载"
    elif command -v wget &> /dev/null; then
        DOWNLOAD_CMD="wget -c"
        echo "✅ 使用 wget 下载"
    else
        echo "❌ 未检测到 aria2c 或 wget, 请先安装"
        exit 1
    fi

    # 创建临时下载脚本
    cat > /tmp/download_models.sh <<'EOF'
#!/bin/bash
set -e

DOWNLOAD_CMD="$1"
BASE_URL="https://www.modelscope.cn/api/v1/models"

# 1. GPT-SoVITS 基础模型
echo "📦 下载 GPT-SoVITS 基础模型..."
mkdir -p gsv-v2final-pretrained
cd gsv-v2final-pretrained

# GPT 模型 checkpoint
$DOWNLOAD_CMD -o s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt \
    "${BASE_URL}/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt"

# SoVITS Generator 模型
$DOWNLOAD_CMD -o s2G2333k.pth \
    "${BASE_URL}/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s2G2333k.pth"

# SoVITS Discriminator 模型
$DOWNLOAD_CMD -o s2D2333k.pth \
    "${BASE_URL}/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k/repo?Revision=master&FilePath=s2D2333k.pth"

cd ..

# 2. 中文 BERT 模型
echo "📦 下载中文 BERT 模型..."
if command -v git &> /dev/null; then
    git clone https://www.modelscope.cn/tiansz/chinese-roberta-wwm-ext-large.git chinese-roberta-wwm-ext-large
else
    echo "⚠️  需要 git 来克隆 BERT 模型仓库"
fi

# 3. 中文 HuBERT 模型
echo "📦 下载中文 HuBERT 模型..."
if command -v git &> /dev/null; then
    git clone https://www.modelscope.cn/TencentGameMate/chinese-hubert-base.git chinese-hubert-base
else
    echo "⚠️  需要 git 来克隆 HuBERT 模型仓库"
fi

echo "✅ 所有模型下载完成!"
EOF

    chmod +x /tmp/download_models.sh
    /tmp/download_models.sh "$DOWNLOAD_CMD"
    rm /tmp/download_models.sh

elif [ "$download_method" == "3" ]; then
    # 方式3: 显示手动下载指南
    echo ""
    echo "⚠️  请手动下载模型并放到以下目录:"
    echo ""
    echo "GPT_SoVITS/pretrained_models/"
    echo "├── gsv-v2final-pretrained/"
    echo "│   ├── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
    echo "│   ├── s2G2333k.pth"
    echo "│   └── s2D2333k.pth"
    echo "├── chinese-roberta-wwm-ext-large/"
    echo "│   ├── config.json"
    echo "│   ├── pytorch_model.bin"
    echo "│   └── ..."
    echo "└── chinese-hubert-base/"
    echo "    ├── config.json"
    echo "    ├── pytorch_model.bin"
    echo "    └── ..."
    echo ""
    exit 0
else
    echo "❌ 无效选择"
    exit 1
fi

echo ""
echo "=========================================="
echo "💡 快速下载链接 (复制到浏览器):"
echo "=========================================="
echo ""
echo "# 基础模型 (必需)"
echo "https://huggingface.co/lj1995/GPT-SoVITS/blob/main/s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt"
echo "https://huggingface.co/lj1995/GPT-SoVITS/blob/main/s2G2333k.pth"
echo "https://huggingface.co/lj1995/GPT-SoVITS/blob/main/s2D2333k.pth"
echo ""
echo "# 中文BERT (必需)"
echo "https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/tree/main"
echo ""
echo "# 中文HuBERT (必需)"
echo "https://huggingface.co/TencentGameMate/chinese-hubert-base/tree/main"
echo ""
echo "=========================================="
echo ""

echo "📋 下载后的目录结构应该是:"
echo ""
tree -L 3 . 2>/dev/null || find . -maxdepth 3 -type f | head -20

echo ""
echo "=========================================="
echo "✅ 下载完成后，重新启动 docker-compose:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo "=========================================="
