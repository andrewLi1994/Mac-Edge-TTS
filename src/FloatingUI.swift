import Cocoa
import AVKit
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var player: AVPlayer!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let args = CommandLine.arguments
        guard args.count > 1 else { NSApp.terminate(nil); return }
        let filePath = args[1]
        let url = URL(fileURLWithPath: filePath)
        
        player = AVPlayer(url: url)
        
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 380
        let windowHeight: CGFloat = 48
        
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
            closeBtn.setFrameOrigin(NSPoint(x: 10, y: (windowHeight - closeBtn.frame.height) / 2))
        }
        
        // --- 倒退 5 秒按钮 ---
        let rewindBtn = NSButton(frame: NSRect(x: 35, y: (windowHeight - 24) / 2, width: 30, height: 24))
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
        let playerWidth: CGFloat = 260
        let playerView = AVPlayerView(frame: NSRect(x: 70, y: 0, width: playerWidth, height: windowHeight))
        playerView.player = player
        playerView.showsFullScreenToggleButton = false
        playerView.controlsStyle = .inline
        window.contentView?.addSubview(playerView)
        
        // --- 倍速按钮 ---
        let speedBtn = NSButton(frame: NSRect(x: 70 + playerWidth + 5, y: (windowHeight - 24) / 2, width: 40, height: 24))
        speedBtn.setButtonType(.momentaryPushIn)
        speedBtn.bezelStyle = .recessed
        speedBtn.isBordered = false
        speedBtn.title = "1x"
        speedBtn.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        speedBtn.contentTintColor = .white
        speedBtn.target = self
        speedBtn.action = #selector(toggleSpeed(_:))
        window.contentView?.addSubview(speedBtn)
        
        window.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            NSApp.terminate(nil)
        }
        
        player.play()
    }
    
    @objc func rewind5s() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTimeMake(value: 5, timescale: 1))
        player.seek(to: newTime)
    }
    
    @objc func toggleSpeed(_ sender: NSButton) {
        let newRate: Float = (player.defaultRate > 1.0) ? 1.0 : 2.0
        player.defaultRate = newRate
        player.rate = newRate
        sender.title = (newRate > 1.0) ? "2x" : "1x"
    }
}

let app = NSApplication.shared
let myDelegate = AppDelegate()
app.setActivationPolicy(.accessory)
app.delegate = myDelegate
app.run()
