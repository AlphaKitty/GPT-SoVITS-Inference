# GPT-SoVITS Docker 部署指南 (Ubuntu)

本指南提供在 Ubuntu 系统下使用 Docker Compose 启动 GPT-SoVITS 的完整说明。

## 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [详细步骤](#详细步骤)
- [脚本说明](#脚本说明)
- [常见问题](#常见问题)
- [端口说明](#端口说明)

## 前置要求

### 1. 系统要求

- Ubuntu 18.04 或更高版本
- 至少 8GB RAM (推荐 16GB+)
- 至少 20GB 可用磁盘空间
- (可选) NVIDIA GPU 用于加速推理

### 2. 安装 Docker

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | bash

# 将当前用户添加到 docker 组 (避免每次使用 sudo)
sudo usermod -aG docker $USER

# 重新登录或执行以下命令使组权限生效
newgrp docker

# 验证安装
docker --version
```

### 3. 安装 Docker Compose

Docker Compose 通常随 Docker 一起安装。如果没有，可以执行：

```bash
# 安装 Docker Compose 插件
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 验证安装
docker compose version
```

### 4. (可选) 安装 NVIDIA Container Toolkit

如果您有 NVIDIA GPU，需要安装 NVIDIA Container Toolkit 以在 Docker 中使用 GPU：

```bash
# 添加 NVIDIA 仓库
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# 安装 NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 重启 Docker 服务
sudo systemctl restart docker

# 验证 GPU 可用
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi
```

## 快速开始

### 方法 1: 使用快速启动脚本 (推荐用于快速测试)

```bash
# 给予执行权限
chmod +x quick_start.sh

# 启动服务 (默认使用 CUDA 12.8 完整版)
./quick_start.sh
```

### 方法 2: 使用完整启动脚本 (推荐)

```bash
# 给予执行权限
chmod +x start_docker.sh

# 启动服务 (带交互式选项)
./start_docker.sh
```

### 方法 3: 使用 Docker Compose 命令

```bash
# 启动 CUDA 12.8 完整版
docker compose up -d GPT-SoVITS-CU128

# 或启动 CUDA 12.8 轻量版
docker compose up -d GPT-SoVITS-CU128-Lite
```

## 详细步骤

### 1. 克隆或进入项目目录

```bash
cd /path/to/GPT-SoVITS-Inference
```

### 2. 给予脚本执行权限

```bash
chmod +x start_docker.sh
chmod +x stop_docker.sh
chmod +x quick_start.sh
```

### 3. 启动服务

运行启动脚本：

```bash
./start_docker.sh
```

脚本会自动：
- 检查 Docker 和 Docker Compose 是否已安装
- 检查 NVIDIA GPU 和 NVIDIA Container Toolkit
- 让您选择要启动的服务版本
- 拉取最新的 Docker 镜像
- 启动选定的服务
- 显示服务状态和访问地址

### 4. 访问 WebUI

服务启动后，在浏览器中访问：

```
http://localhost:8000
```

### 5. 查看日志

```bash
# 查看实时日志
docker compose logs -f GPT-SoVITS-CU128

# 查看最近 100 行日志
docker compose logs --tail 100 GPT-SoVITS-CU128
```

### 6. 停止服务

```bash
# 使用停止脚本
./stop_docker.sh

# 或直接使用 Docker Compose 命令
docker compose down
```

## 脚本说明

### start_docker.sh

完整的启动脚本，包含以下功能：

- ✅ 环境检查 (Docker, Docker Compose, NVIDIA GPU)
- ✅ 交互式服务选择
- ✅ 镜像拉取
- ✅ 服务启动
- ✅ 状态显示
- ✅ 日志查看选项

**使用方法：**

```bash
./start_docker.sh
```

### stop_docker.sh

停止服务脚本，包含以下功能：

- ✅ 显示当前运行的容器
- ✅ 停止所有服务
- ✅ 可选清理资源 (容器、网络、卷)

**使用方法：**

```bash
./stop_docker.sh
```

### quick_start.sh

快速启动脚本，用于快速测试：

- ✅ 无需交互，直接启动默认服务 (CUDA 12.8 完整版)
- ✅ 显示访问地址和常用命令

**使用方法：**

```bash
./quick_start.sh
```

## 服务版本说明

项目提供 4 个服务版本可供选择：

### 1. GPT-SoVITS-CU128 (推荐)

- **镜像：** `xxxxrt666/gpt-sovits:latest-cu128`
- **CUDA 版本：** 12.8
- **特点：** 完整版，包含所有功能和模型
- **适用：** 有 NVIDIA GPU 且 CUDA 12.8 支持

### 2. GPT-SoVITS-CU128-Lite

- **镜像：** `xxxxrt666/gpt-sovits:latest-cu128-lite`
- **CUDA 版本：** 12.8
- **特点：** 轻量版，不包含 ASR 和 UVR5 模型
- **适用：** 磁盘空间有限或只需要基础 TTS 功能

### 3. GPT-SoVITS-CU126

- **镜像：** `xxxxrt666/gpt-sovits:latest-cu126`
- **CUDA 版本：** 12.6
- **特点：** 完整版
- **适用：** CUDA 12.6 支持的系统

### 4. GPT-SoVITS-CU126-Lite

- **镜像：** `xxxxrt666/gpt-sovits:latest-cu126-lite`
- **CUDA 版本：** 12.6
- **特点：** 轻量版
- **适用：** CUDA 12.6 支持且磁盘空间有限

## 端口说明

服务启动后会暴露以下端口：

| 端口 | 说明 |
|------|------|
| 8000 | 主 WebUI 界面 |
| 9871 | 推理服务端口 1 |
| 9872 | 推理服务端口 2 |
| 9873 | 推理服务端口 3 |
| 9874 | 推理服务端口 4 |
| 9880 | API 服务端口 |

## 常用 Docker Compose 命令

```bash
# 启动服务 (后台运行)
docker compose up -d GPT-SoVITS-CU128

# 启动服务 (前台运行，可以直接看到日志)
docker compose up GPT-SoVITS-CU128

# 停止服务
docker compose down

# 重启服务
docker compose restart GPT-SoVITS-CU128

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f GPT-SoVITS-CU128

# 进入容器
docker compose exec GPT-SoVITS-CU128 bash

# 拉取最新镜像
docker compose pull GPT-SoVITS-CU128

# 强制重新创建容器
docker compose up -d --force-recreate GPT-SoVITS-CU128
```

## 常见问题

### 1. 权限问题

**问题：** 执行 Docker 命令时提示权限错误

**解决方法：**

```bash
# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker
```

### 2. GPU 不可用

**问题：** 容器中无法使用 GPU

**解决方法：**

```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 安装 NVIDIA Container Toolkit
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# 验证 GPU 在 Docker 中可用
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi
```

### 3. 端口冲突

**问题：** 端口已被占用

**解决方法：**

```bash
# 查看端口占用
sudo lsof -i :8000

# 修改 docker-compose.yaml 中的端口映射
# 例如将 8000:8000 改为 8001:8000
```

### 4. 共享内存不足

**问题：** 训练或推理时出现共享内存错误

**解决方法：**

在 `docker-compose.yaml` 中增加 `shm_size`：

```yaml
shm_size: "16g"  # 根据可用内存调整
```

### 5. 容器无法启动

**问题：** 容器启动失败

**解决方法：**

```bash
# 查看详细日志
docker compose logs GPT-SoVITS-CU128

# 检查镜像是否正确拉取
docker images | grep gpt-sovits

# 清理并重新启动
docker compose down
docker compose pull
docker compose up -d
```

### 6. 模型文件缺失

**问题：** Lite 版本缺少某些模型

**解决方法：**

Lite 版本不包含 ASR 和 UVR5 模型，需要手动下载：

```bash
# ASR 模型会在首次使用时自动下载

# UVR5 模型需手动下载到
./tools/uvr5/uvr5_weights/
```

### 7. 网络问题导致镜像拉取失败

**问题：** 无法从 Docker Hub 拉取镜像

**解决方法：**

```bash
# 使用国内镜像加速器，编辑 /etc/docker/daemon.json
sudo nano /etc/docker/daemon.json

# 添加以下内容：
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 数据持久化

容器会将当前目录挂载到容器的 `/workspace/GPT-SoVITS`，因此：

- ✅ 模型文件会保存在本地
- ✅ 训练数据会保存在本地
- ✅ 配置文件会保存在本地
- ✅ 容器删除后数据不会丢失

## 性能优化建议

### 1. 使用 GPU 加速

确保安装了 NVIDIA Container Toolkit 并在 `docker-compose.yaml` 中启用 GPU 支持。

### 2. 增加共享内存

根据可用内存调整 `shm_size` 参数：

```yaml
shm_size: "16g"  # 推荐至少 8g
```

### 3. 使用 SSD 存储

将项目目录放在 SSD 上以提高 I/O 性能。

### 4. 调整环境变量

在 `docker-compose.yaml` 中设置 `is_half=true` 以使用半精度（如果 GPU 支持）：

```yaml
environment:
  - is_half=true
```

## 更新说明

### 更新 Docker 镜像

```bash
# 拉取最新镜像
docker compose pull

# 重新创建容器
docker compose up -d --force-recreate
```

### 更新代码

由于使用了目录挂载，更新代码后无需重新构建镜像：

```bash
# 拉取最新代码
git pull

# 重启容器
docker compose restart
```

## 技术支持

- GitHub Issues: https://github.com/RVC-Boss/GPT-SoVITS/issues
- Docker Hub: https://hub.docker.com/r/xxxxrt666/gpt-sovits
- 文档: https://www.yuque.com/baicaigongchang1145haoyuangong/ib3g1e

## 许可证

本项目遵循 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

**享受使用 GPT-SoVITS！** 🎉
