import Foundation
import CoreGraphics
import Observation

@Observable @MainActor
final class BrightnessCoordinator {
    private let store: any PresetStoring
    private let sink: any BrightnessSink
    private let clock: any TimeSource

    var transitionDuration: TimeInterval = 0.6
    private(set) var isEnabled: Bool = true
    private(set) var manualBaseline: Double = 0.8
    private(set) var currentFocus: FocusEvent?
    private(set) var isTransitioning: Bool = false

    private var lastCommandedValue: Double?
    private var transition: ActiveTransition?

    private struct ActiveTransition {
        let from: Double
        let to: Double
        let startTime: TimeInterval
        let displayID: CGDirectDisplayID
        var lastEmittedValue: Double
    }

    init(store: any PresetStoring, sink: any BrightnessSink, clock: any TimeSource) {
        self.store = store
        self.sink = sink
        self.clock = clock
    }

    func start(initialBrightness: Double) {
        let clamped = AppPreset.clamp(initialBrightness)
        manualBaseline = clamped
        lastCommandedValue = clamped
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            transition = nil
            isTransitioning = false
        }
    }

    func handleFocusChange(_ event: FocusEvent) {
        guard isEnabled else { return }
        if event.bundleID == currentFocus?.bundleID {
            currentFocus = event
            return
        }
        currentFocus = event

        let target = store.preset(for: event.bundleID)?.brightness ?? manualBaseline
        let from = currentValue()
        beginTransition(from: from, to: target, displayID: event.displayID)
    }

    func handleObservedBrightness(_ value: Double, on displayID: CGDirectDisplayID) {
        guard isEnabled else { return }
        guard transition == nil else { return }
        let clamped = AppPreset.clamp(value)
        guard let last = lastCommandedValue else {
            lastCommandedValue = clamped
            manualBaseline = clamped
            return
        }
        guard abs(clamped - last) > 0.005 else { return }

        lastCommandedValue = clamped
        if let focus = currentFocus, store.preset(for: focus.bundleID) != nil {
            store.updateBrightness(clamped, for: focus.bundleID)
        } else {
            manualBaseline = clamped
        }
    }

    func tick() {
        guard isEnabled, var active = transition else { return }
        let elapsed = clock.now - active.startTime
        let v = BrightnessCurve.value(at: elapsed,
                                      from: active.from,
                                      to: active.to,
                                      duration: transitionDuration)
        sink.setBrightness(v, on: active.displayID)
        lastCommandedValue = v
        active.lastEmittedValue = v
        if elapsed >= transitionDuration {
            transition = nil
            isTransitioning = false
        } else {
            transition = active
        }
    }

    var currentCommandedValue: Double {
        currentValue()
    }

    func reapplyFocus() {
        guard let focus = currentFocus else { return }
        let target = store.preset(for: focus.bundleID)?.brightness ?? manualBaseline
        let from = currentValue()
        beginTransition(from: from, to: target, displayID: focus.displayID)
    }

    private func currentValue() -> Double {
        if let t = transition { return t.lastEmittedValue }
        return lastCommandedValue ?? manualBaseline
    }

    private func beginTransition(from: Double, to: Double, displayID: CGDirectDisplayID) {
        let active = ActiveTransition(
            from: from, to: to,
            startTime: clock.now,
            displayID: displayID,
            lastEmittedValue: from
        )
        transition = active
        isTransitioning = true
        sink.setBrightness(from, on: displayID)
        lastCommandedValue = from
    }
}
