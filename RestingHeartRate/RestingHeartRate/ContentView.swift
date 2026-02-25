import SwiftUI

struct ContentView: View {

    // MARK: - State

    @State private var healthKit = HealthKitManager()
    @State private var videoURL: URL?
    @State private var videoCreator: String?
    @State private var isLoadingVideo = false
    @State private var didInitialize = false

    // Custom pull-to-refresh (bypasses Dynamic Island gesture gate entirely)
    @State private var pullOffset: CGFloat = 0
    @State private var isRefreshing = false

    private let pexels = PexelsService()
    private let pullThreshold: CGFloat = 80

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color.black.ignoresSafeArea()

            if let url = videoURL {
                VideoPlayerView(url: url)
                    .ignoresSafeArea()
            }

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

            // Loading overlay (video change during pull-refresh only, not initial load)
            if isLoadingVideo, !isRefreshing, didInitialize {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }

            // ── Content ─────────────────────────────────────────
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer(minLength: 0)

                if !didInitialize {
                    bpmContent(bpm: 72, zone: .good)
                        .redacted(reason: .placeholder)
                        .opacity(placeholderPulse ? 0.4 : 0.75)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: placeholderPulse)
                        .onAppear { placeholderPulse = true }
                } else if healthKit.isAuthorized {
                    bpmOverlay
                } else {
                    authCard
                }

                Spacer(minLength: 0)

                creatorCredit
                    .padding(.bottom, 8)
            }
            .offset(y: pullContentOffset)

            // ── Pull indicator ───────────────────────────────────
            VStack {
                if isRefreshing || pullOffset > 15 {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(isRefreshing ? 1 : min(pullOffset / pullThreshold, 1))
                        .opacity(isRefreshing ? 1 : Double(min(pullOffset / 30, 1)))
                        .padding(.top, 56)
                }
                Spacer()
            }
        }
        .gesture(pullGesture)
        .task { await initialize() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            guard didInitialize, healthKit.isAuthorized else { return }
            Task { await refresh() }
        }
    }

    // MARK: - Pull-to-Refresh Gesture

    /// Rubber-band offset for the content while pulling.
    private var pullContentOffset: CGFloat {
        if isRefreshing { return 30 }
        guard pullOffset > 0 else { return 0 }
        return pullOffset * 0.35
    }

    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard !isRefreshing else { return }
                let dy = value.translation.height
                guard dy > 0 else { pullOffset = 0; return }
                // Diminishing pull: feels like elastic rubber-band
                pullOffset = dy * 0.55
            }
            .onEnded { _ in
                guard !isRefreshing else { return }
                if pullOffset >= pullThreshold {
                    triggerRefresh()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        pullOffset = 0
                    }
                }
            }
    }

    private func triggerRefresh() {
        isRefreshing = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            pullOffset = 0
        }
        Task {
            await refresh()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isRefreshing = false
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

    @State private var placeholderPulse = false

    @ViewBuilder
    private var bpmOverlay: some View {
        if let bpm = healthKit.restingHeartRate {
            bpmContent(bpm: bpm, zone: HRZone(bpm: bpm))
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

    private func bpmContent(bpm: Double, zone: HRZone) -> some View {
        VStack(spacing: 10) {
            Text(zone.label.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .kerning(2.5)
                .foregroundStyle(zone.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(zone.color.opacity(0.18), in: Capsule())
                .overlay(Capsule().strokeBorder(zone.color.opacity(0.55), lineWidth: 1))

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

            Text("Resting Heart Rate")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.60))
                .textCase(.uppercase)
                .kerning(1.2)

            statusLabel
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
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

    // MARK: - Creator Credit

    private var creatorCredit: some View {
        Text(videoCreator.map { "Video by \($0) · Pexels" } ?? " ")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.40))
            .opacity(isLoadingVideo || videoCreator == nil ? 0 : 1)
    }

    // MARK: - Logic

    private func initialize() async {
        await healthKit.initialize()
        let zone = healthKit.restingHeartRate.map(HRZone.init) ?? .good
        await loadVideo(for: zone)
        didInitialize = true
    }

    private func refresh() async {
        await healthKit.fetchRestingHeartRate()
        let zone = healthKit.restingHeartRate.map(HRZone.init) ?? .good
        await loadVideo(for: zone)
    }

    private func loadVideo(for zone: HRZone) async {
        isLoadingVideo = true
        defer { isLoadingVideo = false }
        do {
            let result = try await pexels.fetchVideo(for: zone)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                videoURL = result.url
                videoCreator = result.creator
            }
        } catch {
            // Keep existing video on failure
        }
    }
}

#Preview {
    ContentView()
}
