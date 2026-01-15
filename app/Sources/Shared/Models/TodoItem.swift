import SwiftUI
import SwiftData

/// 待办事项
@Model
final class TodoItem {
    /// 唯一标识符
    var id: UUID

    /// 待办标题
    var title: String

    /// 待办描述
    var itemDescription: String?

    /// 优先级
    var priority: Priority

    /// 是否已完成
    var isCompleted: Bool

    /// 完成时间
    var completedAt: Date?

    /// 截止时间
    var dueDate: Date?

    /// 关联的捕获项 ID
    var captureItemId: UUID?

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        itemDescription: String? = nil,
        priority: Priority = .normal,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        captureItemId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.priority = priority
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.captureItemId = captureItemId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 标记完成
    func markCompleted() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }

    /// 取消完成
    func markIncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
}
