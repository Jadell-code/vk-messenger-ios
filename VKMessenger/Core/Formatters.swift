import Foundation

enum Initials {
    static func from(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }.joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}

enum Formatters {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let dayMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static func chatTime(_ date: Date?) -> String {
        guard let date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return timeFormatter.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return "вчера"
        }
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return dayMonthFormatter.string(from: date)
        }
        return dayMonthYearFormatter.string(from: date)
    }

    static func messageTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func feedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "сегодня в \(timeFormatter.string(from: date))"
        }
        if calendar.isDateInYesterday(date) {
            return "вчера в \(timeFormatter.string(from: date))"
        }
        return "\(dayMonthFormatter.string(from: date)) в \(timeFormatter.string(from: date))"
    }
}
