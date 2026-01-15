import Foundation
import OpenAI

/// LLM 服务 - 负责 AI 分类
@MainActor
final class LLMService {
    /// 单例
    static let shared = LLMService()

    /// OpenAI 客户端
    private var openAI: OpenAI?

    /// 是否已配置
    var isConfigured: Bool {
        openAI != nil
    }

    private init() {
        configure()
    }

    /// 配置 API
    func configure() {
        // 优先级：Keychain > 环境变量
        let apiKey = KeychainService.getDashscopeKey()
            ?? ProcessInfo.processInfo.environment["DASHSCOPE_API_KEY"]
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]

        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return
        }

        // Dashscope 兼容模式配置
        let host = ProcessInfo.processInfo.environment["LLM_HOST"]
            ?? "dashscope.aliyuncs.com"
        let basePath = ProcessInfo.processInfo.environment["LLM_BASE_PATH"]
            ?? "/compatible-mode/v1"

        let configuration = OpenAI.Configuration(
            token: apiKey,
            host: host,
            scheme: "https",
            basePath: basePath
        )
        openAI = OpenAI(configuration: configuration)
    }

    /// 使用新 API Key 重新配置
    func reconfigure(with apiKey: String) throws {
        try KeychainService.saveDashscopeKey(apiKey)
        configure()
    }

    /// 测试 API 连通性
    func testConnection() async throws -> Bool {
        guard let openAI = openAI else {
            throw AIAssistantError.configurationMissing("API Key")
        }

        let modelName = ProcessInfo.processInfo.environment["LLM_MODEL"] ?? "qwen-plus"

        let query = ChatQuery(
            messages: [
                .init(role: .user, content: "ping")!
            ],
            model: .init(modelName)
        )

        _ = try await openAI.chats(query: query)
        return true
    }

    /// 分类文本内容（不含 Memory 上下文）
    func classify(_ text: String) async throws -> Classification {
        try await classifyWithContext(text, memoryContext: nil)
    }

    /// 分类文本内容（含 Memory 上下文）
    /// 使用 MemoryManager 中缓存的用户自定义 Memory.md 内容
    func classifyWithMemory(_ text: String) async throws -> Classification {
        // 从 MemoryManager 获取用户自定义的 Memory 内容
        let memoryContext = MemoryManager.shared.getMemoryContext()
        return try await classifyWithContext(text, memoryContext: memoryContext)
    }

    /// 内部分类方法
    private func classifyWithContext(_ text: String, memoryContext: String?) async throws -> Classification {
        guard let openAI = openAI else {
            throw AIAssistantError.configurationMissing("API Key")
        }

        var systemPrompt = """
        你是一个智能助手，负责将用户输入的内容分类到以下三个容器之一：
        1. calendar - 日历事件（有明确时间的安排，如会议、约会）
        2. todo - 待办事项（需要完成的任务、行动项）
        3. note - 笔记（想法、灵感、信息记录、学习内容）

        请返回 JSON 格式：
        {
            "container": "calendar|todo|note",
            "extractedTime": "ISO8601格式时间（如有）",
            "suggestedPriority": "important|normal",
            "summary": "简要说明为什么分类到这个类别（10字以内）"
        }

        注意：summary 字段应说明分类理由，例如"包含会议时间"、"是一个任务"、"记录想法"等。
        """

        // 如果有 Memory 上下文，添加到 prompt
        if let memoryContext = memoryContext, !memoryContext.isEmpty {
            systemPrompt += "\n\n参考以下用户上下文信息，以更准确地分类：\n\(memoryContext)"
        }

        // 从环境变量读取模型名，默认使用 qwen-plus
        let modelName = ProcessInfo.processInfo.environment["LLM_MODEL"] ?? "qwen-plus"

        let query = ChatQuery(
            messages: [
                .init(role: .system, content: systemPrompt)!,
                .init(role: .user, content: text)!
            ],
            model: .init(modelName)
        )

        let result = try await openAI.chats(query: query)

        guard let content = result.choices.first?.message.content else {
            throw AIAssistantError.invalidResponse
        }

        return try parseClassification(from: content)
    }

    /// 解析分类结果
    private func parseClassification(from json: String) throws -> Classification {
        guard let data = json.data(using: .utf8) else {
            throw AIAssistantError.invalidResponse
        }

        struct LLMResponse: Decodable {
            let container: String
            let extractedTime: String?
            let suggestedPriority: String
            let summary: String
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(LLMResponse.self, from: data)

        let containerType: ContainerType
        switch response.container.lowercased() {
        case "calendar": containerType = .calendar
        case "todo": containerType = .todo
        default: containerType = .note
        }

        let priority: Priority = response.suggestedPriority == "important" ? .important : .normal

        var extractedTime: Date?
        if let timeString = response.extractedTime {
            let formatter = ISO8601DateFormatter()
            extractedTime = formatter.date(from: timeString)
        }

        return Classification(
            container: containerType,
            extractedTime: extractedTime,
            suggestedPriority: priority,
            summary: response.summary
        )
    }
}
