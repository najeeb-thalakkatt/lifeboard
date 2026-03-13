import Foundation

// MARK: - Root Widget Data

struct WidgetData: Codable {
    let weeklyTasks: WeeklyTasksData
    let chores: ChoresData
    let buyList: BuyListData
    let userName: String
    let spaceName: String
    let lastUpdated: String

    static let empty = WidgetData(
        weeklyTasks: .empty,
        chores: .empty,
        buyList: .empty,
        userName: "",
        spaceName: "Our Home",
        lastUpdated: ""
    )

    static let preview = WidgetData(
        weeklyTasks: .preview,
        chores: .preview,
        buyList: .preview,
        userName: "Najeeb",
        spaceName: "Our Home",
        lastUpdated: ISO8601DateFormatter().string(from: Date())
    )
}

// MARK: - Weekly Tasks

struct WeeklyTasksData: Codable {
    let total: Int
    let completed: Int
    let inProgress: Int
    let tasks: [WidgetTaskItem]

    static let empty = WeeklyTasksData(total: 0, completed: 0, inProgress: 0, tasks: [])

    static let preview = WeeklyTasksData(
        total: 12,
        completed: 5,
        inProgress: 3,
        tasks: [
            WidgetTaskItem(title: "Grocery shopping", status: "in_progress", emoji: "🛒", dueDate: "2026-03-14"),
            WidgetTaskItem(title: "Pay electricity bill", status: "todo", emoji: "💰", dueDate: "2026-03-15"),
            WidgetTaskItem(title: "Book dentist appointment", status: "todo", emoji: "🦷", dueDate: "2026-03-16"),
            WidgetTaskItem(title: "Plan weekend trip", status: "in_progress", emoji: "✈️", dueDate: nil),
            WidgetTaskItem(title: "Fix kitchen tap", status: "done", emoji: "🔧", dueDate: nil),
            WidgetTaskItem(title: "Call insurance company", status: "todo", emoji: "📞", dueDate: "2026-03-17"),
        ]
    )
}

struct WidgetTaskItem: Codable {
    let title: String
    let status: String
    let emoji: String?
    let dueDate: String?

    var isDone: Bool { status == "done" }
    var isInProgress: Bool { status == "in_progress" }
}

// MARK: - Chores

struct ChoresData: Codable {
    let todayDue: Int
    let overdue: Int
    let items: [WidgetChoreItem]

    static let empty = ChoresData(todayDue: 0, overdue: 0, items: [])

    static let preview = ChoresData(
        todayDue: 3,
        overdue: 1,
        items: [
            WidgetChoreItem(title: "Vacuum living room", emoji: "🧹", assignee: "N", isOverdue: false),
            WidgetChoreItem(title: "Take out trash", emoji: "🗑️", assignee: "P", isOverdue: true),
            WidgetChoreItem(title: "Clean bathroom", emoji: "🚿", assignee: nil, isOverdue: false),
            WidgetChoreItem(title: "Water plants", emoji: "🌱", assignee: "N", isOverdue: false),
        ]
    )
}

struct WidgetChoreItem: Codable {
    let title: String
    let emoji: String
    let assignee: String?
    let isOverdue: Bool
}

// MARK: - Buy List

struct BuyListData: Codable {
    let totalItems: Int
    let items: [WidgetBuyListItem]

    static let empty = BuyListData(totalItems: 0, items: [])

    static let preview = BuyListData(
        totalItems: 7,
        items: [
            WidgetBuyListItem(title: "Milk", category: "Groceries", emoji: "🥛"),
            WidgetBuyListItem(title: "Bread", category: "Groceries", emoji: "🍞"),
            WidgetBuyListItem(title: "Light bulbs", category: "Home", emoji: "💡"),
            WidgetBuyListItem(title: "Laundry detergent", category: "Home", emoji: "🧴"),
            WidgetBuyListItem(title: "Bananas", category: "Groceries", emoji: "🍌"),
            WidgetBuyListItem(title: "Batteries", category: "Home", emoji: "🔋"),
            WidgetBuyListItem(title: "Olive oil", category: "Groceries", emoji: "🫒"),
        ]
    )
}

struct WidgetBuyListItem: Codable {
    let title: String
    let category: String
    let emoji: String?
}
