import Foundation

struct AppPreferences: Equatable {
    var quickDurationPreset: SessionPreset
    var defaultDisplayOption: SessionDisplayOption
    var lowBatteryThreshold: Int?

    static let `default` = AppPreferences(
        quickDurationPreset: .oneHour,
        defaultDisplayOption: .keepDisplayAwake,
        lowBatteryThreshold: nil
    )

    func defaultQuickSessionRequest() -> SessionRequest {
        SessionRequest(
            duration: .preset(quickDurationPreset),
            displayOption: defaultDisplayOption
        )
    }
}
