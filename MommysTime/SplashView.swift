import SwiftUI

/// Wraps the app in the animated splash, shown once per cold launch ahead of
/// onboarding/Home. Full-bleed, tappable to skip, auto-dismisses after ~2.6s.
struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ContentView()
            .overlay {
                if showSplash {
                    SplashView { withAnimation(.easeOut(duration: 0.35)) { showSplash = false } }
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
    }
}

struct SplashView: View {
    var onFinish: () -> Void

    @State private var bloomed = false     // logo disc
    @State private var risen = false       // wordmark → hint stagger
    @State private var swept = false       // progress fill
    @State private var pulsing = false     // heart
    @State private var finished = false

    @State private var dismissTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            SP.canvas.ignoresSafeArea()

            // 1 — decorative blobs, bleeding off-canvas
            GeometryReader { geo in
                Circle()
                    .fill(SP.blobPeach).opacity(0.70)
                    .frame(width: 240, height: 240)
                    .position(x: -60 + 120, y: -70 + 120)
                Circle()
                    .fill(SP.blobRose).opacity(0.75)
                    .frame(width: 280, height: 280)
                    .position(x: geo.size.width + 70 - 140, y: geo.size.height + 90 - 140)
            }
            .ignoresSafeArea()

            // 2 — centre stack
            VStack(spacing: 0) {
                logoDisc

                Text("Mommy's Time")
                    .font(.baloo(34, heavy: true))
                    .foregroundStyle(SP.titleText)
                    .padding(.top, 26)
                    .modifier(Rise(on: risen, delay: 0.18))

                Text("Because you deserve some too")
                    .font(.nunito(14, .bold))
                    .tracking(0.2)
                    .foregroundStyle(SP.taglineText)
                    .padding(.top, 8)
                    .modifier(Rise(on: risen, delay: 0.30))

                progressBar
                    .padding(.top, 34)
                    .modifier(Rise(on: risen, delay: 0.42))
            }
            .padding(.horizontal, 40)
            .multilineTextAlignment(.center)

            // 3 — tap hint
            VStack {
                Spacer()
                Text("Tap to continue")
                    .font(.nunito(11.5, .semibold))
                    .foregroundStyle(SP.hintText)
                    .padding(.bottom, 44)
                    .modifier(Rise(on: risen, delay: 0.60))
            }
            .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear(perform: start)
        .onDisappear { dismissTask?.cancel() }
    }

    // MARK: Elements

    private var logoDisc: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 44))
            .foregroundStyle(SP.heartRose)
            .scaleEffect(pulsing ? 1.06 : 1.0)
            .frame(width: 104, height: 104)
            .background(SP.cardWhite, in: Circle())
            .shadow(color: Color(hex: 0xBE5F78).opacity(0.18), radius: 17, y: 14)
            .opacity(bloomed ? 1 : 0)
            .scaleEffect(bloomed ? 1 : 0.86)
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(SP.trackBg)
            Capsule().fill(SP.fillRose)
                .frame(width: 132)
                .offset(x: swept ? 0 : -132)
        }
        .frame(width: 132, height: 5)
        .clipShape(Capsule())
    }

    // MARK: Motion

    private func start() {
        // bloom
        withAnimation(.timingCurve(0.2, 0.8, 0.3, 1, duration: 0.7)) { bloomed = true }
        // rise — each element animates with its own delay via the Rise modifier
        risen = true
        // sweep
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.9).delay(0.42)) { swept = true }
        // pulse (infinite)
        withAnimation(.easeInOut(duration: 1.2).delay(0.7).repeatForever(autoreverses: true)) {
            pulsing = true
        }
        // auto-dismiss
        let task = DispatchWorkItem { finish() }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: task)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        dismissTask?.cancel()
        onFinish()
    }
}

/// Fades + lifts an element into place; used for the staggered "rise".
private struct Rise: ViewModifier {
    let on: Bool
    let delay: Double
    func body(content: Content) -> some View {
        content
            .opacity(on ? 1 : 0)
            .offset(y: on ? 0 : 14)
            .animation(.easeOut(duration: 0.6).delay(delay), value: on)
    }
}

// MARK: - Splash palette

private enum SP {
    static let canvas = Color(hex: 0xFFF8EE)
    static let cardWhite = Color.white
    static let blobPeach = Color(hex: 0xFBEBD8)
    static let blobRose = Color(hex: 0xF6E6E9)
    static let heartRose = Color(hex: 0xD9758C)
    static let titleText = Color(hex: 0x4A423B)
    static let taglineText = Color(hex: 0xB0899A)
    static let trackBg = Color(hex: 0xF3E1E5)
    static let fillRose = Color(hex: 0xD9758C)
    static let hintText = Color(hex: 0xC3B5A6)
}
