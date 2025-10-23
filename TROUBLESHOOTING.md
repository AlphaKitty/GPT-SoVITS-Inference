# GPT-SoVITS Docker 部署问题排查指南

## 常见问题及解决方案

### 问题 1: "此脚本仅支持 Ubuntu/Debian 系统" 错误

#### 症状
即使在 Ubuntu 系统上运行 `start_docker.sh`，仍然收到错误提示：
```
[ERROR] 此脚本仅支持 Ubuntu/Debian 系统
```

#### 可能的原因

1. **脚本使用了错误的 Shell 解释器**
2. **PATH 环境变量问题**
3. **脚本文件编码或行尾符问题**
4. **权限问题**

#### 解决方案

##### 方案 1: 使用诊断脚本（推荐）

首先运行诊断脚本来了解问题所在：

```bash
# 给予执行权限
chmod +x diagnose_system.sh test_system_check.sh

# 运行完整诊断
./diagnose_system.sh

# 运行快速测试
./test_system_check.sh
```

诊断脚本会显示：
- 系统信息
- 包管理器状态
- Docker 状态
- 用户权限
- 网络连接
- 磁盘空间

##### 方案 2: 使用正确的方式运行脚本

**正确的运行方式：**

```bash
# 方式 1: 直接执行（推荐）
chmod +x start_docker.sh
./start_docker.sh

# 方式 2: 明确使用 bash
bash start_docker.sh

# 方式 3: 使用完整路径
bash /path/to/start_docker.sh
```

**❌ 错误的运行方式：**

```bash
# 不要使用 sh 命令（可能使用不兼容的 shell）
sh start_docker.sh  # ❌ 错误

# 不要在没有权限时运行
start_docker.sh  # ❌ 错误（如果没有执行权限）
```

##### 方案 3: 检查并修复文件编码

如果脚本是从 Windows 系统复制的，可能存在行尾符问题：

```bash
# 安装 dos2unix 工具
sudo apt-get install dos2unix

# 转换行尾符
dos2unix start_docker.sh
dos2unix stop_docker.sh
dos2unix quick_start.sh

# 重新运行
./start_docker.sh
```

##### 方案 4: 手动验证系统兼容性

运行以下命令手动检查：

```bash
# 检查系统类型
cat /etc/os-release

# 检查 apt-get 是否可用
which apt-get
apt-get --version

# 检查 apt 是否可用
which apt
apt --version

# 检查 Shell
echo $SHELL
```

如果以上命令都能正常执行，说明系统是兼容的。

##### 方案 5: 使用 Docker Compose 直接启动

如果脚本问题难以解决，可以直接使用 Docker Compose：

```bash
# 手动安装 Docker（如果未安装）
curl -fsSL https://get.docker.com | sudo bash

# 手动安装 Docker Compose（如果未安装）
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 配置用户权限
sudo usermod -aG docker $USER
newgrp docker

# 直接启动服务
docker compose up -d GPT-SoVITS-CU128

# 查看日志
docker compose logs -f GPT-SoVITS-CU128
```

##### 方案 6: 启用调试模式

在脚本中添加调试输出：

```bash
# 在运行脚本前设置调试模式
bash -x start_docker.sh
```

这将显示每一步的执行过程，帮助找出问题所在。

---

### 问题 2: Docker 权限错误

#### 症状
```
permission denied while trying to connect to the Docker daemon socket
```

#### 解决方案

```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 应用组权限（选择一个方法）
# 方法 1: 使用 newgrp
newgrp docker

# 方法 2: 重新登录
exit  # 然后重新登录

# 方法 3: 重启系统
sudo reboot

# 验证权限
docker ps
```

---

### 问题 3: NVIDIA GPU 不可用

#### 症状
- 容器中无法使用 GPU
- `nvidia-smi` 在容器中返回错误

#### 解决方案

```bash
# 1. 检查主机上的 NVIDIA 驱动
nvidia-smi

# 2. 安装 NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 3. 配置 Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 4. 验证
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu20.04 nvidia-smi
```

---

### 问题 4: 端口已被占用

#### 症状
```
Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use
```

#### 解决方案

```bash
# 查找占用端口的进程
sudo lsof -i :8000

# 选项 1: 停止占用端口的进程
sudo kill -9 <PID>

# 选项 2: 修改 docker-compose.yaml 使用不同端口
# 编辑文件，将端口映射改为：
# ports:
#   - "8001:8000"  # 使用 8001 替代 8000
```

---

### 问题 5: 镜像拉取失败

#### 症状
```
Error response from daemon: Get "https://registry-1.docker.io/v2/": ...
```

#### 解决方案

##### 方案 1: 配置 Docker 镜像加速器

```bash
# 创建或编辑 Docker daemon 配置
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json

# 添加以下内容（使用国内镜像源）
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ]
}

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 重新拉取镜像
docker compose pull
```

##### 方案 2: 使用代理

```bash
# 配置 Docker 使用代理
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf

# 添加以下内容
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

### 问题 6: 磁盘空间不足

#### 症状
```
no space left on device
```

#### 解决方案

```bash
# 清理未使用的 Docker 资源
docker system prune -a --volumes

# 清理悬空镜像
docker image prune -a

# 清理未使用的容器
docker container prune

# 清理未使用的卷
docker volume prune

# 查看磁盘使用情况
docker system df
df -h
```

---

### 问题 7: 容器无法启动

#### 症状
容器反复重启或立即退出

#### 解决方案

```bash
# 查看容器日志
docker compose logs GPT-SoVITS-CU128

# 查看最近 100 行日志
docker compose logs --tail 100 GPT-SoVITS-CU128

# 查看实时日志
docker compose logs -f GPT-SoVITS-CU128

# 检查容器状态
docker compose ps

# 进入容器调试
docker compose exec GPT-SoVITS-CU128 bash
```

---

### 问题 8: 共享内存不足

#### 症状
```
ERROR: Unexpected bus error encountered in worker
```

#### 解决方案

编辑 `docker-compose.yaml`，增加共享内存：

```yaml
services:
  GPT-SoVITS-CU128:
    # ... 其他配置 ...
    shm_size: "16g"  # 增加到 16GB 或更大
```

然后重启服务：

```bash
docker compose down
docker compose up -d GPT-SoVITS-CU128
```

---

## 获取帮助

如果以上方案都无法解决您的问题，请：

1. **运行完整诊断**：
   ```bash
   ./diagnose_system.sh > diagnosis.txt
   ```

2. **收集日志**：
   ```bash
   docker compose logs GPT-SoVITS-CU128 > docker.log
   ```

3. **提交 Issue**：
   - 访问: https://github.com/RVC-Boss/GPT-SoVITS/issues
   - 附上 `diagnosis.txt` 和 `docker.log`
   - 描述详细的错误信息和重现步骤

4. **查看文档**：
   - [快速开始](./DOCKER_SETUP_CN.md)
   - [完整文档](./DOCKER_UBUNTU_README.md)
   - [更新日志](./DOCKER_CHANGELOG.md)

---

## 调试技巧

### 启用详细输出

```bash
# 在脚本中启用调试
bash -x start_docker.sh

# 在 Docker Compose 中启用详细输出
docker compose --verbose up
```

### 检查环境变量

```bash
# 查看所有环境变量
env

# 查看 Docker 相关环境变量
env | grep -i docker

# 查看 PATH
echo $PATH
```

### 测试网络连接

```bash
# 测试互联网连接
ping -c 3 8.8.8.8

# 测试 Docker Hub 连接
ping -c 3 hub.docker.com

# 测试 HTTPS 连接
curl -I https://hub.docker.com
```

### 验证文件完整性

```bash
# 检查脚本语法
bash -n start_docker.sh

# 查看文件类型
file start_docker.sh

# 查看文件权限
ls -la start_docker.sh

# 查看文件编码
file -i start_docker.sh
```

---

**最后更新**: 2025-10-23
**维护者**: GPT-SoVITS Community
