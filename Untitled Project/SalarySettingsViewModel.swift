import Foundation
import Observation

@Observable
@MainActor
final class SalarySettingsViewModel {
    var salaryText = ""
    var salaryType: SalaryType = .beforeTax
    var workStartMinutes = SalarySettings.defaultWorkStartMinutes
    var workEndMinutes = SalarySettings.defaultWorkEndMinutes
    var showSavedMessage = false

    private(set) var hasSavedSettings = false
    private(set) var savedSettings = SalarySettings.empty

    private let repository: SettingsRepository
    private var toastTask: Task<Void, Never>?
    private var lastPersistedSettings = SalarySettings.empty

    init(repository: SettingsRepository? = nil) {
        self.repository = repository ?? DefaultSettingsRepository()
    }

    var salary: Int {
        Int(salaryText) ?? 0
    }

    var scheduleIsValid: Bool {
        workEndMinutes > workStartMinutes
    }

    var canSave: Bool {
        salary > 0 && scheduleIsValid
    }

    func updateSalaryText(_ value: String) {
        salaryText = String(value.filter(\.isNumber).prefix(8))
    }

    func load() {
        apply(repository.load())
    }

    func applyCloudChanges() {
        guard let settings = repository.applyCloudChanges() else { return }
        savedSettings = settings
        guard currentSettings == lastPersistedSettings else {
            lastPersistedSettings = settings
            return
        }
        apply(settings)
    }

    func save() {
        let settings = currentSettings
        guard settings.isValid else { return }

        repository.save(settings)
        lastPersistedSettings = settings
        savedSettings = settings
        hasSavedSettings = true
        showSavedToast()
    }

    private var currentSettings: SalarySettings {
        SalarySettings(
            monthlySalary: salary,
            salaryType: salaryType,
            workStartMinutes: workStartMinutes,
            workEndMinutes: workEndMinutes
        )
    }

    private func apply(_ settings: SalarySettings) {
        salaryText = settings.monthlySalary > 0 ? String(settings.monthlySalary) : ""
        salaryType = settings.salaryType
        workStartMinutes = settings.workStartMinutes
        workEndMinutes = settings.workEndMinutes
        savedSettings = settings
        hasSavedSettings = settings.monthlySalary > 0
        lastPersistedSettings = settings
    }

    private func showSavedToast() {
        toastTask?.cancel()
        showSavedMessage = true
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            self?.showSavedMessage = false
        }
    }
}
