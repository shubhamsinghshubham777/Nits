import Foundation

struct AppPreset: Equatable, Hashable, Codable, Identifiable {
    let bundleID: String
    var brightness: Double
    var displayName: String

    var id: String { bundleID }

    init(bundleID: String, brightness: Double, displayName: String = "") {
        self.bundleID = bundleID
        self.brightness = Self.clamp(brightness)
        self.displayName = displayName
    }

    static func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
