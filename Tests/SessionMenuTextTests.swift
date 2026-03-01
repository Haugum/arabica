import XCTest
@testable import Arabica

final class SessionMenuTextTests: XCTestCase {
    func testPresetMenuTitlesMatchSettledCopy() {
        XCTAssertEqual(SessionPreset.thirtyMinutes.menuTitle, "Keep Mac Awake for 30 Minutes")
        XCTAssertEqual(SessionPreset.oneHour.menuTitle, "Keep Mac Awake for 1 Hour")
        XCTAssertEqual(SessionPreset.twoHours.menuTitle, "Keep Mac Awake for 2 Hours")
    }

    func testEndsAtLabelUsesExpectedTimeFormatting() {
        let formatter = SessionMenuText.makeEndsAtTimeFormatter(
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let endDate = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 1,
            hour: 16,
            minute: 35
        ).date!

        XCTAssertEqual(SessionMenuText.endsAtLabel(for: endDate, formatter: formatter), "Ends At 4:35 PM")
    }
}
