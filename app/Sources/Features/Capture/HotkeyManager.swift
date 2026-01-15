import Foundation
import KeyboardShortcuts

// MARK: - 快捷键名称定义
extension KeyboardShortcuts.Name {
    /// 快速捕获快捷键
    static let quickCapture = Self("quickCapture", default: .init(.v, modifiers: [.command, .shift]))
}

/// 快捷键管理器
@MainActor
final class HotkeyManager {
    /// 单例
    static let shared = HotkeyManager()

    private init() {}

    /// 设置快捷键监听
    func setupHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .quickCapture) { [weak self] in
            // 确保在主线程执行
            Task { @MainActor in
                self?.handleQuickCapture()
            }
        }
    }

    /// 处理快速捕获快捷键
    private func handleQuickCapture() {
        CaptureWindowController.shared.toggleWindow()
    }
}
