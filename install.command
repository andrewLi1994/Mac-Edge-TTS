#!/bin/bash
# ============================================================
# Mac-Edge-TTS 一键安装器
# 双击此文件即可安装，无需手动打开终端
# ============================================================
set -e

# 切换到脚本所在目录（双击运行时 cwd 可能不对）
cd "$(dirname "$0")"

# 清除 macOS 隔离标记（从 GitHub 下载的文件会被标记，导致 Gatekeeper 拦截）
xattr -cr . 2>/dev/null || true

clear
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║     🎧 Mac-Edge-TTS 沉浸式朗读工具 安装器    ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

INSTALL_DIR="$HOME/.local/share/mac-edge-tts"
BIN_DIR="$HOME/.local/bin"

# ============================================================
# 1. 检查 Python3（自动安装）
# ============================================================
echo "  🔍 [1/3] 检查系统环境..."

if ! command -v python3 &> /dev/null; then
    echo ""
    echo "  ⚠️  未找到 Python3，正在触发系统自动安装..."
    echo "  📋 请在弹出的窗口中点击【安装】，然后等待完成。"
    echo ""
    
    # 触发 macOS 的命令行工具安装弹窗（包含 Python3）
    xcode-select --install 2>/dev/null || true
    
    # 等待用户完成安装（轮询检测，最长等 10 分钟）
    echo "  ⏳ 等待安装完成..."
    for i in $(seq 1 120); do
        if command -v python3 &> /dev/null; then
            echo ""
            echo "       ✅ Python3 安装成功！"
            break
        fi
        sleep 5
    done
    
    # 最终检查
    if ! command -v python3 &> /dev/null; then
        echo ""
        echo "  ❌ Python3 安装似乎未完成。"
        echo "     请手动安装后重新双击本文件："
        echo "     方法 1：在终端运行 xcode-select --install"
        echo "     方法 2：前往 https://www.python.org/downloads/"
        echo ""
        echo "  按任意键关闭..."
        read -n 1
        exit 1
    fi
else
    echo "       ✅ Python3 已就绪"
fi

# ============================================================
# 2. 安装 edge-tts 到独立虚拟环境（不污染系统）
# ============================================================
echo ""
echo "  📦 [2/3] 安装语音引擎..."

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
        echo ""
        echo "  按任意键关闭..."
        read -n 1
        exit 1
    fi
    echo "       ✅ 语音引擎安装成功"
else
    echo "       ✅ 语音引擎已安装"
fi

# ============================================================
# 3. 安装播放器 + 系统服务
# ============================================================
echo ""
echo "  🛠️  [3/3] 安装播放器与系统服务..."

# 复制预编译的 Universal Binary（无需 Xcode）
mkdir -p "$BIN_DIR"
cp "./bin/FloatingTTSUI" "$BIN_DIR/FloatingTTSUI"
chmod +x "$BIN_DIR/FloatingTTSUI"
xattr -d com.apple.quarantine "$BIN_DIR/FloatingTTSUI" 2>/dev/null || true
echo "       ✅ 播放器已安装"

# 安装 Automator 服务（动态写入 edge-tts 路径）
WORKFLOW_DIR="$HOME/Library/Services/微软朗读.workflow"
mkdir -p "$WORKFLOW_DIR/Contents"

# 将 wflow 模板中的 __INSTALL_DIR__ 替换为实际安装路径
sed "s|__INSTALL_DIR__|${INSTALL_DIR}|g" "./src/document.wflow" > "$WORKFLOW_DIR/Contents/document.wflow"

cp "./src/Info.plist" "$WORKFLOW_DIR/Contents/Info.plist"

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
echo "  按任意键关闭此窗口..."
read -n 1
