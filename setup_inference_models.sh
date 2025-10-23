#!/bin/bash
# 配置推理模型脚本
# 将预训练模型链接到推理目录

echo "🔧 配置 GPT-SoVITS 推理模型..."

# 定义源目录和目标目录
PRETRAINED_DIR="GPT_SoVITS/pretrained_models/gsv-v2final-pretrained"
GPT_WEIGHTS_V4="GPT_weights_v4"
SOVITS_WEIGHTS_V4="SoVITS_weights_v4"

# 定义模型文件
GPT_MODEL="s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
SOVITS_G_MODEL="s2G2333k.pth"
SOVITS_D_MODEL="s2D2333k.pth"

# 检查预训练模型是否存在
if [ ! -f "$PRETRAINED_DIR/$GPT_MODEL" ]; then
    echo "❌ 错误: 未找到 GPT 预训练模型"
    echo "   路径: $PRETRAINED_DIR/$GPT_MODEL"
    echo "   请先运行 auto_install.sh 下载模型！"
    exit 1
fi

if [ ! -f "$PRETRAINED_DIR/$SOVITS_G_MODEL" ]; then
    echo "❌ 错误: 未找到 SoVITS Generator 模型"
    echo "   路径: $PRETRAINED_DIR/$SOVITS_G_MODEL"
    echo "   请先运行 auto_install.sh 下载模型！"
    exit 1
fi

if [ ! -f "$PRETRAINED_DIR/$SOVITS_D_MODEL" ]; then
    echo "❌ 错误: 未找到 SoVITS Discriminator 模型"
    echo "   路径: $PRETRAINED_DIR/$SOVITS_D_MODEL"
    echo "   请先运行 auto_install.sh 下载模型！"
    exit 1
fi

echo "✅ 预训练模型文件检查通过"

# 创建目标目录
echo "📁 创建推理模型目录..."
mkdir -p "$GPT_WEIGHTS_V4"
mkdir -p "$SOVITS_WEIGHTS_V4"

# 检查是否已存在（避免重复操作）
if [ -f "$GPT_WEIGHTS_V4/$GPT_MODEL" ]; then
    echo "⚠️  GPT 推理模型已存在，跳过"
else
    echo "🔗 链接 GPT 模型到推理目录..."
    # 根据操作系统选择复制或链接
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows: 直接复制（符号链接需要管理员权限）
        cp "$PRETRAINED_DIR/$GPT_MODEL" "$GPT_WEIGHTS_V4/"
        echo "✅ GPT 模型已复制"
    else
        # Linux/Mac: 使用符号链接（节省空间）
        ln -s "../$PRETRAINED_DIR/$GPT_MODEL" "$GPT_WEIGHTS_V4/$GPT_MODEL"
        echo "✅ GPT 模型已链接"
    fi
fi

if [ -f "$SOVITS_WEIGHTS_V4/$SOVITS_G_MODEL" ]; then
    echo "⚠️  SoVITS Generator 已存在，跳过"
else
    echo "🔗 链接 SoVITS Generator 到推理目录..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        cp "$PRETRAINED_DIR/$SOVITS_G_MODEL" "$SOVITS_WEIGHTS_V4/"
        echo "✅ SoVITS Generator 已复制"
    else
        ln -s "../$PRETRAINED_DIR/$SOVITS_G_MODEL" "$SOVITS_WEIGHTS_V4/$SOVITS_G_MODEL"
        echo "✅ SoVITS Generator 已链接"
    fi
fi

if [ -f "$SOVITS_WEIGHTS_V4/$SOVITS_D_MODEL" ]; then
    echo "⚠️  SoVITS Discriminator 已存在，跳过"
else
    echo "🔗 链接 SoVITS Discriminator 到推理目录..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        cp "$PRETRAINED_DIR/$SOVITS_D_MODEL" "$SOVITS_WEIGHTS_V4/"
        echo "✅ SoVITS Discriminator 已复制"
    else
        ln -s "../$PRETRAINED_DIR/$SOVITS_D_MODEL" "$SOVITS_WEIGHTS_V4/$SOVITS_D_MODEL"
        echo "✅ SoVITS Discriminator 已链接"
    fi
fi

# 验证配置
echo ""
echo "🔍 验证推理模型配置..."
echo ""
echo "GPT 模型:"
ls -lh "$GPT_WEIGHTS_V4/"
echo ""
echo "SoVITS 模型:"
ls -lh "$SOVITS_WEIGHTS_V4/"
echo ""

# 检查文件是否可访问
if [ -f "$GPT_WEIGHTS_V4/$GPT_MODEL" ] && \
   [ -f "$SOVITS_WEIGHTS_V4/$SOVITS_G_MODEL" ] && \
   [ -f "$SOVITS_WEIGHTS_V4/$SOVITS_D_MODEL" ]; then
    echo "✅ 推理模型配置成功！"
    echo ""
    echo "现在可以使用以下接口进行音色克隆："
    echo "  - POST /infer_classic (经典模式)"
    echo "  - POST /v1/audio/speech (OpenAI 风格)"
    echo ""
    echo "测试命令："
    echo "  curl http://localhost:8000/classic_model_list/v4"
else
    echo "❌ 推理模型配置失败，请检查文件权限！"
    exit 1
fi
