import Foundation
import Security

/// Keychain 服务 - 安全存储 API Key
final class KeychainService {
    /// 服务标识
    private static let service = "com.henry.AIAssistant"

    /// 保存密钥
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AIAssistantError.storageError("无法编码数据")
        }

        // 删除已存在的
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // 添加新的
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AIAssistantError.storageError("Keychain 保存失败: \(status)")
        }
    }

    /// 读取密钥
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// 删除密钥
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - 便捷方法

    /// 获取 Dashscope API Key
    static func getDashscopeKey() -> String? {
        get(key: "dashscope_api_key")
    }

    /// 保存 Dashscope API Key
    static func saveDashscopeKey(_ value: String) throws {
        try save(key: "dashscope_api_key", value: value)
    }
}
