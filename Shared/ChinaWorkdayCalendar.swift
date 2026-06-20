import Foundation

enum ChinaWorkdayCalendar {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private static let holidayNames2026: [Int: String] = [
        101: "元旦", 102: "元旦", 103: "元旦",
        215: "春节", 216: "春节", 217: "春节", 218: "春节", 219: "春节",
        220: "春节", 221: "春节", 222: "春节", 223: "春节",
        404: "清明节", 405: "清明节", 406: "清明节",
        501: "劳动节", 502: "劳动节", 503: "劳动节", 504: "劳动节", 505: "劳动节",
        619: "端午节", 620: "端午节", 621: "端午节",
        925: "中秋节", 926: "中秋节", 927: "中秋节",
        1001: "国庆节", 1002: "国庆节", 1003: "国庆节", 1004: "国庆节",
        1005: "国庆节", 1006: "国庆节", 1007: "国庆节",
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

            if holidayNames2026[monthAndDay] != nil {
                return false
            }
        }

        return weekday != 1 && weekday != 7
    }

    static func restDayName(for date: Date) -> String? {
        guard !isWorkday(date) else {
            return nil
        }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        if
            components.year == 2026,
            let month = components.month,
            let day = components.day,
            let holidayName = holidayNames2026[month * 100 + day]
        {
            return holidayName
        }

        return "周末"
    }
}
