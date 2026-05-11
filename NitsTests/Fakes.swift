import Foundation
import CoreGraphics
@testable import Nits

@MainActor
final class FakeClock: TimeSource {
    var now: TimeInterval = 0
    func advance(by seconds: TimeInterval) { now += seconds }
}

@MainActor
final class FakeSink: BrightnessSink {
    struct Call: Equatable {
        let value: Double
        let displayID: CGDirectDisplayID
    }
    private(set) var calls: [Call] = []
    func setBrightness(_ value: Double, on displayID: CGDirectDisplayID) {
        calls.append(Call(value: value, displayID: displayID))
    }
    func reset() { calls.removeAll() }
    var lastValue: Double? { calls.last?.value }
    var lastDisplayID: CGDirectDisplayID? { calls.last?.displayID }
}

@MainActor
final class FakeReader: BrightnessReader {
    var value: Double? = 0.5
    func brightness(on displayID: CGDirectDisplayID) -> Double? { value }
}

@MainActor
final class FakeWindowList: WindowListProvider {
    var perPID: [pid_t: [CGRect]] = [:]
    func onScreenWindowBounds(forPID pid: pid_t) -> [CGRect] {
        perPID[pid] ?? []
    }
}

@MainActor
final class FakeScreenProvider: ScreenProvider {
    var mainDisplayID: CGDirectDisplayID = 1
    var displays: [(id: CGDirectDisplayID, frame: CGRect)] = []
    func displayID(containing rect: CGRect) -> CGDirectDisplayID? {
        displays.first(where: { $0.frame.intersects(rect) })?.id
    }
}
