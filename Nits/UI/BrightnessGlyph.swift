import SwiftUI

struct BrightnessGlyph: View {
    let value: Double

    var body: some View {
        Image(systemName: "sun.max.fill", variableValue: value)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.yellow)
            .accessibilityLabel("Brightness \(Int(value * 100)) percent")
    }
}

#if DEBUG
#Preview("BrightnessGlyph") {
    HStack(spacing: 16) {
        ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
            VStack {
                BrightnessGlyph(value: v).font(.system(size: 28))
                Text(String(format: "%.2f", v)).font(.caption)
            }
        }
    }
    .padding()
}
#endif
