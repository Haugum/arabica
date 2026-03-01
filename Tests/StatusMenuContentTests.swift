import Foundation
import XCTest
@testable import Arabica

final class StatusMenuContentTests: XCTestCase {
    private let formatter = SessionMenuText.makeEndsAtTimeFormatter(
        locale: Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone(secondsFromGMT: 0)!
    )

    func testInactiveContentShowsSleepingNormally() {
        XCTAssertEqual(
            StatusMenuContent.make(
                activeSession: nil,
                nextSessionDisplayOption: .keepDisplayAwake,
                now: Date(timeIntervalSinceReferenceDate: 1_000),
                formatter: formatter
            ),
            StatusMenuContent(
                statusTitle: "No Active Session",
                detailTitles: ["Next session will keep the display awake."]
            )
        )
    }

    func testInactiveContentShowsWhenNextSessionLetsDisplaySleep() {
        XCTAssertEqual(
            StatusMenuContent.make(
                activeSession: nil,
                nextSessionDisplayOption: .allowDisplaySleep,
                now: Date(timeIntervalSinceReferenceDate: 1_000),
                formatter: formatter
            ),
            StatusMenuContent(
                statusTitle: "No Active Session",
                detailTitles: ["Next session will let the display sleep."]
            )
        )
    }

    func testActiveTimedContentShowsRemainingTimeAndDisplayMode() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let session = ActiveSession(
            startedAt: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 3,
                day: 1,
                hour: 16,
                minute: 0
            ).date!,
            endsAt: DateComponents(
                calendar: calendar,
                year: 2026,
                month: 3,
                day: 1,
                hour: 16,
                minute: 30
            ).date!,
            displayOption: .allowDisplaySleep
        )

        XCTAssertEqual(
            StatusMenuContent.make(
                activeSession: session,
                nextSessionDisplayOption: .keepDisplayAwake,
                now: DateComponents(
                    calendar: calendar,
                    year: 2026,
                    month: 3,
                    day: 1,
                    hour: 16,
                    minute: 0
                ).date!,
                formatter: formatter
            ),
            StatusMenuContent(
                statusTitle: "Keeping Mac Awake Until 4:30 PM",
                detailTitles: [
                    "30 min remaining.",
                    "Display can still sleep."
                ]
            )
        )
    }

    func testActiveDisplayAwakeContentShowsDisplayAwakeMode() {
        let session = SessionRequest(
            duration: .indefinite,
            displayOption: .keepDisplayAwake
        ).activate(at: Date(timeIntervalSinceReferenceDate: 1_000))

        XCTAssertEqual(
            StatusMenuContent.make(
                activeSession: session,
                nextSessionDisplayOption: .keepDisplayAwake,
                now: Date(timeIntervalSinceReferenceDate: 1_100),
                formatter: formatter
            ),
            StatusMenuContent(
                statusTitle: "Keeping Mac Awake",
                detailTitles: [
                    "Runs until you end it manually.",
                    "Display stays awake too."
                ]
            )
        )
    }
}
