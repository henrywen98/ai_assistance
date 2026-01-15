import Foundation
import SwiftData

/// 应用环境 - 管理全局依赖
@MainActor
final class AppEnvironment {
    /// 单例
    static let shared = AppEnvironment()

    /// SwiftData 模型容器
    var modelContainer: ModelContainer?

    /// 应用状态
    var appState: AppState?

    /// 是否已配置
    private var isConfigured = false

    private init() {}

    /// 配置环境（只执行一次）
    func configure(modelContainer: ModelContainer, appState: AppState) {
        guard !isConfigured else { return }
        self.modelContainer = modelContainer
        self.appState = appState
        self.isConfigured = true
    }
}
