import Foundation

/// 统一错误枚举
enum AIAssistantError: LocalizedError {
    case networkUnavailable
    case llmServiceError(String)
    case invalidResponse
    case storageError(String)
    case ocrFailed(String)
    case notImplemented
    case configurationMissing(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络不可用"
        case .llmServiceError(let msg):
            return "AI 服务错误：\(msg)"
        case .invalidResponse:
            return "无效响应"
        case .storageError(let msg):
            return "存储错误：\(msg)"
        case .ocrFailed(let msg):
            return "图片识别失败：\(msg)"
        case .notImplemented:
            return "功能尚未实现"
        case .configurationMissing(let key):
            return "配置缺失：\(key)"
        case .unknown(let msg):
            return "未知错误：\(msg)"
        }
    }
}
