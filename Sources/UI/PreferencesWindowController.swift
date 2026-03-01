import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let viewModel: PreferencesViewModel

    init(
        preferences: AppPreferences,
        onChange: @escaping (AppPreferences) -> Void
    ) {
        viewModel = PreferencesViewModel(preferences: preferences, onChange: onChange)

        let hostingController = NSHostingController(rootView: PreferencesView(viewModel: viewModel))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 380, height: 240))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(preferences: AppPreferences) {
        viewModel.replace(with: preferences)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class PreferencesViewModel: ObservableObject {
    @Published
    private var preferences: AppPreferences

    private let onChange: (AppPreferences) -> Void

    init(
        preferences: AppPreferences,
        onChange: @escaping (AppPreferences) -> Void
    ) {
        self.preferences = preferences
        self.onChange = onChange
    }

    func binding<Value>(for keyPath: WritableKeyPath<AppPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { self.preferences[keyPath: keyPath] },
            set: {
                self.preferences[keyPath: keyPath] = $0
                self.onChange(self.preferences)
            }
        )
    }

    func replace(with preferences: AppPreferences) {
        self.preferences = preferences
    }
}

private struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    private let thresholdOptions: [Int?] = [nil, 20, 25, 30, 40]

    var body: some View {
        Form {
            Picker("Default Quick Duration", selection: viewModel.binding(for: \.quickDurationPreset)) {
                ForEach(SessionPreset.allCases, id: \.self) { preset in
                    Text(preset.shortTitle).tag(preset)
                }
            }

            Picker("Default Display Behavior", selection: viewModel.binding(for: \.defaultDisplayOption)) {
                ForEach(SessionDisplayOption.allCases, id: \.self) { displayOption in
                    Text(displayOption.preferencesTitle).tag(displayOption)
                }
            }

            Picker("Low Battery Auto-End", selection: viewModel.binding(for: \.lowBatteryThreshold)) {
                ForEach(thresholdOptions, id: \.self) { threshold in
                    Text(threshold.map { "\($0)%" } ?? "Off").tag(threshold)
                }
            }

            Text("Changes save automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(width: 380)
    }
}
