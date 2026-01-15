import AppKit
import SwiftUI
import SwiftData

/// 捕获窗口控制器 - 管理快速捕获浮窗
@MainActor
final class CaptureWindowController {
    /// 单例
    static let shared = CaptureWindowController()

    /// 窗口实例
    private var window: NSWindow?

    private init() {}

    /// 显示捕获窗口
    func showWindow() {
        if window == nil {
            createWindow()
        }

        guard let window = window else { return }

        // 居中显示在屏幕上
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.midX - windowSize.width / 2
            let y = screenFrame.midY - windowSize.height / 2 + 100 // 稍微偏上
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 隐藏捕获窗口
    func hideWindow() {
        window?.orderOut(nil)
    }

    /// 切换窗口显示状态
    func toggleWindow() {
        if window?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }

    /// 创建窗口
    private func createWindow() {
        guard let modelContainer = AppEnvironment.shared.modelContainer,
              let appState = AppEnvironment.shared.appState else {
            return
        }

        let contentView = CaptureView()
            .environment(appState)
            .modelContainer(modelContainer)

        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
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

        // 设置窗口代理以处理关闭事件
        window.delegate = WindowDelegate.shared

        self.window = window
    }
}

// MARK: - 窗口代理
@MainActor
private final class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()

    func windowDidResignKey(_ notification: Notification) {
        // 可选：失去焦点时隐藏窗口
        // CaptureWindowController.shared.hideWindow()
    }
}
