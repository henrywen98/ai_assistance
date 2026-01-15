import Foundation
import SwiftData
import os

/// 分类队列服务 - 管理待分类项的重试（支持指数退避）
@MainActor
final class ClassificationQueueService {
    static let shared = ClassificationQueueService()

    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "ClassificationQueue")

    private var isProcessing = false
    private var isBackgroundProcessingStarted = false
    private var modelContext: ModelContext?

    // MARK: - Configuration

    /// 基础重试间隔（秒），重试序列: 5s -> 10s -> 20s -> 40s -> 60s (capped)
    private let baseRetryInterval: TimeInterval = 5
    private let maxRetryInterval: TimeInterval = 60
    private let maxRetries = 5
    private let pollInterval: TimeInterval = 10

    private init() {}

    // MARK: - 后台处理

    private func calculateBackoff(retryCount: Int) -> TimeInterval {
        min(baseRetryInterval * pow(2, Double(retryCount)), maxRetryInterval)
    }

    /// 启动后台队列处理
    func startBackgroundProcessing(context: ModelContext) {
        guard !isBackgroundProcessingStarted else {
            logger.warning("后台处理已启动，忽略重复调用")
            return
        }

        isBackgroundProcessingStarted = true
        modelContext = context
        logger.info("分类队列后台处理已启动")

        Task {
            while true {
                await processQueue(context: context)
                try? await Task.sleep(for: .seconds(pollInterval))
            }
        }
    }

    /// 立即触发队列处理（供 NetworkMonitor 调用）
    func triggerImmediateProcessing() {
        guard let context = modelContext else {
            logger.warning("无法触发即时处理：ModelContext 未初始化")
            return
        }

        Task {
            logger.info("网络恢复，立即触发队列处理")
            await processQueue(context: context)
        }
    }

    /// 处理待分类队列
    func processQueue(context: ModelContext) async {
        guard !isProcessing else {
            logger.debug("队列处理中，跳过本次轮询")
            return
        }
        guard LLMService.shared.isConfigured else {
            logger.debug("LLM 服务未配置，跳过处理")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        // 查询并过滤待处理项
        let descriptor = FetchDescriptor<CaptureItem>(sortBy: [SortDescriptor(\.createdAt)])

        guard let allItems = try? context.fetch(descriptor) else {
            logger.error("获取捕获项失败")
            return
        }

        let pendingItems = allItems.filter { $0.status == .pending && $0.retryCount < maxRetries }
        guard !pendingItems.isEmpty else { return }

        logger.info("处理队列: \(pendingItems.count) 项待分类")

        for item in pendingItems {
            await classifyItem(item, context: context)

            // 多个项目之间延迟，避免 API 压力
            if pendingItems.count > 1 {
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func classifyItem(_ item: CaptureItem, context: ModelContext) async {
        let retryInfo = item.retryCount > 0 ? " (重试 #\(item.retryCount))" : ""
        logger.info("开始分类: \(item.id)\(retryInfo)")

        do {
            let classification = try await LLMService.shared.classifyWithMemory(item.content)

            item.retryCount = 0
            item.lastError = nil

            ContainerConversionService.shared.autoConvert(item, classification: classification, in: context)
            try context.save()

            logger.info("分类成功: \(item.id) -> \(classification.container.rawValue)")
        } catch {
            handleClassificationError(item, error: error, context: context)
        }
    }

    private func handleClassificationError(_ item: CaptureItem, error: Error, context: ModelContext) {
        item.retryCount += 1
        item.lastError = error.localizedDescription

        if item.retryCount >= maxRetries {
            item.status = .failed
            logger.error("分类失败（已达最大重试 \(self.maxRetries) 次）: \(item.id) - \(error.localizedDescription)")
        } else {
            let nextBackoff = calculateBackoff(retryCount: item.retryCount)
            logger.warning("分类失败，将在 \(Int(nextBackoff))s 后重试 (\(item.retryCount)/\(self.maxRetries)): \(item.id)")
        }

        try? context.save()
    }

    /// 手动触发重试所有失败项
    func retryFailedItems(context: ModelContext) async {
        let descriptor = FetchDescriptor<CaptureItem>()

        guard let allItems = try? context.fetch(descriptor) else { return }

        let failedItems = allItems.filter { $0.status == .failed }
        guard !failedItems.isEmpty else {
            logger.info("没有失败项需要重试")
            return
        }

        logger.info("重置 \(failedItems.count) 个失败项为待处理状态")

        for item in failedItems {
            item.status = .pending
            item.retryCount = 0
            item.lastError = nil
        }
        try? context.save()

        await processQueue(context: context)
    }
}
