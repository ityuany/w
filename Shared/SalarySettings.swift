import Foundation

enum SalaryType: String, CaseIterable, Identifiable {
    case beforeTax
    case afterTax

    var id: Self { self }

    var title: String {
        switch self {
        case .beforeTax: "税前收入"
        case .afterTax: "税后到手"
        }
    }
}

struct SalarySettings: Equatable {
    static let defaultWorkStartMinutes = 9 * 60
    static let defaultWorkEndMinutes = 18 * 60

    var monthlySalary: Int
    var salaryType: SalaryType
    var workStartMinutes: Int
    var workEndMinutes: Int

    static let empty = SalarySettings(
        monthlySalary: 0,
        salaryType: .beforeTax,
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

enum SettingsKey {
    static let monthlySalary = "monthlySalary"
    static let salaryType = "salaryType"
    static let workStartMinutes = "workStartMinutes"
    static let workEndMinutes = "workEndMinutes"
}
