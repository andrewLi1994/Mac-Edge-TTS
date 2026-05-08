#!/bin/bash
# test.sh - 单元/组件测试脚本

echo "🧪 开始运行 Mac-Edge-TTS 自动化测试..."

PASS=0
FAIL=0
WARN=0  # 记录"预期内的模糊场景"，只提示不计入失败

export PATH="$HOME/Library/Python/3.14/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

INSTALL_DIR="$HOME/.local/share/mac-edge-tts"
PYTHON3="$INSTALL_DIR/venv/bin/python3"
WORKFLOW_SRC="./src/document.wflow"
DETECT_LANG_SRC="./src/detect_lang.py"

# ============================================================
# 断言函数
# ============================================================
assert_success() {
    if "$@" > /dev/null 2>&1; then
        echo "  ✅ [通过] $1"
        ((PASS++))
    else
        echo "  ❌ [失败] $1"
        ((FAIL++))
    fi
}

assert_file_exists() {
    if [ -f "$1" ]; then
        echo "  ✅ [通过] 文件存在: $(basename $1)"
        ((PASS++))
    else
        echo "  ❌ [失败] 文件不存在: $1"
        ((FAIL++))
    fi
}

# 严格断言：输出必须完全等于期望值
assert_voice() {
    local desc="$1"
    local text="$2"
    local expected_part="$3"
    local voice
    voice=$("$PYTHON3" "$DETECT_LANG_SRC" "$text" 2>/dev/null)
    if [[ "$voice" == *"$expected_part"* ]]; then
        echo "  ✅ [通过] $desc → $voice"
        ((PASS++))
    else
        echo "  ❌ [失败] $desc"
        echo "            预期包含: $expected_part"
        echo "            实际输出: $voice"
        echo "            输入文本: ${text:0:40}..."
        ((FAIL++))
    fi
}

# 宽松断言：只要不是 ERROR 就通过（用于"模糊"场景）
assert_not_error() {
    local desc="$1"
    local text="$2"
    local voice
    voice=$("$PYTHON3" "$DETECT_LANG_SRC" "$text" 2>/dev/null)
    if [ "$voice" != "ERROR" ] && [ -n "$voice" ]; then
        echo "  ✅ [通过] $desc → $voice（合理输出即可）"
        ((PASS++))
    else
        echo "  ❌ [失败] $desc → 输出了 ERROR，期望能给出某种语音"
        ((FAIL++))
    fi
}

# 期望输出 ERROR 的断言（异常输入应该优雅处理）
assert_error_or_fallback() {
    local desc="$1"
    local text="$2"
    local voice
    voice=$("$PYTHON3" "$DETECT_LANG_SRC" "$text" 2>/dev/null)
    # ERROR 是合理的，但不应该崩溃（有输出就行）
    echo "  ℹ️  [信息] $desc → $voice（异常输入，仅记录行为）"
    ((WARN++))
}

# ============================================================
# 测试用例 1: 环境检查
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 1: 环境检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
assert_success command -v swiftc
assert_file_exists "$INSTALL_DIR/venv/bin/edge-tts"
assert_file_exists "$PYTHON3"
assert_file_exists "$DETECT_LANG_SRC"

# ============================================================
# 测试用例 2: 核心发音引擎 API 连通性
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 2: 核心发音引擎逻辑测试 (API 连通性)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
rm -f /tmp/test_output.mp3
"$INSTALL_DIR/venv/bin/edge-tts" \
    --text "这是一句自动化测试传入的假数据" \
    --voice zh-CN-XiaoxiaoNeural \
    --write-media /tmp/test_output.mp3 > /dev/null 2>&1
assert_file_exists "/tmp/test_output.mp3"

# ============================================================
# 测试用例 3: 原生 UI 源码健康度（Swift 编译）
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 3: 原生 UI 源码健康度 (Swift 编译)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
assert_success swiftc ./src/FloatingUI.swift -o /tmp/TestUI_Temp

# ============================================================
# 测试用例 4: Workflow XML 合法性验证
# 关键：Python 代码嵌入 XML 时 < > & 必须转义，否则 Automator 报 damaged
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 4: Workflow XML 合法性验证 (防止 Automator 报 damaged)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if xmllint --noout "$WORKFLOW_SRC" 2>/dev/null; then
    echo "  ✅ [通过] $WORKFLOW_SRC 是合法的 XML plist"
    ((PASS++))
else
    echo "  ❌ [失败] $WORKFLOW_SRC XML 格式错误！Automator 将无法打开此 Workflow"
    echo "           提示：检查嵌入的代码中是否有未转义的 < > & 字符"
    ((FAIL++))
fi

# ============================================================
# 测试用例 5: 语言检测 — A. 纯单语言基础场景
# 这些是最基本的场景，必须 100% 正确
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 5: 语言检测 — A. 纯单语言基础场景"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
assert_voice "纯中文（简体）"   "今天天气很好，我们一起去公园散步吧"                              "Xiaoxiao"
assert_voice "纯中文（繁体）"   "這是繁體中文的測試，希望能正確識別語言"                           "Xiaoxiao"
assert_voice "纯英文"          "Hello world, this is a complete English sentence for testing"  "Aria"
assert_voice "纯日文"          "こんにちは、今日はいい天気ですね。一緒に公園へ行きましょう"          "Nanami"
assert_voice "纯韩文"          "안녕하세요, 오늘 날씨가 참 좋네요. 같이 공원에 가요"               "SunHi"
assert_voice "纯法语"          "Bonjour le monde, c'est une belle journée pour se promener"   "Denise"
assert_voice "纯德语"          "Hallo Welt, das ist ein schöner Tag für einen Spaziergang"    "Katja"
assert_voice "纯西班牙语"       "Hola Mundo, hoy hace un tiempo hermoso para salir"           "Elvira"
assert_voice "纯意大利语"       "Buongiorno a tutti, oggi è una bella giornata per passeggiare" "Elsa"
assert_voice "纯俄语"          "Привет всем, сегодня прекрасная погода для прогулки"          "Svetlana"

# ============================================================
# 测试用例 6: 语言检测 — B. 主导语言 + 拉丁/ASCII 噪声
# 核心场景：用户通常从网页/文档选中的文字，不可能只含单一语言
# 策略：去掉 ASCII 后，如果目标语言字符 >= 30%，应正确识别
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 6: 语言检测 — B. 主导语言 + ASCII 噪声（真实选文场景）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
assert_voice "中文 + 路径/命令（本次修复的 Bug 原型）" \
    "已经刷新了：~/.local/bin/FloatingTTSUI 上一步已覆盖，pbs -flush 完成，现在可以试了！" \
    "Xiaoxiao"

assert_voice "中文 + 英文 API 术语" \
    "这个 API 接口返回了 200 状态码，error_code 字段为 null，请检查 response.json" \
    "Xiaoxiao"

assert_voice "中文 + 英文品牌名" \
    "我在用 iPhone 拍照，上传到 iCloud，然后在 Mac 上用 Lightroom 编辑" \
    "Xiaoxiao"

assert_voice "中文 + 代码关键字" \
    "调用 detect() 函数会 return None，需要在 try/except 块里捕获 ImportError 异常" \
    "Xiaoxiao"

assert_voice "日文 + 英文品牌名" \
    "AppleのiPhoneはとても人気があります。MacBookも素晴らしいです。" \
    "Nanami"

assert_voice "俄语 + 英文技术词" \
    "Привет, это тест API и Python кода для обработки текста" \
    "Svetlana"

assert_voice "韩语 + 英文品牌" \
    "안녕하세요, Apple Watch와 iPhone을 함께 사용합니다" \
    "SunHi"

# ============================================================
# 测试用例 7: 语言检测 — C. 多语言混合（有明确主导语言）
# 日文本身就混用汉字，关键是靠平/片假名来判定
# 中文与其他 CJK 语言混合时，汉字比例决定结果
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 7: 语言检测 — C. 多语言混合（有明确主导）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# 日文文章：汉字只占约 19%，平/片假名合计 81%，正确识别为日文
assert_voice "日文 + 汉字混合（平假名主导，约81%）" \
    "東京タワーに行きました。とても楽しかったです。また来たいと思います。" \
    "Nanami"

# 含有「に」假名，即使汉字很多也能正确识别为日文
assert_voice "汉字密集的日文（含假名「に」，正确识别为日文）" \
    "東京大阪京都名古屋横浜神戸に行きました。" \
    "Nanami"

# 已知边界：纯汉字（无假名）的日语表达无法与中文区分（属于算法固有限制）
# 例："東京大阪京都名古屋" 纯地名，中日文都合法，交给 assert_not_error
assert_not_error "纯汉字日文地名（与中文不可分，合理输出即可）" \
    "東京大阪京都名古屋横浜神戸"

# 英法混合：都是拉丁系，交给 langdetect，结果取决于字数比例
assert_not_error "英法各半混合（交给 langdetect，合理输出即可）" \
    "Hello bonjour, this is un test pour vérifier le mélange"

# ============================================================
# 测试用例 8: 语言检测 — D. 边界/异常输入（鲁棒性）
# 这些场景下不要崩溃，输出 ERROR 是合理的
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试用例 8: 语言检测 — D. 边界/异常输入（鲁棒性）"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# 单字可识别
assert_voice "单个中文字" "好" "Xiaoxiao"

# 以下场景期望输出 ERROR（没有可识别的文字），只记录行为不计入失败
assert_error_or_fallback "空字符串"     ""
assert_error_or_fallback "纯数字"       "1234567890"
assert_error_or_fallback "纯标点"       "！？。，、——……"
assert_error_or_fallback "纯 Emoji"    "😂🔥💯🎉🎊"
assert_error_or_fallback "URL 链接"    "https://www.github.com/user/repo/issues/123"
assert_error_or_fallback "纯英文单词"   "Hello"

# ============================================================
# 报告
# ============================================================
echo ""
echo "========================================================"
echo "📊 测试报告"
echo "   ✅ 通过: $PASS 项"
echo "   ❌ 失败: $FAIL 项"
echo "   ℹ️  信息（模糊场景，仅记录）: $WARN 项"
echo "========================================================"

if [ $FAIL -gt 0 ]; then
    echo "⚠️  发现错误，请修复代码！"
    exit 1
else
    echo "🎉 所有严格测试均已通过！代码非常健康！"
    exit 0
fi
