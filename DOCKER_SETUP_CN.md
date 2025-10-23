# GPT-SoVITS Docker 快速部署指南

## 🎯 一键启动（推荐）

### 对于全新的 Ubuntu 系统

```bash
# 1. 下载或克隆项目
git clone <repository-url>
cd GPT-SoVITS-Inference

# 2. 给予脚本执行权限
chmod +x start_docker.sh

# 3. 运行启动脚本（会自动安装所有依赖）
./start_docker.sh
```

### 脚本会自动完成以下操作：

1. ✅ 检查并自动安装 Docker
2. ✅ 检查并自动安装 Docker Compose
3. ✅ 检测 NVIDIA GPU 并询问是否安装 Container Toolkit
4. ✅ 配置 Docker 用户组权限
5. ✅ 让您选择服务版本（CUDA 12.6/12.8，完整版/轻量版）
6. ✅ 自动拉取 Docker 镜像
7. ✅ 启动服务并显示访问地址

### 访问服务

服务启动后，在浏览器中访问：

```
http://localhost:8000
```

## 📋 安装内容说明

### start_docker.sh 会安装：

1. **Docker Engine**
   - 使用官方安装脚本
   - 自动配置 systemd 服务
   - 将当前用户添加到 docker 组

2. **Docker Compose Plugin**
   - 最新版 Docker Compose v2
   - 通过 apt 包管理器安装

3. **NVIDIA Container Toolkit**（可选，如果有 GPU）
   - 配置 NVIDIA 仓库
   - 安装 nvidia-container-toolkit
   - 配置 Docker 运行时
   - 验证 GPU 可用性

## 🛠️ 其他脚本

### 快速启动（需预先安装依赖）

```bash
chmod +x quick_start.sh
./quick_start.sh
```

### 停止服务

```bash
chmod +x stop_docker.sh
./stop_docker.sh
```

## 📊 服务版本

- **GPT-SoVITS-CU128**: CUDA 12.8 完整版（推荐）
- **GPT-SoVITS-CU128-Lite**: CUDA 12.8 轻量版
- **GPT-SoVITS-CU126**: CUDA 12.6 完整版
- **GPT-SoVITS-CU126-Lite**: CUDA 12.6 轻量版

## 🔧 常用命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f GPT-SoVITS-CU128

# 重启服务
docker compose restart GPT-SoVITS-CU128

# 停止服务
docker compose down

# 进入容器
docker compose exec GPT-SoVITS-CU128 bash
```

## ❓ 常见问题

### 1. 权限错误

如果遇到 Docker 权限错误，执行：

```bash
# 应用用户组权限
newgrp docker

# 或重新登录系统
```

### 2. GPU 不可用

确保已安装 NVIDIA 驱动：

```bash
# 检查 GPU
nvidia-smi

# 如果未安装驱动
sudo apt-get install nvidia-driver-535
```

### 3. 端口冲突

修改 `docker-compose.yaml` 中的端口映射：

```yaml
ports:
  - "8001:8000"  # 将 8000 改为 8001
```

## 📚 详细文档

完整文档请参阅：[DOCKER_UBUNTU_README.md](./DOCKER_UBUNTU_README.md)

## 💡 提示

- 首次运行需要下载 Docker 镜像（约 5-10GB），可能需要较长时间
- 建议在 SSD 上运行以获得更好的性能
- 如果有 NVIDIA GPU，强烈建议安装 NVIDIA Container Toolkit
- Lite 版本不包含 ASR 和 UVR5 模型，体积更小

## 📞 技术支持

- GitHub Issues: https://github.com/RVC-Boss/GPT-SoVITS/issues
- Docker Hub: https://hub.docker.com/r/xxxxrt666/gpt-sovits

---

**祝您使用愉快！** 🎉
