import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()

    var body: some View {
        ZStack {
            // Subtle warm background
            LinearGradient(
                colors: [Color(.systemBackground), Color.red.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()

                heartRateCard
                    .padding(.horizontal, 20)

                Spacer()

                refreshButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            healthKit.requestAuthorization()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Heart")
                    .font(.largeTitle.bold())
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.title)
                .foregroundStyle(.red)
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
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundStyle(.red)
                .symbolEffect(.pulse, isActive: healthKit.isLoading)
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

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button {
            Task { await healthKit.fetchRestingHeartRate() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                Text("Refresh")
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Color.red.opacity(healthKit.isLoading ? 0.06 : 0.1),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(.red)
        }
        .disabled(healthKit.isLoading)
        .animation(.easeInOut(duration: 0.15), value: healthKit.isLoading)
    }
}

#Preview {
    ContentView()
}
