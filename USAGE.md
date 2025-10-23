# GPT-SoVITS-Inference 使用指南

## 🚀 快速开始

### 方式1: 一键部署（推荐新用户）

如果你还没有克隆项目，可以使用一键部署：

```bash
# 下载并运行一键安装脚本
wget https://raw.githubusercontent.com/AlphaKitty/GPT-SoVITS-Inference/main/auto_install.sh
bash auto_install.sh
```

### 方式2: 在已克隆的项目中执行（推荐）⭐

**适用场景：** 你已经通过 `git clone` 下载了项目代码

```bash
# 1. 克隆项目
git clone https://github.com/AlphaKitty/GPT-SoVITS-Inference.git
cd GPT-SoVITS-Inference

# 2. 直接运行安装脚本（脚本会自动更新代码，不会重新克隆）
bash auto_install.sh
```

**脚本会自动完成以下步骤：**

1. ✅ 安装 Docker
2. ✅ 安装 aria2c（用于模型下载）
3. ✅ 安装 NVIDIA Container Toolkit（GPU支持）
4. ✅ 配置 Docker 镜像加速
5. ✅ 添加用户到 docker 组
6. ✅ 更新当前工程代码（`git pull`）
7. ✅ 检测并适配 docker compose / docker-compose
8. ✅ **检查并下载预训练模型（约2.8GB）** 🆕
9. ✅ 拉取 Docker 镜像
10. ✅ 启动服务
11. ✅ 显示访问地址
12. ✅ 实时监控日志

## 📦 预训练模型下载

### 自动下载（集成在 auto_install.sh 中）

运行 `auto_install.sh` 时，脚本会自动检测模型是否存在：

- **如果缺少模型**：会提示你选择下载方式
- **如果已有模型**：会跳过下载步骤

#### 下载方式选择：

```
选择下载方式:
  1) HuggingFace 镜像 (国外网络快)
  2) ModelScope 镜像 (国内网络快) ⭐推荐
  3) 跳过，稍后手动下载
```

**推荐国内用户选择方式2**，使用 aria2c 16线程下载，速度更快！

### 手动下载（如果自动下载失败）

```bash
# 运行独立的下载脚本
bash download_pretrained_models.sh
```

## 🎯 功能说明

### 1. WebUI 界面

访问 `http://localhost:8000/` 可以使用完整的 Web 界面。

### 2. API 文档

访问 `http://localhost:8000/docs` 查看 OpenAPI 文档和接口说明。

### 3. 音色克隆测试

打开项目中的 `tts_test.html` 文件，可以进行：

- ✅ **快速音色克隆**（Zero-Shot TTS）
  - 上传几秒钟的参考音频
  - 输入参考文本（音频中说的内容）
  - 输入目标文本（想让AI说的内容）
  - 生成克隆音色的语音

- ✅ **经典模式推理**
  - 使用已训练的模型
  - 支持情感控制
  - 多语言支持

## 📋 模型说明

### 必需的预训练模型（约2.8GB）

这些模型是音色克隆和TTS功能的**必要组件**：

| 模型 | 大小 | 功能 | 作用 |
|------|------|------|------|
| s1bert...ckpt | ~600MB | GPT模型 | 文本理解和语义生成 |
| s2G2333k.pth | ~300MB | SoVITS Generator | 语音合成生成器 |
| s2D2333k.pth | ~300MB | SoVITS Discriminator | 质量控制 |
| chinese-bert | ~1.2GB | 中文BERT | 中文语义理解 |
| chinese-hubert | ~400MB | 中文HuBERT | 音色特征提取 |

### 模型的作用

```
上传参考音频 (ref.wav)
    ↓
[chinese-hubert] 提取音色特征
    ↓
输入参考文本 ("你好，我是张三")
    ↓
[chinese-bert] 理解中文语义
    ↓
[s1bert.ckpt] 文本转语义特征
    ↓
输入目标文本 ("今天天气真不错")
    ↓
[s2G2333k.pth] 音色 + 语义 → 生成语音
    ↓
[s2D2333k.pth] 质量优化
    ↓
输出克隆音色的语音 ✅
```

**关键点：**
- ❌ 没有这些模型 = Docker 无法启动
- ✅ 有了这些模型 = 可以立即使用音色克隆
- 🎯 这些是预训练模型，无需额外训练即可使用

## 🔧 常用命令

### 启动服务

```bash
docker-compose up -d
```

### 停止服务

```bash
docker-compose down
```

### 查看日志

```bash
docker-compose logs -f
```

### 重启服务

```bash
docker-compose restart
```

### 检查服务状态

```bash
docker-compose ps
```

## 🐛 常见问题

### Q1: Docker 启动时报错 "FileNotFoundError: pretrained_models"

**原因：** 缺少预训练模型

**解决：**
```bash
# 运行模型下载脚本
bash download_pretrained_models.sh

# 或者重新运行安装脚本
bash auto_install.sh

# 下载完成后重启
docker-compose down
docker-compose up -d
```

### Q2: 提示 "该模型不存在或未设置参考音频"

**原因：** 访问的 `/models/{version}` 接口但没有训练过的模型

**解决：**

**方式1：使用快速音色克隆（推荐）**
- 打开 `tts_test.html`
- 使用 "快速音色克隆" 功能
- 上传参考音频即可，无需训练

**方式2：训练自己的模型**
- 访问 WebUI: `http://localhost:8000/`
- 使用训练界面创建模型
- 模型会保存在 `models/v4/` 目录

### Q3: aria2c 下载速度慢

**解决：**
```bash
# 检查网络连接
ping www.modelscope.cn

# 或者使用 git clone 方式
cd GPT_SoVITS/pretrained_models
git clone https://www.modelscope.cn/tiansz/chinese-roberta-wwm-ext-large.git
```

### Q4: GPU 支持问题

**检查GPU是否可用：**
```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 测试 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

**如果失败：**
```bash
# 重新配置 nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Q5: 端口被占用

**检查端口占用：**
```bash
# 检查 8000 端口
lsof -i :8000

# 或修改 docker-compose.yaml 中的端口
# 将 "8000:8000" 改为 "8001:8000"
```

## 📖 目录结构

```
GPT-SoVITS-Inference/
├── auto_install.sh              # 一键安装脚本（主脚本）
├── download_pretrained_models.sh # 模型下载脚本（独立使用）
├── docker-compose.yaml          # Docker 配置
├── tts_test.html               # 音色克隆测试页面
├── interface.json              # OpenAPI 规范
├── USAGE.md                    # 使用指南（本文档）
├── DOWNLOAD_MODELS_README.md   # 模型下载说明
├── GPU_SETUP.md                # GPU 配置说明
└── GPT_SoVITS/
    ├── gsvi.py                 # FastAPI 服务入口
    ├── webui.py                # Gradio 训练界面
    ├── my_infer.py             # 推理逻辑
    ├── models/                 # 用户训练的模型
    │   └── v4/
    └── pretrained_models/      # 预训练模型（自动下载）
        ├── gsv-v2final-pretrained/
        ├── chinese-roberta-wwm-ext-large/
        └── chinese-hubert-base/
```

## 🎓 进阶使用

### 使用 API 进行音色克隆

```bash
# 1. 上传参考音频
curl -X POST http://localhost:8000/upload \
  -F "file=@reference.wav"

# 2. 调用推理接口
curl -X POST http://localhost:8000/infer_classic \
  -H "Content-Type: application/json" \
  -d '{
    "gpt_model_name": "default",
    "sovits_model_name": "default",
    "ref_audio_path": "uploaded/reference.wav",
    "prompt_text": "你好，我是张三",
    "text": "今天天气真不错",
    "text_language": "zh",
    "prompt_language": "zh"
  }' \
  --output output.wav
```

### 训练自己的模型

1. 访问 WebUI: `http://localhost:8000/`
2. 准备训练数据（音频 + 文本）
3. 上传数据并开始训练
4. 训练完成后在 `models/v4/` 目录查看

## 📞 获取帮助

- 项目地址: https://github.com/AlphaKitty/GPT-SoVITS-Inference
- 提交 Issue: https://github.com/AlphaKitty/GPT-SoVITS-Inference/issues
- 查看文档:
  - `DOWNLOAD_MODELS_README.md` - 模型下载说明
  - `GPU_SETUP.md` - GPU 配置说明
  - `tts_test.html` - 功能测试界面
