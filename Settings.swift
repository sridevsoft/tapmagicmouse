import Foundation

/// How forgiving tap recognition is. Lower = fewer accidental clicks from
/// resting fingers, but you have to tap more crisply.
enum Sensitivity: Int, CaseIterable {
    case low = 0, medium = 1, high = 2

    var title: String {
        switch self {
        case .low: return "Low (fewest accidental clicks)"
        case .medium: return "Medium"
        case .high: return "High (easiest taps)"
        }
    }

    /// A tap must finish within this many seconds.
    var maxDuration: Double {
        switch self {
        case .low: return 0.18
        case .medium: return 0.25
        case .high: return 0.35
        }
    }

    /// The finger may not slide more than this across the surface (0.0-1.0).
    var maxDrift: Float {
        switch self {
        case .low: return 0.04
        case .medium: return 0.08
        case .high: return 0.13
        }
    }
}

enum Settings {
    private static let d = UserDefaults.standard

    static func register() {
        d.register(defaults: [
            "enabled": true,
            "sensitivity": Sensitivity.medium.rawValue,
            "rightZone": 0.65,
            "twoFingerRightClick": false,
            "tapToDrag": false,
        ])
    }

    static var enabled: Bool {
        get { d.bool(forKey: "enabled") }
        set { d.set(newValue, forKey: "enabled") }
    }

    static var sensitivity: Sensitivity {
        get { Sensitivity(rawValue: d.integer(forKey: "sensitivity")) ?? .medium }
        set { d.set(newValue.rawValue, forKey: "sensitivity") }
    }

    /// Taps starting right of this fraction of the surface are right clicks.
    static var rightZone: Float {
        get { min(max(Float(d.double(forKey: "rightZone")), 0.4), 0.95) }
        set { d.set(Double(min(max(newValue, 0.4), 0.95)), forKey: "rightZone") }
    }

    static var twoFingerRightClick: Bool {
        get { d.bool(forKey: "twoFingerRightClick") }
        set { d.set(newValue, forKey: "twoFingerRightClick") }
    }

    static var tapToDrag: Bool {
        get { d.bool(forKey: "tapToDrag") }
        set { d.set(newValue, forKey: "tapToDrag") }
    }
}
