# Mac-Edge-TTS (Mac 沉浸式全局朗读工具)

这是一个极客风格的 macOS 全局"划词朗读"小工具。它通过"系统服务 + Swift 极简悬浮窗 + Python Edge-TTS 引擎"组合而成，致力于提供**零内存占用、随叫随到、用完即走**的完美阅读体验。

## ✨ 特性
- **全局生效**：在任何 App（Safari、微信、备忘录、代码编辑器）中选中文字，按下快捷键即可发音。
- **顶级音质**：底层接入微软 Azure 级别的 Edge-TTS（默认使用逼真的"晓晓"女声）。
- **极简播放器**：朗读时自动在右下角弹出带毛玻璃效果的原生控制器，播报结束**瞬间自我销毁**。
- **原生控制**：支持拖动进度条，支持左侧一键倒退 5 秒，右侧一键切换 2x 倍速。
- **RSVP 沉浸式字幕**：引入快速串行视觉呈现 (RSVP) 模式，利用苹果原生 NLP 引擎实现智能分词，让文字在屏幕中心静止闪现，彻底消除扫视带来的眼球疲劳。
- **零负担**：没有后台常驻进程，不占系统内存。

## 📦 安装（双击即可）

> **前置要求**：仅需 macOS 系统。首次安装时如系统缺少组件，安装器会自动弹窗引导安装。

### 方式 A：终端一行命令（最简单 ✅）
打开终端 (Terminal)，粘贴以下命令并回车：
```bash
cd ~/Downloads/Mac-Edge-TTS-main && xattr -cr . && ./install.command
```

### 方式 B：Finder 操作
1. 下载并解压本项目
2. 双击 **`install.command`**
3. 如果弹出安全提示，打开 **系统设置 → 隐私与安全性**，往下滚点击 **"仍然打开"**
4. 等待安装完成

## ⚙️ 绑定快捷键（必需）
安装成功后，macOS 已经注册了这个服务，你需要给它绑定一个顺手的快捷键：
1. 打开 Mac 的 **系统设置 (System Settings)**。
2. 进入 **键盘 (Keyboard)** → **键盘快捷键 (Keyboard Shortcuts)**。
3. 选择左侧的 **服务 (Services)**。
4. 展开右侧的 **文本 (Text)** 类别，找到 **微软朗读**。
5. 双击右侧空白处，按下你喜欢的快捷键（推荐 `Option + S`）。

## 🎯 使用方法
在任何应用中选中一段文字 → 按下你设定的快捷键 → 开始朗读！

## 🔧 技术说明
- `bin/FloatingTTSUI`：预编译的 Universal Binary（Intel + Apple Silicon），无需 Xcode。
- `src/FloatingUI.swift`：基于 AVFoundation、AVKit 和 NaturalLanguage 编写的原生播放器源码。
- `src/document.wflow`：macOS Automator 服务模板，安装时自动配置路径。
- 语音引擎 `edge-tts` 安装在独立虚拟环境中，不污染系统 Python。
