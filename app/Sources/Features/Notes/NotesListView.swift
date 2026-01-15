import SwiftUI
import SwiftData

/// 笔记列表视图
struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var selectedNote: Note?
    @State private var showingAddSheet = false
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            List(filteredNotes, selection: $selectedNote) { note in
                NoteRow(note: note)
                    .tag(note)
            }
            .searchable(text: $searchText, prompt: "搜索笔记...")
            .navigationTitle("笔记")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewNote()
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let note = selectedNote {
                NoteDetailView(note: note)
            } else {
                ContentUnavailableView(
                    "选择一篇笔记",
                    systemImage: "note.text",
                    description: Text("从左侧列表选择查看或编辑")
                )
            }
        }
    }

    private var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            (note.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            note.content.localizedCaseInsensitiveContains(searchText) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func createNewNote() {
        let newNote = Note(
            content: "",
            title: "新笔记"
        )
        modelContext.insert(newNote)
        selectedNote = newNote
    }
}

// MARK: - 笔记行
struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "无标题")
                .fontWeight(.medium)
                .lineLimit(1)

            Text(note.content.isEmpty ? "无内容" : note.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(note.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if !note.tags.isEmpty {
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 笔记详情/编辑视图
struct NoteDetailView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editingTitle = ""

    /// 上一次同步的笔记 ID，用于检测笔记切换
    @State private var lastSyncedNoteId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // 标题编辑
            TextField("标题", text: $editingTitle)
                .font(.title)
                .fontWeight(.bold)
                .textFieldStyle(.plain)
                .padding()
                .onChange(of: editingTitle) { oldValue, newValue in
                    // 跳过初始同步或无变化的情况
                    guard lastSyncedNoteId == note.id, oldValue != newValue else { return }
                    note.title = newValue.isEmpty ? nil : newValue
                    note.updatedAt = Date()
                }
                .onChange(of: note.id) { _, newId in
                    syncTitle(for: newId)
                }
                .onAppear {
                    syncTitle(for: note.id)
                }

            Divider()

            // 内容编辑
            TextEditor(text: $note.content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding()
                .onChange(of: note.content) {
                    note.updatedAt = Date()
                }

            Divider()

            // 标签区域
            tagsSection
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("编辑标签", systemImage: "tag")
                    }

                    Divider()

                    Button(role: .destructive) {
                        modelContext.delete(note)
                    } label: {
                        Label("删除笔记", systemImage: "trash")
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NoteTagsEditView(note: note)
        }
    }

    private var tagsSection: some View {
        HStack {
            Image(systemName: "tag")
                .foregroundStyle(.secondary)

            let noteTags = note.tags
            if noteTags.isEmpty {
                Text("无标签")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(noteTags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Button {
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.quaternary)
    }

    /// 同步标题状态，标记当前笔记 ID 以区分用户编辑和初始加载
    private func syncTitle(for noteId: UUID) {
        editingTitle = note.title ?? ""
        lastSyncedNoteId = noteId
    }
}

// MARK: - 标签编辑视图
struct NoteTagsEditView: View {
    var note: Note
    @Environment(\.dismiss) private var dismiss
    @State private var tagsText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("标签") {
                    TextField("输入标签，用逗号分隔", text: $tagsText)
                    Text("当前标签将被替换为新输入的标签")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("当前标签") {
                    let currentTags = note.tags
                    if currentTags.isEmpty {
                        Text("无标签")
                            .foregroundStyle(.secondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(currentTags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("编辑标签")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTags()
                        dismiss()
                    }
                }
            }
            .onAppear {
                tagsText = note.tags.joined(separator: ", ")
            }
        }
    }

    private func saveTags() {
        let newTags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        note.tags = newTags
        note.updatedAt = Date()
    }
}

// MARK: - 流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

#Preview {
    NotesListView()
        .modelContainer(DataContainer.previewContainer)
}
