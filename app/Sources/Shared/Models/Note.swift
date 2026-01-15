import SwiftUI
import SwiftData

/// 笔记
@Model
final class Note {
    /// 唯一标识符
    var id: UUID

    /// 笔记内容
    var content: String

    /// 笔记标题（可选，从内容提取）
    var title: String?

    /// 关联图片的本地 URL
    var imageURL: URL?

    /// 是否已转化为其他容器
    var isConverted: Bool

    /// 转化目标类型
    var convertedTo: ContainerType?

    /// 关联的捕获项 ID
    var captureItemId: UUID?

    /// 标签
    var tags: [String]

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        content: String,
        title: String? = nil,
        imageURL: URL? = nil,
        isConverted: Bool = false,
        convertedTo: ContainerType? = nil,
        captureItemId: UUID? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.title = title ?? Note.extractTitle(from: content)
        self.imageURL = imageURL
        self.isConverted = isConverted
        self.convertedTo = convertedTo
        self.captureItemId = captureItemId
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 从内容提取标题（取第一行，最多 50 字符）
    static func extractTitle(from content: String) -> String {
        let firstLine = content.components(separatedBy: .newlines).first ?? content
        if firstLine.count > 50 {
            return String(firstLine.prefix(47)) + "..."
        }
        return firstLine
    }
}
