import SwiftUI
import SwiftData
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
            "directCaptureOnMenuBarClick": false
        ])

        // 设置全局快捷键
        HotkeyManager.shared.setupHotkeys()
        logger.info("全局快捷键已配置 (⌘+Shift+V)")

        // 始终显示在 Dock 中
        NSApp.setActivationPolicy(.regular)

        // 启动分类队列后台处理
        startClassificationQueue()

        // 启动时自动显示捕获箱窗口由 SwiftUI 的 .defaultLaunchBehavior(.presented) 处理
    }

    /// 启动分类队列服务和网络监听
    private func startClassificationQueue() {
        Task { @MainActor [logger] in
            // 等待 AppEnvironment 初始化完成
            try? await Task.sleep(for: .milliseconds(100))

            guard let environment = AppEnvironment.shared else {
                logger.warning("AppEnvironment 未初始化，队列服务启动失败")
                return
            }

            let context = environment.modelContainer.mainContext

            ClassificationQueueService.shared.startBackgroundProcessing(context: context)
            logger.info("分类队列服务已启动")

            NetworkMonitor.shared.onNetworkRestored = {
                ClassificationQueueService.shared.triggerImmediateProcessing()
            }
            NetworkMonitor.shared.start()
            logger.info("网络监听服务已启动")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
        NetworkMonitor.shared.stop()
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

}
