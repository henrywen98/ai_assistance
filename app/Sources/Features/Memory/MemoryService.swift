import Foundation
import SwiftData
import os

/// Memory 服务 - 负责学习和应用用户偏好
@MainActor
final class MemoryService {
    /// 单例
    static let shared = MemoryService()

    /// 日志记录器
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "Memory")

    private init() {}

    // MARK: - 偏好学习

    /// 记录用户纠正分类的行为
    func recordClassificationCorrection(
        originalContent: String,
        originalContainer: ContainerType,
        correctedContainer: ContainerType,
        in context: ModelContext
    ) {
        guard originalContainer != correctedContainer else { return }

        logger.info("记录分类纠正: \(originalContainer.rawValue) -> \(correctedContainer.rawValue)")

        // 提取关键词
        let keywords = extractKeywords(from: originalContent)

        for keyword in keywords {
            // 查找现有规则
            if let existing = findExistingPreference(keyword: keyword, container: correctedContainer, in: context) {
                existing.recordUsage()
                logger.debug("更新现有偏好: \(keyword)")
            } else {
                // 创建新规则
                let entry = MemoryEntry(
                    type: .preference,
                    keyword: keyword,
                    content: "用户将包含「\(keyword)」的内容分类为\(correctedContainer.rawValue)",
                    associatedContainer: correctedContainer
                )
                context.insert(entry)
                logger.debug("创建新偏好: \(keyword) -> \(correctedContainer.rawValue)")
            }

            // 停用原分类的偏好
            if let oldPreference = findExistingPreference(keyword: keyword, container: originalContainer, in: context) {
                oldPreference.deactivate()
            }
        }

        try? context.save()
    }

    /// 记录优先级纠正
    func recordPriorityCorrection(
        content: String,
        correctedPriority: Priority,
        in context: ModelContext
    ) {
        let keywords = extractKeywords(from: content)

        for keyword in keywords {
            if let existing = findPriorityPreference(keyword: keyword, priority: correctedPriority, in: context) {
                existing.recordUsage()
            } else {
                let entry = MemoryEntry(
                    type: .preference,
                    keyword: keyword,
                    content: "用户将包含「\(keyword)」的内容标记为\(correctedPriority.rawValue)",
                    associatedPriority: correctedPriority
                )
                context.insert(entry)
            }
        }

        try? context.save()
    }

    // MARK: - 偏好应用

    /// 根据 Memory 调整分类结果
    func adjustClassification(
        content: String,
        aiResult: Classification,
        in context: ModelContext
    ) -> Classification {
        var adjusted = aiResult

        // 查找匹配的偏好
        if let preference = findBestMatchingPreference(for: content, in: context) {
            if let container = preference.associatedContainer, preference.usageCount >= 3 {
                // 只有使用次数足够多的偏好才覆盖 AI 结果
                adjusted.container = container
                logger.info("Memory 覆盖分类: \(container.rawValue) (使用次数: \(preference.usageCount))")
            }

            if let priority = preference.associatedPriority {
                adjusted.suggestedPriority = priority
            }

            // 记录使用
            preference.recordUsage()
            try? context.save()
        }

        return adjusted
    }

    /// 获取建议容器（基于 Memory）
    func getSuggestedContainer(
        for content: String,
        in context: ModelContext
    ) -> ContainerType? {
        guard let preference = findBestMatchingPreference(for: content, in: context),
              let container = preference.associatedContainer,
              preference.usageCount >= 2 else {
            return nil
        }

        return container
    }

    // MARK: - 关键词提取

    /// 提取文本关键词
    func extractKeywords(from text: String) -> [String] {
        // 简单实现：提取2-8字符的词组
        var keywords: [String] = []

        // 分词（简单按空格和标点分割）
        let components = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 && $0.count <= 8 }

        keywords.append(contentsOf: components.prefix(5))

        // 提取可能的名词短语（中文）
        let chinesePattern = try? NSRegularExpression(pattern: "[\\u4e00-\\u9fa5]{2,6}", options: [])
        if let matches = chinesePattern?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
            for match in matches.prefix(5) {
                if let range = Range(match.range, in: text) {
                    keywords.append(String(text[range]))
                }
            }
        }

        // 去重
        return Array(Set(keywords)).prefix(8).map { $0 }
    }

    // MARK: - 常用信息存储

    /// 分析并存储常用信息（从捕获内容中提取高频词）
    func analyzeAndStoreCommonInfo(
        content: String,
        in context: ModelContext
    ) {
        let keywords = extractKeywords(from: content)

        for keyword in keywords {
            // 检查是否已存在
            if let existing = findKeywordEntry(keyword: keyword, in: context) {
                existing.recordUsage()
                logger.debug("更新高频词: \(keyword) (次数: \(existing.usageCount))")
            } else {
                // 创建新的关键词条目
                let entry = MemoryEntry(
                    type: .keyword,
                    keyword: keyword,
                    content: "用户常提到的内容"
                )
                context.insert(entry)
                logger.debug("新增关键词: \(keyword)")
            }
        }

        // 检测可能的人名
        detectAndStorePeople(in: content, context: context)

        // 检测可能的项目名
        detectAndStoreProjects(in: content, context: context)

        try? context.save()
    }

    /// 获取常用信息列表（用于 AI 上下文）
    func getCommonInfoContext(in context: ModelContext) -> String {
        var contextLines: [String] = []

        // 获取高频关键词
        let keywords = getTopKeywords(limit: 10, in: context)
        if !keywords.isEmpty {
            contextLines.append("用户常提到的关键词: \(keywords.joined(separator: "、"))")
        }

        // 获取人物
        let people = getStoredPeople(in: context)
        if !people.isEmpty {
            contextLines.append("相关人物: \(people.joined(separator: "、"))")
        }

        // 获取项目
        let projects = getStoredProjects(in: context)
        if !projects.isEmpty {
            contextLines.append("相关项目: \(projects.joined(separator: "、"))")
        }

        return contextLines.joined(separator: "\n")
    }

    /// 获取高频关键词
    func getTopKeywords(limit: Int, in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else { return [] }

        return entries
            .filter { $0.type == .keyword && $0.isActive && $0.usageCount >= 3 }
            .prefix(limit)
            .map { $0.keyword }
    }

    /// 获取存储的人物
    func getStoredPeople(in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else { return [] }

        return entries
            .filter { $0.type == .person && $0.isActive }
            .prefix(10)
            .map { $0.keyword }
    }

    /// 获取存储的项目
    func getStoredProjects(in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else { return [] }

        return entries
            .filter { $0.type == .context && $0.isActive }
            .prefix(10)
            .map { $0.keyword }
    }

    // MARK: - 人名和项目检测

    private func detectAndStorePeople(in text: String, context: ModelContext) {
        // 简单的人名模式：X先生、X小姐、小X、老X、X总、X哥、X姐
        let patterns = [
            "([\\u4e00-\\u9fa5]{1,2})(先生|小姐|总|哥|姐)",
            "(小|老)([\\u4e00-\\u9fa5]{1,2})",
            "@([\\w\\u4e00-\\u9fa5]+)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let name = String(text[range])
                        storePerson(name: name, in: context)
                    }
                }
            }
        }
    }

    private func detectAndStoreProjects(in text: String, context: ModelContext) {
        // 项目名模式：X项目、X系统、X平台、X产品
        let patterns = [
            "([\\u4e00-\\u9fa5a-zA-Z0-9]{2,10})(项目|系统|平台|产品|APP|app)",
            "\\[([^\\]]+)\\]"  // [项目名]
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let project = String(text[range])
                        storeProject(name: project, in: context)
                    }
                }
            }
        }
    }

    private func storePerson(name: String, in context: ModelContext) {
        if let existing = findPersonEntry(name: name, in: context) {
            existing.recordUsage()
        } else {
            let entry = MemoryEntry(
                type: .person,
                keyword: name,
                content: "识别到的人物"
            )
            context.insert(entry)
        }
    }

    private func storeProject(name: String, in context: ModelContext) {
        if let existing = findProjectEntry(name: name, in: context) {
            existing.recordUsage()
        } else {
            let entry = MemoryEntry(
                type: .context,
                keyword: name,
                content: "识别到的项目/产品"
            )
            context.insert(entry)
        }
    }

    private func findKeywordEntry(keyword: String, in context: ModelContext) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>()
        guard let entries = try? context.fetch(descriptor) else { return nil }
        return entries.first { $0.type == .keyword && $0.keyword == keyword }
    }

    private func findPersonEntry(name: String, in context: ModelContext) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>()
        guard let entries = try? context.fetch(descriptor) else { return nil }
        return entries.first { $0.type == .person && $0.keyword == name }
    }

    private func findProjectEntry(name: String, in context: ModelContext) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>()
        guard let entries = try? context.fetch(descriptor) else { return nil }
        return entries.first { $0.type == .context && $0.keyword == name }
    }

    // MARK: - 智能关联

    /// 查找与新捕获相关的已有捕获项
    func findRelatedCaptures(
        for capture: CaptureItem,
        in context: ModelContext,
        limit: Int = 5
    ) -> [CaptureItem] {
        let keywords = extractKeywords(from: capture.content)
        guard !keywords.isEmpty else { return [] }

        // 获取所有捕获（排除自己）
        let descriptor = FetchDescriptor<CaptureItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allCaptures = try? context.fetch(descriptor) else { return [] }

        // 计算相似度并排序
        var scoredCaptures: [(CaptureItem, Int)] = []

        for otherCapture in allCaptures {
            guard otherCapture.id != capture.id else { continue }

            // 计算关键词匹配分数
            var score = 0
            let otherKeywords = Set(extractKeywords(from: otherCapture.content))

            for keyword in keywords {
                if otherKeywords.contains(keyword) {
                    score += 2
                } else if otherCapture.content.localizedCaseInsensitiveContains(keyword) {
                    score += 1
                }
            }

            // 同容器加分
            if capture.container == otherCapture.container {
                score += 1
            }

            if score > 0 {
                scoredCaptures.append((otherCapture, score))
            }
        }

        // 按分数排序并返回前 N 个
        return scoredCaptures
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    /// 为捕获项建立关联
    func establishAssociations(
        for capture: CaptureItem,
        in context: ModelContext
    ) {
        let relatedCaptures = findRelatedCaptures(for: capture, in: context)

        if !relatedCaptures.isEmpty {
            capture.relatedCaptureIds = relatedCaptures.map { $0.id }

            // 双向关联
            for related in relatedCaptures {
                if !related.relatedCaptureIds.contains(capture.id) {
                    related.relatedCaptureIds.append(capture.id)
                }
            }

            logger.info("建立关联: \(capture.id) <-> \(relatedCaptures.count) 个相关项")
            try? context.save()
        }
    }

    /// 获取关联的捕获项
    func getRelatedCaptures(
        for capture: CaptureItem,
        in context: ModelContext
    ) -> [CaptureItem] {
        guard !capture.relatedCaptureIds.isEmpty else { return [] }

        let descriptor = FetchDescriptor<CaptureItem>()
        guard let allCaptures = try? context.fetch(descriptor) else { return [] }

        return allCaptures.filter { capture.relatedCaptureIds.contains($0.id) }
    }

    // MARK: - 私有方法

    private func findExistingPreference(
        keyword: String,
        container: ContainerType,
        in context: ModelContext
    ) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>()
        guard let entries = try? context.fetch(descriptor) else { return nil }

        return entries.first { entry in
            entry.type == .preference &&
            entry.keyword == keyword &&
            entry.associatedContainer == container &&
            entry.isActive
        }
    }

    private func findPriorityPreference(
        keyword: String,
        priority: Priority,
        in context: ModelContext
    ) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>()
        guard let entries = try? context.fetch(descriptor) else { return nil }

        return entries.first { entry in
            entry.type == .preference &&
            entry.keyword == keyword &&
            entry.associatedPriority == priority &&
            entry.isActive
        }
    }

    private func findBestMatchingPreference(
        for text: String,
        in context: ModelContext
    ) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )

        guard let entries = try? context.fetch(descriptor) else { return nil }

        let preferences = entries.filter { $0.type == .preference && $0.isActive }

        // 查找最佳匹配
        for entry in preferences {
            if text.localizedCaseInsensitiveContains(entry.keyword) {
                return entry
            }
        }

        return nil
    }
}
