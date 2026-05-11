import SwiftUI
import AppKit

struct MenuBarContent: View {
    let service: NitsService
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusHeader

            Divider().padding(.vertical, 4)

            if let focus = service.coordinator.currentFocus {
                focusedAppRow(bundleID: focus.bundleID)
                Divider().padding(.vertical, 4)
            }

            Button(service.coordinator.isEnabled ? "Pause Nits" : "Resume Nits") {
                service.setEnabled(!service.coordinator.isEnabled)
            }
            .keyboardShortcut("p")

            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",")

            Divider().padding(.vertical, 4)

            Button("Quit Nits") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 240)
    }

    private var statusHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: service.coordinator.isEnabled
                  ? (service.coordinator.isTransitioning ? "sun.max.fill" : "sun.max")
                  : "pause.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(service.coordinator.isEnabled ? Color.yellow : Color.secondary)
                .font(.title2)
            VStack(alignment: .leading, spacing: 0) {
                Text("Nits").font(.body.weight(.semibold))
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private var statusLine: String {
        guard service.coordinator.isEnabled else { return "Paused" }
        if service.coordinator.isTransitioning { return "Transitioning…" }
        return "Active"
    }

    private func focusedAppRow(bundleID: String) -> some View {
        HStack(spacing: 8) {
            if let icon = InstalledAppsScanner.appIcon(forBundleID: bundleID) {
                Image(nsImage: icon).resizable().frame(width: 18, height: 18)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(InstalledAppsScanner.appName(forBundleID: bundleID))
                    .font(.caption.weight(.medium))
                if let preset = service.store.preset(for: bundleID) {
                    Text("Preset \(Int(preset.brightness * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("No preset — using baseline")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

#if DEBUG
#Preview("Active") {
    MenuBarContent(service: PreviewFixtures.makeService(
        currentFocusBundleID: "com.microsoft.VSCode"
    ))
}

#Preview("Paused") {
    MenuBarContent(service: PreviewFixtures.makeService(
        isEnabled: false,
        currentFocusBundleID: "com.apple.Safari"
    ))
}

#Preview("Transitioning") {
    let svc = PreviewFixtures.makeService(currentFocusBundleID: "com.apple.QuickTimePlayerX")
    return MenuBarContent(service: svc)
}
#endif
