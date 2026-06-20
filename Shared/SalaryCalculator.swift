import Foundation

struct SalarySnapshot {
    let earnedToday: Double
    let salaryPerSecond: Double
    let progress: Double
    let isWorkday: Bool
    let isWorking: Bool
    let hasSettings: Bool
}

enum SalaryCalculator {
    static let averageWorkdaysPerMonth = 21.75

    static func snapshot(
        at date: Date,
        settings: SalarySettings,
        calendar: Calendar = ChinaWorkdayCalendar.calendar
    ) -> SalarySnapshot {
        guard settings.isValid else {
            return SalarySnapshot(
                earnedToday: 0,
                salaryPerSecond: 0,
                progress: 0,
                isWorkday: false,
                isWorking: false,
                hasSettings: false
            )
        }

        let dailySalary = Double(settings.monthlySalary) / averageWorkdaysPerMonth
        let workSeconds = Double(settings.workEndMinutes - settings.workStartMinutes) * 60
        let salaryPerSecond = dailySalary / workSeconds

        guard ChinaWorkdayCalendar.isWorkday(date) else {
            return SalarySnapshot(
                earnedToday: 0,
                salaryPerSecond: salaryPerSecond,
                progress: 0,
                isWorkday: false,
                isWorking: false,
                hasSettings: true
            )
        }

        let currentComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
        let currentSeconds = Double(
            (currentComponents.hour ?? 0) * 3_600
                + (currentComponents.minute ?? 0) * 60
                + (currentComponents.second ?? 0)
        )
        let startSeconds = Double(settings.workStartMinutes * 60)
        let endSeconds = Double(settings.workEndMinutes * 60)
        let workedSeconds = min(max(currentSeconds - startSeconds, 0), workSeconds)

        return SalarySnapshot(
            earnedToday: workedSeconds * salaryPerSecond,
            salaryPerSecond: salaryPerSecond,
            progress: workedSeconds / workSeconds,
            isWorkday: true,
            isWorking: currentSeconds >= startSeconds && currentSeconds < endSeconds,
            hasSettings: true
        )
    }
}
