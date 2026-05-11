import AppKit
import CoreGraphics

@MainActor
final class WorkspaceActivationPublisher {
    var onActivate: ((FocusEvent) -> Void)?

    private var observerTask: Task<Void, Never>?

    func start() {
        observerTask?.cancel()
        let stream = NSWorkspace.shared.notificationCenter.notifications(
            named: NSWorkspace.didActivateApplicationNotification
        )
        observerTask = Task { @MainActor [weak self] in
            for await note in stream {
                guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleID = app.bundleIdentifier else { continue }
                let displayID = Self.currentDisplayID()
                let event = FocusEvent(bundleID: bundleID, pid: app.processIdentifier, displayID: displayID)
                self?.onActivate?(event)
            }
        }
    }

    func stop() {
        observerTask?.cancel()
        observerTask = nil
    }

    static func currentDisplayID() -> CGDirectDisplayID {
        if let screen = NSScreen.main,
           let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return CGDirectDisplayID(number.uint32Value)
        }
        return CGMainDisplayID()
    }

    static func builtInDisplayID() -> CGDirectDisplayID? {
        for screen in NSScreen.screens {
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { continue }
            let id = CGDirectDisplayID(number.uint32Value)
            if CGDisplayIsBuiltin(id) != 0 { return id }
        }
        return nil
    }
}
