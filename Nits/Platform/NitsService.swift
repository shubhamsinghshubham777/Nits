import AppKit
import CoreGraphics
import Observation

@Observable @MainActor
final class NitsService {
    let store: any PresetStoring
    let settings: AppSettings
    let coordinator: BrightnessCoordinator
    let launchAtLogin: LaunchAtLoginController

    @ObservationIgnored private let sink: any BrightnessSink
    @ObservationIgnored private let reader: any BrightnessReader
    @ObservationIgnored private let workspace: WorkspaceActivationPublisher
    @ObservationIgnored private let poller: BrightnessPoller
    @ObservationIgnored private let pump: TransitionPump
    @ObservationIgnored private var started = false

    static func live() -> NitsService {
        NitsService(
            store: UserDefaultsPresetStore(),
            settings: AppSettings(),
            sink: DisplayServicesBrightnessSink(),
            reader: DisplayServicesBrightnessReader(),
            clock: SystemTimeSource(),
            launchAtLogin: LaunchAtLoginController()
        )
    }

    init(store: any PresetStoring,
         settings: AppSettings,
         sink: any BrightnessSink,
         reader: any BrightnessReader,
         clock: any TimeSource,
         launchAtLogin: LaunchAtLoginController) {
        self.store = store
        self.settings = settings
        self.sink = sink
        self.reader = reader
        self.launchAtLogin = launchAtLogin

        let coord = BrightnessCoordinator(store: store, sink: sink, clock: clock)
        coord.transitionDuration = settings.transitionDuration
        coord.setEnabled(settings.isEnabled)
        self.coordinator = coord

        self.workspace = WorkspaceActivationPublisher()
        self.poller = BrightnessPoller(reader: reader)
        self.pump = TransitionPump()

        poller.getDisplayID = { WorkspaceActivationPublisher.builtInDisplayID() ?? CGMainDisplayID() }
        workspace.onActivate = { [weak self] event in
            self?.coordinator.handleFocusChange(event)
        }
        poller.onSample = { [weak self] value, display in
            self?.coordinator.handleObservedBrightness(value, on: display)
        }
        pump.onTick = { [weak self] in
            self?.coordinator.tick()
        }
    }

    func start() {
        guard !started else { return }
        started = true
        let displayID = WorkspaceActivationPublisher.builtInDisplayID() ?? CGMainDisplayID()
        let initial = reader.brightness(on: displayID) ?? 0.8
        coordinator.start(initialBrightness: initial)
        workspace.start()
        poller.start()
        pump.start()

        // Apply preset for whatever is already focused (if any).
        if let app = NSWorkspace.shared.frontmostApplication,
           let bundleID = app.bundleIdentifier {
            let event = FocusEvent(
                bundleID: bundleID,
                pid: app.processIdentifier,
                displayID: WorkspaceActivationPublisher.currentDisplayID()
            )
            coordinator.handleFocusChange(event)
        }
    }

    func stop() {
        workspace.stop()
        poller.stop()
        pump.stop()
        started = false
    }

    func updateDuration(_ seconds: TimeInterval) {
        let clamped = min(max(seconds, AppSettings.minDuration), AppSettings.maxDuration)
        settings.transitionDuration = clamped
        coordinator.transitionDuration = clamped
    }

    func setEnabled(_ enabled: Bool) {
        settings.isEnabled = enabled
        coordinator.setEnabled(enabled)
    }

    @discardableResult
    func toggleManaged(bundleID: String, displayName: String) -> Bool {
        if store.preset(for: bundleID) != nil {
            store.remove(bundleID: bundleID)
            if coordinator.currentFocus?.bundleID == bundleID {
                coordinator.reapplyFocus()
            }
            return false
        } else {
            let brightness = coordinator.currentCommandedValue
            store.upsert(AppPreset(bundleID: bundleID,
                                   brightness: brightness,
                                   displayName: displayName))
            return true
        }
    }
}
