import SwiftUI
import SwiftData
import WidgetKit

private extension SalarySettings {
    static let widgetModelContainer = try? SalaryDataStore.makeContainer()

    static func loadFromSwiftData() -> SalarySettings {
        guard let widgetModelContainer else {
            return .empty
        }

        do {
            let context = ModelContext(widgetModelContainer)
            return try SalaryDataStore.latestSettings(in: context)?.value ?? .empty
        } catch {
            return .empty
        }
    }
}

private struct SalaryEntry: TimelineEntry {
    let date: Date
    let snapshot: SalarySnapshot
}

private struct SalaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SalaryEntry {
        SalaryEntry(
            date: .now,
            snapshot: SalaryCalculator.snapshot(
                at: Calendar.current.date(
                    bySettingHour: 13,
                    minute: 30,
                    second: 0,
                    of: .now
                ) ?? .now,
                settings: SalarySettings(
                    monthlySalary: 20_000,
                    workStartMinutes: 9 * 60,
                    workEndMinutes: 18 * 60
                )
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryEntry) -> Void) {
        completion(entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryEntry>) -> Void) {
        let now = Date()
        let calendar = ChinaWorkdayCalendar.calendar
        let settings = SalarySettings.loadFromSwiftData()
        let currentMinute = calendar.date(
            bySetting: .second,
            value: 0,
            of: now
        ) ?? now
        let startOfDay = calendar.startOfDay(for: now)
        let workStart = calendar.date(
            byAdding: .minute,
            value: settings.workStartMinutes,
            to: startOfDay
        ) ?? currentMinute
        let workEnd = calendar.date(
            byAdding: .minute,
            value: settings.workEndMinutes,
            to: startOfDay
        ) ?? currentMinute

        var dates = [currentMinute]

        if ChinaWorkdayCalendar.isWorkday(now) {
            if currentMinute < workStart {
                dates.append(workStart)
            }

            let firstWorkMinute = max(currentMinute, workStart)
            if firstWorkMinute <= workEnd {
                let remainingMinutes = max(
                    0,
                    calendar.dateComponents(
                        [.minute],
                        from: firstWorkMinute,
                        to: workEnd
                    ).minute ?? 0
                )

                dates.append(contentsOf: (0...remainingMinutes).compactMap { offset in
                    calendar.date(byAdding: .minute, value: offset, to: firstWorkMinute)
                })
            }
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
            dates.append(tomorrow)
        }

        let entries = Array(Set(dates))
            .sorted()
            .map { date in
                SalaryEntry(
                    date: date,
                    snapshot: SalaryCalculator.snapshot(at: date, settings: settings)
                )
            }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> SalaryEntry {
        let settings = SalarySettings.loadFromSwiftData()
        return SalaryEntry(
            date: date,
            snapshot: SalaryCalculator.snapshot(at: date, settings: settings)
        )
    }
}

private struct SalaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalaryEntry

    var body: some View {
        if entry.snapshot.hasSettings {
            if entry.snapshot.isWorkday {
                workdayContent
            } else {
                restDayContent
            }
        } else {
            emptyState
        }
    }

    private var workdayContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(
                    headerText,
                    systemImage: entry.snapshot.isWorking ? "bolt.fill" : "moon.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(entry.snapshot.isWorking ? accent : .secondary)

                Spacer()

                if family != .systemSmall {
                    Text("¥\(entry.snapshot.salaryPerSecond, format: .number.precision(.fractionLength(4))) / 秒")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text("¥\(entry.snapshot.earnedToday, format: .number.precision(.fractionLength(2)))")
                .font(.system(size: family == .systemSmall ? 28 : 34, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)

            Text("今天已赚")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 3)

            Spacer(minLength: 12)

            ProgressView(value: entry.snapshot.progress)
                .tint(accent)

            HStack {
                Text(entry.snapshot.progress, format: .percent.precision(.fractionLength(0)))
                Spacer()
                if family == .systemSmall {
                    Text("¥\(entry.snapshot.salaryPerSecond, format: .number.precision(.fractionLength(4))) / 秒")
                } else {
                    Text(entry.snapshot.isWorking ? "工作时间内持续累计" : statusText)
                }
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.top, 6)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.96, blue: 0.91),
                    accent.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var restDayContent: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(restAccent.opacity(0.12))
                .frame(width: family == .systemSmall ? 88 : 120)
                .offset(x: 28, y: -32)

            Image(systemName: "sun.max.fill")
                .font(.system(size: family == .systemSmall ? 24 : 30))
                .foregroundStyle(restSun)
                .padding(.top, 4)
                .padding(.trailing, 2)

            VStack(alignment: .leading, spacing: 0) {
                Label(restDayName, systemImage: "leaf.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(restAccent)

                Spacer(minLength: 10)

                Text("好好休息")
                    .font(
                        .system(
                            size: family == .systemSmall ? 27 : 32,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(restInk)

                Text("今天不计算收入")
                    .font(.caption)
                    .foregroundStyle(restInk.opacity(0.68))
                    .padding(.top, 4)

                Spacer(minLength: 12)

                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("放松一下，享受今天")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(restAccent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.99, blue: 0.94),
                    Color(red: 0.78, green: 0.94, blue: 0.83),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(restDayName)。好好休息，今天不计算收入。")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
            Text("请先设置月薪与工作时间")
                .font(.headline)
            Text("打开 App 完成配置后，小组件会自动显示。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(red: 0.99, green: 0.96, blue: 0.91)
        }
    }

    private var statusText: String {
        guard entry.snapshot.isWorkday else {
            return "休息"
        }
        return entry.snapshot.progress >= 1 ? "今日工作已结束" : "等待上班"
    }

    private var restDayName: String {
        ChinaWorkdayCalendar.restDayName(for: entry.date) ?? "休息日"
    }

    private var headerText: String {
        guard entry.snapshot.isWorkday else {
            return "休息"
        }
        return entry.snapshot.isWorking ? "正在赚钱" : "今日收入"
    }

    private var accent: Color {
        Color(red: 0.96, green: 0.46, blue: 0.12)
    }

    private var restAccent: Color {
        Color(red: 0.10, green: 0.56, blue: 0.31)
    }

    private var restInk: Color {
        Color(red: 0.08, green: 0.28, blue: 0.17)
    }

    private var restSun: Color {
        Color(red: 0.96, green: 0.72, blue: 0.20)
    }
}

struct SalaryWidget: Widget {
    let kind = "SalaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalaryProvider()) { entry in
            SalaryWidgetView(entry: entry)
        }
        .configurationDisplayName("今天赚了多少")
        .description("按工作时间展示今天累计赚到的收入和秒薪。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SalaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalaryWidget()
    }
}
