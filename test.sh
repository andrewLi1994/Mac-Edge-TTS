#!/bin/bash
# test.sh - 单元/组件测试脚本

echo "🧪 开始运行 LocalTTS 自动化测试..."

PASS=0
FAIL=0

# 修复测试环境：确保脚本能找到通过 pip 安装的用户级程序
export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# 定义一个测试验证函数 (断言函数)
assert_success() {
    # 执行传进来的命令，把输出重定向到 /dev/null 保持干净
    if "$@" > /dev/null 2>&1; then
        echo "✅ [通过] $1"
        ((PASS++))
    else
        echo "❌ [失败] $1"
        ((FAIL++))
    fi
}

assert_file_exists() {
    if [ -f "$1" ]; then
        echo "✅ [通过] 成功生成文件: $1"
        ((PASS++))
    else
        echo "❌ [失败] 预期文件未生成: $1"
        ((FAIL++))
    fi
}

echo "----------------------------------------"
echo "测试环境检查..."
assert_success command -v edge-tts
assert_success command -v swiftc

echo "----------------------------------------"
echo "执行测试用例 1: 核心发音引擎逻辑测试 (API 连通性)"
rm -f /tmp/test_output.mp3
# 输入假数据给引擎，测试它是否崩溃，以及是否真的输出了媒体文件
edge-tts --text "这是一句自动化测试传入的假数据" --voice zh-CN-XiaoxiaoNeural --write-media /tmp/test_output.mp3 > /dev/null 2>&1
assert_file_exists "/tmp/test_output.mp3"

echo "----------------------------------------"
echo "执行测试用例 2: 原生 UI 源码健康度测试 (Swift 编译)"
# 尝试调用编译器严格检查你的 Swift 代码是否有语法错误
assert_success swiftc ./src/FloatingUI.swift -o /tmp/TestUI_Temp

echo "----------------------------------------"
echo "📊 测试报告: 成功 $PASS 项，失败 $FAIL 项"

if [ $FAIL -gt 0 ]; then
    echo "⚠️ 发现错误，请修复代码！"
    exit 1
else
    echo "🎉 所有测试均已通过！代码非常健康！"
    exit 0
fi
