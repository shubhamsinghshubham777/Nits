import Testing
import Foundation
@testable import Nits

struct BrightnessCurveTests {
    @Test func returnsFromAtZero() {
        let v = BrightnessCurve.value(at: 0, from: 0.2, to: 0.9, duration: 1.0)
        #expect(abs(v - 0.2) < 1e-9)
    }

    @Test func returnsToAtDuration() {
        let v = BrightnessCurve.value(at: 1.0, from: 0.2, to: 0.9, duration: 1.0)
        #expect(abs(v - 0.9) < 1e-9)
    }

    @Test func monotonicAscending() {
        let duration = 1.0
        var last = -Double.infinity
        for i in 0...100 {
            let t = Double(i) / 100 * duration
            let v = BrightnessCurve.value(at: t, from: 0.1, to: 0.9, duration: duration)
            #expect(v >= last - 1e-12)
            last = v
        }
    }

    @Test func monotonicDescending() {
        let duration = 1.0
        var last = Double.infinity
        for i in 0...100 {
            let t = Double(i) / 100 * duration
            let v = BrightnessCurve.value(at: t, from: 0.9, to: 0.1, duration: duration)
            #expect(v <= last + 1e-12)
            last = v
        }
    }

    @Test func clampedOutsideDuration() {
        let duration = 1.0
        let before = BrightnessCurve.value(at: -1.0, from: 0.2, to: 0.9, duration: duration)
        let after = BrightnessCurve.value(at: 5.0, from: 0.2, to: 0.9, duration: duration)
        #expect(abs(before - 0.2) < 1e-9)
        #expect(abs(after - 0.9) < 1e-9)
    }

    // Going 0 → 1 with easeInOut on gamma-corrected space, the midpoint is the
    // perceptual midpoint pow(0.5, 1/2.2) ≈ 0.73 — distinctly above the linear midpoint 0.5.
    @Test func midpointFollowsPerceptualCurveNotLinear() {
        let duration = 1.0
        let mid = BrightnessCurve.value(at: 0.5, from: 0.0, to: 1.0, duration: duration)
        #expect(mid > 0.6)
        #expect(mid < 0.85)
    }
}
