import SwiftUI
import SwiftData

/// 视图模式
enum CalendarViewMode: String, CaseIterable {
    case list = "列表"
    case timeline = "时间线"
}

/// 日历事件列表视图
struct CalendarListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startTime)
    private var allEvents: [CalendarEvent]

    @State private var selectedEvent: CalendarEvent?
    @State private var showingAddSheet = false
    @State private var viewMode: CalendarViewMode = .timeline

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // 视图模式切换
                Picker("视图", selection: $viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // 内容区域
                switch viewMode {
                case .list:
                    calendarListContent
                case .timeline:
                    Calendar3DTimelineView(
                        pastEvents: pastEvents,
                        todayEvents: todayEvents,
                        futureEvents: futureEvents,
                        selectedEvent: $selectedEvent
                    )
                }
            }
            .navigationTitle("日历")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("新建事件", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CalendarEventEditView(event: nil)
            }
        } detail: {
            if let event = selectedEvent {
                CalendarEventDetailView(event: event)
            } else {
                ContentUnavailableView(
                    "选择一个事件",
                    systemImage: "calendar",
                    description: Text("从左侧列表选择查看详情")
                )
            }
        }
    }

    // MARK: - 列表视图内容
    private var calendarListContent: some View {
        List(selection: $selectedEvent) {
            // 今日事件
            if !todayEvents.isEmpty {
                Section("今日") {
                    ForEach(todayEvents) { event in
                        CalendarEventRow(event: event)
                            .tag(event)
                    }
                }
            }

            // 即将到来
            if !futureEvents.isEmpty {
                Section("即将到来") {
                    ForEach(futureEvents) { event in
                        CalendarEventRow(event: event)
                            .tag(event)
                    }
                }
            }

            // 已完成
            if !pastEvents.isEmpty {
                Section("已完成") {
                    ForEach(pastEvents) { event in
                        CalendarEventRow(event: event)
                            .tag(event)
                    }
                }
            }
        }
    }

    // MARK: - 过去事件（已完成）
    private var pastEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allEvents.filter { $0.startTime < today || $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
    }

    // MARK: - 今日事件
    private var todayEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return allEvents.filter { event in
            !event.isCompleted && event.startTime >= today && event.startTime < tomorrow
        }
    }

    // MARK: - 未来事件
    private var futureEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!

        return allEvents.filter { event in
            !event.isCompleted && event.startTime >= tomorrow
        }
    }
}

// MARK: - 3D 时间线视图
struct Calendar3DTimelineView: View {
    let pastEvents: [CalendarEvent]
    let todayEvents: [CalendarEvent]
    let futureEvents: [CalendarEvent]
    @Binding var selectedEvent: CalendarEvent?

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 过去区域（成就）
                TimelineSection(
                    title: "过去 · 成就",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    perspective: .past,
                    events: pastEvents.prefix(5).map { $0 },
                    selectedEvent: $selectedEvent,
                    emptyMessage: "暂无已完成事件"
                )

                // 当前区域
                TimelineSection(
                    title: "现在 · 今日",
                    icon: "star.fill",
                    color: .orange,
                    perspective: .present,
                    events: todayEvents,
                    selectedEvent: $selectedEvent,
                    emptyMessage: "今日无安排"
                )

                // 未来区域
                TimelineSection(
                    title: "未来 · 安心",
                    icon: "arrow.forward.circle.fill",
                    color: .blue,
                    perspective: .future,
                    events: futureEvents.prefix(5).map { $0 },
                    selectedEvent: $selectedEvent,
                    emptyMessage: "暂无未来安排"
                )
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.green.opacity(0.05), .orange.opacity(0.1), .blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - 时间线透视
enum TimelinePerspective {
    case past, present, future

    var opacity: Double {
        switch self {
        case .past: return 0.7
        case .present: return 1.0
        case .future: return 0.85
        }
    }

    var scale: CGFloat {
        switch self {
        case .past: return 0.92
        case .present: return 1.0
        case .future: return 0.96
        }
    }

    var blur: CGFloat {
        switch self {
        case .past: return 0.5
        case .present: return 0
        case .future: return 0.2
        }
    }
}

// MARK: - 时间线区块
struct TimelineSection: View {
    let title: String
    let icon: String
    let color: Color
    let perspective: TimelinePerspective
    let events: [CalendarEvent]
    @Binding var selectedEvent: CalendarEvent?
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 区块标题
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
                Text("\(events.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .clipShape(Capsule())
            }

            // 事件卡片
            if events.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 8) {
                    ForEach(events) { event in
                        TimelineEventCard(
                            event: event,
                            perspective: perspective,
                            isSelected: selectedEvent?.id == event.id
                        )
                        .onTapGesture {
                            selectedEvent = event
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 5, y: 2)
        )
        .scaleEffect(perspective.scale)
        .opacity(perspective.opacity)
        .blur(radius: perspective.blur)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: perspective == .past ? "checkmark.circle" : "calendar.badge.clock")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - 时间线事件卡片
struct TimelineEventCard: View {
    let event: CalendarEvent
    let perspective: TimelinePerspective
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // 时间
            VStack(alignment: .leading, spacing: 2) {
                if perspective == .past {
                    Text(event.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(event.startTime.formatted(.dateTime.hour().minute()))
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)
            }
            .frame(width: 60, alignment: .leading)

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .strikethrough(event.isCompleted)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 成就徽章（仅过去事件）
            if perspective == .past && event.isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            // 优先级
            if event.priority == .important {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
    }

    private var statusColor: Color {
        if event.isCompleted { return .green }
        if event.priority == .important { return .red }
        return .blue
    }
}

// MARK: - 日历事件行
struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack {
            // 时间指示器
            VStack(alignment: .center, spacing: 2) {
                Text(event.startTime.formatted(.dateTime.hour().minute()))
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)

                if !event.isAllDay {
                    Text(event.endTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50)

            Rectangle()
                .fill(priorityColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .fontWeight(.medium)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if event.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch event.priority {
        case .important: return .red
        case .normal: return .blue
        }
    }
}

// MARK: - 日历事件详情视图
struct CalendarEventDetailView: View {
    @Bindable var event: CalendarEvent
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和状态
                HStack {
                    Text(event.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        event.isCompleted.toggle()
                    } label: {
                        Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(event.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // 时间信息
                GroupBox("时间") {
                    VStack(alignment: .leading, spacing: 8) {
                        if event.isAllDay {
                            LabeledContent("日期", value: event.startTime.formatted(date: .long, time: .omitted))
                            LabeledContent("全天事件", value: "是")
                        } else {
                            LabeledContent("开始", value: event.startTime.formatted())
                            LabeledContent("结束", value: event.endTime.formatted())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 地点
                if let location = event.location, !location.isEmpty {
                    GroupBox("地点") {
                        Text(location)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 备注
                if let notes = event.notes, !notes.isEmpty {
                    GroupBox("备注") {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 元信息
                GroupBox("信息") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("优先级", value: event.priority.rawValue)
                        LabeledContent("创建于", value: event.createdAt.formatted())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("事件详情")
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
                    modelContext.delete(event)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CalendarEventEditView(event: event)
        }
    }
}

// MARK: - 日历事件编辑视图
struct CalendarEventEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var event: CalendarEvent?

    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var location = ""
    @State private var notes = ""
    @State private var priority: Priority = .normal

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }

                Section("时间") {
                    Toggle("全天事件", isOn: $isAllDay)

                    if isAllDay {
                        DatePicker("日期", selection: $startTime, displayedComponents: .date)
                    } else {
                        DatePicker("开始", selection: $startTime)
                        DatePicker("结束", selection: $endTime)
                    }
                }

                Section("详情") {
                    TextField("地点", text: $location)
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(event == nil ? "新建事件" : "编辑事件")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let event = event {
                    title = event.title
                    startTime = event.startTime
                    endTime = event.endTime
                    isAllDay = event.isAllDay
                    location = event.location ?? ""
                    notes = event.notes ?? ""
                    priority = event.priority
                }
            }
        }
    }

    private func saveEvent() {
        if let event = event {
            // 更新现有事件
            event.title = title
            event.startTime = startTime
            event.endTime = isAllDay ? startTime : endTime
            event.isAllDay = isAllDay
            event.location = location.isEmpty ? nil : location
            event.notes = notes.isEmpty ? nil : notes
            event.priority = priority
            event.updatedAt = Date()
        } else {
            // 创建新事件
            let newEvent = CalendarEvent(
                title: title,
                startTime: startTime,
                endTime: isAllDay ? startTime : endTime,
                isAllDay: isAllDay,
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes,
                priority: priority
            )
            modelContext.insert(newEvent)
        }
    }
}

#Preview {
    CalendarListView()
        .modelContainer(DataContainer.previewContainer)
}
