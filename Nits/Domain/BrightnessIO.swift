import Foundation
import CoreGraphics

@MainActor
protocol BrightnessSink: AnyObject {
    func setBrightness(_ value: Double, on displayID: CGDirectDisplayID)
}

@MainActor
protocol BrightnessReader: AnyObject {
    func brightness(on displayID: CGDirectDisplayID) -> Double?
}

@MainActor
protocol WindowListProvider: AnyObject {
    func onScreenWindowBounds(forPID pid: pid_t) -> [CGRect]
}

@MainActor
protocol ScreenProvider: AnyObject {
    var mainDisplayID: CGDirectDisplayID { get }
    func displayID(containing rect: CGRect) -> CGDirectDisplayID?
}
