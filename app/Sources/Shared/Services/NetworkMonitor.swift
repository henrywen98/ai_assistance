import Foundation
import Network
import os

/// 网络状态监听服务
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let logger = Logger(subsystem: "com.henry.AIAssistant", category: "NetworkMonitor")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.henry.AIAssistant.NetworkMonitor")

    private(set) var isConnected = true
    private var isStarted = false

    /// 网络恢复时的回调
    var onNetworkRestored: (() -> Void)?

    private init() {}

    /// 启动网络监听
    func start() {
        guard !isStarted else {
            logger.warning("网络监听已启动，忽略重复调用")
            return
        }

        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }

        monitor.start(queue: queue)
        logger.info("网络监听已启动")
    }

    /// 停止网络监听
    func stop() {
        guard isStarted else { return }

        monitor.cancel()
        isStarted = false
        logger.info("网络监听已停止")
    }

    private func handlePathUpdate(_ path: NWPath) {
        let wasDisconnected = !isConnected
        isConnected = path.status == .satisfied

        if isConnected && wasDisconnected {
            logger.info("网络已恢复连接")
            onNetworkRestored?()
        } else if !isConnected {
            logger.warning("网络已断开")
        }
    }
}
