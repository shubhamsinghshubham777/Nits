import Foundation

enum BrightnessCurve {
    static let gamma: Double = 2.2

    static func value(at elapsed: TimeInterval,
                      from: Double,
                      to: Double,
                      duration: TimeInterval) -> Double {
        guard duration > 0 else { return to }
        let t = max(0, min(1, elapsed / duration))
        let eased = easeInOut(t)
        let pFrom = perceptual(from)
        let pTo = perceptual(to)
        let pV = pFrom + (pTo - pFrom) * eased
        return linear(pV)
    }

    private static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    private static func perceptual(_ x: Double) -> Double {
        pow(max(0, min(1, x)), gamma)
    }

    private static func linear(_ y: Double) -> Double {
        pow(max(0, y), 1.0 / gamma)
    }
}
