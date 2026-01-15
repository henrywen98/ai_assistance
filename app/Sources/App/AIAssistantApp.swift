import SwiftUI
import SwiftData
import KeyboardShortcuts

@main
struct AIAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 全局应用状态
    @State private var appState = AppState()

    /// SwiftData 容器
    var modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try DataContainer.createContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // 配置全局环境
        AppEnvironment.shared.configure(modelContainer: modelContainer, appState: appState)
    }

    var body: some Scene {
        // 菜单栏应用 - Story 1.2
        MenuBarExtra {
            MenuBarContentView()
                .environment(appState)
                .modelContainer(modelContainer)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                if appState.pendingCaptureCount > 0 {
                    Text("\(appState.pendingCaptureCount)")
                        .font(.caption2)
                }
            }
        }
        .menuBarExtraStyle(.window)

        // 设置窗口
        Settings {
            SettingsView()
                .environment(appState)
                .modelContainer(modelContainer)
        }

        // 捕获列表窗口
        Window("捕获箱", id: "capture-list") {
            CaptureListView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 800, height: 600)

        // 日历窗口
        Window("日历", id: "calendar") {
            CalendarListView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 900, height: 600)

        // 待办窗口
        Window("待办", id: "todo") {
            TodoListView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 800, height: 600)

        // 笔记窗口
        Window("笔记", id: "notes") {
            NotesListView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 800, height: 600)

        // 成就窗口
        Window("成就", id: "achievement") {
            AchievementView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 900, height: 600)

        // 今日概览窗口
        Window("今日概览", id: "today-overview") {
            TodayOverviewView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Time Sheet 窗口
        Window("Time Sheet", id: "timesheet") {
            TimeSheetView()
                .environment(appState)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 700, height: 500)
    }
}

/// 菜单栏弹出窗口内容
struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Query private var allCaptures: [CaptureItem]

    private var pendingCaptures: [CaptureItem] {
        allCaptures.filter { $0.status == .pending }
    }

    var body: some View {
        let _ = updatePendingCount()
        VStack(spacing: 16) {
            // 头部
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            Divider()

            // 快速捕获区域
            VStack(spacing: 12) {
                Button {
                    CaptureWindowController.shared.showWindow()
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
                    .padding(.vertical, 8)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            Divider()

            // 快捷入口
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                QuickAccessButton(icon: "tray.full", label: "捕获箱", color: .blue) {
                    openWindow(id: "capture-list")
                }

                QuickAccessButton(icon: "sun.horizon.fill", label: "今日", color: .orange) {
                    openWindow(id: "today-overview")
                }

                QuickAccessButton(icon: "checkmark.seal.fill", label: "成就", color: .green) {
                    openWindow(id: "achievement")
                }

                QuickAccessButton(icon: "clock.badge.checkmark", label: "工时表", color: .purple) {
                    openWindow(id: "timesheet")
                }
            }

            Divider()

            // 底部操作
            HStack {
                Button("设置...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .frame(width: 280)
    }

    private func updatePendingCount() {
        appState.updatePendingCount(pendingCaptures.count)
    }
}

/// 设置视图（占位）
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 250)
    }
}

/// 通用设置
struct GeneralSettingsView: View {
    @State private var apiKey = ""
    @State private var showingSaveConfirmation = false
    @State private var isConfigured = LLMService.shared.isConfigured

    var body: some View {
        Form {
            Section("AI 服务配置") {
                HStack {
                    Text("状态")
                    Spacer()
                    if isConfigured {
                        Label("已配置", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("未配置", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
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
            showingSaveConfirmation = true
        } catch {
            // Handle error
        }
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

/// 快捷入口按钮
struct QuickAccessButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview("MenuBar Content") {
    MenuBarContentView()
        .environment(AppState())
}
