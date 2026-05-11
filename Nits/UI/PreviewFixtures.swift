#if DEBUG
import AppKit
import CoreGraphics

@MainActor
enum PreviewFixtures {
    static let samplePresets: [AppPreset] = [
        AppPreset(bundleID: "com.microsoft.VSCode", brightness: 0.15, displayName: "Visual Studio Code"),
        AppPreset(bundleID: "com.apple.dt.Xcode", brightness: 0.20, displayName: "Xcode"),
        AppPreset(bundleID: "com.apple.Safari", brightness: 0.85, displayName: "Safari"),
        AppPreset(bundleID: "com.apple.QuickTimePlayerX", brightness: 0.95, displayName: "QuickTime Player"),
        AppPreset(bundleID: "com.apple.Terminal", brightness: 0.40, displayName: "Terminal"),
        AppPreset(bundleID: "com.spotify.client", brightness: 0.70, displayName: "Spotify"),
    ]

    static func sampleInstalledApps() -> [InstalledApp] {
        let names: [(String, String)] = [
            ("com.microsoft.VSCode", "Visual Studio Code"),
            ("com.apple.dt.Xcode", "Xcode"),
            ("com.apple.Safari", "Safari"),
            ("com.apple.QuickTimePlayerX", "QuickTime Player"),
            ("com.apple.Terminal", "Terminal"),
            ("com.spotify.client", "Spotify"),
        ]
        return names.map { InstalledApp(bundleID: $0.0, name: $0.1, iconImage: nil) }
    }

    static func makeService(presets: [AppPreset]? = nil,
                             isEnabled: Bool = true,
                             duration: TimeInterval = 0.6,
                             currentFocusBundleID: String? = nil,
                             isTransitioning: Bool = false) -> NitsService {
        let store = InMemoryPresetStore(presets ?? samplePresets)
        let settings = AppSettings(defaults: previewDefaults())
        settings.transitionDuration = duration
        settings.isEnabled = isEnabled
        let svc = NitsService(
            store: store,
            settings: settings,
            sink: NoopBrightnessSink(),
            reader: ConstantBrightnessReader(0.6),
            clock: SystemTimeSource(),
            launchAtLogin: LaunchAtLoginController()
        )
        if let id = currentFocusBundleID {
            svc.coordinator.handleFocusChange(FocusEvent(bundleID: id, pid: 0, displayID: CGMainDisplayID()))
        }
        return svc
    }

    private static func previewDefaults() -> UserDefaults {
        UserDefaults(suiteName: "preview-\(UUID().uuidString)")!
    }
}

@MainActor
private final class NoopBrightnessSink: BrightnessSink {
    func setBrightness(_ value: Double, on displayID: CGDirectDisplayID) {}
}

@MainActor
private final class ConstantBrightnessReader: BrightnessReader {
    let value: Double
    init(_ value: Double) { self.value = value }
    func brightness(on displayID: CGDirectDisplayID) -> Double? { value }
}
#endif
