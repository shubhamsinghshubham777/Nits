import SwiftUI
import AppKit

struct AppPickerView: View {
    let apps: [InstalledApp]
    let isLoading: Bool
    let excludedBundleIDs: Set<String>
    let onPick: (InstalledApp) -> Void
    let onCancel: () -> Void

    @State private var query: String = ""

    private var filtered: [InstalledApp] {
        let available = apps.filter { !excludedBundleIDs.contains($0.bundleID) }
        guard !query.isEmpty else { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add an App").font(.headline)
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
            }
            .padding()

            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Divider()

            if isLoading {
                VStack {
                    ProgressView().controlSize(.small)
                    Text("Scanning /Applications…").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filtered.isEmpty {
                ContentUnavailableView(
                    "No apps found",
                    systemImage: "magnifyingglass",
                    description: Text(query.isEmpty
                        ? "No apps available to add."
                        : "Nothing matches \"\(query)\".")
                )
            } else {
                List(filtered) { app in
                    Button {
                        onPick(app)
                    } label: {
                        HStack(spacing: 10) {
                            if let icon = app.iconImage {
                                Image(nsImage: icon).resizable().interpolation(.high)
                                    .frame(width: 24, height: 24)
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.quaternary)
                                    .frame(width: 24, height: 24)
                                    .overlay(Image(systemName: "app.dashed").foregroundStyle(.secondary))
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                Text(app.bundleID)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 420, height: 480)
    }
}

#if DEBUG
#Preview("Populated") {
    AppPickerView(
        apps: PreviewFixtures.sampleInstalledApps(),
        isLoading: false,
        excludedBundleIDs: [],
        onPick: { _ in },
        onCancel: {}
    )
}

#Preview("Loading") {
    AppPickerView(
        apps: [],
        isLoading: true,
        excludedBundleIDs: [],
        onPick: { _ in },
        onCancel: {}
    )
}

#Preview("Empty") {
    AppPickerView(
        apps: [],
        isLoading: false,
        excludedBundleIDs: [],
        onPick: { _ in },
        onCancel: {}
    )
}
#endif
