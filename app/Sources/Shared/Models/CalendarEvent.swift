import SwiftUI
import SwiftData

/// 日历事件
@Model
final class CalendarEvent {
    /// 唯一标识符
    var id: UUID

    /// 事件标题
    var title: String

    /// 事件描述
    var eventDescription: String?

    /// 开始时间
    var startTime: Date

    /// 结束时间
    var endTime: Date

    /// 是否全天事件
    var isAllDay: Bool

    /// 地点
    var location: String?

    /// 备注
    var notes: String?

    /// 优先级
    var priority: Priority

    /// 关联的捕获项 ID
    var captureItemId: UUID?

    /// 是否已完成
    var isCompleted: Bool

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        eventDescription: String? = nil,
        startTime: Date,
        endTime: Date? = nil,
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        priority: Priority = .normal,
        captureItemId: UUID? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.startTime = startTime
        self.endTime = endTime ?? startTime.addingTimeInterval(3600) // 默认 1 小时
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.priority = priority
        self.captureItemId = captureItemId
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 事件时长（分钟）
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}
