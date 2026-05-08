# Mac-Edge-TTS (Mac 沉浸式全局朗读工具)

这是一个极客风格的 macOS 全局"划词朗读"小工具。它通过"系统服务 + Swift 极简悬浮窗 + Python Edge-TTS 引擎"组合而成，致力于提供**零内存占用、随叫随到、用完即走**的完美阅读体验。

## ✨ 特性
- **全局生效**：在任何 App（Safari、微信、备忘录、代码编辑器）中选中文字，按下快捷键即可发音。
- **顶级音质**：底层接入微软 Azure 级别的 Edge-TTS（支持自动多语言识别与匹配）。
- **极简播放器**：朗读时自动在右下角弹出带毛玻璃效果的原生控制器，播报结束**瞬间自我销毁**。
- **原生控制**：支持拖动进度条，支持左侧一键倒退 5 秒，右侧一键切换 2x 倍速。
- **智能多语言识别**：自动检测选中文字的语言，并自动切换对应的音效（支持中、英、日、韩、法、德等十几种语言）。
- **RSVP 沉浸式字幕**：引入快速串行视觉呈现 (RSVP) 模式，利用苹果原生 NLP 引擎实现智能分词，让文字在屏幕中心静止闪现，彻底消除扫视带来的眼球疲劳。
- **零负担**：没有后台常驻进程，不占系统内存。

## 📦 一键安装

打开终端 (Terminal)，粘贴以下命令并回车：

```bash
curl -fsSL https://raw.githubusercontent.com/andrewLi1994/Mac-Edge-TTS/main/install.sh | bash
```

安装器会自动完成所有步骤：检测环境 → 安装语音引擎 → 下载播放器 → 注册系统服务。

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
- `src/detect_lang.py`：语言检测模块，基于 Unicode 字符集优先判断 + `langdetect` 兜底，确保中英混排等复杂文本能准确匹配对应语音；安装时自动部署到 `~/.local/share/mac-edge-tts/`。
- 语音引擎 `edge-tts` 与 `langdetect` 均安装在独立虚拟环境中，不污染系统 Python。

## 🗑️ 卸载
```bash
rm -rf ~/.local/share/mac-edge-tts ~/.local/bin/FloatingTTSUI ~/Library/Services/微软朗读.workflow
```
