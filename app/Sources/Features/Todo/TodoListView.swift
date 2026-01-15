import SwiftUI
import SwiftData

/// 待办事项列表视图
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var allTodos: [TodoItem]

    @State private var selectedTodo: TodoItem?
    @State private var showingAddSheet = false
    @State private var filterCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            todoToolbar

            // 待办列表
            List {
                // 未完成
                if !pendingTodos.isEmpty {
                    Section("待完成 (\(pendingTodos.count))") {
                        ForEach(pendingTodos) { todo in
                            TodoRow(todo: todo)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTodo = todo }
                        }
                        .onDelete(perform: deleteTodos)
                    }
                }

                // 已完成
                if filterCompleted && !completedTodos.isEmpty {
                    Section("已完成 (\(completedTodos.count))") {
                        ForEach(completedTodos) { todo in
                            TodoRow(todo: todo)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTodo = todo }
                        }
                        .onDelete(perform: deleteCompletedTodos)
                    }
                }

                // 空状态
                if pendingTodos.isEmpty && (!filterCompleted || completedTodos.isEmpty) {
                    ContentUnavailableView(
                        "暂无待办",
                        systemImage: "checklist",
                        description: Text("点击右上角 + 创建新待办")
                    )
                }
            }
        }
        .sheet(item: $selectedTodo) { todo in
            TodoDetailSheet(todo: todo)
        }
        .sheet(isPresented: $showingAddSheet) {
            TodoEditView(todo: nil)
        }
    }

    // MARK: - 工具栏
    private var todoToolbar: some View {
        HStack {
            Text("待办事项")
                .font(.headline)

            Spacer()

            Toggle(isOn: $filterCompleted) {
                Label("显示已完成", systemImage: "checkmark.circle")
            }
            .toggleStyle(.button)
            .controlSize(.small)

            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var pendingTodos: [TodoItem] {
        allTodos.filter { !$0.isCompleted }
    }

    private var completedTodos: [TodoItem] {
        allTodos.filter { $0.isCompleted }
    }

    private func deleteTodos(at offsets: IndexSet) {
        for index in offsets {
            let todo = pendingTodos[index]
            modelContext.delete(todo)
        }
    }

    private func deleteCompletedTodos(at offsets: IndexSet) {
        for index in offsets {
            let todo = completedTodos[index]
            modelContext.delete(todo)
        }
    }
}

// MARK: - 待办行
struct TodoRow: View {
    @Bindable var todo: TodoItem

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    todo.isCompleted.toggle()
                    if todo.isCompleted {
                        todo.completedAt = Date()
                    } else {
                        todo.completedAt = nil
                    }
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let dueDate = todo.dueDate {
                        Label(dueDate.formatted(.relative(presentation: .named)), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(isDueSoon(dueDate) ? .red : .secondary)
                    }

                    if todo.priority == .important {
                        Label("重要", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func isDueSoon(_ date: Date) -> Bool {
        date < Date().addingTimeInterval(86400) && date > Date()
    }
}

// MARK: - 待办详情 Sheet
struct TodoDetailSheet: View {
    @Bindable var todo: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和完成状态
                    HStack {
                        Button {
                            withAnimation {
                                todo.isCompleted.toggle()
                                if todo.isCompleted {
                                    todo.completedAt = Date()
                                } else {
                                    todo.completedAt = nil
                                }
                            }
                        } label: {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title)
                                .foregroundStyle(todo.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(todo.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .strikethrough(todo.isCompleted)
                    }

                    Divider()

                    // 信息
                    VStack(alignment: .leading, spacing: 12) {
                        if todo.priority == .important {
                            Label("重要", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        }

                        if let dueDate = todo.dueDate {
                            Label {
                                Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.blue)
                            }
                        }

                        if let completedAt = todo.completedAt {
                            Label {
                                Text("完成于 \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            } icon: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    // 备注
                    if let itemDescription = todo.itemDescription, !itemDescription.isEmpty {
                        Divider()
                        Text(itemDescription)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("待办详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            modelContext.delete(todo)
                            dismiss()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .frame(minWidth: 350, minHeight: 300)
        .sheet(isPresented: $showingEditSheet) {
            TodoEditView(todo: todo)
        }
    }
}

// MARK: - 待办编辑
struct TodoEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var todo: TodoItem?

    @State private var title = ""
    @State private var itemDescription = ""
    @State private var priority: Priority = .normal
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("备注") {
                    TextField("备注", text: $itemDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(todo == nil ? "新建待办" : "编辑待办")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTodo()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let todo = todo {
                    title = todo.title
                    itemDescription = todo.itemDescription ?? ""
                    priority = todo.priority
                    hasDueDate = todo.dueDate != nil
                    dueDate = todo.dueDate ?? Date()
                }
            }
        }
    }

    private func saveTodo() {
        if let todo = todo {
            todo.title = title
            todo.itemDescription = itemDescription.isEmpty ? nil : itemDescription
            todo.priority = priority
            todo.dueDate = hasDueDate ? dueDate : nil
            todo.updatedAt = Date()
        } else {
            let newTodo = TodoItem(
                title: title,
                itemDescription: itemDescription.isEmpty ? nil : itemDescription,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil
            )
            modelContext.insert(newTodo)
        }
    }
}

#Preview {
    TodoListView()
        .modelContainer(DataContainer.previewContainer)
}
