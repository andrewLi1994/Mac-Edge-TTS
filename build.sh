#!/bin/bash
# ============================================================
# Mac-Edge-TTS 编译构建脚本
# 用于将 Swift 源码编译为可执行二进制文件
# ============================================================

# 设置颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 开始构建 Mac-Edge-TTS 组件...${NC}"

# 1. 环境检查
if ! command -v swiftc &> /dev/null; then
    echo -e "${YELLOW}❌ 错误: 未找到 swiftc 编译器。${NC}"
    echo "请运行 'xcode-select --install' 安装命令行工具。"
    exit 1
fi

# 2. 创建必要的目录
mkdir -p bin
mkdir -p "$HOME/.local/bin"

# 3. 编译源码
echo -e "📦 正在编译 ${BLUE}src/FloatingUI.swift${NC}..."

# 编译为项目内的二进制文件（用于 Git 提交和分发）
if swiftc src/FloatingUI.swift -o bin/FloatingTTSUI; then
    echo -e "${GREEN}✅ 成功编译至 ./bin/FloatingTTSUI${NC}"
else
    echo -e "${YELLOW}❌ 编译失败，请检查源码错误。${NC}"
    exit 1
fi

# 4. 同步到系统路径（用于开发调试立即生效）
cp bin/FloatingTTSUI "$HOME/.local/bin/FloatingTTSUI"
chmod +x "$HOME/.local/bin/FloatingTTSUI"

echo -e "${GREEN}🚀 已同步至 ~/.local/bin/FloatingTTSUI (本地立即生效)${NC}"

# 5. 完成
echo ""
echo -e "${BLUE}✨ 构建流程全部完成！${NC}"
echo "提示：你现在可以运行测试脚本 ./test.sh 验证完整功能。"
