import QuartzCore
import CoreGraphics
import Foundation

/// Turns a stream of Magic Mouse touch frames into clicks and drags.
///
/// The whole problem is separating a deliberate tap from the incidental contact
/// of a hand resting on the mouse or scrolling. A tap qualifies only if it is
/// brief, barely moves across the surface, and is the only finger down.
final class TapEngine {

    enum Phase {
        case idle
        case tracking(started: CFTimeInterval, originX: Float, originY: Float, fingers: Int)
        case rejected            // this contact can no longer become a tap
        case dragging
    }

    private var phase: Phase = .idle
    private let clicker = ClickSynthesizer()

    /// When the previous tap ended, so we can spot a double-tap that starts a drag.
    private var lastTapEnded: CFTimeInterval = 0
    private var lastTapWasRight = false

    private var cursor: CGPoint { CGEvent(source: nil)?.location ?? .zero }

    /// Called for every frame of touch data from the mouse.
    func handle(touches: UnsafeMutablePointer<MTTouch>, count: Int) {
        guard Settings.enabled else { reset(); return }

        if count <= 0 {
            fingersLifted()
            return
        }

        let sens = Settings.sensitivity
        let primary = touches[0]

        switch phase {
        case .dragging:
            clicker.dragMove(to: cursor)

        case .idle:
            begin(with: primary, fingers: count, sens: sens)

        case .tracking(let started, let ox, let oy, let fingers):
            // A second finger arriving mid-contact is a gesture, not a tap —
            // unless two-finger right click is on and it lands quickly.
            let seen = max(fingers, count)
            if seen > 2 || (seen == 2 && !Settings.twoFingerRightClick) {
                phase = .rejected
                return
            }
            if CACurrentMediaTime() - started > sens.maxDuration {
                phase = .rejected
                return
            }
            let drift = max(abs(primary.normalized.position.x - ox),
                            abs(primary.normalized.position.y - oy))
            if drift > sens.maxDrift {
                phase = .rejected
                return
            }
            phase = .tracking(started: started, originX: ox, originY: oy, fingers: seen)

        case .rejected:
            break
        }
    }

    private func begin(with touch: MTTouch, fingers: Int, sens: Sensitivity) {
        let now = CACurrentMediaTime()

        // A fresh contact landing right after a tap means double-tap-and-drag:
        // press now and hold until the finger lifts.
        if Settings.tapToDrag, fingers == 1, !lastTapWasRight,
           now - lastTapEnded <= 0.30 {
            clicker.dragBegin(at: cursor)
            phase = .dragging
            return
        }

        if fingers > 2 || (fingers == 2 && !Settings.twoFingerRightClick) {
            phase = .rejected
            return
        }

        phase = .tracking(started: now,
                          originX: touch.normalized.position.x,
                          originY: touch.normalized.position.y,
                          fingers: fingers)
    }

    private func fingersLifted() {
        switch phase {
        case .dragging:
            clicker.dragEnd(at: cursor)
            lastTapEnded = 0          // a drag does not chain into another drag

        case .tracking(let started, let originX, _, let fingers):
            let sens = Settings.sensitivity
            if CACurrentMediaTime() - started <= sens.maxDuration {
                let isRight = (fingers == 2 && Settings.twoFingerRightClick)
                    || (fingers == 1 && originX > Settings.rightZone)
                clicker.click(at: cursor, button: isRight ? .right : .left)
                lastTapEnded = CACurrentMediaTime()
                lastTapWasRight = isRight
            }

        case .idle, .rejected:
            break
        }
        phase = .idle
    }

    /// Drop any in-progress contact without emitting anything.
    func reset() {
        if case .dragging = phase { clicker.dragEnd(at: cursor) }
        phase = .idle
    }
}
