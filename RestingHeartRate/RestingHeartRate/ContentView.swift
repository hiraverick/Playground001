import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.red.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        Spacer(minLength: 0)

                        if healthKit.isAuthorized {
                            heartRateCard
                                .padding(.horizontal, 20)
                        } else {
                            authorizationPrompt
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .refreshable {
                    await healthKit.fetchRestingHeartRate()
                }
            }
        }
        .task { await healthKit.initialize() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Biometrics")
                    .font(.largeTitle.bold())
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Heart Rate Card

    private var heartRateCard: some View {
        VStack(spacing: 28) {
            heartIcon
            label
            heartRateDisplay
            Divider().padding(.horizontal, 16)
            statusRow
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
        }
    }

    private var heartIcon: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 72, height: 72)

            if let bpm = healthKit.restingHeartRate, !healthKit.isLoading {
                HeartbeatIcon(bpm: bpm)
            } else {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse, isActive: healthKit.isLoading)
            }
        }
    }

    private var label: some View {
        Text("Resting Heart Rate")
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .kerning(1.2)
    }

    @ViewBuilder
    private var heartRateDisplay: some View {
        if healthKit.isLoading {
            ProgressView()
                .tint(.red)
                .scaleEffect(1.4)
                .frame(height: 90)
        } else if let bpm = healthKit.restingHeartRate {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(bpm))")
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
                    .animation(.spring(duration: 0.4), value: bpm)

                Text("BPM")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
            }
        } else {
            Text("—")
                .font(.system(size: 88, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.tertiary)
                .frame(height: 90)
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        if let error = healthKit.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)

        } else if healthKit.restingHeartRate != nil {
            if healthKit.isReadingFromToday {
                Label("Measured today", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            } else if let date = healthKit.lastReadingDate {
                Label {
                    Text("Last reading \(date, style: .relative) ago")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

        } else if !healthKit.isLoading {
            VStack(spacing: 6) {
                Text("No data available")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Sync your Apple Watch to the Health app,\nor wait for tonight's sleep analysis.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Authorization Prompt

    private var authorizationPrompt: some View {
        VStack(spacing: 28) {
            heartIcon
            label

            VStack(spacing: 12) {
                Text("Health Access Required")
                    .font(.system(.headline, design: .rounded))
                Text("Tap below to allow this app to read your resting heart rate from the Health app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = healthKit.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await healthKit.requestAuthorization() }
            } label: {
                HStack(spacing: 8) {
                    if healthKit.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    Text("Enable Health Access")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
            }
            .disabled(healthKit.isLoading)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
        }
    }
}

// MARK: - Heartbeat Animation

private struct HeartbeatIcon: View {
    let bpm: Double

    var body: some View {
        let beatDuration = 60.0 / bpm
        let restDuration = max(0.05, beatDuration - 0.4)

        Image(systemName: "heart.fill")
            .font(.system(size: 32))
            .foregroundStyle(.red)
            .keyframeAnimator(
                initialValue: CGFloat(1.0),
                repeating: true
            ) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                CubicKeyframe(1.3,  duration: 0.10) // lub up
                CubicKeyframe(1.0,  duration: 0.12) // lub down
                CubicKeyframe(1.18, duration: 0.08) // dub up
                CubicKeyframe(1.0,  duration: 0.10) // dub down
                LinearKeyframe(1.0, duration: restDuration) // rest
            }
    }
}

#Preview {
    ContentView()
}
