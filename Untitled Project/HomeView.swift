import SwiftUI

struct HomeView: View {
    let settings: SalarySettings
    let openSettings: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            Circle()
                .fill(Color.appOrangeSoft.opacity(0.5))
                .frame(width: 340, height: 340)
                .blur(radius: 3)
                .offset(x: 180, y: -340)

            if settings.isValid {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    dashboard(at: context.date)
                }
            } else {
                emptyState
            }
        }
        .navigationTitle("首页")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func dashboard(at date: Date) -> some View {
        let snapshot = SalaryCalculator.snapshot(at: date, settings: settings)
        let dailySalary = Double(settings.monthlySalary)
            / SalaryCalculator.averageWorkdaysPerMonth
        let hourlySalary = snapshot.salaryPerSecond * 3_600

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusHeader(snapshot: snapshot, date: date)
                earningsCard(snapshot: snapshot)

                HStack(spacing: 12) {
                    metricCard(
                        title: "每小时",
                        value: hourlySalary,
                        icon: "clock.fill"
                    )
                    metricCard(
                        title: "每天",
                        value: dailySalary,
                        icon: "sun.max.fill"
                    )
                }

                progressCard(snapshot: snapshot)
                scheduleCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }

    private func statusHeader(snapshot: SalarySnapshot, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(snapshot.isWorking ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)

                Text(
                    snapshot.isWorkday
                        ? (snapshot.isWorking ? "工作时间内，收入正在增长" : statusText(snapshot))
                        : "休息"
                )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(snapshot.isWorking ? .primary : .secondary)
            }

            Text(date, format: .dateTime.hour().minute().second())
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
    }

    private func earningsCard(snapshot: SalarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("今天已赚", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(Color.appOrange)

                Spacer()

                Text(settings.salaryType.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appControl, in: Capsule())
            }

            Text(
                snapshot.earnedToday,
                format: .currency(code: "CNY").precision(.fractionLength(2))
            )
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.6)

            HStack {
                Text("每秒")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(
                    snapshot.salaryPerSecond,
                    format: .currency(code: "CNY").precision(.fractionLength(4))
                )
                .fontWeight(.semibold)
                .monospacedDigit()
            }
            .font(.subheadline)
        }
        .padding(22)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.09), radius: 24, y: 10)
    }

    private func metricCard(title: String, value: Double, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.appOrange)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                value,
                format: .currency(code: "CNY").precision(.fractionLength(2))
            )
            .font(.headline.monospacedDigit())
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        }
    }

    private func progressCard(snapshot: SalarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("今日工作进度")
                    .font(.headline)
                Spacer()
                Text(snapshot.progress, format: .percent.precision(.fractionLength(1)))
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }

            ProgressView(value: snapshot.progress)
                .tint(.appOrange)
                .scaleEffect(x: 1, y: 1.5)

            Text(statusText(snapshot))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var scheduleCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(Color.appOrange)

            VStack(alignment: .leading, spacing: 3) {
                Text("工作时间")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(
                    "\(formattedTime(settings.workStartMinutes)) – "
                        + formattedTime(settings.workEndMinutes)
                )
                .font(.headline.monospacedDigit())
            }

            Spacer()

            Text("月薪 ¥\(settings.monthlySalary.formatted())")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appOrangeSoft.opacity(0.6))
                    .frame(width: 96, height: 96)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.appOrange)
            }

            VStack(spacing: 8) {
                Text("还没有收入配置")
                    .font(.title2.bold())
                Text("设置月薪和工作时间后，首页会按秒计算今天赚到的收入。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("去设置", action: openSettings)
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.appOrange, in: Capsule())
        }
        .padding(32)
    }

    private func statusText(_ snapshot: SalarySnapshot) -> String {
        guard snapshot.isWorkday else {
            return "休息"
        }
        if snapshot.progress >= 1 {
            return "今天的工作时间已经结束"
        }
        if snapshot.isWorking {
            return "正在按照每秒收入实时累计"
        }
        return "还没到上班时间"
    }

    private func formattedTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

#Preview {
    HomeView(
        settings: SalarySettings(
            monthlySalary: 20_000,
            salaryType: .beforeTax,
            workStartMinutes: 9 * 60,
            workEndMinutes: 18 * 60
        ),
        openSettings: {}
    )
}
