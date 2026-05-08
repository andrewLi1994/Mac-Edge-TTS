#!/bin/bash
# ============================================================
# Mac-Edge-TTS 远程一键安装脚本
# 用法：curl -fsSL https://raw.githubusercontent.com/andrewLi1994/Mac-Edge-TTS/main/install.sh | bash
# ============================================================
set -e

REPO_BASE="https://raw.githubusercontent.com/andrewLi1994/Mac-Edge-TTS/main"
INSTALL_DIR="$HOME/.local/share/mac-edge-tts"
BIN_DIR="$HOME/.local/bin"

clear
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║     🎧 Mac-Edge-TTS 沉浸式朗读工具 安装器    ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ============================================================
# 1. 检查 Python3（自动安装）
# ============================================================
echo "  🔍 [1/4] 检查系统环境..."

if [[ "$(uname)" != "Darwin" ]]; then
    echo "  ❌ 本工具仅支持 macOS。"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo ""
    echo "  ⚠️  未找到 Python3，正在触发系统自动安装..."
    echo "  📋 请在弹出的窗口中点击【安装】，然后等待完成。"
    echo ""
    xcode-select --install 2>/dev/null || true

    echo "  ⏳ 等待安装完成..."
    for i in $(seq 1 120); do
        if command -v python3 &> /dev/null; then
            echo ""
            echo "       ✅ Python3 安装成功！"
            break
        fi
        sleep 5
    done

    if ! command -v python3 &> /dev/null; then
        echo ""
        echo "  ❌ Python3 安装未完成。请手动安装后重试："
        echo "     xcode-select --install"
        exit 1
    fi
else
    echo "       ✅ Python3 已就绪"
fi

# ============================================================
# 2. 安装 edge-tts 到独立虚拟环境
# ============================================================
echo ""
echo "  📦 [2/4] 安装语音引擎..."

mkdir -p "$INSTALL_DIR"

if [ ! -f "$INSTALL_DIR/venv/bin/python3" ] || ! "$INSTALL_DIR/venv/bin/python3" -c "import langdetect" &>/dev/null; then
    echo "       ⚙️ 正在创建独立运行环境..."
    python3 -m venv "$INSTALL_DIR/venv"
    "$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q 2>/dev/null || true
    echo "       ⚙️ 正在安装 edge-tts 与 langdetect（可能需要 1-2 分钟）..."
    "$INSTALL_DIR/venv/bin/pip" install edge-tts langdetect -q

    if [ ! -f "$INSTALL_DIR/venv/bin/edge-tts" ]; then
        echo ""
        echo "  ❌ edge-tts 安装失败，请检查网络连接后重试。"
        exit 1
    fi
    echo "       ✅ 语音引擎安装成功"
else
    echo "       ✅ 语音引擎已安装"
fi

# ============================================================
# 3. 下载并安装播放器
# ============================================================
echo ""
echo "  🔨 [3/4] 下载播放器..."

mkdir -p "$BIN_DIR"
curl -fsSL "$REPO_BASE/bin/FloatingTTSUI" -o "$BIN_DIR/FloatingTTSUI"
chmod +x "$BIN_DIR/FloatingTTSUI"

# 下载语言检测脚本
curl -fsSL "$REPO_BASE/src/detect_lang.py" -o "$INSTALL_DIR/detect_lang.py"
echo "       ✅ 播放器已安装"

# ============================================================
# 4. 下载并安装 Automator 服务
# ============================================================
echo ""
echo "  🛠️  [4/4] 安装系统服务..."

WORKFLOW_DIR="$HOME/Library/Services/微软朗读.workflow"
mkdir -p "$WORKFLOW_DIR/Contents"

# 下载 wflow 模板并替换占位符为实际路径
curl -fsSL "$REPO_BASE/src/document.wflow" | sed "s|__INSTALL_DIR__|${INSTALL_DIR}|g" > "$WORKFLOW_DIR/Contents/document.wflow"
curl -fsSL "$REPO_BASE/src/Info.plist" -o "$WORKFLOW_DIR/Contents/Info.plist"

# 刷新 macOS 服务缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "       ✅ 系统服务已注册"

# ============================================================
# 完成
# ============================================================
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║            🎉 安装完成！                      ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  📌 最后一步：绑定快捷键"
echo ""
echo "     系统设置 → 键盘 → 键盘快捷键 → 服务"
echo "     在「文本」分类下找到【微软朗读】"
echo "     双击右侧空白，按下快捷键（推荐 Option + S）"
echo ""
echo "  💡 使用：选中任意文字 → 按快捷键 → 开始朗读！"
echo ""
