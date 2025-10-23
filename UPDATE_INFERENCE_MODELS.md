# 推理模型自动配置更新说明

## 🎯 问题描述

之前的 `auto_install.sh` 存在一个逻辑漏洞：

**场景**: 用户手动下载了预训练模型到 `GPT_SoVITS/pretrained_models/`，但没有配置推理目录 `GPT_weights_v4/` 和 `SoVITS_weights_v4/`

**旧版本行为**:
```bash
# 运行 auto_install.sh
bash auto_install.sh

# 输出:
✅ 预训练模型已存在，跳过下载
📦 拉取 Docker 镜像...
🚀 启动服务...

# 结果:
❌ API 调用失败: 无 GPT 模型 / 无 SoVITS 模型
```

**原因**: 脚本只在"下载模型"流程中配置推理目录，如果预训练模型已存在就直接跳过，导致推理目录未配置。

---

## ✅ 解决方案

### 修改后的逻辑

```bash
if [ 预训练模型不存在 ]; then
    # 下载模型
    download_models()

    # 验证模型
    verify_models()

    # 配置推理目录
    setup_inference_models()  ✅
else
    echo "预训练模型已存在，跳过下载"

    # 新增: 检查推理目录是否需要配置
    if [ 推理目录缺失文件 ]; then
        # 配置推理目录
        setup_inference_models()  ✅ 新增！
    else
        echo "推理模型已配置，无需重复设置"
    fi
fi
```

### 核心改进

**新增检查逻辑** (`auto_install.sh:532-588`):

```bash
# 检查推理目录是否需要配置
NEED_SETUP=0
if [ ! -f "GPT_weights_v4/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt" ]; then
    NEED_SETUP=1
fi
if [ ! -f "SoVITS_weights_v4/s2G2333k.pth" ]; then
    NEED_SETUP=1
fi
if [ ! -f "SoVITS_weights_v4/s2D2333k.pth" ]; then
    NEED_SETUP=1
fi

if [ $NEED_SETUP -eq 1 ]; then
    # 自动配置推理模型
    setup_inference_models()
fi
```

---

## 🎯 现在的行为

### 场景 1: 首次安装

```bash
bash auto_install.sh
# 选择 2: HuggingFace 镜像

# 流程:
1️⃣ 下载预训练模型 → GPT_SoVITS/pretrained_models/
2️⃣ 验证模型文件完整性 ✅
3️⃣ 自动配置推理目录 ✅
   - GPT_weights_v4/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
   - SoVITS_weights_v4/s2G2333k.pth
   - SoVITS_weights_v4/s2D2333k.pth
4️⃣ 启动 Docker 服务 ✅

# 结果:
✅ API 可用，音色克隆功能正常
```

### 场景 2: 预训练模型已存在，但推理目录未配置（本次修复的场景）

```bash
# 假设已有文件:
GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/
  ├── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt ✅
  ├── s2G2333k.pth ✅
  └── s2D2333k.pth ✅

# 但推理目录为空:
GPT_weights_v4/         (空)
SoVITS_weights_v4/      (空)

# 运行脚本:
bash auto_install.sh

# 流程:
1️⃣ 检测到预训练模型已存在 → 跳过下载
2️⃣ 检查推理目录 → 发现缺失文件
3️⃣ 自动配置推理目录 ✅ (新增!)
   - 复制 GPT 模型到推理目录
   - 复制 SoVITS 模型到推理目录
4️⃣ 启动 Docker 服务 ✅

# 结果:
✅ API 可用，音色克隆功能正常
```

### 场景 3: 所有模型都已配置

```bash
# 预训练模型存在:
GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/
  ├── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt ✅
  ├── s2G2333k.pth ✅
  └── s2D2333k.pth ✅

# 推理目录也已配置:
GPT_weights_v4/
  └── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt ✅

SoVITS_weights_v4/
  ├── s2G2333k.pth ✅
  └── s2D2333k.pth ✅

# 运行脚本:
bash auto_install.sh

# 流程:
1️⃣ 检测到预训练模型已存在 → 跳过下载
2️⃣ 检查推理目录 → 所有文件已存在
3️⃣ 输出: "✅ 推理模型已配置，无需重复设置"
4️⃣ 启动 Docker 服务

# 结果:
✅ 无重复操作，直接启动
```

---

## 🔧 手动配置工具

如果只需要配置推理目录（不重新下载模型），可以直接使用：

```bash
bash setup_inference_models.sh
```

这个脚本会:
1. 检查预训练模型是否存在
2. 创建推理目录
3. 复制/链接模型文件
4. 验证配置成功

---

## 📊 修改文件清单

| 文件 | 修改内容 | 行号 |
|------|---------|------|
| `auto_install.sh` | 新增推理目录检查逻辑 | 532-588 |
| `setup_inference_models.sh` | 增强输出信息 | 5-23 |
| `UPDATE_INFERENCE_MODELS.md` | 本文档 | - |

---

## ✅ 验证方法

### 测试场景 1: 清空推理目录后重新配置

```bash
# 1. 删除推理目录
rm -rf GPT_weights_v4 SoVITS_weights_v4

# 2. 运行脚本
bash auto_install.sh

# 3. 检查是否自动配置
ls GPT_weights_v4/
ls SoVITS_weights_v4/

# 预期结果:
# GPT_weights_v4/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt
# SoVITS_weights_v4/s2G2333k.pth
# SoVITS_weights_v4/s2D2333k.pth
```

### 测试场景 2: 验证 API 可用性

```bash
# 启动服务后
docker compose up -d

# 等待几秒
sleep 5

# 测试模型列表接口
curl http://localhost:8000/classic_model_list/v4

# 预期返回:
# {
#   "msg": "获取模型列表成功",
#   "gpt": ["【经典】s1bert25hz-5kh-longer-epoch=12-step=369668"],
#   "sovits": ["【经典】s2G2333k", "【经典】s2D2333k"]
# }
```

### 测试场景 3: 测试音色克隆

打开 `tts_test.html`:
1. 点击"开始克隆音色"
2. 应该能成功获取基础模型列表
3. 不会出现"未找到基础模型"错误

---

## 🎉 改进总结

### 修复前

❌ **问题**: 预训练模型存在但推理目录未配置 → API 不可用

**用户体验**:
```
用户: 我已经下载了模型，为什么还是报错？
系统: ❌ 无 GPT 模型
用户: 😡 模型明明在啊！
```

### 修复后

✅ **解决**: 自动检测并配置推理目录 → API 可用

**用户体验**:
```
用户: 运行 auto_install.sh
系统: ✅ 预训练模型已存在，跳过下载
      🔍 检查推理模型配置...
      🔧 配置推理模型目录...
      ✅ 推理模型配置完成
用户: 😊 太好了，直接能用！
```

---

## 📝 技术细节

### 配置逻辑流程图

```
开始
  ↓
检查预训练模型是否存在？
  ↓
├─ 不存在 → 下载模型 → 验证 → 配置推理目录 → 启动
  ↓
└─ 已存在 → 检查推理目录
               ↓
           ├─ 缺失文件 → 配置推理目录 ✅ (新增)
               ↓
           └─ 已配置 → 跳过
  ↓
启动 Docker 服务
```

### 文件检查列表

脚本会检查以下 3 个文件是否存在于推理目录：

1. `GPT_weights_v4/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt`
2. `SoVITS_weights_v4/s2G2333k.pth`
3. `SoVITS_weights_v4/s2D2333k.pth`

**任何一个缺失** → 触发配置流程

---

## 🔄 迁移指南

### 从旧版本升级

如果你使用的是旧版本的 `auto_install.sh`:

```bash
# 1. 拉取最新代码
git pull

# 2. 重新运行脚本（会自动配置推理目录）
bash auto_install.sh

# 3. 验证
curl http://localhost:8000/classic_model_list/v4
```

### 已手动配置的用户

如果你之前已经手动配置了推理目录，**无需任何操作**。

脚本会检测到文件已存在，不会重复配置。

---

## 🆘 常见问题

### Q: 我应该删除旧的推理目录吗？

A: 不需要。脚本会智能检测，只复制缺失的文件。

### Q: 配置是复制还是符号链接？

A:
- **Windows**: 复制（符号链接需要管理员权限）
- **Linux/Mac**: 可以使用符号链接（节省空间）

`auto_install.sh` 默认使用复制，`setup_inference_models.sh` 会根据系统自动选择。

### Q: 如果预训练模型损坏怎么办？

A: 脚本会在复制前检查源文件是否存在，如果不存在会提示：

```
❌ 预训练模型文件不存在，无法配置
```

此时需要重新下载预训练模型。

### Q: 为什么要有两套目录？

A:
- `GPT_SoVITS/pretrained_models/` → 用于训练新模型
- `GPT_weights_v4/` → 用于推理接口

详见: `MODELS_DIRECTORY_GUIDE.md`

---

## 📚 相关文档

- **模型目录详解**: `MODELS_DIRECTORY_GUIDE.md`
- **模型下载修复**: `MODEL_DOWNLOAD_FIX.md`
- **快速启动**: `QUICK_START.md`

---

**更新时间**: 2025-10-23
**版本**: v1.1
