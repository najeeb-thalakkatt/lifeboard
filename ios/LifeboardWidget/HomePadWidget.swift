import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct HomePadProvider: TimelineProvider {
    func placeholder(in context: Context) -> HomePadEntry {
        HomePadEntry(date: Date(), data: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomePadEntry) -> Void) {
        if context.isPreview {
            completion(HomePadEntry(date: Date(), data: .preview))
            return
        }
        let widgetData = DataLoader.load()
        completion(HomePadEntry(date: Date(), data: widgetData))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomePadEntry>) -> Void) {
        let widgetData = DataLoader.load()
        let entry = HomePadEntry(date: Date(), data: widgetData)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

// MARK: - Entry

struct HomePadEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Entry View (size-adaptive)

struct HomePadWidgetEntryView: View {
    var entry: HomePadEntry
    @Environment(\.widgetFamily) var family

    private var chores: ChoresData { entry.data.chores }
    private var buyList: BuyListData { entry.data.buyList }

    /// Chores sorted: overdue first, then by title
    private var sortedChores: [WidgetChoreItem] {
        let overdue = chores.items.filter { $0.isOverdue }
        let rest = chores.items.filter { !$0.isOverdue }
        return overdue + rest
    }

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(spacing: 0) {
            // Left: Chores (max 3)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LifeboardColors.primaryDark)
                    Text("Chores")
                        .font(WidgetFonts.heading(13))
                        .foregroundStyle(.primary)
                    Spacer()
                    if chores.overdue > 0 {
                        Text("\(chores.overdue) overdue")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LifeboardColors.error.cornerRadius(8))
                    }
                }

                if sortedChores.isEmpty {
                    Spacer()
                    Text("All clear! ✨")
                        .font(WidgetFonts.body(12))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(sortedChores.prefix(3).enumerated()), id: \.offset) { _, chore in
                            choreRow(chore)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 8)

            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
                .padding(.vertical, 4)

            // Right: Buy List
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bag")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LifeboardColors.accentWarm)
                    Text("Buy List")
                        .font(WidgetFonts.heading(13))
                        .foregroundStyle(.primary)
                    Spacer()
                    if buyList.totalItems > 0 {
                        Text("\(buyList.totalItems)")
                            .font(WidgetFonts.bodySemibold(12))
                            .foregroundStyle(LifeboardColors.accentWarm)
                    }
                }

                if buyList.items.isEmpty {
                    Spacer()
                    Text("Nothing to buy 🎉")
                        .font(WidgetFonts.body(12))
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(buyList.items.prefix(3).enumerated()), id: \.offset) { _, item in
                            buyListRow(item)
                        }
                        if buyList.items.count > 3 {
                            Text("+\(buyList.items.count - 3) more")
                                .font(WidgetFonts.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Chores section
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LifeboardColors.primaryDark)
                Text("Chores")
                    .font(WidgetFonts.heading(15))
                    .foregroundStyle(.primary)
                Spacer()
                if chores.overdue > 0 {
                    Text("\(chores.overdue) overdue")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LifeboardColors.error.cornerRadius(10))
                }
                if chores.todayDue > 0 {
                    Text("\(chores.todayDue) due today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LifeboardColors.primaryDark)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LifeboardColors.primaryLight.cornerRadius(10))
                }
            }

            if sortedChores.isEmpty {
                HStack {
                    Spacer()
                    WidgetEmptyState(emoji: "✨", message: "All chores done!")
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(sortedChores.prefix(5).enumerated()), id: \.offset) { _, chore in
                        largeChoreRow(chore)
                    }
                }
            }

            Divider()
                .padding(.vertical, 2)

            // Buy list section
            HStack(spacing: 4) {
                Image(systemName: "bag")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LifeboardColors.accentWarm)
                Text("Buy List")
                    .font(WidgetFonts.heading(15))
                    .foregroundStyle(.primary)
                Spacer()
                if buyList.totalItems > 0 {
                    Text("\(buyList.totalItems) items")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(LifeboardColors.accentWarm)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LifeboardColors.accentWarm.opacity(0.12).cornerRadius(10))
                }
            }

            if buyList.items.isEmpty {
                HStack {
                    Spacer()
                    WidgetEmptyState(emoji: "🎉", message: "Nothing to buy!")
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(buyList.items.prefix(5).enumerated()), id: \.offset) { _, item in
                        largeBuyListRow(item)
                    }
                    if buyList.items.count > 5 {
                        Text("+\(buyList.items.count - 5) more")
                            .font(WidgetFonts.caption())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func choreRow(_ chore: WidgetChoreItem) -> some View {
        HStack(spacing: 6) {
            // Red left accent bar for overdue items
            if chore.isOverdue {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(LifeboardColors.error)
                    .frame(width: 3, height: 16)
            }

            Text(chore.emoji)
                .font(.system(size: 12))

            Text(chore.title)
                .font(WidgetFonts.body(12))
                .lineLimit(1)
                .foregroundStyle(chore.isOverdue ? LifeboardColors.error : .primary)

            Spacer(minLength: 0)

            if let assignee = chore.assignee {
                Text(assignee)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(LifeboardColors.primaryDark))
            }
        }
    }

    private func buyListRow(_ item: WidgetBuyListItem) -> some View {
        HStack(spacing: 6) {
            if let emoji = item.emoji {
                Text(emoji)
                    .font(.system(size: 11))
            } else {
                Circle()
                    .fill(LifeboardColors.accentWarm)
                    .frame(width: 5, height: 5)
            }

            Text(item.title)
                .font(WidgetFonts.body(12))
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    private func largeChoreRow(_ chore: WidgetChoreItem) -> some View {
        HStack(spacing: 8) {
            // Red left accent bar for most overdue/urgent item
            if chore.isOverdue {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LifeboardColors.error)
                    .frame(width: 3, height: 22)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LifeboardColors.primaryDark)
                    .frame(width: 3, height: 22)
            }

            Text(chore.emoji)
                .font(.system(size: 13))

            Text(chore.title)
                .font(WidgetFonts.body(13))
                .lineLimit(1)
                .foregroundStyle(chore.isOverdue ? LifeboardColors.error : .primary)

            Spacer(minLength: 0)

            if let assignee = chore.assignee {
                Text(assignee)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(LifeboardColors.primaryDark))
            }
        }
    }

    private func largeBuyListRow(_ item: WidgetBuyListItem) -> some View {
        HStack(spacing: 8) {
            if let emoji = item.emoji {
                Text(emoji)
                    .font(.system(size: 13))
            } else {
                Circle()
                    .fill(LifeboardColors.accentWarm)
                    .frame(width: 6, height: 6)
            }

            Text(item.title)
                .font(WidgetFonts.body(13))
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Text(item.category)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Widget Definition

struct HomePadWidget: Widget {
    let kind: String = "HomePadWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomePadProvider()) { entry in
            if #available(iOS 17.0, *) {
                HomePadWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                HomePadWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Home Pad")
        .description("Today's chores and shopping list at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
