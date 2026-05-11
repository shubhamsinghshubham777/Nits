import Foundation

@MainActor
final class TransitionPump {
    var onTick: (@MainActor () -> Void)?

    private var timer: Timer?

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.onTick?() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
