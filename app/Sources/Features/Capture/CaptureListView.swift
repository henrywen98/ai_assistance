import SwiftUI
import SwiftData

/// 捕获列表视图 - 显示所有捕获项
struct CaptureListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaptureItem.createdAt, order: .reverse) private var captures: [CaptureItem]

    @State private var selectedCapture: CaptureItem?
    @State private var selectedCaptures: Set<CaptureItem.ID> = []
    @State private var searchText = ""
    @State private var isInBatchMode = false
    @State private var isProcessingBatch = false

    var body: some View {
        NavigationSplitView {
            List(filteredCaptures, selection: isInBatchMode ? $selectedCaptures : nil) { capture in
                CaptureRowView(capture: capture)
                    .tag(capture.id)
                    .contextMenu {
                        captureContextMenu(for: capture)
                    }
                    .onTapGesture {
                        if !isInBatchMode {
                            selectedCapture = capture
                        }
                    }
            }
            .searchable(text: $searchText, prompt: "搜索捕获...")
            .navigationTitle("捕获箱")
            .toolbar {
                // 批量模式工具栏
                if isInBatchMode {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Text("\(selectedCaptures.count) 项已选")
                            .foregroundStyle(.secondary)

                        Menu("批量操作") {
                            Button {
                                batchConvert(to: .calendar)
                            } label: {
                                Label("转为日历", systemImage: "calendar")
                            }

                            Button {
                                batchConvert(to: .todo)
                            } label: {
                                Label("转为待办", systemImage: "checklist")
                            }

                            Button {
                                batchConvert(to: .note)
                            } label: {
                                Label("转为笔记", systemImage: "note.text")
                            }

                            Divider()

                            Button(role: .destructive) {
                                batchDelete()
                            } label: {
                                Label("批量删除", systemImage: "trash")
                            }
                        }
                        .disabled(selectedCaptures.isEmpty)

                        Button("完成") {
                            isInBatchMode = false
                            selectedCaptures.removeAll()
                        }
                    }
                } else {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            isInBatchMode = true
                        } label: {
                            Label("批量处理", systemImage: "checklist.checked")
                        }
                        .disabled(captures.isEmpty)

                        Button {
                            CaptureWindowController.shared.showWindow()
                        } label: {
                            Label("新建", systemImage: "plus")
                        }
                    }
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
    }

    // MARK: - 过滤后的捕获项
    private var filteredCaptures: [CaptureItem] {
        if searchText.isEmpty {
            return captures
        }
        return captures.filter { capture in
            capture.content.localizedCaseInsensitiveContains(searchText) ||
            (capture.aiSummary?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - 上下文菜单
    @ViewBuilder
    private func captureContextMenu(for capture: CaptureItem) -> some View {
        Button {
            Task {
                await reclassifyCapture(capture)
            }
        } label: {
            Label("重新分类", systemImage: "sparkles")
        }

        Divider()

        Button {
            capture.container = .calendar
            capture.status = .confirmed
        } label: {
            Label("转为日历", systemImage: "calendar")
        }

        Button {
            capture.container = .todo
            capture.status = .confirmed
        } label: {
            Label("转为待办", systemImage: "checklist")
        }

        Button {
            capture.container = .note
            capture.status = .confirmed
        } label: {
            Label("转为笔记", systemImage: "note.text")
        }

        Divider()

        Button(role: .destructive) {
            deleteCapture(capture)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    // MARK: - 重新分类
    @MainActor
    private func reclassifyCapture(_ capture: CaptureItem) async {
        guard LLMService.shared.isConfigured else {
            print("[CaptureList] LLM service not configured")
            return
        }

        capture.status = .pending

        do {
            let classification = try await LLMService.shared.classifyWithMemory(
                capture.content,
                in: modelContext
            )

            ContainerConversionService.shared.autoConvert(
                capture,
                classification: classification,
                in: modelContext
            )

            try modelContext.save()
            print("[CaptureList] Reclassified capture: \(classification.container)")
        } catch {
            capture.status = .failed
            print("[CaptureList] Reclassify failed: \(error.localizedDescription)")
        }
    }

    // MARK: - 删除捕获项
    private func deleteCapture(_ capture: CaptureItem) {
        if selectedCapture == capture {
            selectedCapture = nil
        }
        modelContext.delete(capture)
    }

    // MARK: - 批量转换
    private func batchConvert(to container: ContainerType) {
        let selectedItems = captures.filter { selectedCaptures.contains($0.id) }
        for capture in selectedItems {
            capture.container = container
            capture.status = .confirmed
        }
        selectedCaptures.removeAll()
        isInBatchMode = false
    }

    // MARK: - 批量删除
    private func batchDelete() {
        let selectedItems = captures.filter { selectedCaptures.contains($0.id) }
        for capture in selectedItems {
            modelContext.delete(capture)
        }
        selectedCaptures.removeAll()
        isInBatchMode = false
    }
}

// MARK: - 捕获行视图
struct CaptureRowView: View {
    let capture: CaptureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusIcon
                Text(capture.aiSummary ?? capture.content.prefix(50).description)
                    .lineLimit(1)
                Spacer()
                containerBadge
            }

            Text(capture.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 状态图标
    private var statusIcon: some View {
        Group {
            switch capture.status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
            case .classified:
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
            case .confirmed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
    }

    // MARK: - 容器标签
    @ViewBuilder
    private var containerBadge: some View {
        if let container = capture.container {
            Text(container.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(containerColor.opacity(0.2))
                .foregroundStyle(containerColor)
                .clipShape(Capsule())
        }
    }

    private var containerColor: Color {
        switch capture.container {
        case .calendar: return .blue
        case .todo: return .orange
        case .note: return .green
        case .none: return .gray
        }
    }
}

// MARK: - 捕获详情视图
struct CaptureDetailView: View {
    @Bindable var capture: CaptureItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 头部信息
                headerSection

                Divider()

                // 内容
                contentSection

                // AI 分析结果
                if capture.status != .pending {
                    aiAnalysisSection
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("捕获详情")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    containerPicker
                } label: {
                    Label("分类", systemImage: "folder")
                }
            }
        }
    }

    // MARK: - 头部信息
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("创建于 \(capture.createdAt.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    statusBadge
                    if let container = capture.container {
                        Text(container.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
    }

    private var statusColor: Color {
        switch capture.status {
        case .pending: return .orange
        case .classified: return .purple
        case .confirmed: return .green
        case .failed: return .red
        }
    }

    private var statusText: String {
        switch capture.status {
        case .pending: return "待处理"
        case .classified: return "已分类"
        case .confirmed: return "已确认"
        case .failed: return "处理失败"
        }
    }

    // MARK: - 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.headline)

            Text(capture.content)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - AI 分析结果
    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI 分析")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                if let summary = capture.aiSummary {
                    LabeledContent("摘要", value: summary)
                }

                if let time = capture.extractedTime {
                    LabeledContent("提取时间", value: time.formatted())
                }

                LabeledContent("建议优先级", value: capture.suggestedPriority.rawValue)
            }
            .padding()
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - 容器选择器
    @ViewBuilder
    private var containerPicker: some View {
        ForEach(ContainerType.allCases) { container in
            Button {
                capture.container = container
                capture.status = .confirmed
            } label: {
                Label(container.displayName, systemImage: container.systemImage)
            }
        }
    }
}

#Preview {
    CaptureListView()
        .modelContainer(DataContainer.previewContainer)
}
