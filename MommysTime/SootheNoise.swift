import AVFoundation
import Combine

/// The white-noise button under the home grid. Brown-ish noise — each sample is
/// a low-passed random walk, which is softer and far less hissy than pure white
/// — generated once into a looping buffer rather than shipped as an audio file.
@MainActor
final class SootheNoise: ObservableObject {
    static let shared = SootheNoise()

    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var wired = false
    private var ramp: Timer?

    /// Comfortable at arm's length from the cot without drowning the room.
    private static let level: Float = 0.32
    private static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private init() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            // A call or another app taking the session leaves us silent; reflect
            // that in the button rather than lying about it.
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            MainActor.assumeIsolated { self?.stop(fade: false) }
        }
    }

    func toggle() { isPlaying ? stop() : start() }

    func start() {
        guard !isPlaying else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback so the ringer switch doesn't silence a sleeping baby's
            // white noise.
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            if !wired {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: Self.format)
                wired = true
            }

            player.volume = 0
            player.scheduleBuffer(Self.noiseBuffer(), at: nil, options: .loops)
            try engine.start()
            player.play()
            isPlaying = true
            fade(to: Self.level, over: 1.2)
        } catch {
            isPlaying = false
        }
    }

    func stop(fade shouldFade: Bool = true) {
        guard isPlaying else { return }
        isPlaying = false
        guard shouldFade else { return teardown() }
        fade(to: 0, over: 0.5) { [weak self] in self?.teardown() }
    }

    private func teardown() {
        ramp?.invalidate()
        ramp = nil
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Linear volume ramp — starting or stopping at full level is a jolt in a
    /// quiet room.
    private func fade(to target: Float, over seconds: Double, then finish: (() -> Void)? = nil) {
        ramp?.invalidate()
        let start = player.volume
        let steps = max(1, Int(seconds * 30))
        var step = 0
        ramp = Timer.scheduledTimer(withTimeInterval: seconds / Double(steps), repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { return timer.invalidate() }
                step += 1
                self.player.volume = start + (target - start) * Float(step) / Float(steps)
                if step >= steps {
                    timer.invalidate()
                    self.ramp = nil
                    finish?()
                }
            }
        }
    }

    /// Four seconds of brown noise. Long enough that the loop point doesn't
    /// become a rhythm you can hear.
    private static func noiseBuffer() -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(format.sampleRate * 4)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames

        let samples = buffer.floatChannelData![0]
        var last: Float = 0
        for i in 0..<Int(frames) {
            let white = Float.random(in: -1...1)
            last = (last + 0.02 * white) / 1.02
            samples[i] = last * 3.5
        }
        return buffer
    }
}
