import SwiftUI
import AVKit

/// A full-bleed, muted, infinitely-looping video player.
struct VideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerView {
        let view = LoopingPlayerView()
        view.play(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) {
        uiView.play(url: url)
    }
}

// MARK: - UIView

final class LoopingPlayerView: UIView {

    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func play(url: URL) {
        guard url != currentURL else { return }
        currentURL = url

        // Stop previous playback
        queuePlayer?.pause()

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        let loop = AVPlayerLooper(player: player, templateItem: item)

        // Crossfade between videos
        let fade = CATransition()
        fade.duration = 0.9
        fade.type = .fade
        playerLayer.add(fade, forKey: "videoFade")

        playerLayer.player = player
        player.play()

        self.queuePlayer = player
        self.looper = loop
    }
}
