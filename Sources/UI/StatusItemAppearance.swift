import AppKit

struct StatusItemAppearance: Equatable {
    enum Style: Equatable {
        case beanOutline
        case beanFilled
    }

    let style: Style
    let accessibilityLabel: String

    static func forSession(_ activeSession: ActiveSession?) -> StatusItemAppearance {
        if activeSession == nil {
            return StatusItemAppearance(
                style: .beanOutline,
                accessibilityLabel: "Arabica is inactive"
            )
        }

        return StatusItemAppearance(
            style: .beanFilled,
            accessibilityLabel: "Arabica is active"
        )
    }

    func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.isTemplate = true
        image.lockFocus()

        defer { image.unlockFocus() }

        NSGraphicsContext.current?.imageInterpolation = .high
        let beanPath = NSBezierPath(ovalIn: NSRect(x: 2.5, y: 2.9, width: 12.9, height: 12.2))

        let creasePath = NSBezierPath()
        creasePath.move(to: NSPoint(x: 13.4, y: 3.8))
        creasePath.curve(
            to: NSPoint(x: 4.9, y: 14.2),
            controlPoint1: NSPoint(x: 10.8, y: 5.0),
            controlPoint2: NSPoint(x: 8.0, y: 12.3)
        )

        let highlightPath = NSBezierPath()
        highlightPath.move(to: NSPoint(x: 12.4, y: 13.2))
        highlightPath.curve(
            to: NSPoint(x: 10.2, y: 14.2),
            controlPoint1: NSPoint(x: 11.7, y: 13.9),
            controlPoint2: NSPoint(x: 10.9, y: 14.3)
        )

        var transform = AffineTransform()
        transform.translate(x: 9, y: 9)
        transform.rotate(byDegrees: -28)
        transform.translate(x: -9, y: -9)
        beanPath.transform(using: transform)
        creasePath.transform(using: transform)
        highlightPath.transform(using: transform)

        NSColor.black.setStroke()

        switch style {
        case .beanOutline:
            beanPath.lineWidth = 1.55
            beanPath.stroke()
            creasePath.lineWidth = 1.2
            creasePath.stroke()
            highlightPath.lineWidth = 0.95
            highlightPath.stroke()
        case .beanFilled:
            NSColor.black.setFill()
            beanPath.fill()

            NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
            creasePath.lineWidth = 1.9
            creasePath.stroke()
            highlightPath.lineWidth = 1.05
            highlightPath.stroke()
            NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
        }

        return image
    }
}
