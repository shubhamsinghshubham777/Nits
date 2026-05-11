import SwiftUI
import AppKit

struct AppPresetRow: View {
    let bundleID: String
    let name: String
    let icon: NSImage?
    @Binding var brightness: Double
    let isCurrentlyFocused: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            iconView
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name).font(.body.weight(.medium))
                    if isCurrentlyFocused {
                        Text("focused")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                HStack(spacing: 8) {
                    BrightnessGlyph(value: brightness).font(.system(size: 12))
                    Slider(value: $brightness, in: 0...1)
                        .controlSize(.small)
                    Text("\(Int(brightness * 100))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(
            isCurrentlyFocused
                ? Color.accentColor.opacity(0.06)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(nsImage: icon).resizable().interpolation(.high)
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .overlay(Image(systemName: "app.dashed").foregroundStyle(.secondary))
        }
    }
}

#if DEBUG
private struct AppPresetRowPreviewWrapper: View {
    @State var brightness: Double
    let name: String
    let isFocused: Bool

    var body: some View {
        AppPresetRow(
            bundleID: "preview",
            name: name,
            icon: nil,
            brightness: $brightness,
            isCurrentlyFocused: isFocused,
            onRemove: {}
        )
        .padding()
        .frame(width: 380)
    }
}

#Preview("Idle") {
    AppPresetRowPreviewWrapper(brightness: 0.4, name: "Visual Studio Code", isFocused: false)
}

#Preview("Currently focused") {
    AppPresetRowPreviewWrapper(brightness: 0.15, name: "Visual Studio Code", isFocused: true)
}

#Preview("At 0%") {
    AppPresetRowPreviewWrapper(brightness: 0.0, name: "Cinema Mode", isFocused: false)
}

#Preview("At 100%") {
    AppPresetRowPreviewWrapper(brightness: 1.0, name: "Sunlit Editor", isFocused: false)
}
#endif
