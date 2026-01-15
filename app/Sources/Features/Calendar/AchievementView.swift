import SwiftUI
import SwiftData

/// 成就可视化视图 - GitHub 贡献图风格
struct AchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCaptures: [CaptureItem]
    @Query private var allTodos: [TodoItem]
    @Query private var allEvents: [CalendarEvent]

    @State private var selectedMonth: Date = Date()
    @State private var selectedDay: DayData?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 统计摘要
                summarySection

                // 热力图
                heatmapSection

                // 月份选择器
                monthSelector

                // 选中日期详情
                if let day = selectedDay {
                    dayDetailSection(day)
                }
            }
            .padding()
        }
        .navigationTitle("成就")
    }

    // MARK: - 统计摘要
    private var summarySection: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "总捕获",
                value: "\(allCaptures.count)",
                icon: "tray.full.fill",
                color: .blue
            )

            StatCard(
                title: "已完成",
                value: "\(completedTodosCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                title: "活跃天数",
                value: "\(activeDaysCount)",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "连续天数",
                value: "\(currentStreak)",
                icon: "bolt.fill",
                color: .purple
            )
        }
    }

    // MARK: - 热力图区域
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("过去 12 个月")
                .font(.headline)

            ContributionHeatmap(
                data: generateHeatmapData(),
                selectedDay: $selectedDay
            )

            // 图例
            HStack {
                Text("少")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(for: level))
                        .frame(width: 12, height: 12)
                }
                Text("多")
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

    // MARK: - 月份选择器
    private var monthSelector: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Text(selectedMonth.formatted(.dateTime.month().year()))
                .font(.headline)
                .frame(minWidth: 120)

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 日期详情
    private func dayDetailSection(_ day: DayData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.date.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                Spacer()
                Button {
                    selectedDay = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                Label("\(day.captureCount) 捕获", systemImage: "tray")
                Label("\(day.completedCount) 完成", systemImage: "checkmark")
                Label("\(day.eventCount) 事件", systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - 辅助计算
    private var completedTodosCount: Int {
        allTodos.filter { $0.isCompleted }.count
    }

    private var activeDaysCount: Int {
        let calendar = Calendar.current
        var days = Set<Date>()

        for capture in allCaptures {
            days.insert(calendar.startOfDay(for: capture.createdAt))
        }

        return days.count
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

    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func generateHeatmapData() -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!

        // 构建每日数据
        var dayMap: [Date: DayData] = [:]

        // 初始化所有日期
        var currentDate = oneYearAgo
        while currentDate <= today {
            dayMap[currentDate] = DayData(
                date: currentDate,
                captureCount: 0,
                completedCount: 0,
                eventCount: 0
            )
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // 统计捕获
        for capture in allCaptures {
            let day = calendar.startOfDay(for: capture.createdAt)
            if var data = dayMap[day] {
                data.captureCount += 1
                dayMap[day] = data
            }
        }

        // 统计完成
        for todo in allTodos where todo.isCompleted {
            let day = calendar.startOfDay(for: todo.updatedAt)
            if var data = dayMap[day] {
                data.completedCount += 1
                dayMap[day] = data
            }
        }

        // 统计事件
        for event in allEvents where event.isCompleted {
            let day = calendar.startOfDay(for: event.startTime)
            if var data = dayMap[day] {
                data.eventCount += 1
                dayMap[day] = data
            }
        }

        return dayMap.values.sorted { $0.date < $1.date }
    }

    private func heatmapColor(for level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}

// MARK: - 日数据模型
struct DayData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var captureCount: Int
    var completedCount: Int
    var eventCount: Int

    var totalActivity: Int {
        captureCount + completedCount + eventCount
    }

    var activityLevel: Int {
        switch totalActivity {
        case 0: return 0
        case 1...2: return 1
        case 3...5: return 2
        case 6...10: return 3
        default: return 4
        }
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 贡献热力图
struct ContributionHeatmap: View {
    let data: [DayData]
    @Binding var selectedDay: DayData?

    private let columns = 53 // 约一年的周数
    private let rows = 7    // 一周7天

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(12), spacing: 3), count: rows), spacing: 3) {
                ForEach(data) { day in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForLevel(day.activityLevel))
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(selectedDay?.id == day.id ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            if selectedDay?.id == day.id {
                                selectedDay = nil
                            } else {
                                selectedDay = day
                            }
                        }
                }
            }
        }
        .frame(height: CGFloat(rows * 12 + (rows - 1) * 3))
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}

#Preview {
    AchievementView()
        .modelContainer(DataContainer.previewContainer)
}
