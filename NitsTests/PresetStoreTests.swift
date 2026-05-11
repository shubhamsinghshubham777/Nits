import Testing
@testable import Nits

@MainActor
struct PresetStoreTests {
    @Test func roundTripByBundleID() {
        let store = InMemoryPresetStore()
        store.upsert(AppPreset(bundleID: "com.acme.A", brightness: 0.3))
        let got = store.preset(for: "com.acme.A")
        #expect(got?.brightness == 0.3)
    }

    @Test func removeDropsTheEntry() {
        let store = InMemoryPresetStore([
            AppPreset(bundleID: "com.acme.A", brightness: 0.3),
            AppPreset(bundleID: "com.acme.B", brightness: 0.7),
        ])
        store.remove(bundleID: "com.acme.A")
        #expect(store.preset(for: "com.acme.A") == nil)
        #expect(store.preset(for: "com.acme.B") != nil)
        #expect(store.presets.count == 1)
    }

    @Test func brightnessClampedOnWrite() {
        let store = InMemoryPresetStore()
        store.upsert(AppPreset(bundleID: "A", brightness: 1.5))
        store.upsert(AppPreset(bundleID: "B", brightness: -0.3))
        #expect(store.preset(for: "A")?.brightness == 1.0)
        #expect(store.preset(for: "B")?.brightness == 0.0)

        store.updateBrightness(2.0, for: "A")
        #expect(store.preset(for: "A")?.brightness == 1.0)
    }

    @Test func insertionOrderPreserved() {
        let store = InMemoryPresetStore()
        let ids = ["c", "a", "b", "d"]
        for id in ids {
            store.upsert(AppPreset(bundleID: id, brightness: 0.5))
        }
        #expect(store.presets.map(\.bundleID) == ids)

        // Updating an existing preset must not reorder.
        store.upsert(AppPreset(bundleID: "a", brightness: 0.1))
        #expect(store.presets.map(\.bundleID) == ids)
    }
}
