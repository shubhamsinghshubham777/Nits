import SwiftUI
import AppKit

@main
struct NitsApp: App {
    @NSApplicationDelegateAdaptor(NitsAppDelegate.self) private var appDelegate
    @State private var service: NitsService = NitsService.live()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(service: service)
                .task { service.start() }
        } label: {
            Image(systemName: service.coordinator.isEnabled
                  ? "sun.max.fill"
                  : "sun.max")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(service: service)
        }
    }
}

final class NitsAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Become a menu-bar–only app at runtime. Skipped inside Xcode Previews so the
        // preview host can complete its normal launch handshake.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == nil {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
