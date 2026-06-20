import Foundation
import SwiftData

enum SalarySchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Settings.self]
    }

    @Model
    final class Settings {
        var recordKey: String = "primary"
        var monthlySalary: Int = 0
        var workStartMinutes: Int = SalarySettings.defaultWorkStartMinutes
        var workEndMinutes: Int = SalarySettings.defaultWorkEndMinutes
        var updatedAt: Date = Date.distantPast

        init(
            recordKey: String = "primary",
            monthlySalary: Int,
            workStartMinutes: Int,
            workEndMinutes: Int,
            updatedAt: Date = .now
        ) {
            self.recordKey = recordKey
            self.monthlySalary = monthlySalary
            self.workStartMinutes = workStartMinutes
            self.workEndMinutes = workEndMinutes
            self.updatedAt = updatedAt
        }

        var value: SalarySettings {
            SalarySettings(
                monthlySalary: monthlySalary,
                workStartMinutes: workStartMinutes,
                workEndMinutes: workEndMinutes
            )
        }

        func update(with settings: SalarySettings) {
            monthlySalary = settings.monthlySalary
            workStartMinutes = settings.workStartMinutes
            workEndMinutes = settings.workEndMinutes
            updatedAt = .now
        }
    }
}

enum SalaryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SalarySchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

typealias SalarySettingsRecord = SalarySchemaV1.Settings

enum SalaryDataStore {
    static let appGroupIdentifier = "group.com.ityuany.timevalue"
    static let cloudKitContainerIdentifier = "iCloud.com.ityuany.timevalue"

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SalarySchemaV1.self)
        let configuration = ModelConfiguration(
            "SalaryData",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier(appGroupIdentifier),
            cloudKitDatabase: inMemory ? .none : .private(cloudKitContainerIdentifier)
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: SalaryMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func latestSettings(in context: ModelContext) throws -> SalarySettingsRecord? {
        var descriptor = FetchDescriptor<SalarySettingsRecord>(
            predicate: #Predicate { $0.recordKey == "primary" },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
