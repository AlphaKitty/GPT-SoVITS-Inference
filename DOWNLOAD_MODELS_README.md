# GPT-SoVITS 预训练模型下载指南

## 问题说明

如果你在启动 Docker Compose 时遇到如下错误:

```
fall back to default t2s_weights_path: GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
FileNotFoundError: [Errno 2] No such file or directory: 'GPT_SoVITS/pretrained_models/...'
```

这说明你缺少必要的预训练模型文件。

## 快速解决方案

### 步骤 1: 运行下载脚本

```bash
bash download_pretrained_models.sh
```

### 步骤 2: 选择下载方式

脚本会提示你选择下载方式:

- **选项 1 - HuggingFace 镜像 (推荐国外用户)**
  - 需要安装 git-lfs: `sudo apt-get install git-lfs`
  - 适合网络访问 HuggingFace 较快的用户

- **选项 2 - ModelScope 镜像 (推荐国内用户)** ⭐
  - 使用 aria2c 或 wget 下载
  - 速度更快,国内网络友好
  - 如果已运行 auto_install.sh,则 aria2c 已自动安装

- **选项 3 - 手动下载**
  - 显示下载链接和目录结构
  - 适合需要通过浏览器或其他工具下载的用户

### 步骤 3: 等待下载完成

下载的模型总大小约 **2.8GB**,包括:

1. **GPT-SoVITS 基础模型** (~1.2GB)
   - s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
   - s2G2333k.pth
   - s2D2333k.pth

2. **中文 BERT 模型** (~1.2GB)
   - chinese-roberta-wwm-ext-large

3. **中文 HuBERT 模型** (~400MB)
   - chinese-hubert-base

### 步骤 4: 重启 Docker Compose

```bash
docker-compose down
docker-compose up -d
```

## 验证安装

下载完成后,你的目录结构应该如下:

```
GPT_SoVITS/pretrained_models/
├── gsv-v2final-pretrained/
│   ├── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
│   ├── s2G2333k.pth
│   └── s2D2333k.pth
├── chinese-roberta-wwm-ext-large/
│   ├── config.json
│   ├── pytorch_model.bin
│   ├── tokenizer.json
│   └── ...
└── chinese-hubert-base/
    ├── config.json
    ├── pytorch_model.bin
    └── ...
```

## 手动下载链接

如果自动下载失败,可以手动下载:

### HuggingFace (国外)

1. GPT-SoVITS 基础模型: https://huggingface.co/lj1995/GPT-SoVITS/tree/main
2. 中文 BERT: https://huggingface.co/hfl/chinese-roberta-wwm-ext-large/tree/main
3. 中文 HuBERT: https://huggingface.co/TencentGameMate/chinese-hubert-base/tree/main

### ModelScope (国内)

访问 ModelScope 官网搜索对应模型:
- https://www.modelscope.cn/models/iic/speech_personal_sambert-hifigan_nsf_tts_zh-cn_pretrain_16k
- https://www.modelscope.cn/models/tiansz/chinese-roberta-wwm-ext-large
- https://www.modelscope.cn/models/TencentGameMate/chinese-hubert-base

## 常见问题

### Q1: 下载速度很慢怎么办?

- 国内用户建议选择 **选项 2 (ModelScope)**
- 使用 aria2c 可以显著提升下载速度 (已在 auto_install.sh 中自动安装)

### Q2: 下载中断了怎么办?

- 重新运行脚本即可,已下载的文件会被跳过
- 如果使用 aria2c 或 wget,支持断点续传

### Q3: git-lfs 是什么?

- Git Large File Storage,用于下载大文件
- 安装命令: `sudo apt-get install git-lfs && git lfs install`

### Q4: 空间不够怎么办?

- 确保至少有 **5GB** 可用磁盘空间
- 可以删除旧的模型文件或清理 Docker 缓存

## 下一步

模型下载完成后,你就可以:

1. 启动服务访问 WebUI: http://localhost:8000
2. 使用 API 进行语音合成
3. 上传参考音频进行零样本音色克隆

详见: `tts_test.html` 中的 "快速音色克隆" 功能
