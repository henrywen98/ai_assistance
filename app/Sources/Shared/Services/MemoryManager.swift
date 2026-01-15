import Foundation
import os

/// Memory 管理器 - 负责读取和缓存用户自定义的 Memory.md 文件
/// Memory.md 的内容会作为系统提示词的一部分，帮助 AI 更好地理解用户的偏好和上下文
@MainActor
final class MemoryManager {
    /// 单例
    static let shared = MemoryManager()

    /// 日志记录器
    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "MemoryManager")

    /// 缓存的 Memory 内容（启动时加载）
    private(set) var cachedContent: String = ""

    /// Memory.md 文件路径
    var memoryFilePath: URL {
        // 存储在 Application Support 目录
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("AIAssistant", isDirectory: true)
        return appFolder.appendingPathComponent("Memory.md")
    }

    private init() {
        // 确保目录存在
        ensureDirectoryExists()
        // 启动时加载
        loadMemory()
    }

    // MARK: - 公开方法

    /// 获取 Memory 内容（用于构建 AI 提示词）
    /// 如果 Memory 为空，返回 nil
    func getMemoryContext() -> String? {
        guard !cachedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return cachedContent
    }

    /// 重新加载 Memory（用于设置界面保存后刷新）
    func reloadMemory() {
        loadMemory()
        logger.info("Memory 已重新加载")
    }

    /// 保存 Memory 内容
    func saveMemory(_ content: String) throws {
        try content.write(to: memoryFilePath, atomically: true, encoding: .utf8)
        cachedContent = content
        logger.info("Memory 已保存")
    }

    /// 获取原始文件内容（用于设置界面编辑）
    func getRawContent() -> String {
        return cachedContent
    }

    // MARK: - 私有方法

    /// 确保应用目录存在
    private func ensureDirectoryExists() {
        let directory = memoryFilePath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                logger.info("创建应用目录: \(directory.path)")
            } catch {
                logger.error("创建目录失败: \(error.localizedDescription)")
            }
        }
    }

    /// 加载 Memory 文件
    private func loadMemory() {
        // 如果文件不存在，创建默认模板
        if !FileManager.default.fileExists(atPath: memoryFilePath.path) {
            createDefaultMemoryFile()
        }

        do {
            cachedContent = try String(contentsOf: memoryFilePath, encoding: .utf8)
            logger.info("Memory 加载成功，内容长度: \(self.cachedContent.count)")
        } catch {
            logger.error("加载 Memory 失败: \(error.localizedDescription)")
            cachedContent = ""
        }
    }

    /// 创建默认的 Memory.md 文件
    private func createDefaultMemoryFile() {
        let defaultContent = """
        # Memory - 个人上下文

        这个文件的内容会作为 AI 的系统提示词，帮助 AI 更好地理解你的偏好和上下文。
        你可以在这里写任何有助于 AI 分类的信息。

        ## 使用示例

        ### 分类偏好
        - 包含「会议」「约」「见面」的内容通常是日历事件
        - 包含「买」「购」「下单」的内容通常是待办事项
        - 包含「想法」「灵感」「记录」的内容通常是笔记

        ### 人物关系
        - 小王是我的同事，负责设计
        - 小李是我的上司

        ### 项目信息
        - AIAssistant 是我正在开发的个人助理 App

        ### 其他偏好
        - 工作相关的事项优先级通常较高
        - 周末的安排优先级通常较低

        ---

        请在下方添加你的个人信息和偏好：

        """

        do {
            try defaultContent.write(to: memoryFilePath, atomically: true, encoding: .utf8)
            cachedContent = defaultContent
            logger.info("创建默认 Memory.md 文件")
        } catch {
            logger.error("创建默认 Memory.md 失败: \(error.localizedDescription)")
        }
    }
}
