import Foundation
import CoreGraphics

@MainActor
struct DisplayResolver {
    let windows: any WindowListProvider
    let screens: any ScreenProvider

    func displayID(forPID pid: pid_t) -> CGDirectDisplayID {
        let rects = windows.onScreenWindowBounds(forPID: pid)
        for rect in rects {
            if let id = screens.displayID(containing: rect) { return id }
        }
        return screens.mainDisplayID
    }
}
