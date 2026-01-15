import Foundation
import SwiftData
import os

/// 分类队列服务 - 管理待分类项的重试
@MainActor
final class ClassificationQueueService {
    /// 单例
    static let shared = ClassificationQueueService()

    /// 日志记录器
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "ClassificationQueue")

    /// 是否正在处理队列
    private var isProcessing = false

    /// 重试间隔（秒）
    private let retryInterval: TimeInterval = 30

    /// 最大重试次数
    private let maxRetries = 3

    private init() {}

    /// 启动后台队列处理
    func startBackgroundProcessing(context: ModelContext) {
        Task {
            while true {
                await processQueue(context: context)
                try? await Task.sleep(for: .seconds(retryInterval))
            }
        }
    }

    /// 处理待分类队列
    func processQueue(context: ModelContext) async {
        guard !isProcessing else { return }
        guard LLMService.shared.isConfigured else { return }

        isProcessing = true
        defer { isProcessing = false }

        // 查找待处理和失败的项
        let descriptor = FetchDescriptor<CaptureItem>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let allItems = try? context.fetch(descriptor) else {
            return
        }

        // 过滤待处理和失败的项
        let pendingItems = allItems.filter { $0.status == .pending || $0.status == .failed }

        logger.info("处理队列: \(pendingItems.count) 项待分类")

        for item in pendingItems {
            await classifyItem(item, context: context)
        }
    }

    /// 分类单个项目
    private func classifyItem(_ item: CaptureItem, context: ModelContext) async {
        do {
            let classification = try await LLMService.shared.classify(item.content)

            ContainerConversionService.shared.autoConvert(
                item,
                classification: classification,
                in: context
            )

            try context.save()
            logger.info("分类成功: \(item.id)")
        } catch {
            item.status = .failed
            try? context.save()
            logger.error("分类失败: \(item.id) - \(error.localizedDescription)")
        }
    }

    /// 手动触发重试所有失败项
    func retryFailedItems(context: ModelContext) async {
        let descriptor = FetchDescriptor<CaptureItem>()

        guard let allItems = try? context.fetch(descriptor) else {
            return
        }

        let failedItems = allItems.filter { $0.status == .failed }

        for item in failedItems {
            item.status = .pending
        }
        try? context.save()

        await processQueue(context: context)
    }
}
