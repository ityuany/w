import Foundation
import WidgetKit

protocol SettingsRepository {
    func load() -> SalarySettings
    func applyCloudChanges() -> SalarySettings?
    func save(_ settings: SalarySettings)
}

final class DefaultSettingsRepository: SettingsRepository {
    private let localStore: UserDefaults
    private let cloudStore: NSUbiquitousKeyValueStore

    init(
        localStore: UserDefaults = .standard,
        cloudStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.localStore = localStore
        self.cloudStore = cloudStore
    }

    func load() -> SalarySettings {
        removeObsoleteCurrencySetting()
        cloudStore.synchronize()

        if let cloudSettings = readCloudSettings() {
            writeLocalSettings(cloudSettings)
            return cloudSettings
        }

        let localSettings = readLocalSettings()
        if localSettings.monthlySalary > 0 {
            writeCloudSettings(localSettings)
        }
        return localSettings
    }

    func applyCloudChanges() -> SalarySettings? {
        guard let settings = readCloudSettings() else { return nil }
        writeLocalSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
        return settings
    }

    func save(_ settings: SalarySettings) {
        writeLocalSettings(settings)
        writeCloudSettings(settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func readLocalSettings() -> SalarySettings {
        SalarySettings(
            monthlySalary: localStore.integer(forKey: SettingsKey.monthlySalary),
            salaryType: SalaryType(
                rawValue: localStore.string(forKey: SettingsKey.salaryType) ?? ""
            ) ?? .beforeTax,
            workStartMinutes: localInteger(
                forKey: SettingsKey.workStartMinutes,
                fallback: SalarySettings.defaultWorkStartMinutes
            ),
            workEndMinutes: localInteger(
                forKey: SettingsKey.workEndMinutes,
                fallback: SalarySettings.defaultWorkEndMinutes
            )
        )
    }

    private func readCloudSettings() -> SalarySettings? {
        guard let salary = cloudStore.object(forKey: SettingsKey.monthlySalary) as? NSNumber else {
            return nil
        }

        return SalarySettings(
            monthlySalary: salary.intValue,
            salaryType: SalaryType(
                rawValue: cloudStore.string(forKey: SettingsKey.salaryType) ?? ""
            ) ?? .beforeTax,
            workStartMinutes: cloudInteger(
                forKey: SettingsKey.workStartMinutes,
                fallback: SalarySettings.defaultWorkStartMinutes
            ),
            workEndMinutes: cloudInteger(
                forKey: SettingsKey.workEndMinutes,
                fallback: SalarySettings.defaultWorkEndMinutes
            )
        )
    }

    private func writeLocalSettings(_ settings: SalarySettings) {
        localStore.set(settings.monthlySalary, forKey: SettingsKey.monthlySalary)
        localStore.set(settings.salaryType.rawValue, forKey: SettingsKey.salaryType)
        localStore.set(settings.workStartMinutes, forKey: SettingsKey.workStartMinutes)
        localStore.set(settings.workEndMinutes, forKey: SettingsKey.workEndMinutes)
    }

    private func writeCloudSettings(_ settings: SalarySettings) {
        cloudStore.set(settings.monthlySalary, forKey: SettingsKey.monthlySalary)
        cloudStore.set(settings.salaryType.rawValue, forKey: SettingsKey.salaryType)
        cloudStore.set(settings.workStartMinutes, forKey: SettingsKey.workStartMinutes)
        cloudStore.set(settings.workEndMinutes, forKey: SettingsKey.workEndMinutes)
        cloudStore.synchronize()
    }

    private func localInteger(forKey key: String, fallback: Int) -> Int {
        localStore.object(forKey: key) == nil ? fallback : localStore.integer(forKey: key)
    }

    private func cloudInteger(forKey key: String, fallback: Int) -> Int {
        (cloudStore.object(forKey: key) as? NSNumber)?.intValue ?? fallback
    }

    private func removeObsoleteCurrencySetting() {
        localStore.removeObject(forKey: "currency")
        cloudStore.removeObject(forKey: "currency")
    }
}
