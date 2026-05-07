#!/bin/bash
set -e

echo "🚀 开始安装 Mac-Edge-TTS (Mac 原生沉浸式朗读工具)..."
echo ""

# ============================================================
# 0. 预检查：系统环境
# ============================================================
echo "🔍 [1/4] 检查系统环境..."

# 检查 macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 错误：本工具仅支持 macOS 系统。"
    exit 1
fi

# 检查 Swift 编译器
if ! command -v swiftc &> /dev/null; then
    echo "⚠️  未找到 Swift 编译器 (swiftc)。"
    echo "   正在尝试安装 Xcode 命令行工具（可能需要几分钟）..."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo "❌ 请在弹出的安装窗口中点击【安装】，完成后重新运行本脚本："
    echo "   ./install.sh"
    exit 1
fi
echo "   ✅ Swift 编译器已就绪"

# 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：未找到 Python3。请先安装 Python3。"
    exit 1
fi
echo "   ✅ Python3 已就绪"

# ============================================================
# 1. 安装 edge-tts
# ============================================================
echo ""
echo "📦 [2/4] 检查语音引擎 (edge-tts)..."

# 检测 Python 用户 bin 路径（关键：不再硬编码版本号）
PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_USER_BIN="$HOME/Library/Python/${PY_VERSION}/bin"
LOCAL_BIN="$HOME/.local/bin"

# 确保 PATH 包含这些路径（当前 shell 生效）
export PATH="$PY_USER_BIN:$LOCAL_BIN:/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v edge-tts &> /dev/null; then
    echo "   ⚙️ 正在安装 edge-tts..."
    if python3 -m pip install edge-tts --user 2>/dev/null; then
        true
    elif python3 -m pip install edge-tts --user --break-system-packages 2>/dev/null; then
        true
    else
        echo "❌ edge-tts 安装失败。请手动运行："
        echo "   pip3 install edge-tts"
        exit 1
    fi

    # 验证安装
    if command -v edge-tts &> /dev/null; then
        echo "   ✅ edge-tts 安装成功"
    else
        echo "   ⚠️  edge-tts 已安装，但需要将以下路径加入 PATH："
        echo "   请在终端执行：echo 'export PATH=\"${PY_USER_BIN}:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
        echo "   然后重新运行 ./install.sh"
        exit 1
    fi
else
    echo "   ✅ edge-tts 已安装"
fi

# ============================================================
# 2. 编译 Swift UI 播放器
# ============================================================
echo ""
echo "🔨 [3/4] 编译原生悬浮 UI..."
mkdir -p "$LOCAL_BIN"
swiftc -O "./src/FloatingUI.swift" -o "$LOCAL_BIN/FloatingTTSUI"
echo "   ✅ 编译成功"

# ============================================================
# 3. 安装 Automator 服务（动态写入 Python 路径）
# ============================================================
echo ""
echo "🛠️  [4/4] 安装 macOS 快捷操作服务..."

WORKFLOW_DIR="$HOME/Library/Services/微软朗读.workflow"
mkdir -p "$WORKFLOW_DIR/Contents"

# 动态替换 wflow 中的 Python 版本路径
# 将模板中的 __PY_USER_BIN__ 占位符替换为实际路径
if grep -q "__PY_USER_BIN__" "./src/document.wflow"; then
    # 新模板模式：使用占位符
    sed "s|__PY_USER_BIN__|${PY_USER_BIN}|g" "./src/document.wflow" > "$WORKFLOW_DIR/Contents/document.wflow"
else
    # 兼容旧文件：直接替换 Python/3.xx/bin 为当前版本
    sed -E "s|Library/Python/[0-9]+\.[0-9]+/bin|Library/Python/${PY_VERSION}/bin|g" "./src/document.wflow" > "$WORKFLOW_DIR/Contents/document.wflow"
fi

cp "./src/Info.plist" "$WORKFLOW_DIR/Contents/Info.plist"

# 刷新 macOS 服务缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# ============================================================
# 完成
# ============================================================
echo ""
echo "🎉 安装完成！"
echo "================================================="
echo ""
echo "  📌 下一步：绑定快捷键"
echo ""
echo "  系统设置 → 键盘 → 键盘快捷键 → 服务"
echo "  在「文本」分类下找到【微软朗读】"
echo "  双击右侧空白处，按下快捷键（推荐 Option + S）"
echo ""
echo "  💡 使用方法：选中任意文字 → 按快捷键 → 开始朗读！"
echo ""
echo "================================================="
