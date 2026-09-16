import SwiftUI

// Building blocks the design repeats on nearly every screen: the uppercase
// section label, pill chips, the Cancel / Title / Save sheet header, circular
// back and add buttons, the −/value/+ stepper and the soft toggle.

/// `SECTION HEADING` — uppercase, tracked, muted.
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.nunito(12, .heavy))
            .tracking(0.8)
            .foregroundStyle(Theme.inkFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Rounded selectable chip — used for topics, categories, ages, relations.
struct ChipButton: View {
    let label: String
    let selected: Bool
    var fills = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.nunito(12.5, .heavy))
                .foregroundStyle(selected ? .white : Theme.inkBody)
                .frame(maxWidth: fills ? .infinity : nil)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? Theme.roseStrong : .white, in: Capsule())
                .shadow(color: Theme.softShadow, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Cancel · Title · Save row that opens every editing sheet.
struct SheetHeader: View {
    let title: String
    var confirm = L.Common.save
    var enabled = true
    var tint: Color = Theme.rose
    var cancel = L.Common.cancel
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.baloo(17, heavy: true))
                .foregroundStyle(Theme.ink)
            HStack {
                Button(action: onCancel) {
                    Text(cancel)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(Theme.inkBody)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onConfirm) {
                    Text(confirm)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(enabled ? .white : Theme.disabledText)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(enabled ? tint : Theme.disabledFill, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
            }
        }
    }
}

/// White circle holding a back chevron — the design's own back affordance.
struct CircleBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("icon-back")
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: 13, height: 13)
                .frame(width: 38, height: 38)
                .background(Color.white, in: Circle())
                .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }
}

/// Rose circle with a plus — the "add" affordance in screen headers.
struct CircleAddButton: View {
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("icon-plus-white")
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: size * 0.4, height: size * 0.4)
                .frame(width: size, height: size)
                .background(Theme.rose, in: Circle())
                .shadow(color: Theme.rose.opacity(0.4), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// Back · Title · trailing-action header used by every pushed detail screen.
struct DetailHeader<Trailing: View>: View {
    let title: String
    var onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            Text(title)
                .font(.baloo(19, heavy: true))
                .foregroundStyle(Theme.ink)
            HStack {
                CircleBackButton(action: onBack)
                Spacer()
                trailing.frame(minWidth: 40)
            }
        }
        .padding(.horizontal, 18)
    }
}

/// Fixed-size stand-in that balances the back button so the title stays
/// centred. It must be sized — a bare `Color.clear` expands vertically and
/// stretches the whole header.
struct HeaderSpacer: View {
    var body: some View { Color.clear.frame(width: 40, height: 40) }
}

extension DetailHeader where Trailing == HeaderSpacer {
    /// Header with no trailing action.
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack) { HeaderSpacer() }
    }
}

/// `−  value  +` inside a soft capsule.
struct SoftStepper: View {
    let label: String
    var minWidth: CGFloat = 70
    var tint: Color = Theme.roseText
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Text(L.Glyph.minus)
                    .font(.nunito(16, .heavy))
                    .foregroundStyle(Theme.inkBody)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
            Text(label)
                .font(.nunito(13, .heavy))
                .foregroundStyle(Theme.inkSoft)
                .frame(minWidth: minWidth)
            Button(action: onIncrement) {
                Text(L.Glyph.plus)
                    .font(.nunito(16, .heavy))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(Theme.field, in: Capsule())
    }
}

/// The design's own 50×30 toggle — SwiftUI's Toggle can't be tinted this way.
struct SoftToggle: View {
    @Binding var isOn: Bool
    var tint: Color = Theme.rose

    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? tint : Theme.toggleOff)
                    .frame(width: 50, height: 30)
                Circle().fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2.5, y: 2)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isOn)
    }
}

/// Big rounded pill button — "Log a feed", "Send to Husband", "Open my app".
struct PrimaryButton: View {
    let title: String
    var icon: String?
    var tint: Color = Theme.roseStrong
    var height: CGFloat = 54
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon {
                    Image(icon)
                        .renderingMode(.original)
                        .resizable().scaledToFit()
                        .frame(width: 16, height: 16)
                }
                Text(title)
                    .font(.baloo(16, heavy: true))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(tint, in: Capsule())
            .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 10, y: 9)
        }
        .buttonStyle(.plain)
    }
}

/// White pillow card with the design's hairline border and soft shadow.
struct SoftCard<Content: View>: View {
    var radius: CGFloat = 26
    var bordered = false
    var padding = EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Theme.cardBorder, lineWidth: 2)
                }
            }
            .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }
}

/// Full-width divider inside a card.
struct CardDivider: View {
    var body: some View {
        Rectangle().fill(Theme.divider).frame(height: 1)
    }
}

/// Left-aligned wrapping row — the design's `flex-wrap` chip groups.
struct FlowRow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = layout(subviews, in: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in layout(subviews, in: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layout(_ subviews: Subviews, in maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > maxWidth && !row.indices.isEmpty {
                rows.append(row)
                row = Row()
                row.indices = [index]
                row.width = size.width
                row.height = size.height
            } else {
                row.indices.append(index)
                row.width = needed
                row.height = max(row.height, size.height)
            }
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
