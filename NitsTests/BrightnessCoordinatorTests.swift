import Testing
import Foundation
import CoreGraphics
@testable import Nits

@MainActor
struct BrightnessCoordinatorTests {
    private let displayA: CGDirectDisplayID = 1
    private let displayB: CGDirectDisplayID = 2

    private func makeSystem(initialBrightness: Double = 0.5,
                            presets: [AppPreset] = [],
                            duration: TimeInterval = 1.0)
    -> (BrightnessCoordinator, InMemoryPresetStore, FakeSink, FakeClock) {
        let store = InMemoryPresetStore(presets)
        let sink = FakeSink()
        let clock = FakeClock()
        let coord = BrightnessCoordinator(store: store, sink: sink, clock: clock)
        coord.transitionDuration = duration
        coord.start(initialBrightness: initialBrightness)
        return (coord, store, sink, clock)
    }

    // 10
    @Test func focusOnManagedAppEndsAtPresetValueOnFocusedDisplay() {
        let (coord, _, sink, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "vscode", brightness: 0.15)],
            duration: 1.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0)
        coord.tick()
        #expect(abs((sink.lastValue ?? -1) - 0.15) < 1e-9)
        #expect(sink.lastDisplayID == displayA)
    }

    // 11
    @Test func focusOnUnmanagedAppEndsAtManualBaseline() {
        let (coord, _, sink, clock) = makeSystem(initialBrightness: 0.42, duration: 1.0)
        coord.handleFocusChange(FocusEvent(bundleID: "unmanaged", pid: 1, displayID: displayA))
        clock.advance(by: 1.0)
        coord.tick()
        #expect(abs((sink.lastValue ?? -1) - 0.42) < 1e-9)
    }

    // 12
    @Test func baselineEqualsInitialBrightnessIfNeverManuallyChanged() {
        let (coord, _, _, _) = makeSystem(initialBrightness: 0.31)
        #expect(coord.manualBaseline == 0.31)
    }

    // 13
    @Test func manualChangeWhileManagedFocusedUpdatesPresetAndBaseline() {
        let (coord, store, _, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "vscode", brightness: 0.15)],
            duration: 1.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); coord.tick()  // settle transition

        coord.handleObservedBrightness(0.65, on: displayA)

        #expect(store.preset(for: "vscode")?.brightness == 0.65)
        #expect(coord.manualBaseline == 0.65)
    }

    // 14
    @Test func manualChangeWhileUnmanagedFocusedUpdatesOnlyBaseline() {
        let (coord, store, _, clock) = makeSystem(initialBrightness: 0.5, duration: 1.0)
        coord.handleFocusChange(FocusEvent(bundleID: "unmanaged", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); coord.tick()

        coord.handleObservedBrightness(0.7, on: displayA)
        #expect(coord.manualBaseline == 0.7)
        #expect(store.presets.isEmpty)
    }

    // 15
    @Test func rapidSwitchStartsFromInterpolatedValue() {
        let (coord, _, sink, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [
                AppPreset(bundleID: "A", brightness: 0.0),
                AppPreset(bundleID: "B", brightness: 1.0),
            ],
            duration: 1.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "A", pid: 1, displayID: displayA))
        clock.advance(by: 0.5); coord.tick()
        let valueMidA = sink.lastValue ?? -1
        // Mid-transition, well clear of 0.5 (the starting value) and 0.0 (the target).
        #expect(valueMidA < 0.5 && valueMidA > 0.0)

        // Now switch to B. The new transition's "from" must equal the *current* value,
        // not A's target (0.0) and not the original baseline (0.5).
        coord.handleFocusChange(FocusEvent(bundleID: "B", pid: 2, displayID: displayB))
        let firstEmitForB = sink.lastValue ?? -1
        #expect(abs(firstEmitForB - valueMidA) < 1e-9)
        #expect(sink.lastDisplayID == displayB)
    }

    // 16
    @Test func reFocusingSameAppDoesNotEmitNewTransition() {
        let (coord, _, sink, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "vscode", brightness: 0.15)],
            duration: 1.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); coord.tick()
        let countAfterSettling = sink.calls.count

        coord.handleFocusChange(FocusEvent(bundleID: "vscode", pid: 1, displayID: displayA))
        clock.advance(by: 1.0); coord.tick()

        #expect(sink.calls.count == countAfterSettling)
    }

    // 17
    @Test func disableMidTransitionCancelsFurtherWrites() {
        let (coord, _, sink, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "A", brightness: 0.0)],
            duration: 1.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "A", pid: 1, displayID: displayA))
        clock.advance(by: 0.25); coord.tick()
        let countBefore = sink.calls.count

        coord.setEnabled(false)
        clock.advance(by: 0.5); coord.tick()
        clock.advance(by: 0.5); coord.tick()

        #expect(sink.calls.count == countBefore)
        #expect(coord.isTransitioning == false)
    }

    // 18
    @Test func transitionRespectsConfiguredDuration() {
        let (coord, _, sink, clock) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "A", brightness: 0.0)],
            duration: 2.0
        )
        coord.handleFocusChange(FocusEvent(bundleID: "A", pid: 1, displayID: displayA))

        // Halfway through 2s, must be strictly between start and target.
        clock.advance(by: 1.0); coord.tick()
        let mid = sink.lastValue ?? -1
        #expect(mid > 0.0 && mid < 0.5)

        // At end of 2s, must reach target.
        clock.advance(by: 1.0); coord.tick()
        #expect(abs((sink.lastValue ?? -1) - 0.0) < 1e-9)

        // Before 2s have elapsed, must NOT yet be at the target.
        let (coord2, _, sink2, clock2) = makeSystem(
            initialBrightness: 0.5,
            presets: [AppPreset(bundleID: "A", brightness: 0.0)],
            duration: 2.0
        )
        coord2.handleFocusChange(FocusEvent(bundleID: "A", pid: 1, displayID: displayA))
        clock2.advance(by: 0.5); coord2.tick()
        #expect((sink2.lastValue ?? -1) > 0.0)
    }
}
