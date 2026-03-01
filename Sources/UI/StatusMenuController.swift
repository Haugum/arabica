import AppKit
import Foundation

@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let model: SessionMenuModel
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(
        model: SessionMenuModel,
        statusBar: NSStatusBar = .system
    ) {
        self.model = model
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        model.onChange = { [weak self] in
            self?.refresh()
        }
        configureStatusItem()
    }

    func start() {
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func refresh() {
        render(activeSession: model.activeSession)
        rebuildMenu()
    }

    private func render(activeSession: ActiveSession?) {
        let appearance = StatusItemAppearance.forSession(activeSession)
        guard let button = statusItem.button else {
            return
        }

        let image = appearance.makeImage()
        image.accessibilityDescription = appearance.accessibilityLabel
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = appearance.accessibilityLabel
    }

    private func configureStatusItem() {
        menu.delegate = self
        statusItem.menu = menu
        statusItem.isVisible = true
    }

    private func rebuildMenu() {
        let content = model.menuContent

        menu.removeAllItems()
        menu.addItem(disabledItem(title: content.statusTitle))
        content.detailTitles.forEach { detailTitle in
            menu.addItem(disabledItem(title: detailTitle))
        }
        menu.addItem(.separator())
        menu.addItem(
            startIndefinitelyMenuItem()
        )
        menu.addItem(displayToggleMenuItem())

        let endSessionItem = actionItem(title: "End Current Session", action: #selector(endSession(_:)))
        endSessionItem.isEnabled = model.activeSession != nil
        menu.addItem(endSessionItem)

        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Quit Arabica", action: #selector(quitApp(_:)), keyEquivalent: "q"))
    }

    private func startIndefinitelyMenuItem() -> NSMenuItem {
        let item = actionItem(
                title: "Keep Awake Indefinitely",
                action: #selector(startIndefiniteSession(_:))
            )
        item.state = model.hasActiveIndefiniteSession ? .on : .off
        return item
    }

    private func displayToggleMenuItem() -> NSMenuItem {
        let item = actionItem(title: "Let Display Sleep", action: #selector(toggleDisplayAwake(_:)))
        item.state = model.letsDisplaySleepForNextSession ? .on : .off
        return item
    }

    private func actionItem(
        title: String,
        action: Selector,
        keyEquivalent: String = ""
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func disabledItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc
    private func startIndefiniteSession(_ sender: Any?) {
        model.toggleIndefiniteSession()
    }

    @objc
    private func endSession(_ sender: Any?) {
        model.endSession()
    }

    @objc
    private func toggleDisplayAwake(_ sender: Any?) {
        model.toggleDisplayAwakeSelection()
    }

    @objc
    private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
