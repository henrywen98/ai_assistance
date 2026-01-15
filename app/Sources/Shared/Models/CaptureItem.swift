import SwiftUI
import SwiftData

/// 捕获项 - 用户通过快速捕获记录的内容
@Model
final class CaptureItem {
    /// 唯一标识符
    var id: UUID

    /// 文本内容
    var content: String

    /// 关联图片的本地 URL
    var imageURL: URL?

    /// AI 分类结果（日历/待办/笔记）
    var container: ContainerType?

    /// 用户是否已确认分类
    var userConfirmed: Bool

    /// AI 提取的时间（日历事件用）
    var extractedTime: Date?

    /// AI 推荐的优先级
    var suggestedPriority: Priority

    /// AI 生成的摘要
    var aiSummary: String?

    /// 关联的捕获项 IDs
    var relatedCaptureIds: [UUID]

    /// 处理状态
    var status: CaptureStatus

    /// 重试计数（分类失败时递增）
    var retryCount: Int

    /// 最后一次错误信息
    var lastError: String?

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        imageURL: URL? = nil,
        container: ContainerType? = nil,
        userConfirmed: Bool = false,
        extractedTime: Date? = nil,
        suggestedPriority: Priority = .normal,
        aiSummary: String? = nil,
        relatedCaptureIds: [UUID] = [],
        status: CaptureStatus = .pending,
        retryCount: Int = 0,
        lastError: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.imageURL = imageURL
        self.container = container
        self.userConfirmed = userConfirmed
        self.extractedTime = extractedTime
        self.suggestedPriority = suggestedPriority
        self.aiSummary = aiSummary
        self.relatedCaptureIds = relatedCaptureIds
        self.status = status
        self.retryCount = retryCount
        self.lastError = lastError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 捕获状态

enum CaptureStatus: String, Codable {
    /// 待处理（等待 AI 分类）
    case pending
    /// 已分类（等待用户确认）
    case classified
    /// 已确认
    case confirmed
    /// 分类失败
    case failed
}

// MARK: - 优先级

enum Priority: String, Codable, CaseIterable {
    case important
    case normal
}
