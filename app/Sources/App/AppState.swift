import SwiftUI

/// 全局应用状态容器
/// 使用 Swift 5.9+ @Observable 宏实现响应式状态管理
@MainActor
@Observable
class AppState {
    // MARK: - Capture State
    /// 捕获窗口是否显示
    var isCaptureWindowVisible = false

    // MARK: - Navigation State
    /// 当前选中的容器类型
    var selectedContainer: ContainerType?

    // MARK: - Processing State
    /// 是否正在处理捕获内容
    var isProcessing = false

    // MARK: - Badge State
    /// 待处理捕获项数量（用于菜单栏角标）
    var pendingCaptureCount = 0

    // MARK: - Initialization
    init() {
        // 初始化将在后续 Story 中扩展
    }

    /// 更新待处理计数
    func updatePendingCount(_ count: Int) {
        pendingCaptureCount = count
    }
}

// MARK: - Container Types
/// 内容容器类型枚举
/// 与 Architecture 4.6 节定义保持一致
enum ContainerType: String, Codable, CaseIterable, Identifiable {
    case calendar
    case todo
    case note  // Architecture 规范：使用单数形式

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calendar: return "日历"
        case .todo: return "待办"
        case .note: return "笔记"
        }
    }

    var systemImage: String {
        switch self {
        case .calendar: return "calendar"
        case .todo: return "checkmark.circle"
        case .note: return "note.text"
        }
    }
}
