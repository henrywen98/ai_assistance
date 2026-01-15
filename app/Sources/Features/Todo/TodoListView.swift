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
        NavigationSplitView {
            List(selection: $selectedTodo) {
                // 未完成
                if !pendingTodos.isEmpty {
                    Section("待完成 (\(pendingTodos.count))") {
                        ForEach(pendingTodos) { todo in
                            TodoRow(todo: todo)
                                .tag(todo)
                        }
                        .onDelete(perform: deleteTodos)
                    }
                }

                // 已完成
                if filterCompleted && !completedTodos.isEmpty {
                    Section("已完成 (\(completedTodos.count))") {
                        ForEach(completedTodos) { todo in
                            TodoRow(todo: todo)
                                .tag(todo)
                        }
                        .onDelete(perform: deleteCompletedTodos)
                    }
                }
            }
            .navigationTitle("待办事项")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }

                ToolbarItem {
                    Toggle(isOn: $filterCompleted) {
                        Label("显示已完成", systemImage: "checkmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                TodoEditView(todo: nil)
            }
        } detail: {
            if let todo = selectedTodo {
                TodoDetailView(todo: todo)
            } else {
                ContentUnavailableView(
                    "选择一个待办",
                    systemImage: "checklist",
                    description: Text("从左侧列表选择查看详情")
                )
            }
        }
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
            if selectedTodo == todo {
                selectedTodo = nil
            }
            modelContext.delete(todo)
        }
    }

    private func deleteCompletedTodos(at offsets: IndexSet) {
        for index in offsets {
            let todo = completedTodos[index]
            if selectedTodo == todo {
                selectedTodo = nil
            }
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

// MARK: - 待办详情
struct TodoDetailView: View {
    @Bindable var todo: TodoItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false

    var body: some View {
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
                        .font(.title)
                        .fontWeight(.bold)
                        .strikethrough(todo.isCompleted)
                }

                // 详细信息
                if let itemDescription = todo.itemDescription, !itemDescription.isEmpty {
                    GroupBox("备注") {
                        Text(itemDescription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                GroupBox("信息") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("优先级", value: todo.priority.rawValue)

                        if let dueDate = todo.dueDate {
                            LabeledContent("截止日期", value: dueDate.formatted())
                        }

                        if let completedAt = todo.completedAt {
                            LabeledContent("完成于", value: completedAt.formatted())
                        }

                        LabeledContent("创建于", value: todo.createdAt.formatted())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("待办详情")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    modelContext.delete(todo)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
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
