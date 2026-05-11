import SwiftUI
import AppKit

struct SettingsView: View {
    let service: NitsService

    @State private var pickerOpen: Bool = false
    @State private var installedApps: [InstalledApp] = []
    @State private var loadingApps: Bool = false
    @State private var launchAtLoginEnabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-adjust brightness on app switch", isOn: enabledBinding)
                    Toggle("Launch Nits at login", isOn: launchBinding)
                    TransitionDurationSlider(seconds: durationBinding)
                }
                .padding(.vertical, 4)
            }

            HStack {
                Text("Per-App Brightness").font(.headline)
                Spacer()
                Button {
                    openPicker()
                } label: {
                    Label("Add App", systemImage: "plus")
                }
                .controlSize(.small)
            }

            if service.store.presets.isEmpty {
                ContentUnavailableView(
                    "No apps configured",
                    systemImage: "moon.zzz",
                    description: Text("Add an app to start auto-adjusting brightness when it's focused.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(service.store.presets) { preset in
                            AppPresetRow(
                                bundleID: preset.bundleID,
                                name: preset.displayName.isEmpty
                                    ? InstalledAppsScanner.appName(forBundleID: preset.bundleID)
                                    : preset.displayName,
                                icon: InstalledAppsScanner.appIcon(forBundleID: preset.bundleID),
                                brightness: binding(forPreset: preset),
                                isCurrentlyFocused: service.coordinator.currentFocus?.bundleID == preset.bundleID,
                                onRemove: { service.store.remove(bundleID: preset.bundleID) }
                            )
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 380)
            }
        }
        .padding(20)
        .frame(width: 480)
        .sheet(isPresented: $pickerOpen) {
            AppPickerView(
                apps: installedApps,
                isLoading: loadingApps,
                excludedBundleIDs: Set(service.store.presets.map(\.bundleID)),
                onPick: { app in
                    service.store.upsert(AppPreset(
                        bundleID: app.bundleID,
                        brightness: 0.5,
                        displayName: app.name
                    ))
                    pickerOpen = false
                },
                onCancel: { pickerOpen = false }
            )
        }
        .task {
            launchAtLoginEnabled = service.launchAtLogin.isEnabled
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sun.max.circle.fill")
                .resizable().frame(width: 28, height: 28)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 0) {
                Text("Nits").font(.title2.weight(.semibold))
                Text("Per-app brightness for macOS")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            statusPill
        }
    }

    @ViewBuilder
    private var statusPill: some View {
        if service.coordinator.isEnabled {
            Label("Active", systemImage: "circle.fill")
                .font(.caption.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.green)
        } else {
            Label("Paused", systemImage: "pause.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { service.coordinator.isEnabled },
            set: { service.setEnabled($0) }
        )
    }

    private var durationBinding: Binding<TimeInterval> {
        Binding(
            get: { service.settings.transitionDuration },
            set: { service.updateDuration($0) }
        )
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { newValue in
                do {
                    try service.launchAtLogin.setEnabled(newValue)
                    launchAtLoginEnabled = service.launchAtLogin.isEnabled
                } catch {
                    NSLog("Nits: launch-at-login change failed: \(error)")
                }
            }
        )
    }

    private func binding(forPreset preset: AppPreset) -> Binding<Double> {
        Binding(
            get: { service.store.preset(for: preset.bundleID)?.brightness ?? preset.brightness },
            set: { service.store.updateBrightness($0, for: preset.bundleID) }
        )
    }

    private func openPicker() {
        pickerOpen = true
        loadingApps = true
        Task.detached(priority: .userInitiated) {
            let apps = await MainActor.run { InstalledAppsScanner.scan() }
            await MainActor.run {
                installedApps = apps
                loadingApps = false
            }
        }
    }
}

#if DEBUG
#Preview("Populated") {
    SettingsView(service: PreviewFixtures.makeService(
        currentFocusBundleID: "com.microsoft.VSCode"
    ))
}

#Preview("Empty") {
    SettingsView(service: PreviewFixtures.makeService(presets: []))
}
#endif
