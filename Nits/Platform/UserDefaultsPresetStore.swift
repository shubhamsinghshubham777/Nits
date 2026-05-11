import Foundation
import Observation

@Observable @MainActor
final class UserDefaultsPresetStore: PresetStoring {
    var presets: [AppPreset] = []
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    init(defaults: UserDefaults = .standard, key: String = "nits.presets.v1") {
        self.defaults = defaults
        self.key = key
        load()
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
        save()
    }

    func updateBrightness(_ value: Double, for bundleID: String) {
        guard let index = presets.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        presets[index].brightness = AppPreset.clamp(value)
        save()
    }

    func remove(bundleID: String) {
        presets.removeAll(where: { $0.bundleID == bundleID })
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        presets = (try? JSONDecoder().decode([AppPreset].self, from: data)) ?? []
    }

    private func save() {
        if let data = try? JSONEncoder().encode(presets) {
            defaults.set(data, forKey: key)
        }
    }
}
