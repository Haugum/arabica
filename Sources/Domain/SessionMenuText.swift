import Foundation

enum SessionMenuText {
    static func makeEndsAtTimeFormatter(
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    static func endsAtLabel(for endDate: Date, formatter: DateFormatter) -> String {
        "Ends At \(timeText(for: endDate, formatter: formatter))"
    }

    static func timeText(for date: Date, formatter: DateFormatter) -> String {
        formatter.string(from: date)
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }
}
