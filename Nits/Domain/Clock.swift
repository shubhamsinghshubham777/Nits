import Foundation
import QuartzCore

@MainActor
protocol TimeSource: AnyObject {
    var now: TimeInterval { get }
}

@MainActor
final class SystemTimeSource: TimeSource {
    var now: TimeInterval { CACurrentMediaTime() }
}
