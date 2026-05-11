import Foundation
import Observation

@MainActor
protocol PresetStoring: AnyObject {
    var presets: [AppPreset] { get }
    func preset(for bundleID: String) -> AppPreset?
    func upsert(_ preset: AppPreset)
    func updateBrightness(_ value: Double, for bundleID: String)
    func remove(bundleID: String)
}

@Observable @MainActor
final class InMemoryPresetStore: PresetStoring {
    var presets: [AppPreset] = []

    init(_ initial: [AppPreset] = []) {
        for preset in initial { upsert(preset) }
    }

    func preset(for bundleID: String) -> AppPreset? {
        presets.first(where: { $0.bundleID == bundleID })
    }

    func upsert(_ preset: AppPreset) {
        if let index = presets.firstIndex(where: { $0.bundleID == preset.bundleID }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
    }

    func updateBrightness(_ value: Double, for bundleID: String) {
        guard let index = presets.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        presets[index].brightness = AppPreset.clamp(value)
    }

    func remove(bundleID: String) {
        presets.removeAll(where: { $0.bundleID == bundleID })
    }
}
