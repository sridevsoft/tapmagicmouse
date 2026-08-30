import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        Settings.register()
        buildMenuBarItem()

        // Bluetooth drops and sleep both invalidate the device handles.
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(wake),
            name: NSWorkspace.didWakeNotification, object: nil)

        if ensureAccessibility() { TouchSource.shared.start() }
    }

    func applicationWillTerminate(_ note: Notification) {
        TouchSource.shared.stop()
    }

    @objc private func wake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            TouchSource.shared.restart()
            self.refreshIcon()
        }
    }

    // MARK: - Permission

    private func ensureAccessibility() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(opts) { return true }

        // Poll until the user grants it, then start for real.
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if AXIsProcessTrustedWithOptions(nil) {
                timer.invalidate()
                TouchSource.shared.start()
                self.refreshIcon()
            }
        }
        return false
    }

    // MARK: - Menu bar

    private func buildMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshIcon()
        statusItem.menu = buildMenu()
    }

    private func refreshIcon() {
        guard let button = statusItem?.button else { return }
        let name = Settings.enabled ? "cursorarrow.click.2" : "cursorarrow.slash"
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "TapMouse") {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = Settings.enabled ? "Tap" : "Tap·off"
        }
        button.appearsDisabled = !Settings.enabled
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(item("Tap to Click", #selector(toggleEnabled), key: "t"))
        menu.addItem(.separator())

        let sens = NSMenu()
        for level in Sensitivity.allCases {
            let i = item(level.title, #selector(pickSensitivity))
            i.tag = level.rawValue
            sens.addItem(i)
        }
        menu.addItem(submenu("Tap Sensitivity", sens))

        let zone = NSMenu()
        for pct in [50, 60, 65, 70, 80] {
            let i = item("Right \(100 - pct)% of surface", #selector(pickZone))
            i.tag = pct
            zone.addItem(i)
        }
        menu.addItem(submenu("Right-Click Area", zone))

        menu.addItem(item("Two-Finger Tap = Right Click", #selector(toggleTwoFinger)))
        menu.addItem(item("Double-Tap and Hold to Drag", #selector(toggleDrag)))

        menu.addItem(.separator())
        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        status.tag = 999
        menu.addItem(status)
        menu.addItem(item("Quit TapMouse", #selector(quit), key: "q"))
        return menu
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    private func submenu(_ title: String, _ sub: NSMenu) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        i.submenu = sub
        return i
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
        if !Settings.enabled { TouchSource.shared.stop() } else { TouchSource.shared.start() }
        refreshIcon()
    }

    @objc private func pickSensitivity(_ sender: NSMenuItem) {
        Settings.sensitivity = Sensitivity(rawValue: sender.tag) ?? .medium
    }

    @objc private func pickZone(_ sender: NSMenuItem) {
        Settings.rightZone = Float(sender.tag) / 100.0
    }

    @objc private func toggleTwoFinger() { Settings.twoFingerRightClick.toggle() }
    @objc private func toggleDrag() { Settings.tapToDrag.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }
}

extension AppDelegate: NSMenuDelegate {
    /// Tick the right boxes each time the menu opens.
    func menuNeedsUpdate(_ menu: NSMenu) {
        for i in menu.items {
            switch i.action {
            case #selector(toggleEnabled): i.state = Settings.enabled ? .on : .off
            case #selector(toggleTwoFinger): i.state = Settings.twoFingerRightClick ? .on : .off
            case #selector(toggleDrag): i.state = Settings.tapToDrag ? .on : .off
            default: break
            }
            if let sub = i.submenu {
                for s in sub.items {
                    if s.action == #selector(pickSensitivity) {
                        s.state = (s.tag == Settings.sensitivity.rawValue) ? .on : .off
                    } else if s.action == #selector(pickZone) {
                        s.state = (abs(Float(s.tag) / 100.0 - Settings.rightZone) < 0.005) ? .on : .off
                    }
                }
            }
            if i.tag == 999 {
                let n = TouchSource.shared.deviceCount
                i.title = AXIsProcessTrustedWithOptions(nil)
                    ? (n > 0 ? "Magic Mouse connected" : "No Magic Mouse found")
                    : "Waiting for Accessibility permission"
            }
        }
    }
}
