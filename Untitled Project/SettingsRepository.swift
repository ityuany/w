import Foundation
import SwiftData
import WidgetKit

protocol SettingsRepository {
    func load() -> SalarySettings
    func save(_ settings: SalarySettings)
}

final class SwiftDataSettingsRepository: SettingsRepository {
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        modelContext = ModelContext(modelContainer)
    }

    func load() -> SalarySettings {
        do {
            return try SalaryDataStore.latestSettings(in: modelContext)?.value ?? .empty
        } catch {
            assertionFailure("Unable to load salary settings: \(error)")
            return .empty
        }
    }

    func save(_ settings: SalarySettings) {
        do {
            let records = try modelContext.fetch(
                FetchDescriptor<SalarySettingsRecord>(
                    predicate: #Predicate { $0.recordKey == "primary" },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            )

            if let record = records.first {
                record.update(with: settings)
                for duplicate in records.dropFirst() {
                    modelContext.delete(duplicate)
                }
            } else {
                modelContext.insert(makeRecord(from: settings))
            }

            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            assertionFailure("Unable to save salary settings: \(error)")
        }
    }

    private func makeRecord(from settings: SalarySettings) -> SalarySettingsRecord {
        SalarySettingsRecord(
            monthlySalary: settings.monthlySalary,
            workStartMinutes: settings.workStartMinutes,
            workEndMinutes: settings.workEndMinutes
        )
    }
}
