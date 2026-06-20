import Foundation

enum ChinaWorkdayCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private static let holidays2026: Set<Int> = [
        101, 102, 103,
        215, 216, 217, 218, 219, 220, 221, 222, 223,
        404, 405, 406,
        501, 502, 503, 504, 505,
        619, 620, 621,
        925, 926, 927,
        1001, 1002, 1003, 1004, 1005, 1006, 1007,
    ]

    private static let adjustedWorkdays2026: Set<Int> = [
        104,
        214, 228,
        509,
        920, 1010,
    ]

    static func isWorkday(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let weekday = components.weekday
        else {
            return false
        }

        if year == 2026 {
            let monthAndDay = month * 100 + day

            if adjustedWorkdays2026.contains(monthAndDay) {
                return true
            }

            if holidays2026.contains(monthAndDay) {
                return false
            }
        }

        return weekday != 1 && weekday != 7
    }
}
