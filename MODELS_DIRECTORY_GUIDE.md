# GPT-SoVITS 模型目录完整指南

## 🤔 问题：为什么有多个模型目录？

很多用户会困惑：我已经下载了模型到 `GPT_SoVITS/pretrained_models/`，为什么还提示找不到模型？

**核心原因**：GPT-SoVITS 项目有**两套独立的模型系统**，用于不同的场景。

---

## 📂 模型目录体系详解

### 目录 1: `GPT_SoVITS/pretrained_models/`
**用途**: 训练新模型的基础

```
GPT_SoVITS/pretrained_models/
├── gsv-v2final-pretrained/
│   ├── s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt  (GPT 基础模型)
│   ├── s2G2333k.pth  (SoVITS Generator)
│   └── s2D2333k.pth  (SoVITS Discriminator)
├── chinese-roberta-wwm-ext-large/  (BERT 模型)
└── chinese-hubert-base/  (HuBERT 模型)
```

**使用场景**:
- ✅ 使用 `webui.py` 训练自己的模型
- ✅ 微调（Fine-tune）特定音色
- ❌ **不能**直接用于推理接口

**相关文件**:
- `webui.py` - 训练界面
- `GPT_SoVITS/TTS_infer_pack/` - 训练代码

---

### 目录 2: `GPT_weights_v4/` 和 `SoVITS_weights_v4/`
**用途**: 推理接口使用的模型（音色克隆）

```
GPT_weights_v4/
  └── *.ckpt  (任意 GPT 模型)

SoVITS_weights_v4/
  └── *.pth  (任意 SoVITS 模型)
```

**使用场景**:
- ✅ `/infer_classic` 接口
- ✅ `/v1/audio/speech` 接口
- ✅ `tts_test.html` 快速音色克隆
- ✅ `gsvi.py` 推理服务

**代码位置**: `tools/my_infer.py:426-464`

```python
def get_classic_model_list(version):
    # 查找经典基础模型
    classic_gpt = glob(f"GPT_weights_{version}/*.ckpt", recursive=True)
    classic_sovits = glob(f"SoVITS_weights_{version}/*.pth", recursive=True)
```

---

### 目录 3: `models/v4/`
**用途**: GSVI 系统管理的完整模型包

```
models/v4/
├── 模型名称1/
│   ├── model.ckpt  (GPT 模型)
│   ├── model.pth  (SoVITS 模型)
│   └── reference_audios/
│       └── 中文/
│           └── emotions/
│               ├── 【开心】今天天气真好.wav
│               └── 【悲伤】我很难过.wav
└── 模型名称2/
    └── ...
```

**使用场景**:
- ✅ `/infer_single` 接口（情感合成）
- ✅ `/infer_multi` 接口（多人对话）
- ✅ 带情感标签的预设音色

**代码位置**: `tools/my_infer.py:217-257`

---

## 🔄 模型文件流转关系

```
1️⃣ 下载阶段
   HuggingFace/ModelScope
          ↓
   GPT_SoVITS/pretrained_models/
   (训练用基础模型)

2️⃣ 配置阶段 (auto_install.sh 自动完成)
   GPT_SoVITS/pretrained_models/
          ↓ 复制/链接
   GPT_weights_v4/
   SoVITS_weights_v4/
   (推理用模型)

3️⃣ 训练阶段 (可选)
   GPT_SoVITS/pretrained_models/
          ↓ webui.py 训练
   models/v4/your_model/
   (用户训练的模型)

4️⃣ 推理阶段
   GPT_weights_v4/ + SoVITS_weights_v4/
          ↓ gsvi.py
   音色克隆服务 (/infer_classic)
```

---

## ⚠️ 常见错误和解决方案

### 错误 1: 接口返回"无 GPT 模型"或"无 SoVITS 模型"

**原因**: 推理目录为空

**检查**:
```bash
ls GPT_weights_v4/
ls SoVITS_weights_v4/
```

**解决**:
```bash
# 方法 1: 运行配置脚本（推荐）
bash setup_inference_models.sh

# 方法 2: 手动复制
mkdir -p GPT_weights_v4 SoVITS_weights_v4

cp GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt GPT_weights_v4/

cp GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s2G2333k.pth SoVITS_weights_v4/

cp GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/s2D2333k.pth SoVITS_weights_v4/
```

---

### 错误 2: `tts_test.html` 显示"未找到基础模型"

**原因**: 调用 `/classic_model_list/v4` 接口时返回空列表

**代码分析**:
```javascript
// tts_test.html:883-905
const modelsResponse = await fetch(`${apiBase}/classic_model_list/v4`);
const modelsData = await modelsResponse.json();

// 返回: { gpt: [], sovits: [] }  ← 空列表！
let gptModel = modelsData.gpt[0];  // undefined
```

**解决**: 确保 `GPT_weights_v4/` 和 `SoVITS_weights_v4/` 有模型文件

---

### 错误 3: 模型已下载但推理失败

**检查清单**:
```bash
# 1. 预训练模型是否存在？
ls -lh GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/
# 应该看到: s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt, s2G2333k.pth, s2D2333k.pth

# 2. 推理模型是否配置？
ls -lh GPT_weights_v4/
ls -lh SoVITS_weights_v4/
# 应该看到相同的文件或符号链接

# 3. API 接口是否能获取模型？
curl http://localhost:8000/classic_model_list/v4
# 应该返回: {"gpt": ["【经典】s1bert25hz-5kh-longer-epoch=12-step=369668"], "sovits": [...]}
```

---

## 🎯 快速配置指南

### 完整安装（推荐）

```bash
# 1. 下载预训练模型
bash auto_install.sh
# 选择 2: HuggingFace 镜像

# auto_install.sh 会自动：
# ✅ 下载到 GPT_SoVITS/pretrained_models/
# ✅ 配置到 GPT_weights_v4/ 和 SoVITS_weights_v4/
# ✅ 验证模型完整性
```

### 已下载模型，仅配置推理

```bash
# 运行配置脚本
bash setup_inference_models.sh

# 验证
curl http://localhost:8000/classic_model_list/v4
```

### Docker 环境

```bash
# 1. 启动容器
docker compose up -d

# 2. 进入容器
docker compose exec GPT-SoVITS-CU128 bash

# 3. 配置推理模型
bash setup_inference_models.sh

# 4. 退出容器
exit

# 5. 重启服务
docker compose restart
```

---

## 📊 接口与模型目录对应关系

| 接口 | 使用的模型目录 | 备注 |
|------|---------------|------|
| `/classic_model_list/v4` | `GPT_weights_v4/`<br>`SoVITS_weights_v4/`<br>`models/v4/` | 返回所有可用模型 |
| `/infer_classic` | `GPT_weights_v4/`<br>`SoVITS_weights_v4/` | 经典模式，需要上传参考音频 |
| `/infer_single` | `models/v4/` | 情感模式，使用预设参考音频 |
| `/infer_multi` | `models/v4/` | 多人对话 |
| `/v1/audio/speech` | `models/v4/` | OpenAI 风格接口 |

---

## 🔧 高级：自定义模型位置

如果你想修改模型查找路径，编辑 `tools/my_infer.py`:

```python
# 第 436-437 行
classic_gpt = glob(f"GPT_weights_{version}/*.ckpt", recursive=True)
classic_sovits = glob(f"SoVITS_weights_{version}/*.pth", recursive=True)

# 可以改为：
classic_gpt = glob(f"你的自定义路径/*.ckpt", recursive=True)
classic_sovits = glob(f"你的自定义路径/*.pth", recursive=True)
```

**不推荐修改**，除非你清楚自己在做什么。

---

## 📝 总结

### 核心要点

1. **预训练模型** (`GPT_SoVITS/pretrained_models/`)
   - 用于训练
   - 从 HuggingFace 下载

2. **推理模型** (`GPT_weights_v4/` 和 `SoVITS_weights_v4/`)
   - 用于音色克隆
   - 从预训练模型复制/链接

3. **用户模型** (`models/v4/`)
   - 用户训练或安装的模型
   - 带有情感标签和参考音频

### 记住

✅ `auto_install.sh` 会自动配置推理模型
✅ `setup_inference_models.sh` 可单独配置
✅ 验证命令: `curl http://localhost:8000/classic_model_list/v4`

---

## 🆘 故障排除

### 问题诊断脚本

创建 `diagnose_models.sh`:
```bash
#!/bin/bash
echo "🔍 GPT-SoVITS 模型诊断"
echo ""

echo "1️⃣ 预训练模型检查:"
ls -lh GPT_SoVITS/pretrained_models/gsv-v2final-pretrained/ 2>/dev/null || echo "❌ 目录不存在"

echo ""
echo "2️⃣ 推理模型检查:"
echo "GPT 模型:"
ls -lh GPT_weights_v4/ 2>/dev/null || echo "❌ 目录不存在"
echo "SoVITS 模型:"
ls -lh SoVITS_weights_v4/ 2>/dev/null || echo "❌ 目录不存在"

echo ""
echo "3️⃣ API 接口检查:"
curl -s http://localhost:8000/classic_model_list/v4 | jq . 2>/dev/null || echo "❌ API 不可用或 jq 未安装"
```

运行:
```bash
bash diagnose_models.sh
```

---

**祝你使用愉快！如有问题，请查看日志或提交 Issue。** 🎉
