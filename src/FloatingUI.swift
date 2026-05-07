import Cocoa
import AVKit
import AVFoundation
import NaturalLanguage

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var player: AVPlayer!
    var subtitleLabel: NSTextField!
    var subtitles: [Subtitle] = []
    
    struct Subtitle {
        let start: TimeInterval
        let end: TimeInterval
        let text: String
        let chunks: [String]
    }
    
    func parseTime(_ timeStr: String) -> TimeInterval {
        let parts = timeStr.components(separatedBy: ":")
        guard parts.count == 3 else { return 0 }
        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let secParts = parts[2].components(separatedBy: ",")
        let seconds = Double(secParts[0]) ?? 0
        let milliseconds = secParts.count > 1 ? (Double(secParts[1]) ?? 0) / 1000.0 : 0
        return hours * 3600 + minutes * 60 + seconds + milliseconds
    }
    
    func parseSRT(content: String) -> [Subtitle] {
        let lines = content.components(separatedBy: .newlines)
        var subs = [Subtitle]()
        var currentStart: TimeInterval = 0
        var currentEnd: TimeInterval = 0
        var currentText = ""
        var isReadingText = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-->") {
                let parts = trimmed.components(separatedBy: "-->")
                if parts.count == 2 {
                    currentStart = parseTime(parts[0].trimmingCharacters(in: .whitespaces))
                    currentEnd = parseTime(parts[1].trimmingCharacters(in: .whitespaces))
                    isReadingText = true
                    currentText = ""
                }
            } else if trimmed.isEmpty {
                if isReadingText {
                    subs.append(Subtitle(start: currentStart, end: currentEnd, text: currentText, chunks: chunkText(currentText)))
                    isReadingText = false
                }
            } else if isReadingText {
                if !currentText.isEmpty { currentText += " " }
                currentText += trimmed
            }
        }
        if isReadingText {
            subs.append(Subtitle(start: currentStart, end: currentEnd, text: currentText, chunks: chunkText(currentText)))
        }
        return subs
    }
    
    func chunkText(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens = [Range<String.Index>]()
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            tokens.append(tokenRange)
            return true
        }
        var chunks = [String]()
        for i in 0..<tokens.count {
            let start = i == 0 ? text.startIndex : tokens[i].lowerBound
            let end = i == tokens.count - 1 ? text.endIndex : tokens[i+1].lowerBound
            chunks.append(String(text[start..<end]))
        }
        return chunks.isEmpty ? [text] : chunks
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let args = CommandLine.arguments
        guard args.count > 1 else { NSApp.terminate(nil); return }
        let filePath = args[1]
        let url = URL(fileURLWithPath: filePath)
        
        var subtitlePath: String? = nil
        if args.count > 2 {
            subtitlePath = args[2]
        }
        if let subtitlePath = subtitlePath, let content = try? String(contentsOfFile: subtitlePath, encoding: .utf8) {
            self.subtitles = parseSRT(content: content)
        }
        
        player = AVPlayer(url: url)
        
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 420
        let windowHeight: CGFloat = 110
        let controlsHeight: CGFloat = 48
        
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), 
                          styleMask: [.titled, .closable, .fullSizeContentView], 
                          backing: .buffered, 
                          defer: false)
        window.setFrameTopLeftPoint(NSPoint(x: screenRect.maxX - windowWidth - 20, y: screenRect.maxY - 40))
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0.1, alpha: 0.9)
        window.isMovableByWindowBackground = true
        
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        if let closeBtn = window.standardWindowButton(.closeButton) {
            closeBtn.setFrameOrigin(NSPoint(x: 10, y: (controlsHeight - closeBtn.frame.height) / 2))
        }
        
        // --- 倒退 5 秒按钮 ---
        let rewindBtn = NSButton(frame: NSRect(x: 35, y: (controlsHeight - 24) / 2, width: 30, height: 24))
        rewindBtn.bezelStyle = .inline
        rewindBtn.isBordered = false
        rewindBtn.imagePosition = .imageOnly
        if let icon = NSImage(systemSymbolName: "gobackward.5", accessibilityDescription: "Rewind 5s") {
            icon.isTemplate = true
            rewindBtn.image = icon
        } else {
            rewindBtn.title = "-5s"
        }
        rewindBtn.contentTintColor = .white
        rewindBtn.target = self
        rewindBtn.action = #selector(rewind5s)
        window.contentView?.addSubview(rewindBtn)
        
        // --- 播放器主体 ---
        let playerWidth: CGFloat = 300
        let playerView = AVPlayerView(frame: NSRect(x: 70, y: 0, width: playerWidth, height: controlsHeight))
        playerView.player = player
        playerView.showsFullScreenToggleButton = false
        playerView.controlsStyle = .inline
        window.contentView?.addSubview(playerView)
        
        // --- 倍速按钮 ---
        let speedBtn = NSButton(frame: NSRect(x: 70 + playerWidth + 5, y: (controlsHeight - 24) / 2, width: 40, height: 24))
        speedBtn.setButtonType(.momentaryPushIn)
        speedBtn.bezelStyle = .recessed
        speedBtn.isBordered = false
        speedBtn.title = "1x"
        speedBtn.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        speedBtn.contentTintColor = .white
        speedBtn.target = self
        speedBtn.action = #selector(toggleSpeed(_:))
        window.contentView?.addSubview(speedBtn)
        
        // --- 字幕显示区域 ---
        // 恢复正常宽度和居中对齐，使用大字号 RSVP 模式
        subtitleLabel = NSTextField(frame: NSRect(x: 15, y: controlsHeight, width: windowWidth - 30, height: windowHeight - controlsHeight - 10))
        subtitleLabel.isEditable = false
        subtitleLabel.isBordered = false
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.textColor = NSColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        subtitleLabel.alignment = .center // 居中显示
        subtitleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold) // 大字号
        subtitleLabel.stringValue = "..."
        subtitleLabel.cell?.wraps = false
        window.contentView?.addSubview(subtitleLabel)
        
        window.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            NSApp.terminate(nil)
        }
        
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.02, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            let current = time.seconds
            if let active = self.subtitles.first(where: { $0.start <= current && $0.end >= current }) {
                let duration = active.end - active.start
                let elapsed = current - active.start
                let progress = max(0.0, min(1.0, elapsed / duration))
                
                let text = active.text
                let totalChars = text.count
                let targetCharIndex = Int(progress * Double(totalChars))
                
                var currentCharCount = 0
                var currentChunk = active.chunks.first ?? ""
                for chunk in active.chunks {
                    currentCharCount += chunk.count
                    if currentCharCount > targetCharIndex {
                        currentChunk = chunk
                        break
                    }
                }
                
                self.subtitleLabel.stringValue = currentChunk
            }
        }
        
        player.play()
    }
    
    @objc func rewind5s() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTimeMake(value: 5, timescale: 1))
        player.seek(to: newTime)
    }
    
    @objc func toggleSpeed(_ sender: NSButton) {
        var currentDefault: Float = 1.0
        if #available(macOS 13.0, *) {
            currentDefault = player.defaultRate
        } else {
            currentDefault = player.rate
        }
        let newRate: Float = (currentDefault > 1.0) ? 1.0 : 2.0
        if #available(macOS 13.0, *) {
            player.defaultRate = newRate
        }
        player.rate = newRate
        sender.title = (newRate > 1.0) ? "2x" : "1x"
    }
}

let app = NSApplication.shared
let myDelegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = myDelegate
app.run()
