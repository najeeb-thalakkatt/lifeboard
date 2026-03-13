import Foundation

/// Loads widget data from the shared App Group UserDefaults.
struct DataLoader {
    static let appGroupId = "group.com.codehive.lifeboard"
    static let widgetDataKey = "widget_data"

    /// Loads and decodes the widget data from shared UserDefaults.
    /// Returns `WidgetData.empty` if no data is available or decoding fails.
    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let jsonString = defaults.string(forKey: widgetDataKey),
              let jsonData = jsonString.data(using: .utf8) else {
            return .empty
        }

        do {
            let data = try JSONDecoder().decode(WidgetData.self, from: jsonData)
            return data
        } catch {
            return .empty
        }
    }

    /// Returns true if widget data has been written at least once.
    static var hasData: Bool {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return false }
        return defaults.string(forKey: widgetDataKey) != nil
    }
}
