import SwiftUI
import AppKit
import CoreGraphics

// MARK: - 日历工具（周一为一周第一天）

extension Calendar {
    static var widget: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // Monday
        return c
    }

    func startOfMonth(_ d: Date) -> Date {
        date(from: dateComponents([.year, .month], from: d))!
    }

    func gridStart(ofMonth d: Date) -> Date {
        let first = startOfMonth(d)
        let offset = (component(.weekday, from: first) - firstWeekday + 7) % 7
        return date(byAdding: .day, value: -offset, to: first)!
    }

    func addDays(_ n: Int, to d: Date) -> Date {
        date(byAdding: .day, value: n, to: d)!
    }

    func daysBetween(_ from: Date, _ to: Date) -> Int {
        dateComponents([.day], from: from, to: to).day ?? 0
    }

    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        isDate(a, inSameDayAs: b)
    }

    func isInSameMonth(_ a: Date, asMonthOf b: Date) -> Bool {
        isDate(a, equalTo: b, toGranularity: .month)
    }

    func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f.string(from: d)
    }

    func yearOnly(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年"
        return f.string(from: d)
    }

    func monthOnly(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月"
        return f.string(from: d)
    }
}

// MARK: - 数据模型

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var colorHex: String
    var colorIndex: Int?   // 主题标签色板中的位置（旧数据为 nil 时回退用 colorHex）
    var start: Date?   // 排期开始日（未排期时为 nil）
    var end: Date?     // 排期结束日
    var isScheduled: Bool { start != nil && end != nil }
}

extension Color {
    init(hex: String) {
        var h = hex
        if h.hasPrefix("#") { h.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255.0,
                  green: Double((v >> 8) & 0xFF) / 255.0,
                  blue: Double(v & 0xFF) / 255.0)
    }

    func hexString() -> String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        return String(format: "#%02X%02X%02X",
                      Int((ns.redComponent * 255).rounded()),
                      Int((ns.greenComponent * 255).rounded()),
                      Int((ns.blueComponent * 255).rounded()))
    }
}

// MARK: - 主题系统（每套含浅色/深色两套完整语义色）

struct ThemePalette {
    let isDark: Bool
    // 品牌
    let primary: String        // 品牌主色
    let primaryPressed: String // 按下态
    let primaryLight: String   // 浅底色
    let accent: String         // 强调色
    let accentLight: String    // 强调浅底
    // 背景层级
    let pageBackground: String
    let cardBackground: String
    let overlayBackground: String
    let inputBackground: String
    // 文字层级
    let textPrimary: String
    let textSecondary: String
    let textTertiary: String
    let textInverse: String
    let buttonText: String     // 主按钮文字（按主题对比度单独指定）
    // 边框与分割线
    let border: String
    let divider: String
    // 遮罩 / 阴影 / 发光
    let mask: String
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let glowOpacity: Double
    // 品牌渐变
    let brandGradient: [String]
    // 状态语义（7 种）
    let statusTodo: String
    let statusDoing: String
    let statusDone: String
    let statusBlocked: String
    let statusOverdue: String
    let statusWarning: String
    let statusInfo: String
    // 优先级语义（4 级）
    let priorityUrgent: String
    let priorityHigh: String
    let priorityMedium: String
    let priorityLow: String
    // 标签色板（≥8）与图表色板（≥6）
    let tagPalette: [String]
    let chartPalette: [String]

    // 便捷 Color 访问
    var cPrimary: Color { Color(hex: primary) }
    var cPrimaryPressed: Color { Color(hex: primaryPressed) }
    var cPrimaryLight: Color { Color(hex: primaryLight) }
    var cAccent: Color { Color(hex: accent) }
    var cAccentLight: Color { Color(hex: accentLight) }
    var cPageBackground: Color { Color(hex: pageBackground) }
    var cCardBackground: Color { Color(hex: cardBackground) }
    var cOverlayBackground: Color { Color(hex: overlayBackground) }
    var cInputBackground: Color { Color(hex: inputBackground) }
    var cTextPrimary: Color { Color(hex: textPrimary) }
    var cTextSecondary: Color { Color(hex: textSecondary) }
    var cTextTertiary: Color { Color(hex: textTertiary) }
    var cTextInverse: Color { Color(hex: textInverse) }
    var cButtonText: Color { Color(hex: buttonText) }
    var cBorder: Color { Color(hex: border) }
    var cDivider: Color { Color(hex: divider) }
    var cShadow: Color { Color(hex: mask).opacity(shadowOpacity) }
    var cGradient: LinearGradient {
        LinearGradient(colors: brandGradient.map { Color(hex: $0) },
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct Theme: Identifiable {
    let id: String
    let name: String
    let cornerRadius: CGFloat
    let light: ThemePalette
    let dark: ThemePalette

    func palette(isDark: Bool) -> ThemePalette { isDark ? dark : light }

    // MARK: 主题一：薄荷巧克力（清透版）
    static let mintChocolate = Theme(
        id: "mintChocolate", name: "薄荷巧克力", cornerRadius: 12,
        light: ThemePalette(
            isDark: false,
            primary: "#6FBF9F", primaryPressed: "#4E9C7E", primaryLight: "#E4F6EE",
            accent: "#7D5D45", accentLight: "#EFE6DC",
            pageBackground: "#F5FAF7", cardBackground: "#FFFFFF", overlayBackground: "#FFFFFF", inputBackground: "#EAF4EF",
            textPrimary: "#2E221B", textSecondary: "#7A6858", textTertiary: "#A7B8AC", textInverse: "#FCF8F2",
            buttonText: "#2E221B",
            border: "#D9E8E0", divider: "#E8F1EC",
            mask: "#000000", shadowOpacity: 0.05, shadowRadius: 6, glowOpacity: 0,
            brandGradient: ["#6FBF9F", "#7D5D45"],
            statusTodo: "#7E9DB5", statusDoing: "#6FBF9F", statusDone: "#4E7D60", statusBlocked: "#9A8FB4",
            statusOverdue: "#C26B78", statusWarning: "#D0AC5E", statusInfo: "#6FA3B8",
            priorityUrgent: "#C26B78", priorityHigh: "#D0AC5E", priorityMedium: "#6FBF9F", priorityLow: "#7E9DB5",
            tagPalette: ["#7FD6B5", "#B9D98E", "#8A6A52", "#F6EEE0", "#E0D3B2", "#B0C2A2", "#D48F99", "#97B4C6"],
            chartPalette: ["#6FBF9F", "#8A6A52", "#B9D98E", "#F6EEE0", "#C26B78", "#97B4C6"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#6FBF9F", primaryPressed: "#4E9C7E", primaryLight: "#24443A",
            accent: "#C08B64", accentLight: "#3A2C20",
            pageBackground: "#241A13", cardBackground: "#302319", overlayBackground: "#3A2B20", inputBackground: "#281D15",
            textPrimary: "#F3FAF6", textSecondary: "#B9A896", textTertiary: "#8D7C6C", textInverse: "#FCF8F2",
            buttonText: "#2E221B",
            border: "#453629", divider: "#382B20",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.18,
            brandGradient: ["#6FBF9F", "#C08B64"],
            statusTodo: "#93A9BB", statusDoing: "#82CEB2", statusDone: "#5C9372", statusBlocked: "#A497C0",
            statusOverdue: "#CE7C88", statusWarning: "#DCB86C", statusInfo: "#7FB0C4",
            priorityUrgent: "#CE7C88", priorityHigh: "#DCB86C", priorityMedium: "#82CEB2", priorityLow: "#93A9BB",
            tagPalette: ["#8CD9B9", "#C0DF9A", "#9A785C", "#E4D5BC", "#CDBD98", "#B7C9A9", "#D69AA2", "#9CBACB"],
            chartPalette: ["#82CEB2", "#C08B64", "#C0DF9A", "#E4D5BC", "#CE7C88", "#9CBACB"]))

    // MARK: 主题二：柠檬汽水（清透版）
    static let lemonSoda = Theme(
        id: "lemonSoda", name: "柠檬汽水", cornerRadius: 14,
        light: ThemePalette(
            isDark: false,
            primary: "#E5CD6D", primaryPressed: "#C4AA48", primaryLight: "#F9F4D9",
            accent: "#55C2AE", accentLight: "#DFF6EF",
            pageBackground: "#FAFBF5", cardBackground: "#FFFFFF", overlayBackground: "#FFFFFF", inputBackground: "#EEF5F1",
            textPrimary: "#203C35", textSecondary: "#5F786D", textTertiary: "#9FB3AA", textInverse: "#203C35",
            buttonText: "#1C382F",
            border: "#DBE9E2", divider: "#EAF2ED",
            mask: "#000000", shadowOpacity: 0.05, shadowRadius: 6, glowOpacity: 0,
            brandGradient: ["#E5CD6D", "#55C2AE"],
            statusTodo: "#7E9DB5", statusDoing: "#E5CD6D", statusDone: "#7FBF6E", statusBlocked: "#7D83C0",
            statusOverdue: "#D06A60", statusWarning: "#D89F4E", statusInfo: "#5FAFD0",
            priorityUrgent: "#D06A60", priorityHigh: "#D89F4E", priorityMedium: "#E5CD6D", priorityLow: "#7E9DB5",
            tagPalette: ["#EBD87E", "#ACD98E", "#86C7DD", "#9CD9BC", "#E39086", "#EDC4A8", "#F5F8F2", "#B0BDC4"],
            chartPalette: ["#E5CD6D", "#7FBF6E", "#86C7DD", "#D06A60", "#E39086", "#9CD9BC"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#E5CD6D", primaryPressed: "#C4AA48", primaryLight: "#3B361F",
            accent: "#55C2AE", accentLight: "#1E342E",
            pageBackground: "#182224", cardBackground: "#202D2F", overlayBackground: "#283638", inputBackground: "#1B2729",
            textPrimary: "#F0F8F5", textSecondary: "#A7BAB2", textTertiary: "#768B85", textInverse: "#182224",
            buttonText: "#1C382F",
            border: "#314244", divider: "#283638",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.18,
            brandGradient: ["#E5CD6D", "#55C2AE"],
            statusTodo: "#93A9BB", statusDoing: "#EDD87E", statusDone: "#94D085", statusBlocked: "#9398D0",
            statusOverdue: "#DB7D70", statusWarning: "#E0B05C", statusInfo: "#6FBFD8",
            priorityUrgent: "#DB7D70", priorityHigh: "#E0B05C", priorityMedium: "#EDD87E", priorityLow: "#93A9BB",
            tagPalette: ["#F0DE8A", "#B5DD98", "#93CFE2", "#A6DCC0", "#E8988E", "#F0CBB0", "#DFE8E2", "#B0BDC4"],
            chartPalette: ["#EDD87E", "#94D085", "#93CFE2", "#DB7D70", "#E8988E", "#A6DCC0"]))

    // MARK: 主题三：巧克力可可（清透版）
    static let chocolateCocoa = Theme(
        id: "chocolateCocoa", name: "巧克力可可", cornerRadius: 10,
        light: ThemePalette(
            isDark: false,
            primary: "#9C6E48", primaryPressed: "#7C5637", primaryLight: "#F1E7D9",
            accent: "#D2A75C", accentLight: "#F7EDD9",
            pageBackground: "#FAF6EF", cardBackground: "#FFFDF8", overlayBackground: "#FFFFFF", inputBackground: "#F2EBDD",
            textPrimary: "#3B2A1E", textSecondary: "#7A654F", textTertiary: "#B09F89", textInverse: "#FCF7EF",
            buttonText: "#FCF7EF",
            border: "#E6DBC9", divider: "#F0E9DB",
            mask: "#000000", shadowOpacity: 0.05, shadowRadius: 6, glowOpacity: 0,
            brandGradient: ["#9C6E48", "#D2A75C"],
            statusTodo: "#7E9DB5", statusDoing: "#9C6E48", statusDone: "#5E9370", statusBlocked: "#9A8FB4",
            statusOverdue: "#B5655A", statusWarning: "#D4914E", statusInfo: "#7E9DB5",
            priorityUrgent: "#B5655A", priorityHigh: "#D4914E", priorityMedium: "#7FAF78", priorityLow: "#7E9DB5",
            tagPalette: ["#A8825C", "#6B4A33", "#D8AE6C", "#F5EBD9", "#E0D2B0", "#A9CE93", "#D48F99", "#97B4C6"],
            chartPalette: ["#9C6E48", "#D2A75C", "#F5EBD9", "#7FAF78", "#D48F99", "#97B4C6"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#D2A75C", primaryPressed: "#B38948", primaryLight: "#42331D",
            accent: "#9C6E48", accentLight: "#312419",
            pageBackground: "#281C12", cardBackground: "#332519", overlayBackground: "#3E2E20", inputBackground: "#2B1E14",
            textPrimary: "#FBF5EA", textSecondary: "#C6B296", textTertiary: "#94806A", textInverse: "#FBF5EA",
            buttonText: "#3B2A1E",
            border: "#463728", divider: "#382B1D",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.14,
            brandGradient: ["#D2A75C", "#9C6E48"],
            statusTodo: "#93A9BB", statusDoing: "#D8AC62", statusDone: "#6FA37F", statusBlocked: "#A497C0",
            statusOverdue: "#C27367", statusWarning: "#DEB45E", statusInfo: "#93A9BB",
            priorityUrgent: "#C27367", priorityHigh: "#DEB45E", priorityMedium: "#6FA37F", priorityLow: "#93A9BB",
            tagPalette: ["#B08A64", "#7A5838", "#DFB577", "#E9DABE", "#CDBC94", "#B2D39C", "#D69AA2", "#9CBACB"],
            chartPalette: ["#D8AC62", "#9C6E48", "#E9DABE", "#6FA37F", "#D69AA2", "#9CBACB"]))

    // MARK: 主题四：蜜桃气泡（清透版）
    static let peachBubble = Theme(
        id: "peachBubble", name: "蜜桃气泡", cornerRadius: 14,
        light: ThemePalette(
            isDark: false,
            primary: "#E4A98E", primaryPressed: "#C6846B", primaryLight: "#F9EEE7",
            accent: "#68B7D4", accentLight: "#E5F3F8",
            pageBackground: "#FCF8F4", cardBackground: "#FFFFFF", overlayBackground: "#FFFFFF", inputBackground: "#F6EEE9",
            textPrimary: "#4C3125", textSecondary: "#8A6E5F", textTertiary: "#BAA79E", textInverse: "#FCF8F3",
            buttonText: "#4C3125",
            border: "#ECDED5", divider: "#F5ECE6",
            mask: "#000000", shadowOpacity: 0.04, shadowRadius: 8, glowOpacity: 0,
            brandGradient: ["#E4A98E", "#68B7D4"],
            statusTodo: "#7E9DB5", statusDoing: "#E4A98E", statusDone: "#9AB78F", statusBlocked: "#9A8FB4",
            statusOverdue: "#C26B78", statusWarning: "#D0AC5E", statusInfo: "#68B7D4",
            priorityUrgent: "#C26B78", priorityHigh: "#D0AC5E", priorityMedium: "#E4A98E", priorityLow: "#7E9DB5",
            tagPalette: ["#ECB49E", "#F0D2A8", "#8EC9DE", "#F7EFDF", "#B0C2A2", "#D48F99", "#B4ABC8", "#B5C0C7"],
            chartPalette: ["#E4A98E", "#68B7D4", "#9AB78F", "#F0D2A8", "#D48F99", "#B4ABC8"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#E4A98E", primaryPressed: "#C6846B", primaryLight: "#402C23",
            accent: "#68B7D4", accentLight: "#223641",
            pageBackground: "#221C2B", cardBackground: "#2C2438", overlayBackground: "#362C45", inputBackground: "#261F31",
            textPrimary: "#FCF5F0", textSecondary: "#C6AEA4", textTertiary: "#9A867D", textInverse: "#221C2B",
            buttonText: "#4C3125",
            border: "#423849", divider: "#352C3E",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.16,
            brandGradient: ["#E4A98E", "#68B7D4"],
            statusTodo: "#93A9BB", statusDoing: "#EDB49E", statusDone: "#A2C09A", statusBlocked: "#A497C0",
            statusOverdue: "#CE7C88", statusWarning: "#DCB86C", statusInfo: "#7DC2DC",
            priorityUrgent: "#CE7C88", priorityHigh: "#DCB86C", priorityMedium: "#EDB49E", priorityLow: "#93A9BB",
            tagPalette: ["#F0BEA8", "#F4D9B2", "#99D1E4", "#E8DCC4", "#B7C9A9", "#D69AA2", "#BDB4D4", "#B5C0C7"],
            chartPalette: ["#EDB49E", "#7DC2DC", "#A2C09A", "#F4D9B2", "#D69AA2", "#BDB4D4"]))

    // MARK: 主题五：海盐焦糖（清透版）
    static let seaSaltCaramel = Theme(
        id: "seaSaltCaramel", name: "海盐焦糖", cornerRadius: 10,
        light: ThemePalette(
            isDark: false,
            primary: "#B07C53", primaryPressed: "#93623C", primaryLight: "#F4E8D7",
            accent: "#5C9AB8", accentLight: "#E4F1F6",
            pageBackground: "#FBF8F2", cardBackground: "#FFFDF8", overlayBackground: "#FFFFFF", inputBackground: "#F4EDDD",
            textPrimary: "#3A2B20", textSecondary: "#7C6A55", textTertiary: "#9FAEBA", textInverse: "#FCF8F1",
            buttonText: "#FCF8F1",
            border: "#E8DEC9", divider: "#F3EDE0",
            mask: "#16202B", shadowOpacity: 0.05, shadowRadius: 6, glowOpacity: 0,
            brandGradient: ["#B07C53", "#5C9AB8"],
            statusTodo: "#7E9DB5", statusDoing: "#B07C53", statusDone: "#8AAE8E", statusBlocked: "#9A8FB4",
            statusOverdue: "#B5655A", statusWarning: "#D0A55C", statusInfo: "#5C9AB8",
            priorityUrgent: "#B5655A", priorityHigh: "#D0A55C", priorityMedium: "#B07C53", priorityLow: "#5C9AB8",
            tagPalette: ["#CCA87A", "#79AEC8", "#F4EBD8", "#E4D5AC", "#B0C2A2", "#C07166", "#B4ABC8", "#B5C0C7"],
            chartPalette: ["#B07C53", "#5C9AB8", "#F4EBD8", "#8AAE8E", "#B5655A", "#B4ABC8"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#B07C53", primaryPressed: "#93623C", primaryLight: "#3A2A1D",
            accent: "#5C9AB8", accentLight: "#1E313C",
            pageBackground: "#1A222B", cardBackground: "#23303A", overlayBackground: "#2C3B46", inputBackground: "#1D2830",
            textPrimary: "#FCF6EE", textSecondary: "#D2C0A2", textTertiary: "#93A8B8", textInverse: "#1A222B",
            buttonText: "#FCF6EE",
            border: "#34434E", divider: "#2A3740",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.14,
            brandGradient: ["#B07C53", "#5C9AB8"],
            statusTodo: "#93A9BB", statusDoing: "#C18F60", statusDone: "#97B89B", statusBlocked: "#A497C0",
            statusOverdue: "#C27367", statusWarning: "#DDB466", statusInfo: "#79AEC8",
            priorityUrgent: "#C27367", priorityHigh: "#DDB466", priorityMedium: "#C18F60", priorityLow: "#79AEC8",
            tagPalette: ["#D6B083", "#86B7D0", "#E8DAB6", "#CDBD90", "#B7C9A9", "#CE8275", "#BDB4D4", "#B5C0C7"],
            chartPalette: ["#C18F60", "#79AEC8", "#E8DAB6", "#97B89B", "#CE8275", "#BDB4D4"]))

    // MARK: 主题六：抹茶拿铁（清透版）
    static let matchaLatte = Theme(
        id: "matchaLatte", name: "抹茶拿铁", cornerRadius: 12,
        light: ThemePalette(
            isDark: false,
            primary: "#90BC7D", primaryPressed: "#6F9A5E", primaryLight: "#ECF3E6",
            accent: "#D0AD6C", accentLight: "#F7F0DD",
            pageBackground: "#FAF9F3", cardBackground: "#FFFFFF", overlayBackground: "#FFFFFF", inputBackground: "#F3EEE1",
            textPrimary: "#2C3424", textSecondary: "#6C7A5E", textTertiary: "#A3AE95", textInverse: "#FCF9F1",
            buttonText: "#FCF9F1",
            border: "#E6DFC8", divider: "#F1EEE2",
            mask: "#202B1E", shadowOpacity: 0.05, shadowRadius: 6, glowOpacity: 0,
            brandGradient: ["#90BC7D", "#D0AD6C"],
            statusTodo: "#7E9DB5", statusDoing: "#90BC7D", statusDone: "#51744A", statusBlocked: "#9A8FB4",
            statusOverdue: "#C26B78", statusWarning: "#D0AC5E", statusInfo: "#7E9DB5",
            priorityUrgent: "#C26B78", priorityHigh: "#D0AC5E", priorityMedium: "#90BC7D", priorityLow: "#7E9DB5",
            tagPalette: ["#A3CF8B", "#F8F4E8", "#DECFA8", "#B0C2A2", "#D8BC62", "#D48F99", "#9AB8CB", "#B09C86"],
            chartPalette: ["#90BC7D", "#D0AD6C", "#F8F4E8", "#D8BC62", "#D48F99", "#9AB8CB"]),
        dark: ThemePalette(
            isDark: true,
            primary: "#90BC7D", primaryPressed: "#6F9A5E", primaryLight: "#2C3A26",
            accent: "#D0AD6C", accentLight: "#3E3320",
            pageBackground: "#1E2718", cardBackground: "#27331F", overlayBackground: "#2F3D25", inputBackground: "#212B1A",
            textPrimary: "#F9F6EC", textSecondary: "#B4C2A2", textTertiary: "#87956F", textInverse: "#1E2718",
            buttonText: "#F9F6EC",
            border: "#38472D", divider: "#2D3A24",
            mask: "#000000", shadowOpacity: 0.5, shadowRadius: 10, glowOpacity: 0.14,
            brandGradient: ["#90BC7D", "#D0AD6C"],
            statusTodo: "#93A9BB", statusDoing: "#9FC789", statusDone: "#5F8A58", statusBlocked: "#A497C0",
            statusOverdue: "#CE7C88", statusWarning: "#DCB86C", statusInfo: "#93A9BB",
            priorityUrgent: "#CE7C88", priorityHigh: "#DCB86C", priorityMedium: "#9FC789", priorityLow: "#93A9BB",
            tagPalette: ["#ABD491", "#EBE7D6", "#C8B890", "#B7C9A9", "#DEC26C", "#D69AA2", "#A3BFD0", "#B09C86"],
            chartPalette: ["#9FC789", "#D0AD6C", "#EBE7D6", "#DEC26C", "#D69AA2", "#A3BFD0"]))

    static let all: [Theme] = [
        mintChocolate, lemonSoda, chocolateCocoa, peachBubble, seaSaltCaramel, matchaLatte,
    ]
}

/// 任务条文字颜色：优先使用主题品牌对比色（buttonText，即各主题规范指定的任务条文字色：
/// 薄荷=深可可、柠檬=深墨绿、可可=奶油白、蜜桃=深桃褐、海盐=奶油白、抹茶=奶白），
/// 与任务条底色对比度充足时直接采用，保证同屏任务条文字统一、跟随主题；
/// 对比度不足时按底色亮度自动切换为主题语义深/浅色，确保任何模式下都可读
func taskTextColor(on c: Color, pal: ThemePalette) -> Color {
    let bg = NSColor(c).usingColorSpace(.sRGB) ?? NSColor(c)
    let lum = 0.2126 * bg.redComponent + 0.7152 * bg.greenComponent + 0.0722 * bg.blueComponent
    let bt = NSColor(pal.cButtonText).usingColorSpace(.sRGB) ?? NSColor(pal.cButtonText)
    let btLum = 0.2126 * bt.redComponent + 0.7152 * bt.greenComponent + 0.0722 * bt.blueComponent
    // 对比度足够：直接用主题品牌对比色（最协调、最“主题化”）
    if abs(btLum - lum) >= 0.30 { return pal.cButtonText }
    // 对比不足：亮底需要深字（浅色模式用一级深色文字；深色模式用主按钮深色或反白深色）
    if lum > 0.5 {
        return pal.isDark ? (btLum > 0.5 ? pal.cTextInverse : pal.cButtonText) : pal.cTextPrimary
    }
    // 暗底需要浅字（深色模式用一级浅色文字；浅色模式用反白浅色文字）
    return pal.isDark ? pal.cTextPrimary : pal.cTextInverse
}

/// 把颜色调深（× (1-f)），用于浅色模式下把手/连接块比任务条主体深 10%—15%
func darker(_ c: Color, _ f: CGFloat) -> Color {
    let ns = NSColor(c).usingColorSpace(.sRGB) ?? NSColor(c)
    return Color(red: ns.redComponent * (1 - f),
                 green: ns.greenComponent * (1 - f),
                 blue: ns.blueComponent * (1 - f),
                 opacity: ns.alphaComponent)
}

/// 把颜色调亮（与白色混合 f），用于深色模式下把手/连接线比任务条主体亮一档
func brighter(_ c: Color, _ f: CGFloat) -> Color {
    let ns = NSColor(c).usingColorSpace(.sRGB) ?? NSColor(c)
    return Color(red: ns.redComponent + (1 - ns.redComponent) * f,
                 green: ns.greenComponent + (1 - ns.greenComponent) * f,
                 blue: ns.blueComponent + (1 - ns.blueComponent) * f,
                 opacity: ns.alphaComponent)
}

/// 按比例混合两个颜色（f 为 b 的占比）：用于把任务条标签色与主题卡片背景轻微混合，降低纯度、更融入主题
func mix(_ a: Color, _ b: Color, _ f: CGFloat) -> Color {
    let na = NSColor(a).usingColorSpace(.sRGB) ?? NSColor(a)
    let nb = NSColor(b).usingColorSpace(.sRGB) ?? NSColor(b)
    return Color(red: na.redComponent * (1 - f) + nb.redComponent * f,
                 green: na.greenComponent * (1 - f) + nb.greenComponent * f,
                 blue: na.blueComponent * (1 - f) + nb.blueComponent * f,
                 opacity: na.alphaComponent)
}

/// 任务条高度：标题在整行宽度下放不下时加高为两行（同一任务跨行各行高度一致，按整行宽统一判断）
func taskBarHeight(title: String, fullRowW: CGFloat, base: CGFloat) -> CGFloat {
    let avail = max(60, fullRowW - 26)
    let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
    let w = (title as NSString).size(withAttributes: [.font: font]).width
    return w > avail ? max(base, 34) : base
}

/// 旧版（v1.5 及更早）固定莫兰迪任务色板，用于数据迁移映射
let legacyPalette: [String] = ["#C2A4A2", "#C4B29B", "#A7B29C", "#9CA9B6", "#A79EB8", "#B8A794", "#AB9F87", "#B09DAE"]

// MARK: - 任务仓库（纯本地存储）

@MainActor
final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var displayedMonth: Date
    @Published var newTitle: String = ""
    @Published var newColorIndex: Int
    @Published var themeId: String
    @Published var isDarkMode: Bool
    // 正在拖拽的任务与把手类型（用于跨行时把手激活色实时跟随新末行/新首行）
    @Published var draggingTaskID: UUID?
    @Published var dragKind: String = ""
    // 窗口是否固定到桌面层（桌面 pin：窗口钉在桌面壁纸之上、其他窗口之下）
    @Published var pinnedToDesktop = false

    private let cal = Calendar.widget

    var theme: Theme { Theme.all.first { $0.id == themeId } ?? Theme.all[0] }
    /// 当前生效的调色板（主题 × 明暗）
    var pal: ThemePalette { theme.palette(isDark: isDarkMode) }

    init() {
        displayedMonth = cal.startOfMonth(Date())
        themeId = UserDefaults.standard.string(forKey: "themeId") ?? "mintChocolate"
        isDarkMode = UserDefaults.standard.bool(forKey: "darkMode")
        newColorIndex = 0
        load()
        save() // 首次启动即建立数据文件
    }

    func setTheme(_ id: String) {
        themeId = id
        UserDefaults.standard.set(id, forKey: "themeId")
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "darkMode")
    }

    /// 任务条颜色：优先主题标签色板位置，旧任务回退到原 hex
    func color(of task: TaskItem) -> Color {
        if let i = task.colorIndex, i >= 0, i < pal.tagPalette.count {
            return Color(hex: pal.tagPalette[i])
        }
        return Color(hex: task.colorHex)
    }

    var unscheduled: [TaskItem] { tasks.filter { !$0.isScheduled } }
    var scheduled: [TaskItem] { tasks.filter { $0.isScheduled } }

    var gridStart: Date { cal.gridStart(ofMonth: displayedMonth) }
    var monthTitle: String { cal.monthTitle(displayedMonth) }
    var yearTitle: String { cal.yearOnly(displayedMonth) }
    var monthNumTitle: String { cal.monthOnly(displayedMonth) }

    func day(at index: Int) -> Date { cal.addDays(index, to: gridStart) }

    // 一周一行的区间装箱：返回若干泳道，每个泳道是一行内互不重叠的任务条
    func rowLanes(_ row: Int) -> [[RowInterval]] {
        let rowStart = day(at: row * 7)
        let rowEnd = day(at: row * 7 + 6)
        let gridEnd = day(at: 41)
        var intervals: [RowInterval] = []
        for t in scheduled {
            guard let s = t.start, let e = t.end else { continue }
            let cs = max(s, rowStart)
            let ce = min(e, rowEnd)
            guard cs <= ce else { continue }
            let isFirst = (s >= rowStart && s <= rowEnd) || (s < gridStart && row == 0)
            let isLast = (e >= rowStart && e <= rowEnd) || (e > gridEnd && row == 5)
            let spans = !(isFirst && isLast)
            let colStart = max(0, min(6, cal.daysBetween(gridStart, cs) - row * 7))
            let colEnd = max(0, min(6, cal.daysBetween(gridStart, ce) - row * 7))
            intervals.append(RowInterval(
                task: t,
                colStart: colStart,
                colEnd: colEnd,
                dayStart: cs,
                isFirstRow: isFirst,
                isLastRow: isLast,
                spansRows: spans,
                weekendOverlap: spans && colEnd >= 5))
        }
        intervals.sort { ($0.colStart, -$0.colEnd) < ($1.colStart, -$1.colEnd) }
        var lanes: [[RowInterval]] = []
        for iv in intervals {
            if let li = lanes.firstIndex(where: { $0.last!.colEnd < iv.colStart }) {
                lanes[li].append(iv)
            } else {
                lanes.append([iv])
            }
        }
        return lanes
    }

    // MARK: 操作

    func addTask() {
        let t = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let idx = newColorIndex % pal.tagPalette.count
        tasks.append(TaskItem(id: UUID(), title: t,
                              colorHex: pal.tagPalette[idx],
                              colorIndex: idx,
                              start: nil, end: nil))
        newTitle = ""
        // 保持当前所选颜色不变，由用户手动切换（不再自动跳到下一个颜色）
        save()
    }

    func removeTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    /// 把任务排到某一天（起点=终点）
    func schedule(_ id: UUID?, on day: Date) {
        guard let id, let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let d = cal.startOfDay(for: day)
        tasks[i].start = d
        tasks[i].end = d
        save()
    }

    /// 整体平移
    func move(_ id: UUID, byDays n: Int) {
        guard n != 0, let i = tasks.firstIndex(where: { $0.id == id }),
              let s = tasks[i].start, let e = tasks[i].end else { return }
        tasks[i].start = cal.addDays(n, to: s)
        tasks[i].end = cal.addDays(n, to: e)
        save()
    }

    /// 拖动左边缘：改开始日
    func resizeStart(_ id: UUID, byDays n: Int) {
        guard n != 0, let i = tasks.firstIndex(where: { $0.id == id }),
              let s = tasks[i].start, let e = tasks[i].end else { return }
        var ns = cal.addDays(n, to: s)
        if ns > e { ns = e }
        tasks[i].start = ns
        save()
    }

    /// 拖动右边缘：改结束日（用于 10.1→10.7 拉长跨度）
    func resizeEnd(_ id: UUID, byDays n: Int) {
        guard n != 0, let i = tasks.firstIndex(where: { $0.id == id }),
              let s = tasks[i].start, let e = tasks[i].end else { return }
        var ne = cal.addDays(n, to: e)
        if ne < s { ne = s }
        tasks[i].end = ne
        save()
    }

    /// 实时拖拽：结束日跟随鼠标所在日期（跨行延伸）
    func setEnd(_ id: UUID, to d: Date) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let s = tasks[i].start ?? d
        tasks[i].end = d < s ? s : d
        save()
    }

    /// 实时拖拽：开始日跟随鼠标所在日期
    func setStart(_ id: UUID, to d: Date) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let e = tasks[i].end ?? d
        tasks[i].start = d > e ? e : d
        save()
    }

    /// 实时拖拽：整体平移，开始日落在给定日期（保持原跨度）
    func moveTo(_ id: UUID, startDate d: Date) {
        guard let i = tasks.firstIndex(where: { $0.id == id }),
              let s = tasks[i].start, let e = tasks[i].end else { return }
        let span = cal.daysBetween(s, e)
        tasks[i].start = d
        tasks[i].end = cal.addDays(span, to: d)
        save()
    }

    func unschedule(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].start = nil
        tasks[i].end = nil
        save()
    }

    func previousMonth() {
        displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    func nextMonth() {
        displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    func goToday() {
        displayedMonth = cal.startOfMonth(Date())
    }

    /// 固定/取消固定到桌面：保持普通窗口层级（交互完全正常），窗口在所有桌面空间跟随显示、位置固定。
    /// 注：壁纸层（desktop level）窗口在 macOS 上无法接收输入，会导致整个界面失效，故不使用
    func toggleDesktopPin() {
        pinnedToDesktop.toggle()
        guard let w = NSApp.windows.first else { return }
        if pinnedToDesktop {
            // 钉在桌面：普通层级 + 所有空间跟随 + 位置固定
            w.level = .normal
            w.collectionBehavior = [.canJoinAllSpaces, .stationary]
        } else {
            w.level = .normal
            w.collectionBehavior = []
        }
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: 持久化

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DesktopTaskCalendar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("tasks.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        if let decoded = try? dec.decode([TaskItem].self, from: data) {
            // 旧版任务没有 colorIndex：按旧莫兰迪色板映射补全，让颜色跟随主题切换
            tasks = decoded.map { t in
                if t.colorIndex == nil,
                   let i = legacyPalette.firstIndex(where: { $0.caseInsensitiveCompare(t.colorHex) == .orderedSame }) {
                    var m = t
                    m.colorIndex = i
                    return m
                }
                return t
            }
        }
    }

    func save() {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(tasks) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

// MARK: - 行内区间（用于绘制/交互）

struct RowInterval: Identifiable {
    var id: UUID { task.id }
    let task: TaskItem
    let colStart: Int // 0...6 列
    let colEnd: Int   // 0...6 列（含）
    let dayStart: Date // 该行内实际起始日（作为拖放目标）
    let isFirstRow: Bool   // 任务开始日所在行（标题在此行显示；左端为开始把手）
    let isLastRow: Bool    // 任务结束日所在行（时间范围在此行显示；右端为结束把手）
    let spansRows: Bool    // 任务跨多行显示（跨行任务需要连续圆角/延续符号/连接块）
    let weekendOverlap: Bool // 该段覆盖周六/周日（跨行任务遇周末降低透明度，不变色相）
}

// MARK: - 日历格子

struct DayCell: View {
    @EnvironmentObject var store: TaskStore
    let day: Date
    var compact: Bool = false // 窗口较小时缩小日期数字与留白，适配更小尺寸

    var body: some View {
        let cal = Calendar.widget
        let theme = store.theme
        let pal = store.pal
        let isToday = cal.isSameDay(day, Date())
        let inMonth = cal.isInSameMonth(day, asMonthOf: store.displayedMonth)
        RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
            .fill(isToday ? pal.cAccentLight
                          : (inMonth ? pal.cCardBackground : pal.cPageBackground))
            .overlay(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                .strokeBorder(isToday ? pal.cAccent.opacity(0.7)
                                      : (inMonth ? pal.cBorder : pal.cBorder.opacity(0.45)),
                              lineWidth: 1))
            .overlay(alignment: .topLeading) {
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: compact ? 10 : 11, weight: isToday ? .semibold : .regular))
                    .foregroundColor(isToday ? pal.cAccent
                                             : (inMonth ? pal.cTextPrimary : pal.cTextTertiary))
                    .padding(.leading, compact ? 5 : 6)
                    .padding(.top, compact ? 2 : 4)
            }
            .contentShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .dropDestination(for: String.self) { ids, _ in
                guard let idStr = ids.first, let id = UUID(uuidString: idStr) else { return false }
                store.schedule(id, on: day)
                return true
            }
    }
}

// MARK: - 任务条拖放目标（待办胶囊拖到任务条上：按鼠标落点精确换算日期，支持同一日期排多个任务）

struct BarDropDelegate: DropDelegate {
    let store: TaskStore
    let id: UUID
    let gridX: CGFloat
    let gridY: CGFloat
    let cellWidth: CGFloat
    let rowH: CGFloat

    func performDrop(info: DropInfo) -> Bool {
        let p = info.location
        let col = min(6, max(0, Int((gridX + p.x) / cellWidth)))
        let row = min(5, max(0, Int((gridY + p.y) / rowH)))
        store.schedule(id, on: store.day(at: row * 7 + col))
        return true
    }
}

// MARK: - 日历上的任务条（跨行连续显示 + 拖拽把手：左=开始 / 右=结束 / 中=整体移动）

/// 短日期格式 "M.d"
func shortDay(_ d: Date) -> String {
    let c = Calendar.widget
    return "\(c.component(.month, from: d)).\(c.component(.day, from: d))"
}

struct TaskBar: View {
    @EnvironmentObject var store: TaskStore
    let task: TaskItem
    let dayStart: Date
    let cellWidth: CGFloat
    let width: CGFloat
    let isFirstRow: Bool   // 任务开始所在行（标题、左把手）
    let isLastRow: Bool    // 任务结束所在行（时间范围、右把手）
    let spansRows: Bool    // 跨多行
    let weekendOverlap: Bool // 覆盖周六/周日（降透明，不变色相）
    let gridX: CGFloat     // 该条在网格坐标系中的 x（布局位置，供拖拽换算日期）
    let gridY: CGFloat     // 该条在网格坐标系中的 y
    let rowH: CGFloat      // 网格行高
    let barHeight: CGFloat // 任务条高度（随泳道数动态适配）

    @State private var dragMode: DragMode?
    @State private var hovered = false
    @State private var pressOffsetDays: Int?

    private let cal = Calendar.widget

    enum DragMode { case move, resizeStart, resizeEnd }

    // 圆角规则：首行左圆右平、末行右圆左平、中间行两端近平，保持连续感
    private func barShape(_ pal: ThemePalette) -> UnevenRoundedRectangle {
        if !spansRows { return UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous) }
        if isFirstRow { return UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 2, topTrailingRadius: 2, style: .continuous) }
        if isLastRow { return UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous) }
        return UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 2, style: .continuous)
    }

    var body: some View {
        let pal = store.pal
        let col = store.color(of: task)
        // 浅色模式：标签色与卡片背景轻微混合（保持明快）；深色模式：明显压暗降纯（与深色主题融合，不刺眼）
        let baseCol = pal.isDark ? mix(col, pal.cCardBackground, 0.45) : mix(col, pal.cCardBackground, 0.10)
        // 跨行任务遇周末：降低一点透明度，但不变色相
        let barCol = weekendOverlap ? baseCol.opacity(pal.isDark ? 0.90 : 0.82) : baseCol
        let handleBase = pal.isDark ? brighter(baseCol, 0.30) : darker(baseCol, 0.15)
        let narrow = width < 34 // 太窄：隐藏文字，只保留把手与色块
        let showLeftHandle = isFirstRow
        let showRightHandle = isLastRow
        // 文字颜色：深色模式统一用主题一级浅色文字（带主题色相，暗底浅字可读且协调）；
        // 浅色模式按亮度适配（优先品牌对比色，对比不足兜底）
        let textColor = pal.isDark ? pal.cTextPrimary : taskTextColor(on: baseCol, pal: pal)

        return ZStack(alignment: .topLeading) {
            barShape(pal)
                .fill(barCol)
                // 同色系细描边：提升任务条精致度（颜色仍跟随主题）
                .overlay(barShape(pal)
                    .strokeBorder(baseCol.opacity(pal.isDark ? 0.45 : 0.35), lineWidth: 1))
                .shadow(color: pal.isDark ? pal.cAccent.opacity(pal.glowOpacity)
                                          : Color.black.opacity(0.10),
                        radius: pal.isDark ? 4 : 2, y: 1)

            // 跨行延续符号：首行右端 / 非首行左端做同色渐隐过渡 + 小圆点
            if spansRows {
                if !isLastRow {
                    LinearGradient(colors: [baseCol.opacity(pal.isDark ? 0.55 : 0.65), baseCol.opacity(0)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: 16)
                        .offset(x: width - 16, y: 0)
                    Circle()
                        .fill(pal.isDark ? brighter(baseCol, 0.45) : baseCol)
                        .frame(width: 4, height: 4)
                        .offset(x: width - 4, y: (barHeight - 4) / 2)
                }
                if !isFirstRow {
                    LinearGradient(colors: [baseCol.opacity(0), baseCol.opacity(pal.isDark ? 0.55 : 0.65)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: 16)
                    Circle()
                        .fill(pal.isDark ? brighter(baseCol, 0.45) : baseCol)
                        .frame(width: 4, height: 4)
                        .offset(x: 0, y: (barHeight - 4) / 2)
                }
            }

            // 文字：跨行任务的末行显示时间范围；首行、中间行以及单格任务（首行=末行）都显示任务名称。
            // 字距随任务条宽度适度延长（有上限，不会拉爆）；文字垂直居中
            if !narrow {
                if isLastRow && !isFirstRow && width >= 64 {
                    Text("\(shortDay(task.start ?? dayStart))–\(shortDay(task.end ?? dayStart))")
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundColor(textColor.opacity(0.88))
                        .kerning(0.1)
                        .lineLimit(1)
                        .padding(.leading, 6)
                        .padding(.trailing, showRightHandle ? 13 : 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    // 字距随条宽延长：宽任务条（跨多天）字距舒展开，封顶 9pt，避免拉爆；
                    // 长名称自动换行（最多 2 行，配合任务条加高），不再用“…”截断
                    let tracking = min(9.0, max(0.0, (width - 90) / 40))
                    Text(task.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                        .kerning(0.3)
                        .tracking(tracking)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                        .padding(.leading, showLeftHandle ? 13 : 6)
                        .padding(.trailing, showRightHandle ? 13 : 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }

            // 把手 / 连接块：首行左=开始把手，末行右=结束把手；非首/末端是同色连接块（不可拖拽）
            if showLeftHandle {
                handle(atLeading: true, base: handleBase)
            } else {
                linkBlock(base: handleBase)
            }
            if showRightHandle {
                handle(atLeading: false, base: handleBase)
            } else {
                linkBlock(base: handleBase, trailing: true)
            }
        }
        .frame(width: width, height: barHeight)
        .contentShape(barShape(pal))
        .gesture(drag)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) { hovered = h }
        }
        .contextMenu {
            Button("移除排期（回到待排列表）") { store.unschedule(task.id) }
            Divider()
            Button("删除任务", role: .destructive) { store.removeTask(task.id) }
        }
        .onDrop(of: [.plainText],
                delegate: BarDropDelegate(store: store, id: task.id,
                                          gridX: gridX, gridY: gridY,
                                          cellWidth: cellWidth, rowH: rowH))
    }

    // 拖拽把手：默认 40% 透明度，悬停/按下/拖拽时 100% 并轻微放大 1.1 倍 + 轻阴影
    private func handle(atLeading: Bool, base: Color) -> some View {
        // 激活态用全局拖拽状态：跨行延伸后，新末行/新首行的把手也能实时高亮
        let isDraggingThis = store.draggingTaskID == task.id &&
            ((atLeading && store.dragKind == "resizeStart") || (!atLeading && store.dragKind == "resizeEnd"))
        let shown = hovered || isDraggingThis
        let c = isDraggingThis ? store.pal.cAccent : base
        return RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(c.opacity(shown ? 1 : 0.4))
            .frame(width: 5, height: 10)
            .scaleEffect(shown ? 1.1 : 1)
            .shadow(color: shown ? c.opacity(0.5) : .clear, radius: 3, y: 1)
            .offset(x: atLeading ? 2.5 : width - 7.5, y: (barHeight - 10) / 2)
            .animation(.easeOut(duration: 0.15), value: hovered)
            .animation(.easeOut(duration: 0.15), value: isDraggingThis)
            .help(atLeading ? "拖动调整开始日期" : "拖动调整结束日期")
    }

    // 中行连接块：同色小方块、低透明度、不可拖拽，避免误操作
    private func linkBlock(base: Color, trailing: Bool = false) -> some View {
        let pal = store.pal
        return RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(base.opacity(pal.isDark ? 0.45 : 0.30))
            .frame(width: 5, height: 10)
            .offset(x: trailing ? width - 7.5 : 2.5, y: (barHeight - 10) / 2)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 鼠标当前所在网格格子 → 日期（绝对位置驱动，斜向跨行也跟手）
                let col = min(6, max(0, Int((gridX + value.location.x) / cellWidth)))
                let row = min(5, max(0, Int((gridY + value.location.y) / rowH)))
                let date = store.day(at: row * 7 + col)
                if dragMode == nil {
                    // 左把手只在首行（任务开始处）可调；右把手只在末行（任务结束处）可调
                    if isFirstRow && value.startLocation.x < 12 {
                        dragMode = .resizeStart
                    } else if isLastRow && value.startLocation.x > width - 12 {
                        dragMode = .resizeEnd
                    } else {
                        dragMode = .move
                    }
                    if dragMode == .move {
                        // 记录按下时鼠标日期与任务开始日的偏移，拖动时保持该偏移
                        pressOffsetDays = cal.daysBetween(task.start ?? date, date)
                    }
                    store.draggingTaskID = task.id
                    store.dragKind = (dragMode == .move) ? "move" : (dragMode == .resizeStart ? "resizeStart" : "resizeEnd")
                }
                guard let mode = dragMode else { return }
                switch mode {
                case .resizeStart: store.setStart(task.id, to: date)
                case .resizeEnd: store.setEnd(task.id, to: date)
                case .move:
                    if let off = pressOffsetDays {
                        store.moveTo(task.id, startDate: cal.addDays(-off, to: date))
                    }
                }
            }
            .onEnded { _ in
                dragMode = nil
                pressOffsetDays = nil
                store.draggingTaskID = nil
                store.dragKind = ""
            }
    }
}

// MARK: - 待排任务胶囊

struct TaskChip: View {
    @EnvironmentObject var store: TaskStore
    let task: TaskItem

    var body: some View {
        let pal = store.pal
        let col = store.color(of: task)
        HStack(spacing: 5) {
            Circle().fill(col).frame(width: 8, height: 8)
            Text(task.title)
                .font(.system(size: 12))
                .foregroundColor(pal.cTextPrimary)
                .lineLimit(1)
            Button {
                store.removeTask(task.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(pal.cTextTertiary)
            }
            .buttonStyle(.plain)
            .help("删除任务")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(col.opacity(0.12)))
        .overlay(Capsule().strokeBorder(col.opacity(0.40), lineWidth: 1))
        .shadow(color: pal.isDark ? pal.cAccent.opacity(pal.glowOpacity * 0.6) : Color.black.opacity(0.03),
                radius: pal.isDark ? 4 : 2, y: 1)
        .contentShape(Capsule())
        .draggable(task.id.uuidString)
        .help("拖到日历任意日期即可排期")
    }
}

// MARK: - 月历网格

/// 一个泳道的预排布局：任务条集合 + 起始 y + 泳道高度（按标题换行需求自适应）
struct LaneLayout {
    let items: [RowInterval]
    let y: CGFloat
    let h: CGFloat
}

struct MonthGrid: View {
    @EnvironmentObject var store: TaskStore

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / 7
            let cellH = geo.size.height / 6
            // 行内泳道数决定任务条基础高度：重叠/交叉任务越多，条越紧凑，保证都能堆叠显示且不溢出
            let maxLanes = max(1, (0..<6).map { store.rowLanes($0).count }.max() ?? 1)
            let barH = min(24, max(14, (cellH - 32) / CGFloat(maxLanes) - 2))
            // 顶部日期区：窗口变矮时按比例压缩（最小 14），任务条从日期下方开始，不盖日期
            let topPad = min(22, max(14, cellH * 0.30))
            let compactCell = cellH < 50
            // 预计算每行泳道布局：条高随标题是否换行自适应，泳道按累计高度排布互不重叠
            let rowLayouts: [[LaneLayout]] = (0..<6).map { row in
                let lanes = store.rowLanes(row)
                var result: [LaneLayout] = []
                var curY: CGFloat = topPad
                for lane in lanes {
                    let laneH = lane
                        .map { taskBarHeight(title: $0.task.title, fullRowW: geo.size.width, base: barH) }
                        .max() ?? barH
                    result.append(LaneLayout(items: lane, y: curY, h: laneH))
                    curY += laneH + 3
                }
                return result
            }
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { col in
                                DayCell(day: store.day(at: row * 7 + col), compact: compactCell)
                                    .frame(width: cellW, height: cellH)
                            }
                        }
                    }
                }
                // 任务条层：position 定位使布局位置=视觉位置，拖拽坐标可直接换算网格日期
                ForEach(0..<6, id: \.self) { row in
                    ForEach(Array(rowLayouts[row].enumerated()), id: \.offset) { _, layout in
                        ForEach(layout.items) { iv in
                            let barW = CGFloat(iv.colEnd - iv.colStart + 1) * cellW - 4
                            let x = CGFloat(iv.colStart) * cellW + 2
                            let y = CGFloat(row) * cellH + layout.y
                            TaskBar(task: iv.task,
                                    dayStart: iv.dayStart,
                                    cellWidth: cellW,
                                    width: barW,
                                    isFirstRow: iv.isFirstRow,
                                    isLastRow: iv.isLastRow,
                                    spansRows: iv.spansRows,
                                    weekendOverlap: iv.weekendOverlap,
                                    gridX: x, gridY: y, rowH: cellH,
                                    barHeight: layout.h)
                                .frame(width: barW, height: layout.h)
                                .position(x: x + barW / 2, y: y + layout.h / 2)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 主界面

struct ContentView: View {
    @EnvironmentObject var store: TaskStore
    @State private var showThemeMenu = false

    var body: some View {
        VStack(spacing: 10) {
            header
            inputRow
            unscheduledRow
            weekdayHeader
            MonthGrid()
        }
        .padding(14)
        .background(store.pal.cPageBackground)
        .frame(minWidth: 520, minHeight: 440)
    }

    private var header: some View {
        let pal = store.pal
        return HStack(spacing: 12) {
            iconButton(icon: "chevron.left", help: "上一月") { store.previousMonth() }
            // 月份突出：大号“M月” + 上方小号“yyyy年”
            VStack(spacing: 1) {
                Text(store.yearTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(pal.cTextTertiary)
                Text(store.monthNumTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(pal.cTextPrimary)
            }
            .frame(minWidth: 110)
            iconButton(icon: "chevron.right", help: "下一月") { store.nextMonth() }
            Button("回到今天") { store.goToday() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(pal.cTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(pal.cTextPrimary.opacity(0.05)))
                .overlay(Capsule().strokeBorder(pal.cTextPrimary.opacity(0.14), lineWidth: 1))
            Spacer()
            iconButton(icon: store.pinnedToDesktop ? "pin.fill" : "pin",
                       help: store.pinnedToDesktop ? "取消固定到桌面" : "固定到桌面（窗口钉在桌面层，壁纸之上、普通窗口之下，跨空间跟随）") {
                store.toggleDesktopPin()
            }
            iconButton(icon: pal.isDark ? "sun.max" : "moon",
                       help: pal.isDark ? "切换浅色模式" : "切换深色模式") { store.toggleDarkMode() }
            themeMenu
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: store.theme.cornerRadius, style: .continuous).fill(pal.cCardBackground))
        .overlay(RoundedRectangle(cornerRadius: store.theme.cornerRadius, style: .continuous).strokeBorder(pal.cBorder, lineWidth: 1))
        .shadow(color: pal.cShadow, radius: pal.shadowRadius, y: 2)
    }

    private var themeMenu: some View {
        let pal = store.pal
        return Button {
            showThemeMenu.toggle()
        } label: {
            Image(systemName: "paintpalette")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(pal.cTextSecondary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(pal.cTextSecondary.opacity(0.08)))
                .overlay(Circle().strokeBorder(pal.cTextSecondary.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("切换主题（6 套配色 × 明暗模式）")
        .popover(isPresented: $showThemeMenu, arrowEdge: .bottom) {
            themePopover
        }
    }

    // 主题切换弹出面板：完全自绘（背景/文字/选中态都用主题色），不受系统 Menu 强制着色影响
    private var themePopover: some View {
        let pal = store.pal
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Theme.all) { t in
                Button {
                    store.setTheme(t.id)
                    showThemeMenu = false
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(t.light.cPrimary).frame(width: 12, height: 12)
                        Text(t.name)
                            .font(.system(size: 12))
                            .foregroundColor(pal.cTextPrimary)
                        Spacer()
                        if store.themeId == t.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(pal.cAccent)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(minWidth: 190, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(store.themeId == t.id ? pal.cAccent.opacity(0.12) : pal.cTextPrimary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(store.themeId == t.id ? pal.cAccent.opacity(0.35) : pal.cBorder, lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(pal.cOverlayBackground))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(pal.cBorder, lineWidth: 1))
        .shadow(color: pal.cShadow, radius: pal.shadowRadius, y: 2)
    }

    private func iconButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        let pal = store.pal
        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(pal.cTextSecondary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(pal.cTextSecondary.opacity(0.08)))
                .overlay(Circle().strokeBorder(pal.cTextSecondary.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var inputRow: some View {
        let pal = store.pal
        return HStack(spacing: 10) {
            TextField("输入任务名称，回车或点“添加”", text: $store.newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(pal.cTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(pal.cInputBackground))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(pal.cBorder, lineWidth: 1))
                .onSubmit { store.addTask() }
            HStack(spacing: 6) {
                ForEach(Array(pal.tagPalette.enumerated()), id: \.offset) { i, hex in
                    Button {
                        store.newColorIndex = i
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(store.newColorIndex == i ? pal.cTextPrimary : pal.cTextPrimary.opacity(0.15), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .help("选择任务颜色")
                }
            }
            Button("添加") { store.addTask() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(pal.cButtonText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(pal.cPrimary))
                .shadow(color: pal.isDark ? pal.cAccent.opacity(pal.glowOpacity) : pal.cPrimary.opacity(0.18),
                        radius: pal.isDark ? 6 : 4, y: 1)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: store.theme.cornerRadius, style: .continuous).fill(pal.cCardBackground))
        .overlay(RoundedRectangle(cornerRadius: store.theme.cornerRadius, style: .continuous).strokeBorder(pal.cBorder, lineWidth: 1))
        .shadow(color: pal.cShadow, radius: pal.shadowRadius, y: 2)
    }

    private var unscheduledRow: some View {
        let pal = store.pal
        return Group {
            if store.unscheduled.isEmpty {
                Text("暂无待排任务 —— 输入任务后，把它拖到日历任意日期即可排期")
                    .font(.system(size: 12))
                    .foregroundColor(pal.cTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.unscheduled) { t in
                            TaskChip(task: t)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var weekdayHeader: some View {
        let pal = store.pal
        return HStack(spacing: 0) {
            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { d in
                Text(d)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(pal.cTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 2)
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 标准 macOS 应用：正常窗口、Dock 图标，窗口位置记忆
        let apply: () -> Void = {
            if let w = NSApp.windows.first {
                w.title = "桌面任务日历"
                w.setFrameAutosaveName("DesktopTaskCalendarMain")
            }
        }
        apply()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { apply() }
    }
}

@main
struct DesktopTaskCalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TaskStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 980, height: 640)
        .commands {
            // 菜单栏命令：固定/取消固定到桌面（Cmd+P）——即使顶栏按钮被其他窗口遮挡，也能从菜单栏随时切换
            CommandMenu("窗口") {
                Button(store.pinnedToDesktop ? "取消固定到桌面" : "固定到桌面") {
                    store.toggleDesktopPin()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}
