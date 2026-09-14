import SwiftUI
import CoreData

/// The community tab: discussions other mums have started, with hugs instead of
/// upvotes. No advice unless you ask — that's the house rule.
struct VillageView: View {
    var onToast: (String) -> Void = { _ in }

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \VillageThread.createdAt, ascending: false)],
        animation: .default
    )
    private var threads: FetchedResults<VillageThread>

    @State private var topic = "All"
    @State private var showingNewThread = false

    static let topics = ["Nights", "Feeding", "Me-time"]

    private var shown: [VillageThread] {
        topic == "All" ? Array(threads) : threads.filter { $0.topic == topic }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header.padding(.horizontal, 22)
                    topicChips.padding(.top, 14)
                    threadList.padding(.top, 14).padding(.horizontal, 18)
                }
                .padding(.top, 8)
                .padding(.bottom, 116)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: VillageThread.self) { thread in
                VillageThreadView(thread: thread, onToast: onToast)
            }
            .sheet(isPresented: $showingNewThread) {
                NewThreadSheet(onPosted: { onToast("Discussion posted to the community") })
            }
            .onAppear { VillageSeed.seedIfNeeded(in: context) }
        }
        .tint(Theme.rose)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Community")
                    .font(.baloo(32))
                    .foregroundStyle(Theme.ink)
                Text(countLine)
                    .font(.nunito(13, .semibold))
                    .foregroundStyle(Theme.inkMuted)
            }
            Spacer()
            Button { showingNewThread = true } label: {
                Image("icon-plus-white")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 15, height: 15)
                    .frame(width: 40, height: 40)
                    .background(Theme.rose, in: Circle())
                    .shadow(color: Theme.rose.opacity(0.4), radius: 6, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    private var countLine: String {
        let n = threads.count
        return "\(n) discussion\(n == 1 ? "" : "s") · no advice unless you ask"
    }

    private var topicChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["All"] + Self.topics, id: \.self) { t in
                    let on = topic == t
                    Button { withAnimation(.easeInOut(duration: 0.18)) { topic = t } } label: {
                        Text(t)
                            .font(.nunito(12.5, .heavy))
                            .foregroundStyle(on ? .white : Theme.inkBody)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .background(on ? Theme.roseStrong : .white, in: Capsule())
                            .shadow(color: Theme.softShadow, radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 4)
        }
    }

    private var threadList: some View {
        VStack(spacing: 10) {
            ForEach(shown, id: \.objectID) { thread in
                NavigationLink(value: thread) {
                    ThreadCard(thread: thread)
                }
                .buttonStyle(.plain)
            }
            if shown.isEmpty {
                VStack(spacing: 5) {
                    Text("Nothing here yet")
                        .font(.baloo(16, heavy: true))
                        .foregroundStyle(Theme.ink)
                    Text("Be the first to start a \(topic.lowercased()) discussion.")
                        .font(.nunito(12.5, .semibold))
                        .lineSpacing(5)
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .padding(.horizontal, 22)
                .background(Theme.roseTint, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}

// MARK: - Thread card

private struct ThreadCard: View {
    @ObservedObject var thread: VillageThread

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                TopicPill(topic: thread.topic ?? "")
                Text(thread.displayMeta)
                    .font(.nunito(11.5, .semibold))
                    .foregroundStyle(Theme.inkMuted)
                Spacer(minLength: 0)
            }
            Text(thread.title ?? "")
                .font(.baloo(16, heavy: true))
                .lineSpacing(3)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)
            Text(preview)
                .font(.nunito(13, .semibold))
                .lineSpacing(4)
                .foregroundStyle(Theme.inkBody)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            HStack(spacing: 14) {
                countLabel("icon-message-grey", thread.replyCountLabel, Theme.inkBody)
                countLabel("icon-heart", "\(thread.hugs) hugs", Theme.tileGlyph)
            }
            .padding(.top, 11)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    /// The card shows the opening of the post, trimmed to one or two lines.
    private var preview: String {
        let body = thread.body ?? ""
        guard body.count > 92 else { return body }
        return body.prefix(92).trimmingCharacters(in: .whitespaces) + "…"
    }

    private func countLabel(_ asset: String, _ text: String, _ colour: Color) -> some View {
        HStack(spacing: 6) {
            Image(asset)
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: 15, height: 15)
            Text(text)
                .font(.nunito(12, .heavy))
                .foregroundStyle(colour)
        }
    }
}

private struct TopicPill: View {
    let topic: String

    var body: some View {
        Text(topic)
            .font(.nunito(10.5, .heavy))
            .foregroundStyle(Theme.roseLabel)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.roseBadgeBg, in: Capsule())
    }
}

/// Round initial badge used for post and reply authors.
private struct Avatar: View {
    let name: String
    var size: CGFloat = 36

    var body: some View {
        Circle()
            .fill(VillageStyle.tint(for: name))
            .frame(width: size, height: size)
            .overlay {
                Text(name.prefix(1))
                    .font(.nunito(size * 0.36, .heavy))
                    .foregroundStyle(Color(hex: 0x6E5A4E))
            }
    }
}

enum VillageStyle {
    /// Two warm avatar tints, picked deterministically from the name so a given
    /// author keeps the same colour across launches.
    static func tint(for name: String) -> Color {
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return sum.isMultiple(of: 2) ? Color(hex: 0xF6E6E9) : Color(hex: 0xF3E7DA)
    }
}

// MARK: - Thread detail

struct VillageThreadView: View {
    @ObservedObject var thread: VillageThread
    var onToast: (String) -> Void = { _ in }

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.userName) private var userName = "You"

    @State private var draft = ""

    private var replies: [VillageReply] {
        let all = thread.replies as? Set<VillageReply> ?? []
        return all.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    postCard.padding(.top, 16).padding(.horizontal, 18)
                    Text("\(replies.count) REPLIES")
                        .font(.nunito(12, .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 18)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)
                    replyList.padding(.horizontal, 18)
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .safeAreaInset(edge: .bottom) { composer(proxy) }
        }
    }

    private var header: some View {
        ZStack {
            Text("Discussion")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(Theme.ink)
            HStack {
                CircleBackButton { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 18)
    }

    private var postCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Avatar(name: thread.author ?? "You")
                VStack(alignment: .leading, spacing: 1) {
                    Text(thread.author ?? "You")
                        .font(.nunito(13.5, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(thread.displayMeta)
                        .font(.nunito(11.5, .semibold))
                        .foregroundStyle(Theme.inkMuted)
                }
                Spacer(minLength: 0)
                TopicPill(topic: thread.topic ?? "")
            }
            Text(thread.title ?? "")
                .font(.baloo(19, heavy: true))
                .lineSpacing(3)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            Text(thread.body ?? "")
                .font(.nunito(14, .bold))
                .lineSpacing(6)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)
            hugButton.padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 2)
        }
        .shadow(color: Theme.softShadow, radius: 9, y: 5)
    }

    private var hugButton: some View {
        Button(action: toggleHug) {
            HStack(spacing: 7) {
                Image(thread.hugged ? "icon-heart-fill" : "icon-heart")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 15, height: 15)
                Text(hugLabel)
                    .font(.nunito(12.5, .heavy))
                    .foregroundStyle(Theme.tileGlyph)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(thread.hugged ? Theme.roseBadgeBg : Theme.canvas, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.cardBorder, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private var hugLabel: String {
        "\(thread.hugs) hugs" + (thread.hugged ? " · you too" : "")
    }

    private func toggleHug() {
        thread.hugged.toggle()
        thread.hugs += thread.hugged ? 1 : -1
        try? context.save()
    }

    private var replyList: some View {
        VStack(spacing: 9) {
            ForEach(replies, id: \.objectID) { reply in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 9) {
                        Avatar(name: reply.author ?? "You", size: 28)
                        Text(reply.author ?? "You")
                            .font(.nunito(12.5, .heavy))
                            .foregroundStyle(Theme.ink)
                        Text(reply.displayWhen)
                            .font(.nunito(11, .semibold))
                            .foregroundStyle(Theme.inkMuted)
                        Spacer(minLength: 0)
                    }
                    Text(reply.body ?? "")
                        .font(.nunito(13.5, .bold))
                        .lineSpacing(5)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color(hex: 0x7A6248).opacity(0.08), radius: 8, y: 4)
            }
        }
    }

    private func composer(_ proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 9) {
            TextField("Write a reply…", text: $draft)
                .font(.nunito(13.5, .bold))
                .foregroundStyle(Theme.ink)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.cardBorder, lineWidth: 2))

            Button { post(proxy) } label: {
                Image("share-plan-white")
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: 17, height: 17)
                    .frame(width: 44, height: 44)
                    .background(draft.isBlank ? Color(hex: 0xE3CFC0) : Theme.rose, in: Circle())
                    .shadow(color: Theme.rose.opacity(0.35), radius: 6, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 96)
        .background {
            Theme.canvas
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.divider).frame(height: 1)
                }
                .ignoresSafeArea()
        }
    }

    private func post(_ proxy: ScrollViewProxy) {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            onToast("Write a reply first")
            return
        }
        let reply = VillageReply(context: context)
        reply.id = UUID()
        reply.author = userName.isEmpty ? "You" : userName
        reply.body = text
        reply.createdAt = Date()
        reply.thread = thread
        try? context.save()

        draft = ""
        onToast("Reply posted")
        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
    }
}

// MARK: - New discussion

struct NewThreadSheet: View {
    var onPosted: () -> Void = {}

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.userName) private var userName = "You"
    @AppStorage(SettingsKeys.babyAgeBand) private var babyAge = "0–6 months"

    @State private var topic = "Nights"
    @State private var title = ""
    @State private var body_ = ""

    private var canPost: Bool { !title.isBlank }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(
                    title: "New discussion",
                    confirm: "Post",
                    enabled: canPost,
                    onCancel: { dismiss() },
                    onConfirm: post
                )

                SectionLabel("TOPIC").padding(.top, 20).padding(.bottom, 8)
                HStack(spacing: 8) {
                    ForEach(VillageView.topics, id: \.self) { t in
                        ChipButton(label: t, selected: topic == t) { topic = t }
                    }
                }

                SectionLabel("WHAT'S ON YOUR MIND?").padding(.top, 20).padding(.bottom, 8)
                VStack(spacing: 0) {
                    TextField("Give it a title", text: $title)
                        .font(.baloo(16, heavy: true))
                        .foregroundStyle(Theme.ink)
                        .padding(.vertical, 14)
                    Rectangle().fill(Theme.divider).frame(height: 1)
                    TextField(
                        "Tell the community a bit more — what happened, what you need.",
                        text: $body_,
                        axis: .vertical
                    )
                    .lineLimit(5...)
                    .font(.nunito(14, .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, 18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: Theme.softShadow, radius: 9, y: 5)

                Text("Posts show your first name only. No advice unless you ask — that's the house rule.")
                    .font(.nunito(11.5, .semibold))
                    .lineSpacing(4)
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.canvas)
        .presentationBackground(Theme.canvas)
        .presentationDragIndicator(.hidden)
    }

    private func post() {
        guard canPost else { return }
        let thread = VillageThread(context: context)
        thread.id = UUID()
        thread.author = userName.split(separator: " ").first.map(String.init) ?? "You"
        thread.topic = topic
        thread.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        thread.body = body_.isBlank ? "—" : body_.trimmingCharacters(in: .whitespacesAndNewlines)
        thread.meta = "Baby \(babyAge) · just now"
        thread.hugs = 0
        thread.hugged = false
        thread.createdAt = Date()
        try? context.save()

        dismiss()
        onPosted()
    }
}

// MARK: - Seed content

enum VillageSeed {
    private static let flag = "villageSeeded"

    /// Drops in the three starter discussions the first time the tab is opened,
    /// so the community isn't an empty room. Only ever runs once.
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        UserDefaults.standard.set(true, forKey: flag)

        let now = Date()
        func hoursAgo(_ h: Double) -> Date { now.addingTimeInterval(-h * 3600) }

        let seeds: [(String, String, String, String, String, Int32, Double, [(String, String, Double)])] = [
            ("Aina", "Baby 4 months · 2h ago", "Nights",
             "Third night of 3am wake-ups",
             "She settles in twenty minutes but I'm wide awake until five. Not looking for fixes — just needed to say it out loud somewhere that gets it.",
             14, 2, [
                ("Suraya", "Sitting with you. Week three of the same here. It does end, but that doesn't make tonight easier.", 1),
                ("Mei", "Saying it out loud counts. Hope you get a long stretch tonight.", 0.67),
             ]),
            ("Suraya", "Baby 7 weeks · 5h ago", "Feeding",
             "Combi feeding and the guilt finally lifted",
             "Switched this week after six weeks of trying to do it all by breast. She's fed, she's growing, and I slept four hours straight for the first time. Posting in case someone needs permission.",
             22, 5, [
                ("Hana", "I needed this today. Thank you for posting it.", 3),
                ("Aina", "Fed is fed. Four hours is huge — hope tonight gives you another.", 2),
                ("Priya", "Did your supply settle after? Asking because I'm a week behind you.", 1),
             ]),
            ("Mei", "Baby 9 months · yesterday", "Me-time",
             "Booked 40 minutes for a walk with no pram",
             "First time since January. Put it in the app as a block so nobody could claim the slot. Came home a different person. What's your smallest win this week?",
             31, 26, [
                ("Aina", "A shower with the door closed. Genuinely.", 20),
                ("Nurul", "Blocking the slot is the trick. If it isn't in the app someone else takes the hour.", 14),
             ]),
        ]

        for (author, meta, topic, title, body, hugs, age, replies) in seeds {
            let thread = VillageThread(context: context)
            thread.id = UUID()
            thread.author = author
            thread.meta = meta
            thread.topic = topic
            thread.title = title
            thread.body = body
            thread.hugs = hugs
            thread.hugged = false
            thread.createdAt = hoursAgo(age)

            for (who, text, when) in replies {
                let reply = VillageReply(context: context)
                reply.id = UUID()
                reply.author = who
                reply.body = text
                reply.when = relative(hours: when)
                reply.createdAt = hoursAgo(when)
                reply.thread = thread
            }
        }
        try? context.save()
    }

    private static func relative(hours: Double) -> String {
        if hours < 1 { return "\(Int(hours * 60))m ago" }
        if hours < 24 { return "\(Int(hours))h ago" }
        return "\(Int(hours / 24))d ago"
    }
}

// MARK: - Model conveniences

extension VillageThread {
    /// Seeded posts carry a hand-written byline; posts you write age naturally.
    var displayMeta: String {
        if let meta, !meta.isEmpty, author != "You" { return meta }
        return RelativeLabel.since(createdAt)
    }

    var replyCountLabel: String {
        let n = replies?.count ?? 0
        return "\(n) \(n == 1 ? "reply" : "replies")"
    }
}

extension VillageReply {
    var displayWhen: String {
        if let when, !when.isEmpty { return when }
        return RelativeLabel.since(createdAt)
    }
}

enum RelativeLabel {
    static func since(_ date: Date?) -> String {
        guard let date else { return "just now" }
        let minutes = max(0, Int(Date().timeIntervalSince(date) / 60))
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return days == 1 ? "yesterday" : "\(days)d ago"
    }
}

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview {
    VillageView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
