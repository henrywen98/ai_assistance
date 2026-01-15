import AppKit
import SwiftUI
import SwiftData
import os

/// 捕获窗口控制器 - 管理快速捕获浮窗
@MainActor
final class CaptureWindowController {
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "CaptureWindow")
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
        logger.info("createWindow() 被调用")

        // 获取或创建环境
        let modelContainer: ModelContainer
        let appState: AppState

        if let container = AppEnvironment.shared.modelContainer,
           let state = AppEnvironment.shared.appState {
            modelContainer = container
            appState = state
            logger.info("使用 AppEnvironment 中的环境")
        } else {
            // 备用方案：自己创建
            logger.warning("AppEnvironment 未配置，创建新环境")
            do {
                modelContainer = try DataContainer.createContainer()
                appState = AppState()
                AppEnvironment.shared.configure(modelContainer: modelContainer, appState: appState)
            } catch {
                logger.error("创建环境失败: \(error.localizedDescription)")
                return
            }
        }

        logger.info("环境检查通过，开始创建窗口")

        let contentView = CaptureView()
            .environment(appState)
            .modelContainer(modelContainer)

        let hostingView = NSHostingView(rootView: contentView)

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

        // 设置窗口代理以处理关闭事件
        window.delegate = WindowDelegate.shared

        self.window = window
    }
}

// MARK: - 自定义窗口类（支持无边框窗口接收键盘输入）
private final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
