import SwiftUI
import SwiftData
import KeyboardShortcuts

@main
struct AIAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// SwiftData 容器
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try DataContainer.createContainer()
            // 立即初始化 AppEnvironment（在任何 UI 创建之前）
            let appState = AppState()
            AppEnvironment.initialize(modelContainer: modelContainer, appState: appState)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        // 菜单栏 - 简化为快速捕获入口
        MenuBarExtra {
            MenuBarContentView()
                .environment(AppEnvironment.shared.appState)
                .modelContainer(modelContainer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                if AppEnvironment.shared.appState.pendingCaptureCount > 0 {
                    Text("\(AppEnvironment.shared.appState.pendingCaptureCount)")
                        .font(.caption2)
                }
            }
        }
        .menuBarExtraStyle(.window)

        // 设置窗口
        Settings {
            SettingsView()
                .environment(AppEnvironment.shared.appState)
                .modelContainer(modelContainer)
        }

        // 主面板窗口（启动时自动显示）
        Window("AI Assistant", id: "main-panel") {
            MainPanelView()
                .environment(AppEnvironment.shared.appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 1000, height: 700)
        .defaultLaunchBehavior(.presented)
    }
}

/// 菜单栏弹出窗口内容（简化版 - 快速捕获入口）
struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(\.dismiss) private var dismiss
    @Query private var allCaptures: [CaptureItem]

    /// 点击菜单栏直接打开捕获
    @AppStorage("directCaptureOnMenuBarClick") private var directCaptureMode = false

    private var pendingCaptures: [CaptureItem] {
        allCaptures.filter { $0.status == .pending }
    }

    var body: some View {
        VStack(spacing: 12) {
            // 快速捕获按钮
            Button {
                CaptureWindowController.shared.showWindow()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("新建捕获")
                    Spacer()
                    Text("⌘⇧V")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Divider()

            // 打开主面板
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main-panel")
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "macwindow")
                        .foregroundStyle(.blue)
                    Text("打开主面板")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider()

            // 底部操作
            HStack {
                Button("设置...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .padding(12)
        .frame(width: 240)
        .onChange(of: pendingCaptures.count, initial: true) { _, newCount in
            appState.updatePendingCount(newCount)
        }
        .onAppear {
            // 如果启用了直接捕获模式，立即打开捕获窗口
            if directCaptureMode {
                CaptureWindowController.shared.showWindow()
                dismiss()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openDashboard)) { _ in
            // 点击 Dock 图标时打开主面板
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main-panel")
        }
    }
}

/// 设置视图
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            MemorySettingsView()
                .tabItem {
                    Label("Memory", systemImage: "brain")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
        }
        .frame(width: 600, height: 500)
    }
}

/// 通用设置
struct GeneralSettingsView: View {
    @State private var apiKey = ""
    @State private var showingSaveConfirmation = false
    @State private var isConfigured = LLMService.shared.isConfigured

    /// API 测试状态
    @State private var isTesting = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    /// 点击菜单栏直接打开捕获
    @AppStorage("directCaptureOnMenuBarClick") private var directCaptureMode = false

    var body: some View {
        Form {
            Section("AI 服务配置") {
                HStack {
                    Text("状态")
                    Spacer()

                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("测试中...")
                            .foregroundStyle(.secondary)
                    } else if let result = testResult {
                        switch result {
                        case .success:
                            Label("连接成功", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .failure(let error):
                            Label("连接失败", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .help(error)
                        }
                    } else if isConfigured {
                        Label("已配置", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("未配置", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    if isConfigured && !isTesting {
                        Button("测试") {
                            testAPIConnection()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SecureField("Dashscope API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                Button("保存 API Key") {
                    saveApiKey()
                }
                .disabled(apiKey.isEmpty)

                Text("API Key 将安全存储在 Keychain 中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("菜单栏") {
                Toggle("点击菜单栏直接打开捕获窗口", isOn: $directCaptureMode)
                Text("启用后点击菜单栏图标将直接弹出捕获输入框")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .alert("保存成功", isPresented: $showingSaveConfirmation) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("API Key 已保存，AI 分类功能已启用。")
        }
        .onAppear {
            isConfigured = LLMService.shared.isConfigured
        }
    }

    private func saveApiKey() {
        do {
            try LLMService.shared.reconfigure(with: apiKey)
            apiKey = ""
            isConfigured = true
            testResult = nil  // 重置测试结果
            showingSaveConfirmation = true
        } catch {
            print("[Settings] Failed to save API key: \(error.localizedDescription)")
        }
    }

    private func testAPIConnection() {
        isTesting = true
        testResult = nil

        Task {
            do {
                _ = try await LLMService.shared.testConnection()
                testResult = .success
            } catch {
                testResult = .failure(error.localizedDescription)
            }
            isTesting = false
        }
    }
}

/// Memory 设置
struct MemorySettingsView: View {
    @State private var memoryContent: String = ""
    @State private var showingSaveConfirmation = false
    @State private var hasUnsavedChanges = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 说明
            VStack(alignment: .leading, spacing: 4) {
                Text("个人上下文 (Memory)")
                    .font(.headline)
                Text("在此编辑你的个人偏好和上下文信息，AI 会根据这些内容更准确地分类你的输入。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 编辑器
            TextEditor(text: $memoryContent)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.secondary.opacity(0.3), width: 1)
                .onChange(of: memoryContent) { _, _ in
                    hasUnsavedChanges = true
                }

            // 底部工具栏
            HStack {
                // 文件位置
                Button {
                    revealInFinder()
                } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
                .buttonStyle(.link)

                Spacer()

                // 状态
                if hasUnsavedChanges {
                    Text("有未保存的更改")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                // 保存按钮
                Button("保存") {
                    saveMemory()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasUnsavedChanges)
            }
        }
        .padding()
        .onAppear {
            loadMemory()
        }
        .alert("保存成功", isPresented: $showingSaveConfirmation) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("Memory 已保存，下次分类时将使用新的上下文。")
        }
    }

    private func loadMemory() {
        memoryContent = MemoryManager.shared.getRawContent()
        hasUnsavedChanges = false
    }

    private func saveMemory() {
        do {
            try MemoryManager.shared.saveMemory(memoryContent)
            hasUnsavedChanges = false
            showingSaveConfirmation = true
        } catch {
            print("[MemorySettings] Failed to save: \(error.localizedDescription)")
        }
    }

    private func revealInFinder() {
        let url = MemoryManager.shared.memoryFilePath
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}

/// 快捷键设置
struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("快速捕获:", name: .quickCapture)
        }
        .padding()
    }
}

#Preview("MenuBar Content") {
    MenuBarContentView()
        .environment(AppState())
}
