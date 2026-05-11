import Foundation
import CoreGraphics

// DisplayServices.framework is a private framework that provides reliable
// brightness control on Apple Silicon for the built-in display.
// External displays require DDC/CI and are not handled here (v1 scope).
private typealias DSSetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
private typealias DSGetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

private enum DisplayServicesBindings {
    static let handle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
    }()

    static let setBrightness: DSSetFn? = {
        guard let handle, let sym = dlsym(handle, "DisplayServicesSetBrightness") else { return nil }
        return unsafeBitCast(sym, to: DSSetFn.self)
    }()

    static let getBrightness: DSGetFn? = {
        guard let handle, let sym = dlsym(handle, "DisplayServicesGetBrightness") else { return nil }
        return unsafeBitCast(sym, to: DSGetFn.self)
    }()
}

@MainActor
final class DisplayServicesBrightnessSink: BrightnessSink {
    func setBrightness(_ value: Double, on displayID: CGDirectDisplayID) {
        guard CGDisplayIsBuiltin(displayID) != 0 else { return }
        guard let fn = DisplayServicesBindings.setBrightness else { return }
        _ = fn(displayID, Float(AppPreset.clamp(value)))
    }
}

@MainActor
final class DisplayServicesBrightnessReader: BrightnessReader {
    func brightness(on displayID: CGDirectDisplayID) -> Double? {
        guard CGDisplayIsBuiltin(displayID) != 0 else { return nil }
        guard let fn = DisplayServicesBindings.getBrightness else { return nil }
        var out: Float = 0
        let rc = fn(displayID, &out)
        guard rc == 0 else { return nil }
        return Double(out)
    }
}
