# GPT-SoVITS 模型下载修复说明

## 问题描述

原 `auto_install.sh` 脚本存在以下问题：

1. **ModelScope 源模型版本不匹配**
   - 脚本下载：`s1bert25hz-2kh-longer-epoch=68e-step=50232.ckpt` (旧版本)
   - 程序需要：`s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt` (新版本)
   - 导致启动时出现 `FileNotFoundError`

2. **缺少国内可用的稳定下载源**
   - 选项 1 (HuggingFace) 需要科学上网
   - 选项 2 (ModelScope) 模型版本过时

## 解决方案

### 已整合的修改

在 `auto_install.sh` 中新增了 **HuggingFace 镜像源**下载选项，现在有 4 个下载选项：

#### 选项 1: HuggingFace 官方源
- **适用场景**: 有科学上网能力
- **优点**: 官方源，完整仓库，版本最新
- **缺点**: 需要科学上网
- **方式**: `git clone` 完整仓库

#### 选项 2: HuggingFace 镜像 hf-mirror.com ⭐推荐
- **适用场景**: 国内网络，推荐使用
- **优点**:
  - 国内可访问
  - 模型版本正确 (v2 final, 5k 小时训练)
  - 支持断点续传
- **下载工具**: aria2c / wget / curl
- **镜像地址**: `https://hf-mirror.com`

#### 选项 3: ModelScope 镜像 ⚠️
- **适用场景**: 仅当前两个选项都失败时使用
- **优点**: 国内访问快
- **缺点**: 模型版本可能不匹配
- **警告**: 会提示用户模型版本风险

#### 选项 4: 跳过下载
- 提供详细的手动下载指南
- 列出所有需要的文件和下载地址

### 新增功能

1. **模型文件验证**
   - 下载完成后自动验证关键文件是否存在
   - 显示每个文件的验证状态
   - 如果有文件缺失，提示用户重新下载

2. **多下载工具支持**
   - 优先使用 `aria2c` (多线程，速度快)
   - 备选 `wget` (稳定)
   - 最后使用 `curl` (通用)

3. **更清晰的提示信息**
   - 每个选项都有明确的说明
   - 显示预计下载大小
   - 警告潜在的问题

## 使用方法

### 方式 1: 运行完整安装脚本（推荐新用户）

```bash
bash auto_install.sh
```

脚本会自动：
1. 安装 Docker 和相关工具
2. 下载预训练模型（选择选项 2）
3. 启动 Docker 容器

### 方式 2: 仅下载/修复模型（推荐已安装用户）

如果你已经运行过脚本但模型有问题，可以：

```bash
# 清理旧的模型文件
rm -rf GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/*

# 重新运行脚本，只下载模型部分
bash auto_install.sh
# 在模型下载选项中选择 2 (HuggingFace 镜像)
```

### 方式 3: 使用独立修复脚本

```bash
bash download_models_fix.sh
# 选择 2 (HuggingFace 镜像)
```

## 模型文件清单

### 必需的 GPT-SoVITS v2 模型

#### 1️⃣ 预训练模型（用于训练）
**放置位置**: `GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/`

**下载地址**: https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained

- ✅ `s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt` (155 MB)
  - GPT 模型，用于文本理解和语音生成
  - ⚠️ 文件名中的 `=` 号必须保留！

- ✅ `s2G2333k.pth` (106 MB)
  - SoVITS Generator，语音合成生成器

- ✅ `s2D2333k.pth` (93.5 MB)
  - SoVITS Discriminator，语音质量判别器

#### 2️⃣ 推理模型（用于音色克隆）
**放置位置**: `GPT_weights_v4/` 和 `SoVITS_weights_v4/`

**来源**: 从预训练模型复制/链接

```
GPT_weights_v4/
  └── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt  (复制或链接)

SoVITS_weights_v4/
  ├── s2G2333k.pth  (复制或链接)
  └── s2D2333k.pth  (复制或链接)
```

**⚠️ 重要**: `auto_install.sh` 会自动配置推理模型目录。如果手动下载，需要运行：
```bash
bash setup_inference_models.sh
```

### 必需的 NLP 模型
放置位置: `GPT_SoVITS/pretrained_models/`

- ✅ `chinese-roberta-wwm-ext-large/` (~1.2GB)
  - 中文语义理解模型

- ✅ `chinese-hubert-base/` (~400MB)
  - 中文音色特征提取模型

## 验证安装

### 检查文件结构

```bash
ls -lh GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/
```

应该看到：
```
s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
s2G2333k.pth
s2D2333k.pth
```

### 检查文件大小

```bash
du -sh GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/*
```

预期大小（总计约 355 MB）：
- `s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt`: 155 MB
- `s2G2333k.pth`: 106 MB
- `s2D2333k.pth`: 93.5 MB

### 启动测试

```bash
# 清理并重启容器（推荐，确保干净启动）
docker compose down && docker compose up -d

# 查看日志
docker compose logs -f
```

如果没有出现 `FileNotFoundError`，说明模型配置正确。

## 常见问题

### Q1: 下载速度太慢怎么办？
A:
- 确保安装了 `aria2c`：`sudo apt-get install aria2`
- aria2c 支持 16 线程并发下载，速度会快很多

### Q2: 下载中断了怎么办？
A:
- 重新运行脚本，选择相同的选项
- aria2c 和 wget 都支持断点续传
- 会自动跳过已下载的文件

### Q3: ModelScope 下载的模型能用吗？
A:
- 不推荐，版本不匹配会导致启动失败
- 如果已经下载，请删除后重新用选项 2 下载

### Q4: 手动下载应该怎么做？
A:
1. 访问 https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained
2. 下载三个文件到 `GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/`
3. 确保文件名完全一致（包括 `=` 号）

### Q5: 为什么要下载这么多模型？
A:
- GPT-SoVITS 是一个复杂的 AI 语音克隆系统
- 需要多个模型协同工作：
  - GPT 模型理解文本和韵律
  - SoVITS 模型生成音色
  - BERT 模型理解中文语义
  - HuBERT 模型提取音色特征

## 技术细节

### HuggingFace 镜像下载 URL 格式

```bash
https://hf-mirror.com/{owner}/{repo}/resolve/main/{path}/{filename}
```

示例：
```bash
https://hf-mirror.com/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch%3D12-step%3D369668.ckpt
```

注意：URL 中的 `=` 需要编码为 `%3D`

### aria2c 下载参数说明

```bash
aria2c -x 16 -s 16 -k 1M -o output_filename "url"
```

- `-x 16`: 最多使用 16 个连接
- `-s 16`: 分割成 16 个片段并行下载
- `-k 1M`: 每个片段最小 1MB
- `-o`: 输出文件名

## 更新日志

### 2025-10-23
- ✅ 新增 HuggingFace 镜像下载选项（选项 2）
- ✅ 将 ModelScope 改为选项 3，并添加警告
- ✅ 新增模型文件验证功能
- ✅ 支持 aria2c/wget/curl 多种下载工具
- ✅ 更新手动下载指南
- ✅ 修复文件名不匹配问题

## 参考链接

- 官方模型仓库: https://huggingface.co/lj1995/GPT-SoVITS
- HuggingFace 镜像: https://hf-mirror.com
- 项目文档: https://github.com/RVC-Boss/GPT-SoVITS
