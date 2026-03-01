import Foundation

struct UntilTime: Equatable {
    let hour: Int
    let minute: Int

    func resolvedEndDate(relativeTo now: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        let candidate = calendar.date(from: components)!
        guard candidate > now else {
            return calendar.date(byAdding: .day, value: 1, to: candidate)!
        }

        return candidate
    }
}

extension SessionRequest {
    static func until(
        _ time: UntilTime,
        relativeTo now: Date,
        displayOption: SessionDisplayOption,
        calendar: Calendar
    ) -> SessionRequest {
        SessionRequest(
            duration: .until(time.resolvedEndDate(relativeTo: now, calendar: calendar)),
            displayOption: displayOption
        )
    }
}
