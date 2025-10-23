# 外网地址配置说明

## 问题描述

之前的 `/infer_classic` 接口返回的音频 URL 地址是：
```json
{
  "audio_url": "http://0.0.0.0:8000/output/xxx.wav"
}
```

这个地址无法在其他机器上访问。现在已修复为自动获取外网 IP 或手动指定。

---

## 解决方案

### 方式 1: 自动获取外网 IP（默认）

**直接运行（不需要任何配置）**：

```bash
python gsvi.py -p 8000
```

程序会自动尝试获取外网 IP，优先级如下：

1. ✅ **外网 IP**（通过 ipify.org API）
   ```
   📡 自动获取的访问地址: http://123.45.67.89:8000
   ```

2. ✅ **局域网 IP**（如果无法获取外网 IP）
   ```
   📡 自动获取的访问地址: http://192.168.1.100:8000
   ```

3. ✅ **Localhost**（如果前两者都失败）
   ```
   📡 自动获取的访问地址: http://127.0.0.1:8000
   ```

**返回示例**：
```json
{
  "msg": "Success",
  "audio_url": "http://123.45.67.89:8000/output/xxx.wav"
}
```

---

### 方式 2: 手动指定外网地址

#### 2.1 使用 IP 地址

```bash
python gsvi.py -p 8000 --public-url http://123.45.67.89:8000
# 或简写
python gsvi.py -p 8000 -u 123.45.67.89
```

#### 2.2 使用域名

```bash
python gsvi.py -p 8000 -u http://your-domain.com:8000
# 或
python gsvi.py -p 8000 -u your-domain.com
```

#### 2.3 使用 HTTPS（如果配置了反向代理）

```bash
python gsvi.py -p 8000 -u https://tts.example.com
```

---

## Docker 环境配置

### 方式 1: 使用环境变量（推荐）

编辑 `docker-compose.yaml`：

```yaml
services:
  GPT-SoVITS-CU128:
    environment:
      - is_half=true
      - PUBLIC_URL=http://your-ip:8000  # 添加这一行
```

取消注释并填入你的外网 IP：

```yaml
environment:
  - is_half=true
  - PUBLIC_URL=http://123.45.67.89:8000  # 你的外网IP
```

然后重启：

```bash
docker compose down
docker compose up -d
```

### 方式 2: 直接修改启动命令

编辑 `docker-compose.yaml`：

```yaml
# 注释掉动态命令部分
# command: >
#   bash -c "..."

# 使用静态命令
command: python gsvi.py -p 8000 -u http://123.45.67.89:8000
```

重启容器：

```bash
docker compose down
docker compose up -d
```

### 方式 3: 自动获取（默认行为）

如果不配置 `PUBLIC_URL` 环境变量，程序会自动尝试获取外网 IP。

**注意**：在 Docker 容器内可能无法正确获取宿主机的外网 IP，建议使用方式 1 或方式 2 手动指定。

---

## 验证配置

### 1. 查看启动日志

```bash
# Docker 环境
docker compose logs GPT-SoVITS-CU128 | grep "📡"

# 输出示例：
# 📡 使用指定的公网地址: 123.45.67.89:8000
```

### 2. 测试 API 返回

```bash
# 上传参考音频
curl -X POST http://localhost:8000/upload \
  -F "file=@reference.wav" \
  -F "model_name=test"

# 调用推理接口
curl -X POST http://localhost:8000/infer_classic \
  -H "Content-Type: application/json" \
  -d '{
    "gpt_model_name": "【经典】s1bert25hz-5kh-longer-epoch=12-step=369668",
    "sovits_model_name": "【经典】s2G2333k",
    "ref_audio_path": "custom_refs/test_reference.wav",
    "prompt_text": "这是参考文本",
    "prompt_text_lang": "zh",
    "text": "你好，这是音色克隆测试",
    "text_lang": "zh"
  }'
```

**正确的返回示例**（使用外网 IP）：

```json
{
  "msg": "Success",
  "audio_url": "http://123.45.67.89:8000/output/20250101_120000_infer_classic.wav"
}
```

**错误的返回示例**（未配置）：

```json
{
  "msg": "Success",
  "audio_url": "http://0.0.0.0:8000/output/xxx.wav"  // ❌ 无法访问
}
```

---

## 常见问题

### Q1: 我的服务器在内网，外网地址是 NAT 转换的，怎么配置？

A: 手动指定你的**外网 IP**（不是内网 IP）：

```bash
# 假设你的外网 IP 是 203.0.113.100
python gsvi.py -p 8000 -u http://203.0.113.100:8000
```

或在 `docker-compose.yaml` 中：

```yaml
environment:
  - PUBLIC_URL=http://203.0.113.100:8000
```

### Q2: 我配置了 Nginx 反向代理，使用 HTTPS，怎么配置？

A: 指定你的域名和协议：

```bash
python gsvi.py -p 8001 -u https://tts.example.com
```

**Nginx 配置示例**：

```nginx
server {
    listen 443 ssl;
    server_name tts.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Q3: 自动获取的 IP 不对怎么办？

A: 使用 `-u` 参数手动指定：

```bash
# 查看自动获取的IP
python gsvi.py -p 8000
# 输出: 📡 自动获取的访问地址: http://192.168.1.100:8000

# 如果不对，手动指定
python gsvi.py -p 8000 -u http://123.45.67.89:8000
```

### Q4: 端口映射后，返回的端口不对怎么办？

A: 在 `-u` 参数中指定正确的端口：

```bash
# 假设容器内是 8000，但映射到宿主机的 9000
docker run -p 9000:8000 ...

# 启动时指定：
python gsvi.py -p 8000 -u http://your-ip:9000
```

或在 `docker-compose.yaml` 中：

```yaml
ports:
  - "9000:8000"  # 宿主机:容器
environment:
  - PUBLIC_URL=http://123.45.67.89:9000  # 使用宿主机端口
```

### Q5: 我有多个域名，如何支持？

A: 目前只支持配置一个主要地址。如果客户端需要使用不同的域名，可以在客户端请求时传递 `dl_url` 参数：

```json
{
  "dl_url": "http://alternative-domain.com:8000",
  ...其他参数
}
```

这样返回的 `audio_url` 会使用你指定的 `dl_url`。

---

## 代码实现详解

### `gsvi.py` 的改动

#### 1. 增强的 `get_public_ip()` 函数

```python
def get_public_ip():
    """
    获取公网IP地址
    优先级：
    1. 通过 ipify.org API 获取外网IP
    2. 获取本地网络IP（局域网IP）
    3. 使用 localhost (127.0.0.1)
    """
    # 尝试获取外网IP
    try:
        import requests
        ip = requests.get("https://api.ipify.org", timeout=3).text
        print(f"✅ 获取到外网IP: {ip}")
        return ip
    except Exception as e:
        print(f"⚠️  无法获取外网IP: {e}")

    # 尝试获取局域网IP
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        print(f"✅ 使用局域网IP: {local_ip}")
        return local_ip
    except Exception as e:
        print(f"⚠️  无法获取局域网IP: {e}")

    # 最后使用 localhost
    print("⚠️  使用默认地址: 127.0.0.1")
    return "127.0.0.1"
```

#### 2. 新增 `--public-url` 参数

```python
parser.add_argument("-u","--public-url", type=str, default="",
                    help="返回给客户端的公网地址(如: http://your-domain.com:8001)")
```

#### 3. 启动时的地址解析逻辑

```python
# 确定返回给客户端的主机地址
if args.public_url:
    # 用户手动指定了公网URL
    if public_url.startswith('http://') or public_url.startswith('https://'):
        # 解析完整URL
        from urllib.parse import urlparse
        parsed = urlparse(public_url)
        host = parsed.hostname  # 只包含主机名
        if parsed.port:
            port = parsed.port
    else:
        # 只是IP或域名
        host = args.public_url.split(':')[0]
else:
    # 自动获取IP
    host = get_public_ip()
```

---

## 升级指南

### 从旧版本升级

1. **拉取最新代码**：
   ```bash
   git pull
   ```

2. **重启服务**：

   **非 Docker 环境**：
   ```bash
   # 停止旧进程
   pkill -f gsvi.py

   # 启动新版本（自动获取IP）
   python gsvi.py -p 8000

   # 或手动指定
   python gsvi.py -p 8000 -u http://your-ip:8000
   ```

   **Docker 环境**：
   ```bash
   # 重新构建镜像（如果有本地修改）
   docker compose build

   # 重启容器
   docker compose down
   docker compose up -d
   ```

3. **验证**：
   ```bash
   # 查看日志，确认IP正确
   docker compose logs GPT-SoVITS-CU128 | grep "📡"

   # 测试API
   curl http://localhost:8000/classic_model_list/v4
   ```

---

## 技术细节

### 代码位置

| 文件 | 修改内容 | 行号 |
|------|---------|------|
| `gsvi.py` | 增强 `get_public_ip()` 函数 | 371-402 |
| `gsvi.py` | 新增 `--public-url` 参数 | 412 |
| `gsvi.py` | 地址解析逻辑 | 420-440 |
| `gsvi.py` | 使用 `host` 变量生成 `audio_url` | 190, 243 |
| `docker-compose.yaml` | 添加 `PUBLIC_URL` 环境变量支持 | 66-86 |

### 向后兼容性

✅ **完全兼容**！如果你不配置任何参数，程序会自动尝试获取外网 IP，比旧版本的 `0.0.0.0` 更智能。

如果自动获取失败，会使用 `127.0.0.1`，至少在本地可用。

---

## 相关文档

- **模型目录详解**: `MODELS_DIRECTORY_GUIDE.md`
- **模型下载修复**: `MODEL_DOWNLOAD_FIX.md`
- **推理模型配置**: `UPDATE_INFERENCE_MODELS.md`
- **快速启动**: `QUICK_START.md`

---

**更新时间**: 2025-10-23
**版本**: v1.0
