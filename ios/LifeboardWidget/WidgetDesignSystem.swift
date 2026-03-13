import SwiftUI

// MARK: - Lifeboard Widget Colors

struct LifeboardColors {
    // Primary palette
    static let primaryDark = Color(hex: 0x2F6264)
    static let primaryLight = Color(hex: 0xE2EAEB)
    static let background = Color(hex: 0x77B5B3)
    static let accentWarm = Color(hex: 0xF5A623)
    static let error = Color(hex: 0xD94F4F)
    /// Adaptive background — light in light mode, dark in dark mode.
    static let widgetBackground = Color(.systemBackground)

    // Status colors
    static let statusTodo = Color(hex: 0x2F6264)
    static let statusInProgress = Color(hex: 0xF5A623)
    static let statusDone = Color(hex: 0x4CAF50)

    /// Returns the status accent color for a given status string.
    static func statusColor(for status: String) -> Color {
        switch status {
        case "in_progress": return statusInProgress
        case "done": return statusDone
        default: return statusTodo
        }
    }

    /// Warm status label text.
    static func statusLabel(for status: String) -> String {
        switch status {
        case "todo": return "Next Up"
        case "in_progress": return "Working on it"
        case "done": return "Done!"
        default: return status
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Widget Text Styles

struct WidgetFonts {
    // Heading — maps to Nunito feel using SF Rounded
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Body — maps to Inter feel using SF default
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func bodySemibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func caption() -> Font {
        .system(size: 11, weight: .regular)
    }

    static func captionSemibold() -> Font {
        .system(size: 11, weight: .semibold)
    }

    // Big number for progress ring
    static func stat() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func statSmall() -> Font {
        .system(size: 18, weight: .bold, design: .rounded)
    }
}

// MARK: - Progress Ring View

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .stroke(
                        LifeboardColors.primaryLight,
                        lineWidth: lineWidth
                    )
            }
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }

    private var progressGradient: AngularGradient {
        if progress >= 1.0 {
            return AngularGradient(
                colors: [LifeboardColors.accentWarm, LifeboardColors.statusDone],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
        return AngularGradient(
            colors: [LifeboardColors.primaryDark, LifeboardColors.statusDone],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let status: String
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(LifeboardColors.statusColor(for: status))
            .frame(width: size, height: size)
    }
}

// MARK: - Empty State View

struct WidgetEmptyState: View {
    let emoji: String
    let message: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 28))
            Text(message)
                .font(WidgetFonts.body(12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
