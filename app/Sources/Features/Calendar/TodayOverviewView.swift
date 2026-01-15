import SwiftUI
import SwiftData

/// 今日概览视图
struct TodayOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCaptures: [CaptureItem]
    @Query private var allTodos: [TodoItem]
    @Query private var allEvents: [CalendarEvent]
    @Query private var allNotes: [Note]

    @AppStorage("showTodayOverview") private var showTodayOverview = true
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            headerSection

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // 问候语
                    greetingSection

                    // 今日日程
                    if !todayEvents.isEmpty {
                        todayEventsSection
                    }

                    // 待办概览
                    todoPrioritySection

                    // 昨日笔记
                    if !yesterdayNotes.isEmpty {
                        yesterdayNotesSection
                    }

                    // 统计卡片
                    statsSection
                }
                .padding()
            }

            Divider()

            // 底部操作
            footerSection
        }
        .frame(width: 400, height: 500)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    // MARK: - 头部
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日概览")
                    .font(.headline)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - 问候语
    private var greetingSection: some View {
        VStack(spacing: 8) {
            Text(greeting)
                .font(.title)
                .fontWeight(.bold)

            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.2), .yellow.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - 今日日程
    private var todayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("今日日程 (\(todayEvents.count))", systemImage: "calendar")
                .font(.headline)

            ForEach(todayEvents.prefix(3)) { event in
                HStack {
                    Circle()
                        .fill(event.priority == .important ? .red : .blue)
                        .frame(width: 8, height: 8)

                    Text(event.startTime.formatted(.dateTime.hour().minute()))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text(event.title)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.vertical, 4)
            }

            if todayEvents.count > 3 {
                Text("还有 \(todayEvents.count - 3) 个日程...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - 待办优先
    private var todoPrioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("待办事项", systemImage: "checklist")
                .font(.headline)

            HStack(spacing: 16) {
                VStack {
                    Text("\(importantTodos.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    Text("重要")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(normalTodos.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                    Text("普通")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(completedTodayCount)")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Text("今日完成")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - 昨日笔记
    private var yesterdayNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("昨日新增笔记 (\(yesterdayNotes.count))", systemImage: "note.text")
                .font(.headline)

            ForEach(yesterdayNotes.prefix(2)) { note in
                Text(note.content)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - 统计
    private var statsSection: some View {
        HStack(spacing: 12) {
            MiniStatCard(
                value: "\(allCaptures.count)",
                label: "总捕获",
                icon: "tray.full",
                color: .blue
            )

            MiniStatCard(
                value: "\(currentStreak)",
                label: "连续天",
                icon: "flame",
                color: .orange
            )

            MiniStatCard(
                value: "\(todayCaptures.count)",
                label: "今日捕获",
                icon: "plus.circle",
                color: .green
            )
        }
    }

    // MARK: - 底部
    private var footerSection: some View {
        HStack {
            Toggle("每日显示", isOn: $showTodayOverview)
                .toggleStyle(.checkbox)
                .font(.caption)

            Spacer()

            Button("开始新的一天") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - 数据计算
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }

    private var motivationalMessage: String {
        let messages = [
            "新的一天，新的开始",
            "保持专注，一步一步来",
            "今天也要加油",
            "相信自己，你可以的"
        ]
        return messages.randomElement() ?? messages[0]
    }

    private var todayEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return allEvents.filter { event in
            !event.isCompleted && event.startTime >= today && event.startTime < tomorrow
        }.sorted { $0.startTime < $1.startTime }
    }

    private var importantTodos: [TodoItem] {
        allTodos.filter { !$0.isCompleted && $0.priority == .important }
    }

    private var normalTodos: [TodoItem] {
        allTodos.filter { !$0.isCompleted && $0.priority == .normal }
    }

    private var completedTodayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return allTodos.filter { todo in
            todo.isCompleted && calendar.isDate(todo.updatedAt, inSameDayAs: today)
        }.count
    }

    private var yesterdayNotes: [Note] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return allNotes.filter { note in
            note.createdAt >= yesterday && note.createdAt < today
        }
    }

    private var todayCaptures: [CaptureItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return allCaptures.filter { capture in
            calendar.isDate(capture.createdAt, inSameDayAs: today)
        }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var days = Set<Date>()

        for capture in allCaptures {
            days.insert(calendar.startOfDay(for: capture.createdAt))
        }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while days.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }

        return streak
    }
}

// MARK: - 迷你统计卡片
struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    TodayOverviewView()
        .modelContainer(DataContainer.previewContainer)
}
