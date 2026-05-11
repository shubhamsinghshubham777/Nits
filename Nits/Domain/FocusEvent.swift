import Foundation
import CoreGraphics

struct FocusEvent: Equatable, Hashable {
    let bundleID: String
    let pid: pid_t
    let displayID: CGDirectDisplayID
}
