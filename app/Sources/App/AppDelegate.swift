import SwiftUI
import os

/// 通知名扩展
extension Notification.Name {
    static let openDashboard = Notification.Name("openDashboard")
}

/// 应用代理 - 处理系统级事件
class AppDelegate: NSObject, NSApplicationDelegate {

    /// 统一日志记录器
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "AppDelegate")

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("AIAssistant 启动完成")

        // 注册默认设置值
        UserDefaults.standard.register(defaults: [
            "showInDock": false,
            "directCaptureOnMenuBarClick": false
        ])

        // 设置全局快捷键
        HotkeyManager.shared.setupHotkeys()
        logger.info("全局快捷键已配置 (⌘+Shift+V)")

        // 恢复 Dock 图标可见性设置
        let showInDock = UserDefaults.standard.bool(forKey: "showInDock")
        if showInDock {
            NSApp.setActivationPolicy(.regular)
        }

        // 启动时自动显示捕获箱窗口由 SwiftUI 的 .defaultLaunchBehavior(.presented) 处理
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        logger.info("AIAssistant 正在退出")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 菜单栏应用不应在窗口关闭后退出
        return false
    }

    /// 点击 Dock 图标时触发
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 点击 Dock 图标时总是显示 Dashboard
        NotificationCenter.default.post(name: .openDashboard, object: nil)
        return false
    }

    // MARK: - System Events

    func applicationDidBecomeActive(_ notification: Notification) {
        // 应用激活时的处理
    }

    func applicationDidResignActive(_ notification: Notification) {
        // 应用失去焦点时的处理
    }
}
