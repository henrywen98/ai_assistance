import SwiftUI
import SwiftData

/// SwiftData 数据容器配置
enum DataContainer {
    /// 所有数据模型
    static let schema = Schema([
        CaptureItem.self,
        CalendarEvent.self,
        TodoItem.self,
        Note.self,
        MemoryEntry.self
    ])

    /// 模型配置
    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .automatic
    )

    /// 创建 ModelContainer
    static func createContainer() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }

    /// 预览用的内存容器
    @MainActor
    static var previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            // 添加示例数据
            let context = container.mainContext
            addSampleData(to: context)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    /// 添加示例数据（预览用）
    @MainActor
    private static func addSampleData(to context: ModelContext) {
        // 示例捕获
        let capture1 = CaptureItem(
            content: "明天下午3点和小王开会",
            container: .calendar,
            aiConfidence: 0.92,
            userConfirmed: true,
            status: .confirmed
        )
        context.insert(capture1)

        // 示例待办
        let todo1 = TodoItem(
            title: "完成项目报告",
            priority: .important
        )
        context.insert(todo1)

        // 示例日历
        let event1 = CalendarEvent(
            title: "团队会议",
            startTime: Date().addingTimeInterval(86400)
        )
        context.insert(event1)

        // 示例笔记
        let note1 = Note(
            content: "今天学到了 SwiftData 的用法"
        )
        context.insert(note1)
    }
}
