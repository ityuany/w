import Foundation
import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct MyApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try SalaryDataStore.makeContainer()
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(modelContainer: modelContainer)
        }
        .modelContainer(modelContainer)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: SalarySettingsViewModel
    @State private var selectedTab: AppTab = .home

    init(modelContainer: ModelContainer) {
        _viewModel = State(
            initialValue: SalarySettingsViewModel(
                repository: SwiftDataSettingsRepository(modelContainer: modelContainer)
            )
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("首页", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView(settings: viewModel.savedSettings) {
                        selectedTab = .profile
                    }
                }
            }

            Tab("我的", systemImage: "person.fill", value: .profile) {
                NavigationStack {
                    SettingsView(viewModel: viewModel)
                }
            }
        }
        .tint(.appOrange)
        .task {
            viewModel.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.load()
            }
        }
    }
}

private enum AppTab: Hashable {
    case home
    case profile
}

struct SettingsView: View {
    @Bindable var viewModel: SalarySettingsViewModel
    @FocusState private var salaryFieldIsFocused: Bool

    private var salaryBinding: Binding<String> {
        Binding(
            get: { viewModel.salaryText },
            set: viewModel.updateSalaryText
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            Circle()
                .fill(Color.appOrangeSoft.opacity(0.55))
                .frame(width: 320, height: 320)
                .blur(radius: 2)
                .offset(x: 170, y: -330)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 28)

                    salaryCard
                        .padding(.top, 34)

                    workScheduleCard
                        .padding(.top, 20)

                    privacyNote
                        .padding(.top, 28)

                    saveButton
                        .padding(.top, 24)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .tint(.appOrange)
        .overlay(alignment: .top) {
            if viewModel.showSavedMessage {
                savedToast
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.82),
            value: viewModel.showSavedMessage
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appInk)
                    .frame(width: 54, height: 54)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(Color.appOrange)
            }

            Text("先聊聊你的收入")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-0.8)

            Text("设置月薪和工作时间后，我们会帮你更直观地计算每天、每小时的时间价值。")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var salaryCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("税前月薪")
                .font(.system(size: 17, weight: .semibold))

            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text("¥")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                salaryInput

                Text("/ 月")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

        }
        .padding(22)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.09), radius: 24, y: 10)
        .onTapGesture {
            salaryFieldIsFocused = true
        }
    }

    private var salaryInput: some View {
        TextField("0", text: salaryBinding)
            .font(.system(size: 52, weight: .bold, design: .rounded))
            .tracking(-1.5)
            .focused($salaryFieldIsFocused)
#if os(iOS)
            .keyboardType(.numberPad)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("完成") {
                        salaryFieldIsFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
#endif
    }

    private var workScheduleCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("工作时间")
                .font(.system(size: 17, weight: .semibold))

            timePickerRow(
                title: "上班时间",
                systemImage: "sunrise.fill",
                minutes: $viewModel.workStartMinutes
            )

            Divider()

            timePickerRow(
                title: "下班时间",
                systemImage: "sunset.fill",
                minutes: $viewModel.workEndMinutes
            )

            if !viewModel.scheduleIsValid {
                Label("下班时间需要晚于上班时间", systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
            }
        }
        .padding(22)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.appCardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    private func timePickerRow(
        title: String,
        systemImage: String,
        minutes: Binding<Int>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .medium))

            Spacer()

            DatePicker(
                title,
                selection: timeBinding(for: minutes),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .padding(.top, 2)

            Text("收入和工作时间保存在你的设备和私人 iCloud 中，不会分享给其他人。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(.horizontal, 4)
    }

    private var saveButton: some View {
        Button {
            salaryFieldIsFocused = false
            viewModel.save()
        } label: {
            HStack(spacing: 10) {
                Text(viewModel.hasSavedSettings ? "保存设置" : "开始使用")
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(
                viewModel.canSave
                    ? Color.black
                    : Color.appDisabledText
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                viewModel.canSave
                    ? Color.appOrange
                    : Color.appDisabledControl,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
    }

    private var savedToast: some View {
        Label("设置已保存", systemImage: "checkmark.circle.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.black.opacity(0.9), in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    private func timeBinding(for minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    byAdding: .minute,
                    value: minutes.wrappedValue,
                    to: Calendar.current.startOfDay(for: Date())
                ) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

}

extension Color {
    static let appOrange = adaptive(
        light: (0.96, 0.46, 0.12),
        dark: (1.00, 0.55, 0.20)
    )
    static let appOrangeSoft = adaptive(
        light: (1.00, 0.73, 0.48),
        dark: (0.34, 0.20, 0.10)
    )
    static let appBackground = adaptive(
        light: (0.99, 0.96, 0.91),
        dark: (0.075, 0.065, 0.055)
    )
    static let appCard = adaptive(
        light: (1.00, 0.995, 0.98),
        dark: (0.14, 0.125, 0.105)
    )
    static let appCardBorder = adaptive(
        light: (0.87, 0.82, 0.75),
        dark: (0.28, 0.24, 0.20)
    )
    static let appControl = adaptive(
        light: (0.94, 0.93, 0.91),
        dark: (0.20, 0.18, 0.15)
    )
    static let appInk = adaptive(
        light: (0.02, 0.02, 0.02),
        dark: (0.96, 0.94, 0.90)
    )
    static let appOnInk = adaptive(
        light: (1.00, 1.00, 1.00),
        dark: (0.06, 0.055, 0.045)
    )
    static let appDisabledControl = adaptive(
        light: (0.72, 0.70, 0.67),
        dark: (0.25, 0.23, 0.20)
    )
    static let appDisabledText = adaptive(
        light: (1.00, 1.00, 1.00),
        dark: (0.58, 0.55, 0.50)
    )

    static func adaptive(
        light: (red: Double, green: Double, blue: Double),
        dark: (red: Double, green: Double, blue: Double)
    ) -> Color {
#if os(iOS)
        Color(uiColor: UIColor { traits in
            let components = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: components.red,
                green: components.green,
                blue: components.blue,
                alpha: 1
            )
        })
#else
        Color(red: light.red, green: light.green, blue: light.blue)
#endif
    }
}

#Preview {
    let container = try! SalaryDataStore.makeContainer(inMemory: true)
    ContentView(modelContainer: container)
        .modelContainer(container)
}
