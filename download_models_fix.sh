#!/bin/bash
# 修复脚本：下载正确版本的 GPT-SoVITS v2 预训练模型

echo "🔧 GPT-SoVITS 模型修复脚本"
echo "==========================================="

MODELS_DIR="GPT_SoVITS/pretrained_models"
mkdir -p "$MODELS_DIR/gsv-v2final-pretrained"

cd "$MODELS_DIR/gsv-v2final-pretrained"

echo ""
echo "选择下载源:"
echo "  1) HuggingFace (国外快，需要科学上网)"
echo "  2) HuggingFace 镜像 hf-mirror.com (国内可用)"
echo "  3) 手动下载提示"
echo ""
read -p "请选择 [1-3]: " choice

case $choice in
  1)
    echo "📥 从 HuggingFace 下载..."

    # 方式1：使用 git clone（推荐，但需要 git-lfs）
    if command -v git-lfs &> /dev/null; then
      echo "✅ 使用 git-lfs 克隆完整仓库..."
      cd ..
      rm -rf gsv-v2final-pretrained
      git clone https://huggingface.co/lj1995/GPT-SoVITS
      mv GPT-SoVITS gsv-v2final-pretrained
      echo "✅ 模型下载完成"
    else
      echo "❌ 未安装 git-lfs，请先安装："
      echo "   sudo apt-get install git-lfs"
      echo "   git lfs install"
      exit 1
    fi
    ;;

  2)
    echo "📥 从 HuggingFace 镜像下载..."

    # 检查下载工具
    if command -v wget &> /dev/null; then
      DOWNLOAD_CMD="wget -c"
    elif command -v curl &> /dev/null; then
      DOWNLOAD_CMD="curl -L -o"
    else
      echo "❌ 需要 wget 或 curl"
      exit 1
    fi

    BASE_URL="https://hf-mirror.com/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained"

    echo "📦 [1/3] 下载 GPT 模型 checkpoint (~600MB)..."
    if [ ! -f "s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" ]; then
      if command -v wget &> /dev/null; then
        wget -c "$BASE_URL/s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt" \
          -O s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
      else
        curl -L "$BASE_URL/s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt" \
          -o s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
      fi
      echo "✅ GPT 模型下载完成"
    else
      echo "✅ GPT 模型已存在"
    fi

    echo "📦 [2/3] 下载 SoVITS Generator (~300MB)..."
    if [ ! -f "s2G2333k.pth" ]; then
      if command -v wget &> /dev/null; then
        wget -c "$BASE_URL/s2G2333k.pth"
      else
        curl -L "$BASE_URL/s2G2333k.pth" -o s2G2333k.pth
      fi
      echo "✅ Generator 下载完成"
    else
      echo "✅ Generator 已存在"
    fi

    echo "📦 [3/3] 下载 SoVITS Discriminator (~300MB)..."
    if [ ! -f "s2D2333k.pth" ]; then
      if command -v wget &> /dev/null; then
        wget -c "$BASE_URL/s2D2333k.pth"
      else
        curl -L "$BASE_URL/s2D2333k.pth" -o s2D2333k.pth
      fi
      echo "✅ Discriminator 下载完成"
    else
      echo "✅ Discriminator 已存在"
    fi

    echo ""
    echo "✅ 所有模型下载完成！"
    ;;

  3)
    echo ""
    echo "📋 手动下载步骤："
    echo ""
    echo "1. 访问 https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained"
    echo ""
    echo "2. 下载以下 3 个文件到 GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/ 目录："
    echo "   - s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt  (155 MB)"
    echo "   - s2G2333k.pth  (106 MB)"
    echo "   - s2D2333k.pth  (93.5 MB)"
    echo ""
    echo "   ⚠️  注意：文件名中的 '=' 号必须保留，不要重命名！"
    echo ""
    echo "3. 如果还需要 BERT 和 HuBERT 模型："
    echo ""
    echo "   下载到 GPT_SoVITS/pretrained_models/ 目录："
    echo "   - chinese-roberta-wwm-ext-large (约 1.2GB)"
    echo "     https://huggingface.co/hfl/chinese-roberta-wwm-ext-large"
    echo ""
    echo "   - chinese-hubert-base (约 400MB)"
    echo "     https://huggingface.co/TencentGameMate/chinese-hubert-base"
    echo ""
    ;;

  *)
    echo "❌ 无效选择"
    exit 1
    ;;
esac

# 返回项目根目录
cd ../../..

echo ""
echo "==========================================="
echo "✅ 完成！现在可以重启 Docker 容器："
echo ""
echo "   # 清理旧容器并重新启动（推荐）"
echo "   docker compose down && docker compose up -d"
echo ""
echo "   # 或仅重启（快速）"
echo "   docker compose restart"
echo "==========================================="
