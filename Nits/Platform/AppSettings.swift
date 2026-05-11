import Foundation
import Observation

@Observable @MainActor
final class AppSettings {
    static let minDuration: TimeInterval = 0.3
    static let maxDuration: TimeInterval = 2.0
    static let defaultDuration: TimeInterval = 0.6

    var transitionDuration: TimeInterval {
        didSet { defaults.set(transitionDuration, forKey: Keys.duration) }
    }

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.object(forKey: Keys.duration) as? TimeInterval
        self.transitionDuration = stored.map {
            min(max($0, Self.minDuration), Self.maxDuration)
        } ?? Self.defaultDuration
        self.isEnabled = (defaults.object(forKey: Keys.enabled) as? Bool) ?? true
    }

    private enum Keys {
        static let duration = "nits.transitionDuration"
        static let enabled = "nits.isEnabled"
    }
}
