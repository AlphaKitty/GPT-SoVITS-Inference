# GPT-SoVITS Docker 部署

这是 GPT-SoVITS 的 Docker 部署方案，支持在 Ubuntu 系统上一键部署。

## 📚 文档索引

根据您的需求选择合适的文档：

### 🚀 快速开始（推荐）

**[DOCKER_SETUP_CN.md](./DOCKER_SETUP_CN.md)** - 5 分钟快速部署指南
- ✅ 适合：想快速启动的用户
- ✅ 内容：一键启动命令、常用操作、常见问题

### 📖 完整文档

**[DOCKER_UBUNTU_README.md](./DOCKER_UBUNTU_README.md)** - 详细部署文档
- ✅ 适合：想深入了解的用户
- ✅ 内容：详细安装步骤、配置说明、故障排除

### 📝 更新日志

**[DOCKER_CHANGELOG.md](./DOCKER_CHANGELOG.md)** - 脚本更新历史
- ✅ 适合：关注新功能的用户
- ✅ 内容：版本更新、功能改进、技术细节

## 🎯 极速开始

如果您赶时间，只需执行以下命令：

```bash
# 1. 给予执行权限
chmod +x start_docker.sh

# 2. 运行脚本（自动安装所有依赖）
./start_docker.sh

# 3. 浏览器访问
# http://localhost:8000
```

就这么简单！脚本会自动安装 Docker、Docker Compose 和 NVIDIA Container Toolkit（如果需要）。

## 📦 脚本说明

### 主要脚本

| 脚本 | 功能 | 推荐度 |
|------|------|--------|
| **start_docker.sh** | 完整启动脚本，支持自动安装依赖 | ⭐⭐⭐⭐⭐ |
| **quick_start.sh** | 快速启动脚本，需预先安装依赖 | ⭐⭐⭐ |
| **stop_docker.sh** | 停止和清理脚本 | ⭐⭐⭐⭐ |

### start_docker.sh 功能亮点

- ✅ 自动检测并安装 Docker
- ✅ 自动检测并安装 Docker Compose
- ✅ 自动检测 GPU 并安装 NVIDIA Container Toolkit
- ✅ 自动配置用户权限
- ✅ 交互式选择服务版本
- ✅ 自动拉取最新镜像
- ✅ 显示服务状态和访问地址
- ✅ 可选查看实时日志

## 🔧 服务版本

提供 4 个服务版本：

| 版本 | CUDA | 大小 | 说明 |
|------|------|------|------|
| GPT-SoVITS-CU128 | 12.8 | ~10GB | 完整版，推荐 ⭐ |
| GPT-SoVITS-CU128-Lite | 12.8 | ~5GB | 轻量版 |
| GPT-SoVITS-CU126 | 12.6 | ~10GB | 完整版 |
| GPT-SoVITS-CU126-Lite | 12.6 | ~5GB | 轻量版 |

**完整版 vs 轻量版：**
- 完整版：包含所有模型和工具（ASR、UVR5）
- 轻量版：不含 ASR 和 UVR5 模型，体积更小

## 🌟 特性

### 零配置部署
- 无需手动安装任何依赖
- 脚本自动检测并安装所需组件
- 全自动化配置流程

### 智能 GPU 支持
- 自动检测 NVIDIA GPU
- 询问是否安装 NVIDIA Container Toolkit
- 验证 GPU 在 Docker 中的可用性

### 交互式体验
- 清晰的彩色输出
- 友好的错误提示
- 每步确认选项

### 数据持久化
- 模型文件保存在本地
- 训练数据保存在本地
- 容器删除后数据不丢失

## 📋 系统要求

### 最低要求
- Ubuntu 18.04 或更高版本
- 8GB RAM
- 20GB 可用磁盘空间

### 推荐配置
- Ubuntu 22.04 LTS
- 16GB+ RAM
- 50GB+ SSD 空间
- NVIDIA GPU（用于加速）

## 🔗 快速链接

- **GitHub**: https://github.com/RVC-Boss/GPT-SoVITS
- **Docker Hub**: https://hub.docker.com/r/xxxxrt666/gpt-sovits
- **官方文档**: https://www.yuque.com/baicaigongchang1145haoyuangong/ib3g1e

## ❓ 获取帮助

### 常见问题

1. **Docker 权限错误**
   ```bash
   newgrp docker
   ```

2. **GPU 不可用**
   ```bash
   # 检查驱动
   nvidia-smi

   # 安装驱动
   sudo apt-get install nvidia-driver-535
   ```

3. **端口冲突**
   - 修改 `docker-compose.yaml` 中的端口映射

### 获取支持

- 查看文档：[DOCKER_UBUNTU_README.md](./DOCKER_UBUNTU_README.md)
- 提交 Issue：https://github.com/RVC-Boss/GPT-SoVITS/issues
- 查看更新日志：[DOCKER_CHANGELOG.md](./DOCKER_CHANGELOG.md)

## 📞 贡献

欢迎提交 Pull Request 改进脚本和文档！

## 📄 许可证

MIT License - 详见项目根目录的 LICENSE 文件

---

**享受使用 GPT-SoVITS！** 🎉

如果觉得有帮助，请给项目一个 ⭐ Star！
