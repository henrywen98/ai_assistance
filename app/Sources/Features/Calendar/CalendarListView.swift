import SwiftUI
import SwiftData

/// 日历视图模式
enum CalendarViewMode: String, CaseIterable {
    case list = "列表"
    case day = "天"
    case week = "周"
}

/// 日历事件列表视图
struct CalendarListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startTime)
    private var allEvents: [CalendarEvent]

    @State private var selectedEvent: CalendarEvent?
    @State private var showingAddSheet = false
    @State private var viewMode: CalendarViewMode = .day
    @State private var currentDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            calendarToolbar

            // 日历内容区域（全宽）
            switch viewMode {
            case .day:
                DayCalendarView(
                    date: currentDate,
                    events: eventsForDate(currentDate),
                    onEventTap: { event in
                        selectedEvent = event
                    }
                )
            case .week:
                WeekCalendarView(
                    startOfWeek: startOfWeek(for: currentDate),
                    allEvents: allEvents,
                    onEventTap: { event in
                        selectedEvent = event
                    }
                )
            case .list:
                CalendarListContent(
                    allEvents: allEvents,
                    onEventTap: { event in
                        selectedEvent = event
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CalendarEventEditView(event: nil)
        }
        .sheet(item: $selectedEvent) { event in
            CalendarEventDetailSheet(event: event)
        }
    }

    // MARK: - 顶部工具栏
    private var calendarToolbar: some View {
        HStack(spacing: 12) {
            // 日期导航
            HStack(spacing: 4) {
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button {
                    currentDate = Date()
                } label: {
                    Text("今天")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // 当前日期显示
            Text(dateTitle)
                .font(.headline)
                .frame(minWidth: 120)

            Spacer()

            // 视图模式切换
            Picker("", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            // 新建按钮
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

    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            formatter.dateFormat = "M月d日 EEEE"
        case .week:
            let weekStart = startOfWeek(for: currentDate)
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
            let startFormatter = DateFormatter()
            startFormatter.dateFormat = "M月d日"
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d日"
            return "\(startFormatter.string(from: weekStart)) - \(endFormatter.string(from: weekEnd))"
        case .list:
            formatter.dateFormat = "yyyy年M月"
        }
        return formatter.string(from: currentDate)
    }

    private func navigateDate(by value: Int) {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            currentDate = calendar.date(byAdding: .day, value: value, to: currentDate) ?? currentDate
        case .week:
            currentDate = calendar.date(byAdding: .weekOfYear, value: value, to: currentDate) ?? currentDate
        case .list:
            currentDate = calendar.date(byAdding: .month, value: value, to: currentDate) ?? currentDate
        }
    }

    private func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allEvents.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }
    }

}

// MARK: - 列表视图内容
struct CalendarListContent: View {
    let allEvents: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void

    private var pastEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allEvents.filter { $0.startTime < today || $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
    }

    private var todayEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return allEvents.filter { event in
            !event.isCompleted && event.startTime >= today && event.startTime < tomorrow
        }
    }

    private var futureEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        return allEvents.filter { event in
            !event.isCompleted && event.startTime >= tomorrow
        }
    }

    var body: some View {
        List {
            if !todayEvents.isEmpty {
                Section("今日") {
                    ForEach(todayEvents) { event in
                        CalendarEventRow(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { onEventTap(event) }
                    }
                }
            }

            if !futureEvents.isEmpty {
                Section("即将到来") {
                    ForEach(futureEvents) { event in
                        CalendarEventRow(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { onEventTap(event) }
                    }
                }
            }

            if !pastEvents.isEmpty {
                Section("已完成") {
                    ForEach(pastEvents) { event in
                        CalendarEventRow(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture { onEventTap(event) }
                    }
                }
            }
        }
    }
}

// MARK: - 天视图
struct DayCalendarView: View {
    let date: Date
    let events: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void

    private let hourHeight: CGFloat = 60
    private let startHour = 6  // 从6点开始显示
    private let endHour = 23   // 到23点结束

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // 时间网格
                    timeGrid

                    // 当前时间线
                    if Calendar.current.isDateInToday(date) {
                        currentTimeLine
                    }

                    // 事件块
                    eventsOverlay
                }
                .padding(.leading, 50) // 为时间标签留空间
            }
            .onAppear {
                // 滚动到当前时间附近
                if Calendar.current.isDateInToday(date) {
                    let currentHour = Calendar.current.component(.hour, from: Date())
                    proxy.scrollTo(max(startHour, currentHour - 1), anchor: .top)
                }
            }
        }
    }

    // MARK: - 时间网格
    private var timeGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    // 时间标签
                    Text(String(format: "%02d:00", hour))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 45, alignment: .trailing)
                        .offset(x: -50)

                    // 分隔线
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    // MARK: - 当前时间线
    private var currentTimeLine: some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        return HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(.red)
                .frame(height: 2)
        }
        .offset(y: yOffset)
    }

    // MARK: - 事件覆盖层
    private var eventsOverlay: some View {
        ForEach(events) { event in
            eventBlock(for: event)
        }
    }

    private func eventBlock(for event: CalendarEvent) -> some View {
        let calendar = Calendar.current
        let eventHour = calendar.component(.hour, from: event.startTime)
        let eventMinute = calendar.component(.minute, from: event.startTime)

        let yOffset = CGFloat(eventHour - startHour) * hourHeight + CGFloat(eventMinute) / 60 * hourHeight

        // 计算事件高度
        let duration = event.endTime.timeIntervalSince(event.startTime) / 3600 // 小时数
        let height = max(hourHeight * 0.5, CGFloat(duration) * hourHeight)

        return Button {
            onEventTap(event)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if height > 40 {
                    Text(event.startTime.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(eventColor(for: event))
            )
        }
        .buttonStyle(.plain)
        .offset(y: yOffset)
        .padding(.horizontal, 4)
    }

    private func eventColor(for event: CalendarEvent) -> Color {
        if event.isCompleted {
            return .gray
        }
        return event.priority == .important ? .red.opacity(0.8) : .blue.opacity(0.8)
    }
}

// MARK: - 周视图
struct WeekCalendarView: View {
    let startOfWeek: Date
    let allEvents: [CalendarEvent]
    let onEventTap: (CalendarEvent) -> Void

    private let hourHeight: CGFloat = 50
    private let startHour = 6
    private let endHour = 23

    var body: some View {
        GeometryReader { geometry in
            let timeColumnWidth: CGFloat = 58  // 包含右侧间距
            let availableWidth = geometry.size.width - timeColumnWidth
            let dayWidth = availableWidth / 7

            ScrollView {
                VStack(spacing: 0) {
                    // 星期头部
                    weekHeader(dayWidth: dayWidth, timeColumnWidth: timeColumnWidth)

                    // 时间网格 + 事件
                    ZStack(alignment: .topLeading) {
                        weekGrid(dayWidth: dayWidth, timeColumnWidth: timeColumnWidth)
                        weekEvents(dayWidth: dayWidth, timeColumnWidth: timeColumnWidth)
                        if isCurrentWeek {
                            currentTimeLine(dayWidth: dayWidth, timeColumnWidth: timeColumnWidth)
                        }
                    }
                }
            }
        }
    }

    private var isCurrentWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(Date(), equalTo: startOfWeek, toGranularity: .weekOfYear)
    }

    // MARK: - 星期头部
    private func weekHeader(dayWidth: CGFloat, timeColumnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // 空白角落
            Color.clear
                .frame(width: timeColumnWidth, height: 60)

            // 7天
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
                let isToday = Calendar.current.isDateInToday(date)

                VStack(spacing: 4) {
                    Text(dayOfWeek(for: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.headline)
                        .foregroundStyle(isToday ? .white : .primary)
                        .frame(width: 28, height: 28)
                        .background(isToday ? Color.blue : Color.clear)
                        .clipShape(Circle())
                }
                .frame(width: dayWidth, height: 60)
            }
        }
        .background(Color.primary.opacity(0.03))
    }

    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - 周网格
    private func weekGrid(dayWidth: CGFloat, timeColumnWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(startHour...endHour, id: \.self) { hour in
                HStack(spacing: 0) {
                    // 时间标签
                    Text(String(format: "%02d", hour))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: timeColumnWidth - 8, height: hourHeight, alignment: .trailing)
                        .padding(.trailing, 8)

                    // 7天的格子
                    ForEach(0..<7, id: \.self) { _ in
                        Rectangle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            .frame(width: dayWidth, height: hourHeight)
                    }
                }
            }
        }
    }

    // MARK: - 周事件
    private func weekEvents(dayWidth: CGFloat, timeColumnWidth: CGFloat) -> some View {
        ForEach(0..<7, id: \.self) { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
            let dayEvents = eventsForDate(date)

            ForEach(dayEvents) { event in
                weekEventBlock(for: event, dayOffset: dayOffset, dayWidth: dayWidth, timeColumnWidth: timeColumnWidth)
            }
        }
    }

    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allEvents.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }
    }

    private func weekEventBlock(for event: CalendarEvent, dayOffset: Int, dayWidth: CGFloat, timeColumnWidth: CGFloat) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startTime)
        let minute = calendar.component(.minute, from: event.startTime)

        let xOffset = timeColumnWidth + CGFloat(dayOffset) * dayWidth + 2
        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        let duration = event.endTime.timeIntervalSince(event.startTime) / 3600
        let height = max(hourHeight * 0.4, CGFloat(duration) * hourHeight - 2)

        return Button {
            onEventTap(event)
        } label: {
            Text(event.title)
                .font(.caption2)
                .lineLimit(2)
                .padding(4)
                .frame(width: dayWidth - 4, height: height, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.priority == .important ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                )
        }
        .buttonStyle(.plain)
        .offset(x: xOffset, y: yOffset)
    }

    // MARK: - 当前时间线
    private func currentTimeLine(dayWidth: CGFloat, timeColumnWidth: CGFloat) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        var dayOffset = calendar.component(.weekday, from: Date()) - calendar.firstWeekday
        if dayOffset < 0 { dayOffset += 7 }

        let xOffset = timeColumnWidth + CGFloat(dayOffset) * dayWidth
        let yOffset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(.red)
                .frame(width: dayWidth - 8, height: 2)
        }
        .offset(x: xOffset - 4, y: yOffset - 3)
    }
}

// MARK: - 日历事件行
struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack {
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

// MARK: - 日历事件详情 Sheet
struct CalendarEventDetailSheet: View {
    @Bindable var event: CalendarEvent
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和完成状态
                    HStack {
                        Text(event.title)
                            .font(.title2)
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

                    Divider()

                    // 时间信息
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            if event.isAllDay {
                                Text(event.startTime.formatted(date: .long, time: .omitted))
                                Text("全天")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            } else {
                                VStack(alignment: .leading) {
                                    Text(event.startTime.formatted(date: .abbreviated, time: .shortened))
                                    Text("至 \(event.endTime.formatted(date: .omitted, time: .shortened))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)
                        }
                    }

                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location")
                            .foregroundStyle(.secondary)
                    }

                    if let notes = event.notes, !notes.isEmpty {
                        Divider()
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("事件详情")
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
                            modelContext.delete(event)
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
            event.title = title
            event.startTime = startTime
            event.endTime = isAllDay ? startTime : endTime
            event.isAllDay = isAllDay
            event.location = location.isEmpty ? nil : location
            event.notes = notes.isEmpty ? nil : notes
            event.priority = priority
            event.updatedAt = Date()
        } else {
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
