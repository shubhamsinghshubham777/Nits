import Foundation
import CoreGraphics

@MainActor
final class BrightnessPoller {
    var onSample: (@MainActor (Double, CGDirectDisplayID) -> Void)?
    var getDisplayID: (@MainActor () -> CGDirectDisplayID)?

    private let reader: any BrightnessReader
    private var timer: Timer?

    init(reader: any BrightnessReader) {
        self.reader = reader
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard let id = self.getDisplayID?() else { return }
                if let value = self.reader.brightness(on: id) {
                    self.onSample?(value, id)
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
