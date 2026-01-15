import AppKit
import SwiftUI
import SwiftData
import os

/// 捕获窗口控制器 - 管理快速捕获浮窗
/// 整个类都在 @MainActor 隔离下，确保线程安全
@MainActor
final class CaptureWindowController: NSObject {
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "CaptureWindow")

    /// 单例 - 使用 @MainActor 确保在主线程初始化
    static let shared = CaptureWindowController()

    /// 当前窗口 - 受 @MainActor 保护
    private var currentWindow: NSWindow?

    private override init() {
        super.init()
    }

    func showWindow() {
        if let window = currentWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        logger.info("创建新捕获窗口")

        let contentView = CaptureView()
            .modelContainer(AppEnvironment.shared.modelContainer)
            .environment(AppEnvironment.shared.appState)

        let hostingView = NSHostingView(rootView: AnyView(contentView))

        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 150),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 200
            let y = screenFrame.midY + 50
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        currentWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        logger.info("捕获窗口显示成功")
    }

    func hideWindow() {
        currentWindow?.orderOut(nil)
        currentWindow = nil
    }

    func toggleWindow() {
        if currentWindow?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }
}

// MARK: - 自定义窗口类
private final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func close() {
        CaptureWindowController.shared.hideWindow()
    }
}
