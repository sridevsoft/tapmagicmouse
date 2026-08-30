import Foundation

/// Finds Magic Mice and feeds their touch frames to the engine.
final class TouchSource {

    static let shared = TouchSource()
    private let engine = TapEngine()
    private var devices: [MTDeviceRef] = []

    private(set) var deviceCount = 0

    func start() {
        guard devices.isEmpty else { return }
        guard let list = MTDeviceCreateList() else { return }
        let array = list.takeRetainedValue() as NSArray
        let n = CFArrayGetCount(array)

        // A Magic Mouse reports an opaque surface; a trackpad does not. Never
        // touch a built-in trackpad — macOS already owns its tap-to-click.
        var candidates: [MTDeviceRef] = []
        var fallback: [MTDeviceRef] = []
        for i in 0..<n {
            let device = unsafeBitCast(CFArrayGetValueAtIndex(array, i), to: MTDeviceRef.self)
            if MTDeviceIsBuiltIn(device) { continue }
            if MTDeviceIsOpaqueSurface(device) { candidates.append(device) }
            else { fallback.append(device) }
        }

        // Only fall back to "any external multitouch device" if the surface probe
        // recognised nothing, so an unfamiliar Magic Mouse still works.
        for device in (candidates.isEmpty ? fallback : candidates) {
            devices.append(device)
            MTRegisterContactFrameCallback(device, frameCallback)
            MTDeviceStart(device, 0)
        }
        deviceCount = devices.count
    }

    func stop() {
        for device in devices {
            MTUnregisterContactFrameCallback(device, frameCallback)
            MTDeviceStop(device)
        }
        devices.removeAll()
        deviceCount = 0
        engine.reset()
    }

    /// Devices go away on sleep and Bluetooth reconnects; rebuild the list.
    func restart() {
        stop()
        start()
    }

    fileprivate func deliver(_ touches: UnsafeMutablePointer<MTTouch>, _ count: Int) {
        engine.handle(touches: touches, count: count)
    }

    fileprivate func deliverLift() {
        var dummy = MTTouch()
        withUnsafeMutablePointer(to: &dummy) { engine.handle(touches: $0, count: 0) }
    }
}

/// C callback — must be a plain function with no captured state.
private func frameCallback(device: Int32, touches: UnsafeMutablePointer<MTTouch>?,
                           numTouches: Int32, timestamp: Double, frame: Int32) -> Int32 {
    if numTouches <= 0 || touches == nil {
        TouchSource.shared.deliverLift()
    } else {
        TouchSource.shared.deliver(touches!, Int(numTouches))
    }
    return 0
}
