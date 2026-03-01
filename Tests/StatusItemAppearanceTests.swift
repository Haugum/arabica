import Foundation
import XCTest
@testable import Arabica

final class StatusItemAppearanceTests: XCTestCase {
    func testInactiveSessionUsesOutlineBeanIcon() {
        XCTAssertEqual(
            StatusItemAppearance.forSession(nil),
            StatusItemAppearance(
                style: .beanOutline,
                accessibilityLabel: "Arabica is inactive"
            )
        )
    }

    func testActiveSessionUsesFilledBeanIcon() {
        let session = SessionRequest(
            duration: .indefinite,
            displayOption: .allowDisplaySleep
        ).activate(at: Date(timeIntervalSinceReferenceDate: 1_000))

        XCTAssertEqual(
            StatusItemAppearance.forSession(session),
            StatusItemAppearance(
                style: .beanFilled,
                accessibilityLabel: "Arabica is active"
            )
        )
    }
}
