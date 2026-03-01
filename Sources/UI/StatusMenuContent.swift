import Foundation

struct StatusMenuContent: Equatable {
    let statusTitle: String
    let detailTitles: [String]

    static func make(
        activeSession: ActiveSession?,
        nextSessionDisplayOption: SessionDisplayOption,
        now: Date,
        formatter: DateFormatter = SessionMenuText.makeEndsAtTimeFormatter()
    ) -> StatusMenuContent {
        guard let activeSession else {
            return StatusMenuContent(
                statusTitle: "No Active Session",
                detailTitles: [inactiveDisplayText(for: nextSessionDisplayOption)]
            )
        }

        let details = detailTitles(for: activeSession, now: now, formatter: formatter)

        if let endsAt = activeSession.endsAt {
            return StatusMenuContent(
                statusTitle: "Keeping Mac Awake Until \(SessionMenuText.timeText(for: endsAt, formatter: formatter))",
                detailTitles: details
            )
        }

        return StatusMenuContent(
            statusTitle: "Keeping Mac Awake",
            detailTitles: details
        )
    }

    private static func inactiveDisplayText(for displayOption: SessionDisplayOption) -> String {
        switch displayOption {
        case .allowDisplaySleep:
            return "Next session will let the display sleep."
        case .keepDisplayAwake:
            return "Next session will keep the display awake."
        }
    }

    private static func detailTitles(
        for activeSession: ActiveSession,
        now: Date,
        formatter: DateFormatter
    ) -> [String] {
        var details: [String] = []

        if let endsAt = activeSession.endsAt {
            details.append("\(remainingText(until: endsAt, now: now)) remaining.")
        } else {
            details.append("Runs until you end it manually.")
        }

        details.append(displayText(for: activeSession.displayOption))
        return details
    }

    private static func remainingText(until endsAt: Date, now: Date) -> String {
        let totalMinutes = max(1, Int(ceil(endsAt.timeIntervalSince(now) / 60)))

        if totalMinutes.isMultiple(of: 60) {
            let hours = totalMinutes / 60
            return hours == 1 ? "1 hr" : "\(hours) hr"
        }

        return "\(totalMinutes) min"
    }

    private static func displayText(for displayOption: SessionDisplayOption) -> String {
        switch displayOption {
        case .allowDisplaySleep:
            return "Display can still sleep."
        case .keepDisplayAwake:
            return "Display stays awake too."
        }
    }
}
