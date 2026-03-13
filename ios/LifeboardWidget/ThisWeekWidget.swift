import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ThisWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThisWeekEntry {
        ThisWeekEntry(date: Date(), data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (ThisWeekEntry) -> Void) {
        if context.isPreview {
            completion(ThisWeekEntry(date: Date(), data: .preview))
            return
        }
        let widgetData = DataLoader.load()
        completion(ThisWeekEntry(date: Date(), data: widgetData))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThisWeekEntry>) -> Void) {
        let widgetData = DataLoader.load()
        let entry = ThisWeekEntry(date: Date(), data: widgetData)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

// MARK: - Entry

struct ThisWeekEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Entry View (size-adaptive)

struct ThisWeekWidgetEntryView: View {
    var entry: ThisWeekEntry
    @Environment(\.widgetFamily) var family

    private var weekly: WeeklyTasksData { entry.data.weeklyTasks }
    private var progress: Double {
        weekly.total > 0 ? Double(weekly.completed) / Double(weekly.total) : 0
    }
    private var allDone: Bool { weekly.total > 0 && weekly.completed == weekly.total }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            lockScreenRectangular
        default:
            smallView
        }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(spacing: 0) {
            if weekly.total == 0 {
                WidgetEmptyState(emoji: "📅", message: "Ready to plan\nyour week?")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer(minLength: 8)

                ZStack {
                    ProgressRing(progress: progress, lineWidth: 9, size: 76)
                    VStack(spacing: 0) {
                        Text("\(weekly.completed)")
                            .font(WidgetFonts.stat())
                            .foregroundStyle(allDone ? LifeboardColors.accentWarm : LifeboardColors.primaryDark)
                        Text("/ \(weekly.total)")
                            .font(WidgetFonts.caption())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(allDone ? "We did it! 🎉" : "Our Week")
                    .font(WidgetFonts.bodySemibold(12))
                    .foregroundStyle(allDone ? LifeboardColors.accentWarm : .primary)
                    .padding(.top, 4)

                Spacer(minLength: 6)

                // Linear progress bar at bottom
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(.systemFill))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(LifeboardColors.primaryDark)
                            .frame(width: geo.size.width * CGFloat(min(progress, 1.0)), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Medium (stacked layout)

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row
            HStack {
                Text("Our Week")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Text(entry.data.spaceName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Progress zone: 44pt ring inline + progress bar + stat badges
            HStack(spacing: 10) {
                ZStack {
                    ProgressRing(progress: progress, lineWidth: 5, size: 44)
                    VStack(spacing: 0) {
                        Text("\(weekly.completed)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(allDone ? LifeboardColors.accentWarm : LifeboardColors.primaryDark)
                        Text("/\(weekly.total)")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color(.systemFill))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(LifeboardColors.primaryDark)
                                .frame(width: geo.size.width * CGFloat(min(progress, 1.0)), height: 3)
                        }
                    }
                    .frame(height: 3)

                    HStack(spacing: 12) {
                        let todoCount = max(0, weekly.total - weekly.completed - weekly.inProgress)
                        statBadge(count: todoCount, label: "Next Up", color: LifeboardColors.statusTodo)
                        statBadge(count: weekly.inProgress, label: "Active", color: LifeboardColors.statusInProgress)
                        statBadge(count: weekly.completed, label: "Done", color: LifeboardColors.statusDone)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            // Task list: up to 3 rows (in_progress first, then todo by due date)
            if weekly.tasks.isEmpty {
                Text("No tasks yet")
                    .font(WidgetFonts.body(12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(upcomingTasks.prefix(3).enumerated()), id: \.offset) { _, task in
                        taskRow(task)
                    }
                    let overflow = upcomingTasks.count - 3
                    if overflow > 0 {
                        Text("+\(overflow) more")
                            .font(WidgetFonts.caption())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Compact header: 52pt ring + title + stat badges
            HStack(spacing: 12) {
                ZStack {
                    ProgressRing(progress: progress, lineWidth: 6, size: 52)
                    VStack(spacing: 0) {
                        Text("\(weekly.completed)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(allDone ? LifeboardColors.accentWarm : LifeboardColors.primaryDark)
                        Text("/\(weekly.total)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(allDone ? "We did it! 🎉" : "Our Week")
                        .font(WidgetFonts.heading(16))
                        .foregroundStyle(allDone ? LifeboardColors.accentWarm : .primary)

                    let todoCount = max(0, weekly.total - weekly.completed - weekly.inProgress)
                    HStack(spacing: 10) {
                        statBadge(count: todoCount, label: "Next Up", color: LifeboardColors.statusTodo)
                        statBadge(count: weekly.inProgress, label: "Active", color: LifeboardColors.statusInProgress)
                        statBadge(count: weekly.completed, label: "Done", color: LifeboardColors.statusDone)
                    }
                }
                Spacer()
            }

            Divider()

            // Task list: up to 8 rows, 28pt each
            if weekly.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    WidgetEmptyState(emoji: "📋", message: "Plan your week to see tasks here")
                    Spacer()
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(sortedTasks.prefix(8).enumerated()), id: \.offset) { _, task in
                        largeTaskRow(task)
                    }
                }
                Spacer(minLength: 0)

                // Overdue summary at bottom
                let overdueCount = sortedTasks.filter { task in
                    guard let due = task.dueDate else { return false }
                    return isOverdue(due)
                }.count
                if overdueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(LifeboardColors.error)
                        Text("\(overdueCount) overdue")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(LifeboardColors.error)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private var accessoryCircularView: some View {
        if #available(iOS 16.0, *) {
            Gauge(value: progress) {
                Image(systemName: "checklist")
            } currentValueLabel: {
                Text("\(weekly.completed)")
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 4, size: 52, showBackground: true)
                VStack(spacing: 0) {
                    Text("\(weekly.completed)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("/\(weekly.total)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .semibold))
                Text("Our Week")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(weekly.completed)/\(weekly.total)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }

            ProgressView(value: progress)
                .tint(.primary)

            if let nextTask = upcomingTasks.first {
                Text(nextTask.title)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("All done this week")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var upcomingTasks: [WidgetTaskItem] {
        let inProg = weekly.tasks.filter { $0.isInProgress }
        let todo = weekly.tasks.filter { !$0.isDone && !$0.isInProgress }
        return inProg + todo
    }

    private var sortedTasks: [WidgetTaskItem] {
        weekly.tasks.sorted { a, b in
            let order = ["in_progress": 0, "todo": 1, "done": 2]
            return (order[a.status] ?? 1) < (order[b.status] ?? 1)
        }
    }

    private func taskRow(_ task: WidgetTaskItem) -> some View {
        HStack(spacing: 6) {
            StatusDot(status: task.status, size: 6)

            if let emoji = task.emoji {
                Text(emoji)
                    .font(.system(size: 12))
            }

            Text(task.title)
                .font(WidgetFonts.body(12))
                .lineLimit(1)
                .foregroundStyle(task.isDone ? .secondary : .primary)

            Spacer(minLength: 0)

            if let dueDate = task.dueDate {
                Text(formatShortDate(dueDate))
                    .font(WidgetFonts.caption())
                    .foregroundStyle(isOverdue(dueDate) ? LifeboardColors.error : .secondary)
            }
        }
    }

    private func largeTaskRow(_ task: WidgetTaskItem) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(task.isDone ? Color.clear : LifeboardColors.statusColor(for: task.status))
                .frame(width: 3, height: 22)

            if let emoji = task.emoji {
                Text(emoji)
                    .font(.system(size: 13))
            }

            Group {
                if #available(iOS 16.0, *) {
                    Text(task.title)
                        .font(WidgetFonts.body(13))
                        .lineLimit(1)
                        .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                        .strikethrough(task.isDone, color: .secondary)
                } else {
                    Text(task.title)
                        .font(WidgetFonts.body(13))
                        .lineLimit(1)
                        .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                }
            }

            Spacer(minLength: 0)

            if let dueDate = task.dueDate {
                Text(formatShortDate(dueDate))
                    .font(WidgetFonts.caption())
                    .foregroundStyle(isOverdue(dueDate) ? LifeboardColors.error : .secondary)
            }
        }
        .frame(minHeight: 22)
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func formatShortDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }

    private func isOverdue(_ dateStr: String) -> Bool {
        guard !dateStr.isEmpty else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Widget Definition

struct ThisWeekWidget: Widget {
    let kind: String = "ThisWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThisWeekProvider()) { entry in
            if #available(iOS 17.0, *) {
                ThisWeekWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                ThisWeekWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Our Week")
        .description("See how your household week is going.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .systemSmall, .systemMedium, .systemLarge,
                .accessoryCircular, .accessoryRectangular,
            ]
        } else {
            return [.systemSmall, .systemMedium, .systemLarge]
        }
    }
}
