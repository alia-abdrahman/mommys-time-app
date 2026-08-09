import SwiftUI

// MARK: - Steps

enum GuideStepID: Hashable {
    case addBlock
    case findTime
}

struct GuideStep: Identifiable {
    let id: GuideStepID
    let title: String
    let message: String
}

// MARK: - Controller

final class GuideController: ObservableObject {
    @Published private(set) var index = 0
    @Published private(set) var isActive = false

    let steps: [GuideStep]

    init(steps: [GuideStep]) {
        self.steps = steps
    }

    var currentStep: GuideStep? {
        guard isActive, steps.indices.contains(index) else { return nil }
        return steps[index]
    }

    var isLastStep: Bool { index >= steps.count - 1 }

    func start() {
        guard !steps.isEmpty else { return }
        index = 0
        withAnimation(.easeInOut) { isActive = true }
    }

    func advance() {
        if isLastStep {
            finish()
        } else {
            withAnimation(.easeInOut) { index += 1 }
        }
    }

    func finish() {
        withAnimation(.easeInOut) {
            isActive = false
            index = 0
        }
    }
}

// MARK: - Anchoring

/// Collects the on-screen bounds of each guide target so the overlay can
/// spotlight it. Toolbar items don't propagate anchors reliably, so only
/// tag targets that live in the normal view hierarchy.
struct GuideAnchorKey: PreferenceKey {
    static var defaultValue: [GuideStepID: Anchor<CGRect>] = [:]
    static func reduce(
        value: inout [GuideStepID: Anchor<CGRect>],
        nextValue: () -> [GuideStepID: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct BubbleSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    /// Marks this view as the target for a guide step.
    func guideAnchor(_ id: GuideStepID) -> some View {
        anchorPreference(key: GuideAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Presents the coach-mark overlay above the tagged targets.
    func guideOverlay(_ controller: GuideController) -> some View {
        overlayPreferenceValue(GuideAnchorKey.self) { anchors in
            GeometryReader { proxy in
                GuideOverlay(controller: controller, anchors: anchors, proxy: proxy)
            }
        }
    }

    fileprivate func reverseMask<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        mask {
            ZStack {
                Rectangle()
                content().blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

// MARK: - Overlay

private struct GuideOverlay: View {
    @ObservedObject var controller: GuideController
    let anchors: [GuideStepID: Anchor<CGRect>]
    let proxy: GeometryProxy

    @State private var bubbleSize: CGSize = .zero

    var body: some View {
        if let step = controller.currentStep {
            let rect = anchors[step.id].map { proxy[$0] }
            ZStack(alignment: .topLeading) {
                dimmer(around: rect)
                bubble(for: step, target: rect)
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func dimmer(around rect: CGRect?) -> some View {
        let base = Rectangle().fill(Color.black.opacity(0.55))
        Group {
            if let rect {
                let hole = rect.insetBy(dx: -10, dy: -10)
                base.reverseMask {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: hole.width, height: hole.height)
                        .position(x: hole.midX, y: hole.midY)
                }
            } else {
                base
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { controller.advance() }
    }

    private func bubble(for step: GuideStep, target rect: CGRect?) -> some View {
        let margin: CGFloat = 16
        let maxWidth = min(300, proxy.size.width - margin * 2)
        let halfWidth = maxWidth / 2

        // Centered fallback when the target isn't on screen.
        let anchorRect = rect ?? CGRect(
            x: proxy.size.width / 2, y: proxy.size.height / 2, width: 0, height: 0
        )
        let placeBelow = anchorRect.midY < proxy.size.height * 0.5

        let centerX = min(
            max(anchorRect.midX, margin + halfWidth),
            proxy.size.width - margin - halfWidth
        )
        let gap: CGFloat = 12
        let centerY = placeBelow
            ? anchorRect.maxY + gap + bubbleSize.height / 2
            : anchorRect.minY - gap - bubbleSize.height / 2
        let pointerX = min(max(anchorRect.midX - centerX, -(halfWidth - 22)), halfWidth - 22)

        return VStack(spacing: 0) {
            if placeBelow && rect != nil {
                GuideTriangle().fill(Color(.systemBackground))
                    .frame(width: 22, height: 11)
                    .offset(x: pointerX)
            }
            card(for: step)
            if !placeBelow && rect != nil {
                GuideTriangle().fill(Color(.systemBackground))
                    .rotationEffect(.degrees(180))
                    .frame(width: 22, height: 11)
                    .offset(x: pointerX)
            }
        }
        .frame(width: maxWidth)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: BubbleSizeKey.self, value: g.size)
            }
        )
        .onPreferenceChange(BubbleSizeKey.self) { bubbleSize = $0 }
        .position(x: centerX, y: centerY)
    }

    private func card(for step: GuideStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title)
                .font(.headline)
            Text(step.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("\(controller.index + 1) of \(controller.steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !controller.isLastStep {
                    Button("Skip") { controller.finish() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button(controller.isLastStep ? "Got it" : "Next") {
                    controller.advance()
                }
                .font(.subheadline.bold())
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}

private struct GuideTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
