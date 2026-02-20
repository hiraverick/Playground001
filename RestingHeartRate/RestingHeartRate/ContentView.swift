import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()
    @State private var pexels = PexelsService()
    @State private var videoURL: URL? = nil
    @State private var currentZone: HRZone? = nil
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // MARK: Background video
                if let url = videoURL {
                    VideoPlayerView(url: url)
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    Color.black.ignoresSafeArea()
                }

                // MARK: Gradient overlay — darkens edges, keeps centre readable
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.55), location: 0.00),
                        .init(color: .black.opacity(0.10), location: 0.35),
                        .init(color: .black.opacity(0.10), location: 0.65),
                        .init(color: .black.opacity(0.65), location: 1.00),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: Content
                ScrollView {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                        Spacer(minLength: 0)

                        if healthKit.isAuthorized {
                            bpmOverlay
                        } else {
                            authCard
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .refreshable {
                    await refresh()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task { await initialize() }
        .onChange(of: healthKit.restingHeartRate) { _, bpm in
            guard let bpm else { return }
            let zone = HRZone(bpm: bpm)
            if zone != currentZone {
                currentZone = zone
                Task { await loadVideo(for: zone) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Biometrics")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
        }
    }

    // MARK: - BPM Overlay

    @ViewBuilder
    private var bpmOverlay: some View {
        if healthKit.isLoading && healthKit.restingHeartRate == nil {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        } else if let bpm = healthKit.restingHeartRate {
            let zone = HRZone(bpm: bpm)
            VStack(spacing: 10) {

                // Zone pill
                Text(zone.label.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .kerning(2.5)
                    .foregroundStyle(zone.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(zone.color.opacity(0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(zone.color.opacity(0.55), lineWidth: 1))

                // BPM number
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(bpm))")
                        .font(.system(size: 108, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.4), value: bpm)
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)

                    Text("BPM")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 14)
                }

                // Label
                Text("Resting Heart Rate")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.60))
                    .textCase(.uppercase)
                    .kerning(1.2)

                // Status
                statusLabel
                    .padding(.top, 6)
            }
            .multilineTextAlignment(.center)

        } else if !healthKit.isLoading {
            VStack(spacing: 12) {
                Text("—")
                    .font(.system(size: 108, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if let error = healthKit.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
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
                .foregroundStyle(.white.opacity(0.60))
            }
        }
    }

    // MARK: - Auth Card

    private var authCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Health Access Required")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                Text("Allow this app to read your resting\nheart rate from the Health app.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
            }

            if let error = healthKit.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
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
            .padding(.horizontal, 32)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 32)
    }

    // MARK: - Logic

    private func initialize() async {
        await healthKit.initialize()
        if let bpm = healthKit.restingHeartRate {
            let zone = HRZone(bpm: bpm)
            currentZone = zone
            await loadVideo(for: zone)
        }
    }

    private func refresh() async {
        await healthKit.fetchRestingHeartRate()
        if let bpm = healthKit.restingHeartRate {
            await loadVideo(for: HRZone(bpm: bpm))
        }
    }

    private func loadVideo(for zone: HRZone) async {
        do {
            let url = try await pexels.fetchVideoURL(for: zone)
            withAnimation(.easeInOut(duration: 0.6)) {
                videoURL = url
            }
        } catch {
            // Keep existing video on failure; black background if none loaded yet
        }
    }
}

#Preview {
    ContentView()
}
