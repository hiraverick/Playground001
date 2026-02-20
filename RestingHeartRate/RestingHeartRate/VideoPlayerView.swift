import SwiftUI
import AVKit

struct VideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerView {
        LoopingPlayerView()
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) {
        uiView.play(url: url)
    }

    static func dismantleUIView(_ uiView: LoopingPlayerView, coordinator: ()) {
        uiView.stop()
    }
}

// MARK: - UIView

final class LoopingPlayerView: UIView {

    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { tearDown() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func play(url: URL) {
        guard url != currentURL else { return }
        currentURL = url

        tearDown()

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 5

        let newPlayer = AVQueuePlayer()
        newPlayer.isMuted = true
        newPlayer.automaticallyWaitsToMinimizeStalling = true

        let newLooper = AVPlayerLooper(player: newPlayer, templateItem: item)

        let fade = CATransition()
        fade.duration = 0.8
        fade.type = .fade
        playerLayer.add(fade, forKey: "videoFade")

        playerLayer.player = newPlayer
        newPlayer.play()

        player = newPlayer
        looper = newLooper
    }

    func stop() {
        tearDown()
        currentURL = nil
    }

    private func tearDown() {
        looper?.disableLooping()
        looper = nil
        player?.pause()
        player?.removeAllItems()
        playerLayer.player = nil
        player = nil
    }
}
