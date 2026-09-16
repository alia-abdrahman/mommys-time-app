import SwiftUI

/// Which subscription is selected. A case rather than a string so the CTA and
/// the fine print can't drift apart once the names are translated.
enum PaywallPlan {
    case monthly, yearly

    var lowercasedName: String {
        self == .yearly ? L.Paywall.planYearlyLower : L.Paywall.planMonthlyLower
    }
}

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.isPremium) private var isPremium = false

    var onToast: (String) -> Void = { _ in }

    @State private var plan = PaywallPlan.yearly

    private struct Perk { let asset, title, sub: String }
    /// Must stay in step with everything actually gated: the three starred tiles
    /// on Home and the Sync row in Settings.
    private let perks = [
        Perk(asset: "wake-window", title: L.Paywall.perkWakeTitle, sub: L.Paywall.perkWakeSub),
        Perk(asset: "recipes", title: L.Paywall.perkRecipesTitle, sub: L.Paywall.perkRecipesSub),
        Perk(asset: "my-spending", title: L.Paywall.perkSpendingTitle, sub: L.Paywall.perkSpendingSub),
        Perk(asset: "sync-to-cloud", title: L.Paywall.perkSyncTitle, sub: L.Paywall.perkSyncSub),
    ]

    private struct Plan: Identifiable {
        let id: PaywallPlan
        let name, tag, sub, price: String
    }
    private let plans = [
        Plan(id: .monthly, name: L.Paywall.planMonthly, tag: "",
             sub: L.Paywall.planMonthlySub, price: L.Paywall.planMonthlyPrice),
        Plan(id: .yearly, name: L.Paywall.planYearly, tag: L.Paywall.saveTag,
             sub: L.Paywall.planYearlySub, price: L.Paywall.planYearlyPrice),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                heroCard.padding(.top, 18)

                sectionLabel(L.Paywall.unlockLabel).padding(.top, 18).padding(.bottom, 8)
                perkList

                sectionLabel(L.Paywall.planLabel).padding(.top, 18).padding(.bottom, 8)
                planCards

                primaryCTA.padding(.top, 18)
                finePrint.padding(.top, 8)
                restoreLink.padding(.top, 12)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(PW.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(PW.sheetBg)
        .presentationDragIndicator(.hidden)
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(L.Paywall.title)
                .font(.baloo(17, heavy: true))
                .foregroundStyle(PW.textPrimary)
            HStack {
                Color.clear.frame(width: 64, height: 1)
                Spacer()
                Button { dismiss() } label: {
                    Text(L.Common.close)
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(PW.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(spacing: 0) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundStyle(PW.roseCTA)
                .frame(width: 56, height: 56)
                .background(.white, in: Circle())
                .padding(.bottom, 10)
            Text(L.Paywall.heroTitle)
                .font(.baloo(22, heavy: true))
                .foregroundStyle(PW.textPrimary)
                .multilineTextAlignment(.center)
            Text(L.Paywall.heroSub(perkCount))
                .font(.nunito(13.5, .semibold)).lineSpacing(5)
                .foregroundStyle(PW.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(PW.roseFill, in: RoundedRectangle(cornerRadius: 28))
    }

    /// Spelled out so the headline can't drift when a perk is added or removed.
    private var perkCount: String {
        L.Paywall.countWords[safe: perks.count] ?? "\(perks.count)"
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(PW.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Perks

    private var perkList: some View {
        VStack(spacing: 9) {
            ForEach(perks, id: \.title) { perk in
                HStack(spacing: 13) {
                    Image(perk.asset)
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 19, height: 19)
                        .foregroundStyle(PW.roseAccent)
                        .frame(width: 38, height: 38)
                        .background(PW.tileFill, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(perk.title).font(.nunito(14.5, .heavy)).foregroundStyle(PW.textPrimary)
                        Text(perk.sub).font(.nunito(12, .semibold)).foregroundStyle(PW.textMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 13).padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 12, y: 4)
            }
        }
    }

    // MARK: Plans

    private var planCards: some View {
        VStack(spacing: 9) {
            ForEach(plans) { p in
                let selected = p.id == plan
                Button { plan = p.id } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(selected ? PW.roseCTA : PW.radioIdle).frame(width: 22, height: 22)
                            if selected { Circle().fill(.white).frame(width: 8, height: 8) }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 7) {
                                Text(p.name).font(.nunito(15, .heavy)).foregroundStyle(PW.textPrimary)
                                if !p.tag.isEmpty {
                                    Text(p.tag)
                                        .font(.nunito(9.5, .heavy)).tracking(0.6)
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 3).padding(.horizontal, 7)
                                        .background(PW.saveGreen, in: Capsule())
                                }
                            }
                            Text(p.sub).font(.nunito(12, .semibold)).foregroundStyle(PW.textMuted)
                        }
                        Spacer(minLength: 8)
                        Text(p.price).font(.baloo(16, heavy: true)).foregroundStyle(PW.roseValue).fixedSize()
                    }
                    .padding(.vertical, 14).padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(selected ? PW.roseCTA : .clear, lineWidth: 2)
                    )
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: CTA / footer

    private var primaryCTA: some View {
        Button { subscribe() } label: {
            HStack(spacing: 9) {
                Image(systemName: isPremium ? "checkmark" : "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text(isPremium ? L.Paywall.ctaOwned : L.Paywall.cta(plan.lowercasedName))
                    .font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(PW.roseCTA, in: Capsule())
            .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 20, y: 9)
        }
        .buttonStyle(.plain)
    }

    private var finePrint: some View {
        Text(plan == .yearly ? L.Paywall.finePrintYearly : L.Paywall.finePrintMonthly)
            .font(.nunito(11.5, .semibold)).lineSpacing(4)
            .foregroundStyle(PW.hintText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var restoreLink: some View {
        Button { onToast(L.Paywall.toastNoPurchase) } label: {
            Text(L.Paywall.restore)
                .font(.nunito(12.5, .heavy))
                .foregroundStyle(PW.linkRose)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func subscribe() {
        guard !isPremium else { return }
        isPremium = true
        onToast(L.Paywall.toastUnlocked)
        dismiss()
    }
}

// MARK: - Paywall palette

private enum PW {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let tileFill = Color(hex: 0xFBEBD8)
    static let roseAccent = Color(hex: 0xC4788C)
    static let roseValue = Color(hex: 0xC46A82)
    static let roseCTA = Color(hex: 0xD9758C)
    static let linkRose = Color(hex: 0xC97B8C)
    static let saveGreen = Color(hex: 0xD98FA0)
    static let radioIdle = Color(hex: 0xF4EDE4)
    static let hintText = Color(hex: 0xA99B8C)
}
