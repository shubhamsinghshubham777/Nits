import Testing
import Foundation
import CoreGraphics
@testable import Nits

@MainActor
struct NitsServiceToggleTests {
    private let displayA: CGDirectDisplayID = 1

    private func makeService(presets: [AppPreset] = [],
                             duration: TimeInterval = 1.0)
    -> (NitsService, InMemoryPresetStore, FakeSink, FakeClock) {
        let store = InMemoryPresetStore(presets)
        let sink = FakeSink()
        let clock = FakeClock()
        let settings = AppSettings(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        settings.transitionDuration = duration
        settings.isEnabled = true
        let svc = NitsService(
            store: store,
            settings: settings,
            sink: sink,
            reader: FakeReader(),
            clock: clock,
            launchAtLogin: LaunchAtLoginController()
        )
        svc.coordinator.start(initialBrightness: 0.5)
        return (svc, store, sink, clock)
    }

    @Test func addingPresetCapturesCurrentCommandedBrightness() {
        let (svc, store, _, clock) = makeService(duration: 1.0)
        // Focus an unmanaged app; baseline 0.5 becomes the commanded value once the transition settles.
        svc.coordinator.handleFocusChange(FocusEvent(bundleID: "com.acme.X", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); svc.coordinator.tick()
        // Simulate user nudging brightness while that unmanaged app is focused — baseline moves.
        svc.coordinator.handleObservedBrightness(0.33, on: displayA)

        let added = svc.toggleManaged(bundleID: "com.acme.X", displayName: "Acme X")

        #expect(added == true)
        #expect(store.preset(for: "com.acme.X")?.brightness == 0.33)
        #expect(store.preset(for: "com.acme.X")?.displayName == "Acme X")
    }

    @Test func removingPresetWhileFocusedTransitionsBackTowardBaseline() {
        let (svc, store, sink, clock) = makeService(
            presets: [AppPreset(bundleID: "vscode", brightness: 0.1, displayName: "VSCode")],
            duration: 1.0
        )
        svc.coordinator.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); svc.coordinator.tick()
        #expect(abs((sink.lastValue ?? -1) - 0.1) < 1e-9)

        let added = svc.toggleManaged(bundleID: "vscode", displayName: "VSCode")

        #expect(added == false)
        #expect(store.preset(for: "vscode") == nil)
        // A new transition toward the manual baseline (0.5) must have started.
        #expect(svc.coordinator.isTransitioning)
        clock.advance(by: 1.0); svc.coordinator.tick()
        #expect(abs((sink.lastValue ?? -1) - 0.5) < 1e-9)
    }

    @Test func removingPresetForNonFocusedAppDoesNotRetrigger() {
        let (svc, store, sink, clock) = makeService(
            presets: [
                AppPreset(bundleID: "vscode", brightness: 0.1, displayName: "VSCode"),
                AppPreset(bundleID: "safari", brightness: 0.9, displayName: "Safari"),
            ],
            duration: 1.0
        )
        svc.coordinator.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); svc.coordinator.tick()
        let callsBefore = sink.calls.count

        let added = svc.toggleManaged(bundleID: "safari", displayName: "Safari")

        #expect(added == false)
        #expect(store.preset(for: "safari") == nil)
        // No new transition should have started for the still-focused vscode app.
        #expect(sink.calls.count == callsBefore)
        #expect(svc.coordinator.isTransitioning == false)
    }

    @Test func toggleIsIdempotentAcrossTwoCalls() {
        let (svc, store, _, _) = makeService()
        _ = svc.toggleManaged(bundleID: "com.acme.X", displayName: "Acme X")
        #expect(store.preset(for: "com.acme.X") != nil)
        _ = svc.toggleManaged(bundleID: "com.acme.X", displayName: "Acme X")
        #expect(store.preset(for: "com.acme.X") == nil)
    }
}
