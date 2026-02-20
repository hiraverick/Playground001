import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()
    @State private var pexels = PexelsService()
    @State private var videoURL: URL? = nil
    @State private var currentZone: HRZone? = nil
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            // MARK: Background video
            if let url = videoURL {
                VideoPlayerView(url: url)
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                Color.black.ignoresSafeArea()
            }

            // MARK: Gradient overlay
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
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                Spacer()

                if healthKit.isAuthorized {
                    bpmOverlay
                } else {
                    authCard
                }

                Spacer()
            }
        }
        .task { await initialize() }
        .onChange(of: healthKit.restingHeartRate) { _, bpm in
            guard let bpm else { return }
            let zone = HRZone(bpm: bpm)
            if zone != currentZone {
                currentZone = zone
                Task { await loadVideo(for: zone) }
            }
        }
        // Auto-refresh when app returns to foreground
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await refresh() }
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
            Button {
                Task { await refresh() }
            } label: {
                Group {
                    if isRefreshing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.70))
                    }
                }
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(isRefreshing)
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.18))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().strokeBorder(.red.opacity(0.35), lineWidth: 1))
                Image(systemName: "heart.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 6) {
                Text("Health Access Required")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 3)
                Text("Allow this app to read your resting\nheart rate from the Health app.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
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
                .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
            }
            .disabled(healthKit.isLoading)
            .padding(.top, 6)
        }
        .padding(.horizontal, 40)
        .multilineTextAlignment(.center)
    }

    // MARK: - Logic

    private func initialize() async {
        await healthKit.initialize()
        if let bpm = healthKit.restingHeartRate {
            let zone = HRZone(bpm: bpm)
            currentZone = zone
            await loadVideo(for: zone)
        } else {
            await loadVideo(for: .good)
        }
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await healthKit.fetchRestingHeartRate()
        if let bpm = healthKit.restingHeartRate {
            await loadVideo(for: HRZone(bpm: bpm))
        }
        isRefreshing = false
    }

    private func loadVideo(for zone: HRZone) async {
        do {
            let url = try await pexels.fetchVideoURL(for: zone)
            withAnimation(.easeInOut(duration: 0.6)) {
                videoURL = url
            }
        } catch {
            // Keep existing video on failure
        }
    }
}

#Preview {
    ContentView()
}
