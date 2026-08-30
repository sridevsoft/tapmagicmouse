import QuartzCore
import CoreGraphics
import Foundation

/// Posts synthetic mouse events.
///
/// The subtle part is `clickState`. macOS decides "this was a double-click" from
/// a counter carried on the event itself, not from timing at the receiving end.
/// A naive tap-to-click posts every click with clickState 1, so double-tapping
/// never opens a folder in Finder or selects a word in a text field. We track
/// the run length ourselves and stamp it on the event.
final class ClickSynthesizer {

    private var lastClickTime: CFTimeInterval = 0
    private var lastClickPoint = CGPoint.zero
    private var lastButton: CGMouseButton = .left
    private var clickRun: Int64 = 0

    /// macOS's own double-click speed, as set in System Settings.
    private var doubleClickInterval: CFTimeInterval {
        let t = UserDefaults.standard.double(forKey: "com.apple.mouse.doubleClickThreshold")
        return t > 0 ? t : 0.5
    }

    private func nextClickState(at point: CGPoint, button: CGMouseButton) -> Int64 {
        let now = CACurrentMediaTime()
        let soonEnough = (now - lastClickTime) <= doubleClickInterval
        let closeEnough = abs(point.x - lastClickPoint.x) < 6 && abs(point.y - lastClickPoint.y) < 6

        if soonEnough && closeEnough && button == lastButton {
            clickRun = min(clickRun + 1, 3)
        } else {
            clickRun = 1
        }

        lastClickTime = now
        lastClickPoint = point
        lastButton = button
        return clickRun
    }

    func click(at point: CGPoint, button: CGMouseButton) {
        let state = nextClickState(at: point, button: button)
        let down: CGEventType = (button == .right) ? .rightMouseDown : .leftMouseDown
        let up: CGEventType = (button == .right) ? .rightMouseUp : .leftMouseUp

        post(type: down, at: point, button: button, clickState: state)
        post(type: up, at: point, button: button, clickState: state)
    }

    func dragBegin(at point: CGPoint) {
        // Reuse the click run so a double-tap-drag still reads as a double-click
        // press, which is what makes text selection by word work.
        let state = nextClickState(at: point, button: .left)
        post(type: .leftMouseDown, at: point, button: .left, clickState: state)
    }

    func dragMove(to point: CGPoint) {
        post(type: .leftMouseDragged, at: point, button: .left, clickState: 1)
    }

    func dragEnd(at point: CGPoint) {
        post(type: .leftMouseUp, at: point, button: .left, clickState: 1)
    }

    private func post(type: CGEventType, at point: CGPoint, button: CGMouseButton, clickState: Int64) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type,
                                  mouseCursorPosition: point, mouseButton: button) else { return }
        event.setIntegerValueField(.mouseEventClickState, value: clickState)
        event.post(tap: .cghidEventTap)
    }
}
