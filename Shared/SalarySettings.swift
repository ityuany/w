import Foundation

struct SalarySettings: Equatable {
    static let defaultWorkStartMinutes = 9 * 60
    static let defaultWorkEndMinutes = 18 * 60

    var monthlySalary: Int
    var workStartMinutes: Int
    var workEndMinutes: Int

    static let empty = SalarySettings(
        monthlySalary: 0,
        workStartMinutes: defaultWorkStartMinutes,
        workEndMinutes: defaultWorkEndMinutes
    )

    var hasValidSchedule: Bool {
        workEndMinutes > workStartMinutes
    }

    var isValid: Bool {
        monthlySalary > 0 && hasValidSchedule
    }
}
