import Foundation
import SwiftData

/// Memory 条目类型
enum MemoryType: String, Codable, CaseIterable {
    case preference = "偏好"      // 分类偏好规则
    case person = "人物"          // 人际关系
    case rule = "规则"            // 自定义规则
    case keyword = "关键词"       // 高频关键词
    case context = "上下文"       // 常用上下文信息
}

/// Memory 条目 - 存储学习到的规则和偏好
@Model
final class MemoryEntry {
    /// 唯一标识
    var id: UUID

    /// 类型
    var type: MemoryType

    /// 关键词/触发词
    var keyword: String

    /// 关联的容器类型（用于偏好）
    var associatedContainer: ContainerType?

    /// 关联的优先级（用于偏好）
    var associatedPriority: Priority?

    /// 内容/描述
    var content: String

    /// 使用次数
    var usageCount: Int

    /// 是否启用
    var isActive: Bool

    /// 创建时间
    var createdAt: Date

    /// 最后使用时间
    var lastUsedAt: Date

    /// 来源捕获 ID（可选，用于追溯）
    var sourceCaptureId: UUID?

    init(
        type: MemoryType,
        keyword: String,
        content: String = "",
        associatedContainer: ContainerType? = nil,
        associatedPriority: Priority? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.keyword = keyword
        self.content = content
        self.associatedContainer = associatedContainer
        self.associatedPriority = associatedPriority
        self.usageCount = 1
        self.isActive = true
        self.createdAt = Date()
        self.lastUsedAt = Date()
    }

    /// 记录使用
    func recordUsage() {
        usageCount += 1
        lastUsedAt = Date()
    }

    /// 停用规则（用于纠正）
    func deactivate() {
        isActive = false
    }
}

// MARK: - Memory 查询扩展
extension MemoryEntry {
    /// 查找匹配的偏好规则
    static func findPreference(
        for text: String,
        in context: ModelContext
    ) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else {
            return nil
        }

        // 过滤活跃的偏好类型
        let preferences = entries.filter { entry in
            entry.isActive && entry.type == .preference
        }

        // 查找关键词匹配
        for entry in preferences {
            if text.localizedCaseInsensitiveContains(entry.keyword) {
                return entry
            }
        }

        return nil
    }

    /// 获取所有活跃的 Memory 条目（用于 AI 上下文）
    static func getActiveMemories(
        in context: ModelContext,
        limit: Int = 10
    ) -> [MemoryEntry] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else {
            return []
        }

        return Array(entries.filter { $0.isActive }.prefix(limit))
    }
}
