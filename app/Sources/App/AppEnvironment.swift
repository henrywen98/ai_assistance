import Foundation
import SwiftData

/// 应用环境 - 管理全局依赖
/// 使用强制初始化，不再使用可选值
@MainActor
final class AppEnvironment {
    /// 单例（延迟初始化，但一旦初始化就不可变）
    static var shared: AppEnvironment!

    /// SwiftData 模型容器（非可选）
    let modelContainer: ModelContainer

    /// 应用状态（非可选）
    let appState: AppState

    /// 私有初始化器
    private init(modelContainer: ModelContainer, appState: AppState) {
        self.modelContainer = modelContainer
        self.appState = appState
    }

    /// 初始化单例（必须在应用启动时调用一次）
    static func initialize(modelContainer: ModelContainer, appState: AppState) {
        guard shared == nil else {
            fatalError("AppEnvironment already initialized")
        }
        shared = AppEnvironment(modelContainer: modelContainer, appState: appState)
    }
}
