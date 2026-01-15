import SwiftUI
import SwiftData

/// 主面板视图 - 统一的功能入口
struct MainPanelView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings

    @State private var selectedSection: SidebarSection = .capture

    /// 侧边栏分区
    enum SidebarSection: String, CaseIterable, Identifiable {
        case capture = "捕获箱"
        case calendar = "日历"
        case todo = "待办"
        case notes = "笔记"
        case achievement = "成就"
        case timesheet = "工时表"
        case today = "今日概览"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .capture: return "tray.full"
            case .calendar: return "calendar"
            case .todo: return "checklist"
            case .notes: return "note.text"
            case .achievement: return "trophy"
            case .timesheet: return "clock.badge.checkmark"
            case .today: return "sun.horizon.fill"
            }
        }

        var color: Color {
            switch self {
            case .capture: return .blue
            case .calendar: return .red
            case .todo: return .orange
            case .notes: return .green
            case .achievement: return .purple
            case .timesheet: return .indigo
            case .today: return .yellow
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - 侧边栏
    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section {
                ForEach(SidebarSection.allCases.filter { $0 != .today }) { section in
                    sidebarItem(section)
                }
            }

            Section {
                sidebarItem(.today)
            }

            Section {
                Button {
                    openSettings()
                } label: {
                    Label("设置", systemImage: "gear")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AI Assistant")
        .frame(minWidth: 180)
    }

    /// 侧边栏项
    private func sidebarItem(_ section: SidebarSection) -> some View {
        Label {
            Text(section.rawValue)
        } icon: {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
        }
        .tag(section)
    }

    // MARK: - 内容区域
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .capture:
            CaptureListContentView()
        case .calendar:
            CalendarListView()
        case .todo:
            TodoListView()
        case .notes:
            NotesListView()
        case .achievement:
            AchievementView()
        case .timesheet:
            TimeSheetView()
        case .today:
            TodayOverviewView()
        }
    }
}

/// 捕获箱内容视图（从 CaptureListView 提取，去除外层 NavigationSplitView）
struct CaptureListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaptureItem.createdAt, order: .reverse) private var allCaptures: [CaptureItem]

    @State private var selectedCapture: CaptureItem?
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var captureToDelete: CaptureItem?

    /// 过滤后的捕获项
    private var filteredCaptures: [CaptureItem] {
        if searchText.isEmpty {
            return allCaptures
        }
        return allCaptures.filter { capture in
            capture.content.localizedCaseInsensitiveContains(searchText) ||
            (capture.aiSummary?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// 待处理项
    private var pendingCaptures: [CaptureItem] {
        filteredCaptures.filter { $0.status == .pending || $0.status == .failed }
    }

    /// 已处理项
    private var processedCaptures: [CaptureItem] {
        filteredCaptures.filter { $0.status == .confirmed }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCapture) {
                if !pendingCaptures.isEmpty {
                    Section("待处理 (\(pendingCaptures.count))") {
                        ForEach(pendingCaptures) { capture in
                            CaptureRowView(capture: capture)
                                .tag(capture)
                                .contextMenu {
                                    contextMenuItems(for: capture)
                                }
                        }
                    }
                }

                if !processedCaptures.isEmpty {
                    Section("已处理 (\(processedCaptures.count))") {
                        ForEach(processedCaptures) { capture in
                            CaptureRowView(capture: capture)
                                .tag(capture)
                                .contextMenu {
                                    contextMenuItems(for: capture)
                                }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "搜索捕获...")
            .navigationTitle("捕获箱")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        CaptureWindowController.shared.showWindow()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("新建捕获")
                }
            }
        } detail: {
            if let capture = selectedCapture {
                CaptureDetailView(capture: capture)
            } else {
                ContentUnavailableView(
                    "选择一个捕获项",
                    systemImage: "tray",
                    description: Text("从左侧列表选择查看详情")
                )
            }
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let capture = captureToDelete {
                    deleteCapture(capture)
                }
            }
        } message: {
            Text("确定要删除这个捕获项吗？此操作无法撤销。")
        }
    }

    @ViewBuilder
    private func contextMenuItems(for capture: CaptureItem) -> some View {
        Button {
            Task {
                await reclassifyCapture(capture)
            }
        } label: {
            Label("重新分类", systemImage: "arrow.triangle.2.circlepath")
        }
        .disabled(!LLMService.shared.isConfigured)

        Divider()

        Button(role: .destructive) {
            captureToDelete = capture
            showingDeleteConfirmation = true
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    private func reclassifyCapture(_ capture: CaptureItem) async {
        guard LLMService.shared.isConfigured else { return }

        capture.status = .pending

        do {
            let classification = try await LLMService.shared.classifyWithMemory(capture.content)

            ContainerConversionService.shared.autoConvert(
                capture,
                classification: classification,
                in: modelContext
            )

            try modelContext.save()
        } catch {
            capture.status = .failed
        }
    }

    private func deleteCapture(_ capture: CaptureItem) {
        if selectedCapture == capture {
            selectedCapture = nil
        }
        modelContext.delete(capture)
        try? modelContext.save()
    }
}

#Preview {
    MainPanelView()
        .environment(AppState())
        .modelContainer(DataContainer.previewContainer)
}
