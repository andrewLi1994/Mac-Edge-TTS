#!/bin/bash
set -e

echo "🚀 开始安装 Mac 原生沉浸式朗读工具 (LocalTTS-Project)..."

# 1. 检查并安装 edge-tts
echo "📦 检查底层语音引擎 (edge-tts)..."
if ! command -v edge-tts &> /dev/null; then
    echo "⚙️ 未找到 edge-tts，正在通过 pip 安装..."
    python3 -m pip install edge-tts --break-system-packages --user
else
    echo "✅ edge-tts 已安装！"
fi

# 2. 编译 Swift UI 播放器
echo "🔨 正在编译原生悬浮 UI..."
mkdir -p "$HOME/.local/bin"
swiftc -O "./src/FloatingUI.swift" -o "$HOME/.local/bin/FloatingTTSUI"
echo "✅ UI 编译成功！"

# 3. 安装 Automator 快捷操作
echo "🛠️ 正在安装 macOS 快捷操作服务..."
WORKFLOW_DIR="$HOME/Library/Services/微软朗读.workflow"
mkdir -p "$WORKFLOW_DIR/Contents"

cp "./src/Info.plist" "$WORKFLOW_DIR/Contents/Info.plist"
cp "./src/document.wflow" "$WORKFLOW_DIR/Contents/document.wflow"

# 刷新 macOS 服务缓存
/System/Library/CoreServices/pbs -flush

echo "🎉 安装完成！"
echo "================================================="
echo "请打开 Mac 的 [系统设置] -> [键盘] -> [键盘快捷键] -> [服务]"
echo "在 [文本] 类别下找到【微软朗读】并绑定一个快捷键 (如 Option + S) 即可使用！"
echo "================================================="
