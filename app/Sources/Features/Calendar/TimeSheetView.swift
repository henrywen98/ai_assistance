import SwiftUI
import SwiftData
import AppKit

/// 时间范围选择
enum TimeSheetRange: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case custom = "自定义"
}

/// Time Sheet 视图
struct TimeSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startTime) private var allEvents: [CalendarEvent]

    @State private var selectedRange: TimeSheetRange = .week
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var showingExportSheet = false
    @State private var exportText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbar

            Divider()

            // 时间表内容
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedByDate, id: \.date) { dayGroup in
                        DayTimeBlock(
                            date: dayGroup.date,
                            events: dayGroup.events,
                            totalMinutes: dayGroup.totalMinutes
                        )
                    }

                    if groupedByDate.isEmpty {
                        ContentUnavailableView(
                            "无数据",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("所选时间范围内没有日历事件")
                        )
                    }
                }
                .padding()
            }

            Divider()

            // 汇总栏
            summaryBar
        }
        .navigationTitle("Time Sheet")
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(text: exportText)
        }
    }

    // MARK: - 工具栏
    private var toolbar: some View {
        HStack {
            Picker("时间范围", selection: $selectedRange) {
                ForEach(TimeSheetRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: selectedRange) { _, newValue in
                updateDateRange(for: newValue)
            }

            if selectedRange == .custom {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(width: 110)

                Text("至")
                    .foregroundStyle(.secondary)

                DatePicker("", selection: $endDate, displayedComponents: .date)
                    .labelsHidden()
                    .frame(width: 110)
            }

            Spacer()

            Button {
                exportTimeSheet()
            } label: {
                Label("导出", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
    }

    // MARK: - 汇总栏
    private var summaryBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("总计")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatDuration(totalMinutes))
                    .font(.title2.bold())
            }

            Spacer()

            VStack(alignment: .center) {
                Text("日均")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatDuration(averageMinutesPerDay))
                    .font(.headline)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("事件数")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(filteredEvents.count)")
                    .font(.headline)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - 数据计算
    private var filteredEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

        return allEvents.filter { event in
            event.startTime >= start && event.startTime < end
        }
    }

    private var groupedByDate: [DayGroup] {
        let calendar = Calendar.current
        var groups: [Date: [CalendarEvent]] = [:]

        for event in filteredEvents {
            let day = calendar.startOfDay(for: event.startTime)
            groups[day, default: []].append(event)
        }

        return groups.map { date, events in
            let totalMinutes = events.reduce(0) { sum, event in
                sum + Int(event.endTime.timeIntervalSince(event.startTime) / 60)
            }
            return DayGroup(date: date, events: events.sorted { $0.startTime < $1.startTime }, totalMinutes: totalMinutes)
        }.sorted { $0.date > $1.date }
    }

    private var totalMinutes: Int {
        groupedByDate.reduce(0) { $0 + $1.totalMinutes }
    }

    private var averageMinutesPerDay: Int {
        guard !groupedByDate.isEmpty else { return 0 }
        return totalMinutes / groupedByDate.count
    }

    private func updateDateRange(for range: TimeSheetRange) {
        let calendar = Calendar.current
        let today = Date()

        switch range {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: today)!
            endDate = today
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
            endDate = today
        case .custom:
            break
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private func exportTimeSheet() {
        var lines: [String] = []
        lines.append("Time Sheet")
        lines.append("===========")
        lines.append("范围: \(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
        lines.append("")

        for group in groupedByDate {
            lines.append("📅 \(group.date.formatted(date: .complete, time: .omitted)) - \(formatDuration(group.totalMinutes))")
            for event in group.events {
                let duration = Int(event.endTime.timeIntervalSince(event.startTime) / 60)
                lines.append("  • \(event.startTime.formatted(.dateTime.hour().minute())) - \(event.endTime.formatted(.dateTime.hour().minute())): \(event.title) (\(formatDuration(duration)))")
            }
            lines.append("")
        }

        lines.append("===========")
        lines.append("总计: \(formatDuration(totalMinutes))")
        lines.append("事件数: \(filteredEvents.count)")

        exportText = lines.joined(separator: "\n")
        showingExportSheet = true
    }
}

// MARK: - 日期分组
struct DayGroup {
    let date: Date
    let events: [CalendarEvent]
    let totalMinutes: Int
}

// MARK: - 日时间块
struct DayTimeBlock: View {
    let date: Date
    let events: [CalendarEvent]
    let totalMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 日期头
            HStack {
                VStack(alignment: .leading) {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                    Text("\(events.count) 个事件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatDuration(totalMinutes))
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }

            // 时间块
            ForEach(events) { event in
                TimeBlockRow(event: event)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - 时间块行
struct TimeBlockRow: View {
    let event: CalendarEvent

    private var duration: Int {
        Int(event.endTime.timeIntervalSince(event.startTime) / 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 时间范围
            VStack(alignment: .leading, spacing: 2) {
                Text(event.startTime.formatted(.dateTime.hour().minute()))
                    .font(.caption.monospacedDigit())
                Text(event.endTime.formatted(.dateTime.hour().minute()))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)

            // 进度条
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 4)

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .lineLimit(1)

                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 时长
            Text(formatDuration(duration))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch event.priority {
        case .important: return .red
        case .normal: return .blue
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h\(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        }
        return "\(mins)m"
    }
}

// MARK: - 导出面板
struct ExportSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("导出 Time Sheet")
                    .font(.headline)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }

            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )

            HStack {
                Button("复制到剪贴板") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("保存为文件") {
                    saveToFile()
                }
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }

    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "timesheet-\(Date().formatted(date: .numeric, time: .omitted)).txt"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
        dismiss()
    }
}

#Preview {
    TimeSheetView()
        .modelContainer(DataContainer.previewContainer)
}
