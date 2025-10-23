#!/bin/bash

# 简化的系统检测测试脚本
# 用于快速诊断 start_docker.sh 的系统检测问题

echo "======================================"
echo "  系统检测测试"
echo "======================================"
echo ""

# 测试 1: 检查 apt-get 命令
echo "1. 测试 apt-get 命令"
echo "-----------------------------------"
if command -v apt-get &> /dev/null; then
    echo "✓ apt-get 命令存在"
    echo "  路径: $(which apt-get)"
else
    echo "✗ apt-get 命令不存在"
fi
echo ""

# 测试 2: 检查 apt 命令
echo "2. 测试 apt 命令"
echo "-----------------------------------"
if command -v apt &> /dev/null; then
    echo "✓ apt 命令存在"
    echo "  路径: $(which apt)"
else
    echo "✗ apt 命令不存在"
fi
echo ""

# 测试 3: 组合检测
echo "3. 组合检测（脚本中使用的逻辑）"
echo "-----------------------------------"
if ! command -v apt-get &> /dev/null && ! command -v apt &> /dev/null; then
    echo "✗ 检测失败: apt-get 和 apt 都不存在"
    echo "  这就是您遇到的错误！"
else
    echo "✓ 检测成功: 至少有一个包管理器可用"
fi
echo ""

# 测试 4: 读取系统信息
echo "4. 读取 /etc/os-release"
echo "-----------------------------------"
if [ -f /etc/os-release ]; then
    echo "✓ 文件存在"
    . /etc/os-release
    echo "  ID: $ID"
    echo "  NAME: $NAME"
    echo "  VERSION: $VERSION"
else
    echo "✗ 文件不存在"
fi
echo ""

# 测试 5: 环境变量
echo "5. 环境检查"
echo "-----------------------------------"
echo "  SHELL: $SHELL"
echo "  PATH: $PATH"
echo "  USER: $USER"
echo "  HOME: $HOME"
echo ""

# 测试 6: 实际测试 apt-get
echo "6. 实际执行 apt-get 命令"
echo "-----------------------------------"
if apt-get --version &> /dev/null; then
    echo "✓ apt-get 可以正常执行"
    apt-get --version | head -n 1
else
    echo "✗ apt-get 无法执行"
fi
echo ""

echo "======================================"
echo "  测试完成"
echo "======================================"
echo ""

# 给出建议
echo "💡 如果所有测试都通过，但 start_docker.sh 仍然报错，"
echo "   请尝试以下方法："
echo ""
echo "1. 直接运行（不使用 sh 命令）:"
echo "   chmod +x start_docker.sh"
echo "   ./start_docker.sh"
echo ""
echo "2. 使用 bash 明确指定解释器:"
echo "   bash start_docker.sh"
echo ""
echo "3. 检查脚本的行尾符（Windows vs Unix）:"
echo "   dos2unix start_docker.sh"
echo ""
