#!/bin/bash
# test.sh - 单元/组件测试脚本

echo "🧪 开始运行 Mac-Edge-TTS 自动化测试..."

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
echo "执行测试用例 3: 多语言自动识别逻辑测试"

test_lang_detection() {
    local text="$1"
    local expected_voice_part="$2"
    
    # 模拟 document.wflow 中的 Python 识别逻辑
    local detected_voice=$(python3 -c "
import sys
try:
    from langdetect import detect, DetectorFactory
    DetectorFactory.seed = 0
    text = sys.argv[1]
    lang = detect(text)
    mapping = {
        'zh-cn': 'zh-CN-XiaoxiaoNeural', 'en': 'en-US-AriaNeural',
        'ja': 'ja-JP-NanamiNeural', 'ko': 'ko-KR-SunHiNeural',
        'fr': 'fr-FR-DeniseNeural', 'de': 'de-DE-KatjaNeural',
        'es': 'es-ES-ElviraNeural', 'it': 'it-IT-ElsaNeural',
        'ru': 'ru-RU-SvetlanaNeural'
    }
    if lang.startswith('zh'): print(mapping.get('zh-cn'))
    else: print(mapping.get(lang, 'ERROR'))
except ImportError:
    print('SKIP_NO_LIB')
except:
    print('ERROR')
" "$text")

    if [ "$detected_voice" = "SKIP_NO_LIB" ]; then
        echo "⚠️  [跳过] 未检测到 langdetect 库，请先运行安装脚本"
        return 0
    fi

    if [[ "$detected_voice" == *"$expected_voice_part"* ]]; then
        echo "✅ [通过] 识别: \"${text:0:15}...\" -> $detected_voice"
        ((PASS++))
    else
        echo "❌ [失败] 识别错误: \"${text:0:15}...\" 预期包含 $expected_voice_part，实际得到 $detected_voice"
        ((FAIL++))
    fi
}

test_lang_detection "你好，世界" "Xiaoxiao"
test_lang_detection "Hello world, this is a test" "Aria"
test_lang_detection "こんにちは世界、これはテストです" "Nanami"
test_lang_detection "Bonjour le monde, c'est un test" "Denise"
test_lang_detection "Hallo Welt, das ist ein Test" "Katja"
test_lang_detection "Hola Mundo, esto es una prueba" "Elvira"
test_lang_detection "Buongiorno a tutti, questa è una prova" "Elsa"
test_lang_detection "Привет всем, это проверка системы" "Svetlana"

echo "----------------------------------------"
echo "📊 测试报告: 成功 $PASS 项，失败 $FAIL 项"

if [ $FAIL -gt 0 ]; then
    echo "⚠️ 发现错误，请修复代码！"
    exit 1
else
    echo "🎉 所有测试均已通过！代码非常健康！"
    exit 0
fi
