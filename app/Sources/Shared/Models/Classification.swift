import Foundation

/// AI 分类结果
struct Classification: Codable, Equatable {
    /// 目标容器
    var container: ContainerType

    /// 提取的时间（日历事件用）
    var extractedTime: Date?

    /// 建议优先级
    var suggestedPriority: Priority

    /// AI 生成的摘要
    var summary: String

    init(
        container: ContainerType,
        extractedTime: Date? = nil,
        suggestedPriority: Priority = .normal,
        summary: String = ""
    ) {
        self.container = container
        self.extractedTime = extractedTime
        self.suggestedPriority = suggestedPriority
        self.summary = summary
    }
}

// MARK: - Classification Helper
extension Classification {
    /// 创建默认的待办分类
    static func defaultTodo(summary: String = "") -> Classification {
        Classification(
            container: .todo,
            extractedTime: nil,
            suggestedPriority: .normal,
            summary: summary
        )
    }

    /// 创建默认的笔记分类
    static func defaultNote(summary: String = "") -> Classification {
        Classification(
            container: .note,
            extractedTime: nil,
            suggestedPriority: .normal,
            summary: summary
        )
    }
}
