import SwiftUI

struct TransitionDurationSlider: View {
    @Binding var seconds: TimeInterval

    private var ms: Int { Int((seconds * 1000).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Transition", systemImage: "timelapse")
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(ms) ms")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: $seconds,
                in: AppSettings.minDuration...AppSettings.maxDuration,
                step: 0.05
            ) {
                Text("Transition duration")
            } minimumValueLabel: {
                Text("300 ms").font(.caption2).foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("2000 ms").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
private struct TransitionDurationSliderPreview: View {
    @State var fast: TimeInterval = AppSettings.minDuration
    @State var mid: TimeInterval = 1.1
    @State var slow: TimeInterval = AppSettings.maxDuration

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TransitionDurationSlider(seconds: $fast)
            TransitionDurationSlider(seconds: $mid)
            TransitionDurationSlider(seconds: $slow)
        }
        .padding()
        .frame(width: 380)
    }
}

#Preview("Min, mid, max") {
    TransitionDurationSliderPreview()
}
#endif
