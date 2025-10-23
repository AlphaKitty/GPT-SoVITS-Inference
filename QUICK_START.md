# GPT-SoVITS Docker 快速启动指南

## 🚀 三步启动

### 步骤 1: 给予执行权限

```bash
chmod +x docker_start.sh
```

### 步骤 2: 运行启动脚本

```bash
./docker_start.sh
```

### 步骤 3: 访问服务

浏览器打开: **http://localhost:8000**

就这么简单！

---

## 📦 可用脚本对比

| 脚本 | 功能 | 适用场景 | 推荐度 |
|------|------|---------|--------|
| **docker_start.sh** | 检测+安装+启动 | 全新系统，一键部署 | ⭐⭐⭐⭐⭐ |
| **start_docker_simple.sh** | 仅启动服务 | 已安装 Docker | ⭐⭐⭐⭐ |
| **install_dependencies.sh** | 交互式安装 | 单独安装组件 | ⭐⭐⭐ |
| **start_docker.sh** | 完整功能（旧版） | 兼容性测试 | ⭐⭐⭐ |

## 🎯 推荐使用流程

### 场景 1: 全新 Ubuntu 系统

```bash
# 一键完成所有事情
chmod +x docker_start.sh
./docker_start.sh
```

脚本会自动：
- ✅ 检测并安装 Docker
- ✅ 检测并安装 Docker Compose
- ✅ 检测 GPU 并安装 NVIDIA Toolkit
- ✅ 配置权限
- ✅ 启动服务

### 场景 2: 已安装 Docker

```bash
# 直接启动服务
chmod +x start_docker_simple.sh
./start_docker_simple.sh
```

### 场景 3: 只想安装依赖

```bash
# 交互式安装
chmod +x install_dependencies.sh
./install_dependencies.sh
```

---

## ⚡ 常用命令

### 查看日志

```bash
docker compose logs -f GPT-SoVITS-CU128
```

### 停止服务

```bash
docker compose down
```

### 重启服务

```bash
docker compose restart GPT-SoVITS-CU128
```

### 查看状态

```bash
docker compose ps
```

### 进入容器

```bash
docker compose exec GPT-SoVITS-CU128 bash
```

---

## 🔧 服务版本

| 版本 | CUDA | 大小 | 包含内容 |
|------|------|------|---------|
| **GPT-SoVITS-CU128** | 12.8 | ~10GB | 完整版（ASR + UVR5） ⭐ 推荐 |
| GPT-SoVITS-CU128-Lite | 12.8 | ~5GB | 轻量版 |
| GPT-SoVITS-CU126 | 12.6 | ~10GB | 完整版（ASR + UVR5） |
| GPT-SoVITS-CU126-Lite | 12.6 | ~5GB | 轻量版 |

**完整版 vs 轻量版：**
- 完整版包含 ASR（自动语音识别）和 UVR5（人声分离）模型
- 轻量版需要手动下载这些模型

---

## ❓ 常见问题

### 1. 权限错误

```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 应用权限
newgrp docker
# 或重新登录
```

### 2. 端口冲突

编辑 `docker-compose.yaml`，修改端口：

```yaml
ports:
  - "8001:8000"  # 改为其他端口
```

### 3. GPU 不可用

```bash
# 检查驱动
nvidia-smi

# 如果未安装
sudo apt-get install nvidia-driver-535

# 重启系统
sudo reboot
```

### 4. 镜像拉取慢

配置 Docker 镜像加速：

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

sudo systemctl restart docker
```

---

## 📚 详细文档

- **完整文档**: [DOCKER_UBUNTU_README.md](./DOCKER_UBUNTU_README.md)
- **问题排查**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **更新日志**: [DOCKER_CHANGELOG.md](./DOCKER_CHANGELOG.md)

---

## 💡 提示

- 首次运行需要下载约 5-10GB 的 Docker 镜像
- 推荐使用 SSD 以获得更好性能
- 确保至少有 20GB 可用磁盘空间
- 如果有 NVIDIA GPU，强烈建议安装 NVIDIA Container Toolkit

---

## 🆘 获取帮助

### 运行诊断

```bash
chmod +x diagnose_system.sh
./diagnose_system.sh
```

### 提交 Issue

访问: https://github.com/RVC-Boss/GPT-SoVITS/issues

---

## 📦 预训练模型下载

### 必需的 3 个核心模型文件

**位置**: `GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/`

**下载地址**: https://huggingface.co/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained

| 文件名 | 大小 | 说明 |
|--------|------|------|
| `s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt` | 155 MB | GPT 模型 |
| `s2G2333k.pth` | 106 MB | Generator |
| `s2D2333k.pth` | 93.5 MB | Discriminator |

⚠️ **重要**: 文件名中的 `=` 号必须保留！

### 自动下载模型

```bash
# 方式 1: 使用完整安装脚本
bash auto_install.sh
# 选择选项 2: HuggingFace 镜像 (国内推荐) ⭐

# 方式 2: 使用模型修复脚本
bash download_models_fix.sh
# 选择选项 2
```

### 模型下载选项

| 选项 | 适用场景 | 推荐度 |
|------|----------|--------|
| 1️⃣ HuggingFace 官方 | 有科学上网 | ⭐⭐⭐ |
| 2️⃣ HuggingFace 镜像 | 国内网络 | ⭐⭐⭐⭐⭐ |
| 3️⃣ ModelScope | ⚠️ 版本旧，不推荐 | ⭐ |
| 4️⃣ 手动下载 | 备用方案 | ⭐⭐ |

### 验证模型文件

```bash
# 检查文件是否存在
ls -lh GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/

# 应该看到（总计约 355 MB）：
# s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt  (155 MB)
# s2G2333k.pth                                     (106 MB)
# s2D2333k.pth                                     (93.5 MB)
```

### 常见问题: FileNotFoundError

如果启动时遇到找不到模型文件的错误：

```bash
# 清理旧模型
rm -rf GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/*

# 重新下载（选择 HuggingFace 镜像）
bash download_models_fix.sh

# 重启容器
docker compose restart
```

**详细说明**: 查看 `MODEL_DOWNLOAD_FIX.md`

---

**祝您使用愉快！** 🎉
