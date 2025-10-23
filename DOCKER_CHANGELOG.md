# Docker 部署脚本更新日志

## 版本 2.0 - 2025-10-23

### 🎉 主要更新

#### 1. 自动依赖安装功能

`start_docker.sh` 现在支持自动安装所有必需的依赖项：

- ✅ **Docker Engine**: 自动检测并安装 Docker
- ✅ **Docker Compose**: 自动检测并安装 Docker Compose Plugin
- ✅ **NVIDIA Container Toolkit**: 自动检测 GPU 并安装 NVIDIA 工具包（可选）
- ✅ **用户权限配置**: 自动配置 Docker 用户组权限

#### 2. 改进的安装函数

新增三个安装函数：

##### `install_docker()`
- 使用官方安装脚本安装 Docker
- 自动配置 systemd 服务
- 将当前用户添加到 docker 组
- 启动并启用 Docker 服务
- 提供组权限即时应用选项

##### `install_docker_compose()`
- 通过 apt 安装 Docker Compose Plugin
- 自动更新包索引
- 验证安装成功

##### `install_nvidia_toolkit()`
- 检测 NVIDIA 驱动是否已安装
- 配置 NVIDIA 仓库和 GPG 密钥
- 安装 nvidia-container-toolkit
- 配置 Docker 运行时以支持 GPU
- 重启 Docker 服务
- 验证 GPU 在 Docker 中的可用性

#### 3. 增强的检查逻辑

更新了三个检查函数：

##### `check_docker()`
- 检测 Docker 是否已安装
- 如果未安装，询问是否自动安装
- 安装后验证是否成功
- 提供手动安装命令作为备选

##### `check_docker_compose()`
- 检测 Docker Compose 是否已安装
- 如果未安装，询问是否自动安装
- 安装后验证是否成功
- 提供手动安装命令作为备选

##### `check_nvidia_docker()`
- 检测 NVIDIA GPU 和驱动
- 检测 NVIDIA Container Toolkit 是否已配置
- 如果有 GPU 但未配置工具包，询问是否安装
- 根据检测结果设置 USE_GPU 变量

### 📝 使用体验改进

#### 交互式安装确认

所有安装操作都会先询问用户确认：

```bash
是否自动安装 Docker? (y/n, 默认 y):
是否自动安装 Docker Compose? (y/n, 默认 y):
是否安装 NVIDIA Container Toolkit 以启用 GPU 支持? (y/n, 默认 y):
```

#### 详细的状态反馈

每个步骤都有清晰的状态提示：

- 🔵 `[INFO]`: 提供操作信息
- 🟢 `[SUCCESS]`: 操作成功完成
- 🟡 `[WARNING]`: 警告信息
- 🔴 `[ERROR]`: 错误信息

#### 智能的错误处理

- 如果用户拒绝安装必需的依赖，脚本会退出并提供手动安装命令
- 如果安装失败，脚本会显示错误信息并退出
- 对于可选的 NVIDIA Toolkit，安装失败不会影响脚本继续执行

### 🆕 新增文件

#### 1. DOCKER_SETUP_CN.md
简化的中文快速开始指南：
- 一键启动说明
- 脚本功能概览
- 常用命令参考
- 常见问题解答

#### 2. DOCKER_CHANGELOG.md
详细的更新日志文档（本文件）

### 📖 文档更新

#### DOCKER_UBUNTU_README.md
- 更新"快速开始"章节，突出自动安装功能
- 添加"极速启动（零配置）"章节
- 更新 start_docker.sh 功能说明
- 添加完整的脚本流程说明

### 🔄 向后兼容性

- 所有现有功能保持不变
- 脚本仍然可以在已安装 Docker 的系统上正常运行
- 不会影响现有的 Docker 配置

### 📋 完整功能列表

#### start_docker.sh 现在包含：

1. **环境检查**
   - 检查用户权限
   - 检查操作系统类型

2. **依赖安装**（新增）
   - Docker Engine 自动安装
   - Docker Compose 自动安装
   - NVIDIA Container Toolkit 自动安装

3. **环境验证**
   - Docker 版本检查
   - Docker Compose 版本检查
   - GPU 可用性检查

4. **服务配置**
   - 交互式服务版本选择
   - 镜像拉取选项
   - GPU 支持配置

5. **服务管理**
   - 启动选定的服务
   - 显示服务状态
   - 提供访问地址

6. **监控选项**
   - 可选的实时日志查看
   - 常用命令提示

### 🎯 使用场景

#### 场景 1: 全新的 Ubuntu 系统

```bash
# 只需两个命令
chmod +x start_docker.sh
./start_docker.sh

# 脚本会自动：
# 1. 安装 Docker
# 2. 安装 Docker Compose
# 3. 安装 NVIDIA Toolkit（如果有 GPU）
# 4. 配置权限
# 5. 启动服务
```

#### 场景 2: 已安装 Docker 的系统

```bash
./start_docker.sh

# 脚本会跳过已安装的组件，直接启动服务
```

#### 场景 3: 有 GPU 但未安装 NVIDIA Toolkit

```bash
./start_docker.sh

# 脚本会：
# 1. 检测到 GPU
# 2. 询问是否安装 NVIDIA Toolkit
# 3. 如果同意，自动安装并配置
# 4. 启动服务并启用 GPU 支持
```

### ⚙️ 技术细节

#### Docker 安装方法

使用 Docker 官方安装脚本：
```bash
curl -fsSL https://get.docker.com | sudo bash
```

优点：
- 自动检测系统版本
- 使用官方仓库
- 始终安装最新稳定版

#### Docker Compose 安装方法

使用 apt 包管理器：
```bash
sudo apt-get install docker-compose-plugin
```

优点：
- 与 Docker 完美集成
- 使用 `docker compose` 命令（v2 语法）
- 通过系统包管理器管理

#### NVIDIA Container Toolkit 安装方法

标准安装流程：
1. 添加 NVIDIA 仓库
2. 安装 nvidia-container-toolkit
3. 配置 Docker 运行时
4. 重启 Docker 服务
5. 验证 GPU 可用

### 🔒 安全考虑

- 使用 `sudo` 仅在必要时
- 官方安装脚本使用 HTTPS
- GPG 密钥验证
- 用户确认所有安装操作

### 🚀 性能优化

- 并行执行独立的检查操作
- 只在需要时下载和安装
- 跳过已安装的组件
- 智能缓存检测结果

### 📊 测试环境

已在以下环境测试：
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

支持的架构：
- x86_64 (amd64)
- ARM64 (理论上支持，未完全测试)

### 🐛 已知限制

1. 仅支持 Ubuntu/Debian 系统（使用 apt）
2. NVIDIA Toolkit 安装需要预先安装 NVIDIA 驱动
3. 首次安装 Docker 后可能需要重新登录以应用组权限
4. 某些网络环境可能无法访问 Docker Hub 或 NVIDIA 仓库

### 💡 最佳实践

1. **首次安装建议**
   - 在全新系统上运行脚本
   - 确保有良好的网络连接
   - 准备足够的磁盘空间（至少 20GB）

2. **GPU 用户建议**
   - 先安装 NVIDIA 驱动
   - 运行 `nvidia-smi` 确认驱动正常
   - 让脚本自动安装 NVIDIA Toolkit

3. **权限问题**
   - 如果遇到权限错误，运行 `newgrp docker`
   - 或者重新登录系统
   - 避免使用 root 用户运行

4. **网络问题**
   - 配置 Docker 镜像加速器
   - 使用代理（如需要）
   - 考虑手动下载镜像

### 📈 未来计划

可能的改进方向：

1. **多系统支持**
   - 支持 CentOS/RHEL（使用 yum/dnf）
   - 支持 Arch Linux（使用 pacman）
   - 支持 macOS（使用 Docker Desktop）

2. **更智能的检测**
   - 检测网络速度并推荐镜像源
   - 检测系统资源并推荐服务版本
   - 检测已有容器并提供升级选项

3. **增强的日志**
   - 保存安装日志到文件
   - 提供详细的错误诊断
   - 生成安装报告

4. **配置持久化**
   - 保存用户选择
   - 下次启动使用相同配置
   - 提供配置文件编辑器

### 📝 贡献者

- 初始版本：基于 GPT-SoVITS 官方 docker-compose.yaml
- v2.0 更新：添加自动安装功能和完整文档

### 📄 许可证

遵循 GPT-SoVITS 项目的 MIT 许可证

---

**更新时间**: 2025-10-23
**脚本版本**: 2.0
**维护者**: GPT-SoVITS Community
