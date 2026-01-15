import Foundation
import SwiftData

/// 容器转换服务 - 负责将捕获项转换为不同容器类型
@MainActor
final class ContainerConversionService {
    /// 单例
    static let shared = ContainerConversionService()

    private init() {}

    /// 将捕获项转换为日历事件
    func convertToCalendar(
        _ capture: CaptureItem,
        startTime: Date,
        endTime: Date? = nil,
        isAllDay: Bool = false,
        in context: ModelContext
    ) -> CalendarEvent {
        let event = CalendarEvent(
            title: capture.aiSummary ?? String(capture.content.prefix(50)),
            eventDescription: capture.content,
            startTime: startTime,
            endTime: endTime,
            isAllDay: isAllDay,
            priority: capture.suggestedPriority,
            captureItemId: capture.id
        )

        context.insert(event)

        // 更新捕获项状态
        capture.container = .calendar
        capture.status = .confirmed

        return event
    }

    /// 将捕获项转换为待办事项
    func convertToTodo(
        _ capture: CaptureItem,
        dueDate: Date? = nil,
        in context: ModelContext
    ) -> TodoItem {
        let todo = TodoItem(
            title: capture.aiSummary ?? String(capture.content.prefix(50)),
            itemDescription: capture.content,
            priority: capture.suggestedPriority,
            dueDate: dueDate ?? capture.extractedTime,
            captureItemId: capture.id
        )

        context.insert(todo)

        // 更新捕获项状态
        capture.container = .todo
        capture.status = .confirmed

        return todo
    }

    /// 将捕获项转换为笔记
    func convertToNote(
        _ capture: CaptureItem,
        in context: ModelContext
    ) -> Note {
        let note = Note(
            content: capture.content,
            title: capture.aiSummary,
            imageURL: capture.imageURL,
            captureItemId: capture.id
        )

        context.insert(note)

        // 更新捕获项状态
        capture.container = .note
        capture.status = .confirmed

        return note
    }

    /// 根据 AI 分类结果自动转换
    func autoConvert(
        _ capture: CaptureItem,
        classification: Classification,
        in context: ModelContext
    ) {
        // 更新 CaptureItem 属性
        capture.extractedTime = classification.extractedTime
        capture.suggestedPriority = classification.suggestedPriority
        capture.aiSummary = classification.summary

        // 根据分类结果创建实际实体
        switch classification.container {
        case .calendar:
            let startTime = classification.extractedTime ?? Date()
            _ = convertToCalendar(capture, startTime: startTime, in: context)
        case .todo:
            _ = convertToTodo(capture, dueDate: classification.extractedTime, in: context)
        case .note:
            _ = convertToNote(capture, in: context)
        }
    }

    /// 手动更改容器类型
    func manualConvert(
        _ capture: CaptureItem,
        to newContainer: ContainerType,
        in context: ModelContext
    ) {
        // 执行转换
        switch newContainer {
        case .calendar:
            let time = capture.extractedTime ?? Date()
            _ = convertToCalendar(capture, startTime: time, in: context)
        case .todo:
            _ = convertToTodo(capture, in: context)
        case .note:
            _ = convertToNote(capture, in: context)
        }
    }
}
