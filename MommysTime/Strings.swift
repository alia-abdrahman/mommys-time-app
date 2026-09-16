import Foundation

// MARK: - The string catalogue
//
// Every piece of copy the user can read lives here and nowhere else. Views pull
// text from `L.<Screen>.<name>` so translating the app is a matter of adding a
// String Catalog (`Localizable.xcstrings`) with the keys below — no view has to
// be touched again.
//
// Each entry is `String(localized:defaultValue:)`, so the literal doubles as the
// English source *and* the fallback if a translation is missing. Values that
// take numbers or names are functions; the interpolation becomes a `%@`/`%lld`
// placeholder in the catalog, which translators are free to reorder.
//
// Two rules keep in-app language switching working, and both are easy to break
// by accident when adding a string — copy a neighbouring line and you're fine:
//
//  * every entry is a computed `var` (or a `func`), never a stored `let`. A
//    stored one resolves once and caches whichever language the process read
//    first, so it would go on showing the old language after a switch.
//  * every lookup passes `bundle: Bundle.appLanguage` — the `.lproj` for the
//    language she picked. Without it the lookup goes to `Bundle.main`, which is
//    fixed at launch and only ever follows the device.
//
// See `AppLanguage.swift`.
//
// Two things deliberately do NOT live in here as localised text:
//
//  * `L.Glyph` — "+", "−", "×". Typographic symbols, identical in every
//    language; translating them would only invite mistakes.
//  * The raw values persisted to Core Data / UserDefaults (`FeedType.all`,
//    `PumpSide.all`, `VillageTopic.rawValue`, …). Those are *identifiers*, not
//    copy: they must stay stable in English or a user who switches language
//    loses their saved rows. Each one has a `label` that looks its display text
//    up here instead.

enum L {

    // MARK: - Symbols (never translated)

    enum Glyph {
        static let plus = "+"
        static let minus = "−"
        /// The little "clear" cross on removable rows.
        static let remove = "×"
        /// Quantity prefix — "×3 on hand".
        static let times = "×"
        static let placeholder = "—"
    }

    // MARK: - Shared vocabulary

    enum Common {
        static var save: String { String(localized: "common.save", defaultValue: "Save", bundle: Bundle.appLanguage) }
        static var cancel: String { String(localized: "common.cancel", defaultValue: "Cancel", bundle: Bundle.appLanguage) }
        static var done: String { String(localized: "common.done", defaultValue: "Done", bundle: Bundle.appLanguage) }
        static var close: String { String(localized: "common.close", defaultValue: "Close", bundle: Bundle.appLanguage) }
        static var delete: String { String(localized: "common.delete", defaultValue: "Delete", bundle: Bundle.appLanguage) }
        static var edit: String { String(localized: "common.edit", defaultValue: "Edit", bundle: Bundle.appLanguage) }
        static var today: String { String(localized: "common.today", defaultValue: "Today", bundle: Bundle.appLanguage) }
        static var tomorrow: String { String(localized: "common.tomorrow", defaultValue: "Tomorrow", bundle: Bundle.appLanguage) }
        static var none: String { String(localized: "common.none", defaultValue: "—", bundle: Bundle.appLanguage) }
    }

    /// Lengths of time. Every screen that shows a duration composes it from
    /// these three, so "1h 30m" reads the same everywhere.
    enum Duration {
        static func minutes(_ m: Int) -> String {
            String(localized: "duration.minutes", defaultValue: "\(m) min", bundle: Bundle.appLanguage)
        }
        static func hours(_ h: Int) -> String {
            String(localized: "duration.hours", defaultValue: "\(h)h", bundle: Bundle.appLanguage)
        }
        static func hoursMinutes(_ h: Int, _ m: Int) -> String {
            String(localized: "duration.hoursMinutes", defaultValue: "\(h)h \(m)m", bundle: Bundle.appLanguage)
        }
        static var zeroMinutes: String { String(localized: "duration.zero", defaultValue: "0m", bundle: Bundle.appLanguage) }

        /// "45 min" under the hour, "1h" / "1h 30m" over it.
        static func compact(_ m: Int) -> String {
            guard m >= 60 else { return minutes(m) }
            let h = m / 60, r = m % 60
            return r == 0 ? hours(h) : hoursMinutes(h, r)
        }
    }

    /// "in 20 min", "3h ago" — the two directions a relative time can point.
    enum Relative {
        static var now: String { String(localized: "relative.now", defaultValue: "now", bundle: Bundle.appLanguage) }
        static var justNow: String { String(localized: "relative.justNow", defaultValue: "just now", bundle: Bundle.appLanguage) }
        static var yesterday: String { String(localized: "relative.yesterday", defaultValue: "yesterday", bundle: Bundle.appLanguage) }

        static func inMinutes(_ m: Int) -> String {
            String(localized: "relative.in.minutes", defaultValue: "in \(m) min", bundle: Bundle.appLanguage)
        }
        static func inHours(_ h: Int) -> String {
            String(localized: "relative.in.hours", defaultValue: "in \(h)h", bundle: Bundle.appLanguage)
        }
        static func inHoursMinutes(_ h: Int, _ m: Int) -> String {
            String(localized: "relative.in.hoursMinutes", defaultValue: "in \(h)h \(m)m", bundle: Bundle.appLanguage)
        }
        static func inDays(_ d: Int) -> String {
            String(localized: "relative.in.days", defaultValue: "in \(d)d", bundle: Bundle.appLanguage)
        }
        static func inDaysHours(_ d: Int, _ h: Int) -> String {
            String(localized: "relative.in.daysHours", defaultValue: "in \(d)d \(h)h", bundle: Bundle.appLanguage)
        }

        static func minutesAgo(_ m: Int) -> String {
            String(localized: "relative.ago.minutes", defaultValue: "\(m)m ago", bundle: Bundle.appLanguage)
        }
        static func minutesAgoLong(_ m: Int) -> String {
            String(localized: "relative.ago.minutesLong", defaultValue: "\(m) min ago", bundle: Bundle.appLanguage)
        }
        static func hoursAgo(_ h: Int) -> String {
            String(localized: "relative.ago.hours", defaultValue: "\(h)h ago", bundle: Bundle.appLanguage)
        }
        static func hoursMinutesAgo(_ h: Int, _ m: Int) -> String {
            String(localized: "relative.ago.hoursMinutes", defaultValue: "\(h)h \(m)m ago", bundle: Bundle.appLanguage)
        }
        static func daysAgo(_ d: Int) -> String {
            String(localized: "relative.ago.days", defaultValue: "\(d)d ago", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - App chrome

    enum App {
        static var name: String { String(localized: "app.name", defaultValue: "Mommy's Time", bundle: Bundle.appLanguage) }
        static var tagline: String { String(localized: "app.tagline", defaultValue: "Because you deserve some too", bundle: Bundle.appLanguage) }

        static func version(_ short: String, build: String) -> String {
            String(localized: "app.version", defaultValue: "v\(short) (build \(build))", bundle: Bundle.appLanguage)
        }
        /// Shown when the bundle has no version — should never reach a user.
        static let versionFallback = "1.0"
        static let buildFallback = "1"
    }

    enum Tabs {
        static var home: String { String(localized: "tab.home", defaultValue: "Home", bundle: Bundle.appLanguage) }
        static var community: String { String(localized: "tab.community", defaultValue: "Community", bundle: Bundle.appLanguage) }
        static var settings: String { String(localized: "tab.settings", defaultValue: "Settings", bundle: Bundle.appLanguage) }
    }

    enum Splash {
        static var tapToContinue: String { String(localized: "splash.tapToContinue", defaultValue: "Tap to continue", bundle: Bundle.appLanguage) }
    }

    // MARK: - Schedule blocks

    enum Blocks {
        static var kids: String { String(localized: "block.category.kids", defaultValue: "Kids", bundle: Bundle.appLanguage) }
        static var chores: String { String(localized: "block.category.chores", defaultValue: "Chores", bundle: Bundle.appLanguage) }
        static var appointment: String { String(localized: "block.category.appointment", defaultValue: "Appointment", bundle: Bundle.appLanguage) }
        static var quiet: String { String(localized: "block.category.quiet", defaultValue: "Quiet time", bundle: Bundle.appLanguage) }
        static var meTime: String { String(localized: "block.category.meTime", defaultValue: "Me time", bundle: Bundle.appLanguage) }

        /// Title written onto a booked me-time block.
        static var meTimeBlockTitle: String { String(localized: "block.meTime.title", defaultValue: "Me-time", bundle: Bundle.appLanguage) }

        enum Template {
            static var schoolRun: String { String(localized: "block.template.schoolRun", defaultValue: "School run", bundle: Bundle.appLanguage) }
            static var schoolHours: String { String(localized: "block.template.schoolHours", defaultValue: "School hours", bundle: Bundle.appLanguage) }
            static var napTime: String { String(localized: "block.template.napTime", defaultValue: "Nap time", bundle: Bundle.appLanguage) }
            static var cooking: String { String(localized: "block.template.cooking", defaultValue: "Cooking", bundle: Bundle.appLanguage) }
            static var dinnerBath: String { String(localized: "block.template.dinnerBath", defaultValue: "Kids' dinner & bath", bundle: Bundle.appLanguage) }
            static var bedtimeRoutine: String { String(localized: "block.template.bedtime", defaultValue: "Bedtime routine", bundle: Bundle.appLanguage) }
            static var laundry: String { String(localized: "block.template.laundry", defaultValue: "Laundry", bundle: Bundle.appLanguage) }
            static var groceries: String { String(localized: "block.template.groceries", defaultValue: "Groceries", bundle: Bundle.appLanguage) }
        }
    }

    // MARK: - Onboarding

    enum Onboarding {
        static var skip: String { String(localized: "onboarding.skip", defaultValue: "Skip", bundle: Bundle.appLanguage) }
        static var ctaStart: String { String(localized: "onboarding.cta.start", defaultValue: "Show me how", bundle: Bundle.appLanguage) }
        static var ctaContinue: String { String(localized: "onboarding.cta.continue", defaultValue: "Continue", bundle: Bundle.appLanguage) }
        static var ctaFinish: String { String(localized: "onboarding.cta.finish", defaultValue: "Open my app", bundle: Bundle.appLanguage) }

        static var welcomeEyebrow: String { String(localized: "onboarding.welcome.eyebrow", defaultValue: "WELCOME TO", bundle: Bundle.appLanguage) }
        static var welcomeBody: String {
            String(
                localized: "onboarding.welcome.body",
                defaultValue: "Nobody hands you a manual for the newborn months. This app holds the whole of it — the baby, the house, the money, and you.",
                bundle: Bundle.appLanguage
            )
        }
        static var promiseNormalTitle: String { String(localized: "onboarding.promise.normal.title", defaultValue: "Know what's normal", bundle: Bundle.appLanguage) }
        static var promiseNormalSub: String { String(localized: "onboarding.promise.normal.sub", defaultValue: "Feeds, sleep and growth, in plain numbers", bundle: Bundle.appLanguage) }
        static var promiseHouseholdTitle: String { String(localized: "onboarding.promise.household.title", defaultValue: "Run the household", bundle: Bundle.appLanguage) }
        static var promiseHouseholdSub: String { String(localized: "onboarding.promise.household.sub", defaultValue: "Tasks, supplies, appointments, spending", bundle: Bundle.appLanguage) }
        static var promiseAloneTitle: String { String(localized: "onboarding.promise.alone.title", defaultValue: "Never do it alone", bundle: Bundle.appLanguage) }
        static var promiseAloneSub: String { String(localized: "onboarding.promise.alone.sub", defaultValue: "Ask other mothers, any hour of the night", bundle: Bundle.appLanguage) }

        static var babyTitle: String { String(localized: "onboarding.baby.title", defaultValue: "Tell us about your baby", bundle: Bundle.appLanguage) }
        static var babySub: String { String(localized: "onboarding.baby.sub", defaultValue: "Age sets what's normal for feeds, sleep and growth.", bundle: Bundle.appLanguage) }
        static var babyNamePlaceholder: String { String(localized: "onboarding.baby.namePlaceholder", defaultValue: "Baby's name", bundle: Bundle.appLanguage) }
        static var babyAgeLabel: String { String(localized: "onboarding.baby.ageLabel", defaultValue: "HOW OLD?", bundle: Bundle.appLanguage) }

        static var dayTitle: String { String(localized: "onboarding.day.title", defaultValue: "When are you awake?", bundle: Bundle.appLanguage) }
        static var daySub: String { String(localized: "onboarding.day.sub", defaultValue: "Reminders and tasks stay inside these hours.", bundle: Bundle.appLanguage) }
        static var dayStarts: String { String(localized: "onboarding.day.starts", defaultValue: "Starts", bundle: Bundle.appLanguage) }
        static var dayEnds: String { String(localized: "onboarding.day.ends", defaultValue: "Ends", bundle: Bundle.appLanguage) }
        static func dayNote(_ onDuty: String) -> String {
            String(
                localized: "onboarding.day.note",
                defaultValue: "That's \(onDuty) on duty. Nothing will buzz outside it — nights are hard enough.",
                bundle: Bundle.appLanguage
            )
        }

        static var careTitle: String { String(localized: "onboarding.care.title", defaultValue: "Who's in your corner?", bundle: Bundle.appLanguage) }
        static var careSub: String { String(localized: "onboarding.care.sub", defaultValue: "One person you can hand something to on a bad day.", bundle: Bundle.appLanguage) }
        static var careNamePlaceholder: String { String(localized: "onboarding.care.namePlaceholder", defaultValue: "Their name", bundle: Bundle.appLanguage) }
        static var careRelationLabel: String { String(localized: "onboarding.care.relationLabel", defaultValue: "THEY ARE MY", bundle: Bundle.appLanguage) }
        static var careNote: String { String(localized: "onboarding.care.note", defaultValue: "Just for your own reference — no accounts, no invites, nothing sent.", bundle: Bundle.appLanguage) }

        static var doneTitle: String { String(localized: "onboarding.done.title", defaultValue: "You're ready", bundle: Bundle.appLanguage) }
        static func doneTitleNamed(_ baby: String) -> String {
            String(localized: "onboarding.done.titleNamed", defaultValue: "You and \(baby) are ready", bundle: Bundle.appLanguage)
        }
        static var doneSub: String { String(localized: "onboarding.done.sub", defaultValue: "One day at a time from here. Change any of this in Settings.", bundle: Bundle.appLanguage) }
        static var summaryBaby: String { String(localized: "onboarding.summary.baby", defaultValue: "Baby", bundle: Bundle.appLanguage) }
        static var summaryDay: String { String(localized: "onboarding.summary.day", defaultValue: "Your day", bundle: Bundle.appLanguage) }
        static var summaryCorner: String { String(localized: "onboarding.summary.corner", defaultValue: "In my corner", bundle: Bundle.appLanguage) }
        static var summaryNotSet: String { String(localized: "onboarding.summary.notSet", defaultValue: "Not set", bundle: Bundle.appLanguage) }
        static var summaryNobody: String { String(localized: "onboarding.summary.nobody", defaultValue: "Nobody yet", bundle: Bundle.appLanguage) }
        static func summaryBabyValue(_ name: String, _ age: String) -> String {
            String(localized: "onboarding.summary.babyValue", defaultValue: "\(name) · \(age)", bundle: Bundle.appLanguage)
        }
        static func summaryDayValue(_ start: String, _ end: String) -> String {
            String(localized: "onboarding.summary.dayValue", defaultValue: "\(start) – \(end)", bundle: Bundle.appLanguage)
        }
        static func summaryCornerValue(_ name: String, _ relation: String) -> String {
            String(localized: "onboarding.summary.cornerValue", defaultValue: "\(name) · \(relation)", bundle: Bundle.appLanguage)
        }

        static var toastSkipped: String { String(localized: "onboarding.toast.skipped", defaultValue: "You can run setup again in Settings", bundle: Bundle.appLanguage) }
        static var toastDone: String { String(localized: "onboarding.toast.done", defaultValue: "All set — welcome", bundle: Bundle.appLanguage) }
        static var toastDoneNamed: String { String(localized: "onboarding.toast.doneNamed", defaultValue: "All set — welcome, mama", bundle: Bundle.appLanguage) }
    }

    /// The language picker — shown as the first onboarding step and again in
    /// Settings. The language *names* aren't here: they live on `AppLanguage`
    /// and are written in their own language, never translated.
    enum Language {
        static var title: String { String(localized: "language.title", defaultValue: "Choose your language", bundle: Bundle.appLanguage) }
        static var sub: String { String(localized: "language.sub", defaultValue: "You can change this any time in Settings.", bundle: Bundle.appLanguage) }
        static var followDevice: String { String(localized: "language.followDevice", defaultValue: "Follow device", bundle: Bundle.appLanguage) }
    }

    /// Age bands. The raw value is persisted, the label is what she reads.
    enum AgeBand {
        static var newborn: String { String(localized: "ageBand.newborn", defaultValue: "Newborn", bundle: Bundle.appLanguage) }
        static var zeroToSix: String { String(localized: "ageBand.0to6", defaultValue: "0–6 months", bundle: Bundle.appLanguage) }
        static var sixToTwelve: String { String(localized: "ageBand.6to12", defaultValue: "6–12 months", bundle: Bundle.appLanguage) }
        static var overOneYear: String { String(localized: "ageBand.1yearPlus", defaultValue: "1 year +", bundle: Bundle.appLanguage) }
    }

    /// Who she can hand something to. Raw value persisted, label displayed.
    enum Relation {
        static var husband: String { String(localized: "relation.husband", defaultValue: "Husband", bundle: Bundle.appLanguage) }
        static var wife: String { String(localized: "relation.wife", defaultValue: "Wife", bundle: Bundle.appLanguage) }
        static var partner: String { String(localized: "relation.partner", defaultValue: "Partner", bundle: Bundle.appLanguage) }
        static var mum: String { String(localized: "relation.mum", defaultValue: "Mum", bundle: Bundle.appLanguage) }
        static var nanny: String { String(localized: "relation.nanny", defaultValue: "Nanny", bundle: Bundle.appLanguage) }
        static var grandma: String { String(localized: "relation.grandma", defaultValue: "Grandma", bundle: Bundle.appLanguage) }
        static var sitter: String { String(localized: "relation.sitter", defaultValue: "Sitter", bundle: Bundle.appLanguage) }
    }

    // MARK: - Home

    enum Home {
        static var greetingMorning: String { String(localized: "home.greeting.morning", defaultValue: "Good morning", bundle: Bundle.appLanguage) }
        static var greetingAfternoon: String { String(localized: "home.greeting.afternoon", defaultValue: "Good afternoon", bundle: Bundle.appLanguage) }
        static var greetingEvening: String { String(localized: "home.greeting.evening", defaultValue: "Good evening", bundle: Bundle.appLanguage) }
        static var hello: String { String(localized: "home.hello", defaultValue: "Hello, mama", bundle: Bundle.appLanguage) }
        static var prompt: String { String(localized: "home.prompt", defaultValue: "What would you like to do today?", bundle: Bundle.appLanguage) }

        static var tipLabel: String { String(localized: "home.tip.label", defaultValue: "TIP OF THE DAY", bundle: Bundle.appLanguage) }
        static var tips: [String] {
            [
                String(localized: "home.tip.1", defaultValue: "You can't pour from an empty cup. Ten minutes for you counts.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.2", defaultValue: "Rest is productive too. The laundry can wait a little longer.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.3", defaultValue: "A calm mama is the best gift for your little ones. Breathe.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.4", defaultValue: "Done is better than perfect — especially today.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.5", defaultValue: "Small pockets of me-time add up to a whole happier you.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.6", defaultValue: "It's okay to ask for help. You don't have to do it all alone.", bundle: Bundle.appLanguage),
                String(localized: "home.tip.7", defaultValue: "Celebrate the tiny wins. You're doing more than you think.", bundle: Bundle.appLanguage),
            ]
        }

        static var reminderNothing: String { String(localized: "home.reminder.nothing", defaultValue: "Nothing else scheduled today — enjoy the calm.", bundle: Bundle.appLanguage) }
        static func reminderNext(_ title: String) -> String {
            String(localized: "home.reminder.next", defaultValue: "Next: \(title) ", bundle: Bundle.appLanguage)
        }
        static var nextBlockFallback: String { String(localized: "home.next.blockFallback", defaultValue: "your next block", bundle: Bundle.appLanguage) }
        static var nextAppointmentFallback: String { String(localized: "home.next.appointmentFallback", defaultValue: "appointment", bundle: Bundle.appLanguage) }
        static var nextPumpSession: String { String(localized: "home.next.pumpSession", defaultValue: "Pump session", bundle: Bundle.appLanguage) }

        static var tileSchedule: String { String(localized: "home.tile.schedule", defaultValue: "Daily Task", bundle: Bundle.appLanguage) }
        static var tileAppointment: String { String(localized: "home.tile.appointment", defaultValue: "Appointment", bundle: Bundle.appLanguage) }
        static var tileInventory: String { String(localized: "home.tile.inventory", defaultValue: "Inventory", bundle: Bundle.appLanguage) }
        static var tilePump: String { String(localized: "home.tile.pump", defaultValue: "Pump Tracker", bundle: Bundle.appLanguage) }
        static var tileFeed: String { String(localized: "home.tile.feed", defaultValue: "Feed Log", bundle: Bundle.appLanguage) }
        static var tileGrowth: String { String(localized: "home.tile.growth", defaultValue: "Growth Log", bundle: Bundle.appLanguage) }
        static var tileWake: String { String(localized: "home.tile.wake", defaultValue: "Wake Window", bundle: Bundle.appLanguage) }
        static var tileRecipes: String { String(localized: "home.tile.recipes", defaultValue: "Recipes", bundle: Bundle.appLanguage) }
        static var tileSpending: String { String(localized: "home.tile.spending", defaultValue: "My Spending", bundle: Bundle.appLanguage) }

        static var sootheOnTitle: String { String(localized: "home.soothe.on.title", defaultValue: "Calming noise is playing", bundle: Bundle.appLanguage) }
        static var sootheOffTitle: String { String(localized: "home.soothe.off.title", defaultValue: "Baby won't settle?", bundle: Bundle.appLanguage) }
        static var sootheOnSub: String { String(localized: "home.soothe.on.sub", defaultValue: "Tap stop when baby settles", bundle: Bundle.appLanguage) }
        static var sootheOffSub: String { String(localized: "home.soothe.off.sub", defaultValue: "One tap plays calming white noise", bundle: Bundle.appLanguage) }
        static var sootheStop: String { String(localized: "home.soothe.stop", defaultValue: "Stop", bundle: Bundle.appLanguage) }
        static var soothePlay: String { String(localized: "home.soothe.play", defaultValue: "Play", bundle: Bundle.appLanguage) }
    }

    enum Notifications {
        static var title: String { String(localized: "notifications.title", defaultValue: "Notifications", bundle: Bundle.appLanguage) }
        static var emptyTitle: String { String(localized: "notifications.empty.title", defaultValue: "You're all caught up", bundle: Bundle.appLanguage) }
        static var emptySub: String { String(localized: "notifications.empty.sub", defaultValue: "Reminders and gentle nudges will show up here.", bundle: Bundle.appLanguage) }
    }

    // MARK: - Daily Task

    enum Schedule {
        static var title: String { String(localized: "schedule.title", defaultValue: "Daily Task", bundle: Bundle.appLanguage) }
        static var emptyTitle: String { String(localized: "schedule.empty.title", defaultValue: "Your day is a blank page", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "schedule.empty.body",
                defaultValue: "Add your kids' routines, chores and appointments — then let the app find the pockets of time that belong to you.",
                bundle: Bundle.appLanguage
            )
        }
        static var emptyCTA: String { String(localized: "schedule.empty.cta", defaultValue: "Add your first block", bundle: Bundle.appLanguage) }
        static var pastTitle: String { String(localized: "schedule.past.title", defaultValue: "Nothing was scheduled", bundle: Bundle.appLanguage) }
        static var pastBody: String { String(localized: "schedule.past.body", defaultValue: "This day is in the past and has no blocks to show.", bundle: Bundle.appLanguage) }

        static func blockTime(_ start: String, _ end: String, _ duration: String) -> String {
            String(localized: "schedule.block.time", defaultValue: "\(start) – \(end) · \(duration)", bundle: Bundle.appLanguage)
        }
    }

    enum AddBlock {
        static var title: String { String(localized: "addBlock.title", defaultValue: "Add to your day", bundle: Bundle.appLanguage) }
        static var quickAdd: String { String(localized: "addBlock.quickAdd", defaultValue: "QUICK ADD", bundle: Bundle.appLanguage) }
        static var details: String { String(localized: "addBlock.details", defaultValue: "DETAILS", bundle: Bundle.appLanguage) }
        static var titlePlaceholder: String { String(localized: "addBlock.titlePlaceholder", defaultValue: "Title (e.g. Nap time)", bundle: Bundle.appLanguage) }
        static var starts: String { String(localized: "addBlock.starts", defaultValue: "Starts", bundle: Bundle.appLanguage) }
        static var length: String { String(localized: "addBlock.length", defaultValue: "Length", bundle: Bundle.appLanguage) }
        static var recurring: String { String(localized: "addBlock.recurring", defaultValue: "Recurring", bundle: Bundle.appLanguage) }
        static var recurringSub: String { String(localized: "addBlock.recurringSub", defaultValue: "Repeat this every day", bundle: Bundle.appLanguage) }
        static var endsOn: String { String(localized: "addBlock.endsOn", defaultValue: "Ends on", bundle: Bundle.appLanguage) }

        static func recurNote(days: Int, until: String) -> String {
            let span = days == 1
                ? String(localized: "addBlock.recurNote.dayOne", defaultValue: "\(days) day", bundle: Bundle.appLanguage)
                : String(localized: "addBlock.recurNote.dayOther", defaultValue: "\(days) days", bundle: Bundle.appLanguage)
            return String(
                localized: "addBlock.recurNote",
                defaultValue: "Repeats on \(span) — today through \(until). Change the end date any time.",
                bundle: Bundle.appLanguage
            )
        }

        static var toastNeedsTitle: String { String(localized: "addBlock.toast.needsTitle", defaultValue: "Give it a title first", bundle: Bundle.appLanguage) }
        static func toastRepeating(until: String) -> String {
            String(localized: "addBlock.toast.repeating", defaultValue: "Added to every day until \(until)", bundle: Bundle.appLanguage)
        }
        static func toastAdded(_ title: String) -> String {
            String(localized: "addBlock.toast.added", defaultValue: "\(title) added", bundle: Bundle.appLanguage)
        }
    }

    enum EditBlock {
        static var title: String { String(localized: "editBlock.title", defaultValue: "Edit block", bundle: Bundle.appLanguage) }
        static var details: String { String(localized: "editBlock.details", defaultValue: "Details", bundle: Bundle.appLanguage) }
        static var category: String { String(localized: "editBlock.category", defaultValue: "Category", bundle: Bundle.appLanguage) }
        static var starts: String { String(localized: "editBlock.starts", defaultValue: "Starts", bundle: Bundle.appLanguage) }
        static var ends: String { String(localized: "editBlock.ends", defaultValue: "Ends", bundle: Bundle.appLanguage) }
        static var repeatsDaily: String { String(localized: "editBlock.repeatsDaily", defaultValue: "Repeats every day", bundle: Bundle.appLanguage) }
        static var quietHint: String {
            String(
                localized: "editBlock.quietHint",
                defaultValue: "Quiet time (naps, school hours) counts as free time for YOU — the app will favour these windows when finding your me-time. 🌙",
                bundle: Bundle.appLanguage
            )
        }
        static var deleteButton: String { String(localized: "editBlock.delete", defaultValue: "Delete block", bundle: Bundle.appLanguage) }
        static var deleteRepeatingTitle: String { String(localized: "editBlock.delete.repeatingTitle", defaultValue: "Delete this repeating block?", bundle: Bundle.appLanguage) }
        static var deleteTitle: String { String(localized: "editBlock.delete.title", defaultValue: "Delete this block?", bundle: Bundle.appLanguage) }
        static var deleteMeTimeMessage: String {
            String(
                localized: "editBlock.delete.meTimeMessage",
                defaultValue: "This me-time session will no longer count towards your goal.",
                bundle: Bundle.appLanguage
            )
        }
        static var deleteRepeatingMessage: String {
            String(
                localized: "editBlock.delete.repeatingMessage",
                defaultValue: "It will be removed from every day, not just today.",
                bundle: Bundle.appLanguage
            )
        }
        static var deleteMessage: String { String(localized: "editBlock.delete.message", defaultValue: "This can't be undone.", bundle: Bundle.appLanguage) }
    }

    // MARK: - Find my time

    enum FindTime {
        static var title: String { String(localized: "findTime.title", defaultValue: "Your best windows", bundle: Bundle.appLanguage) }
        static var footerNote: String {
            String(
                localized: "findTime.footerNote",
                defaultValue: "Booking a slot adds it to today's schedule — your me-time becomes as official as the chores.",
                bundle: Bundle.appLanguage
            )
        }
        static let emptyEmoji = "😮‍💨"
        static var emptyTitle: String { String(localized: "findTime.empty.title", defaultValue: "No free windows left today", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "findTime.empty.body",
                defaultValue: "Today is a full one, mama. Try again tomorrow, or shorten the minimum gap in Settings.",
                bundle: Bundle.appLanguage
            )
        }
        static var book: String { String(localized: "findTime.book", defaultValue: "Book this time", bundle: Bundle.appLanguage) }
        static func range(_ start: String, _ end: String) -> String {
            String(localized: "findTime.range", defaultValue: "\(start) – \(end)", bundle: Bundle.appLanguage)
        }
        static func booked(_ duration: String) -> String {
            String(localized: "findTime.booked", defaultValue: "Booked \(duration) of me-time", bundle: Bundle.appLanguage)
        }

        static var noteAfterBedtime: String { String(localized: "findTime.note.afterBedtime", defaultValue: "After bedtime — nobody will need you.", bundle: Bundle.appLanguage) }
        static var noteQuiet: String { String(localized: "findTime.note.quiet", defaultValue: "The kids are settled — the house is quiet.", bundle: Bundle.appLanguage) }
        static var noteLong: String { String(localized: "findTime.note.long", defaultValue: "A lovely long stretch — a real pocket for you.", bundle: Bundle.appLanguage) }
        static func noteMinutes(_ m: Int) -> String {
            String(localized: "findTime.note.minutes", defaultValue: "\(m) free minutes just for you.", bundle: Bundle.appLanguage)
        }

        /// The scoring engine's own explanations, shown on the ranked slots.
        static func reasonLongStretch(_ m: Int) -> String {
            String(localized: "findTime.reason.longStretch", defaultValue: "A lovely long stretch — \(m) minutes", bundle: Bundle.appLanguage)
        }
        static var reasonQuiet: String { String(localized: "findTime.reason.quiet", defaultValue: "The kids are settled — quiet time 🌙", bundle: Bundle.appLanguage) }
        static var reasonAfterBedtime: String { String(localized: "findTime.reason.afterBedtime", defaultValue: "After the kids' bedtime", bundle: Bundle.appLanguage) }
        static var reasonAfterChore: String {
            String(
                localized: "findTime.reason.afterChore",
                defaultValue: "Right after a big chore — maybe start with something light",
                bundle: Bundle.appLanguage
            )
        }
        static func reasonFreeMinutes(_ m: Int) -> String {
            String(localized: "findTime.reason.freeMinutes", defaultValue: "\(m) free minutes just for you", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Share the plan

    enum SharePlan {
        static var title: String { String(localized: "sharePlan.title", defaultValue: "Share the plan", bundle: Bundle.appLanguage) }
        static var sendTo: String { String(localized: "sharePlan.sendTo", defaultValue: "SEND TO", bundle: Bundle.appLanguage) }
        static var emptyPreview: String {
            String(
                localized: "sharePlan.emptyPreview",
                defaultValue: "Nothing scheduled yet. Add a block or book some me-time and it'll appear here, ready to send.",
                bundle: Bundle.appLanguage
            )
        }
        static var countEmpty: String { String(localized: "sharePlan.count.empty", defaultValue: "empty", bundle: Bundle.appLanguage) }
        static func count(_ n: Int) -> String {
            n == 1
                ? String(localized: "sharePlan.count.one", defaultValue: "\(n) item", bundle: Bundle.appLanguage)
                : String(localized: "sharePlan.count.other", defaultValue: "\(n) items", bundle: Bundle.appLanguage)
        }
        static func itemMeta(_ duration: String, _ category: String) -> String {
            String(localized: "sharePlan.itemMeta", defaultValue: "\(duration) · \(category)", bundle: Bundle.appLanguage)
        }
        static var askEmpty: String {
            String(
                localized: "sharePlan.ask.empty",
                defaultValue: "No me-time booked yet — book a window first and the ask writes itself.",
                bundle: Bundle.appLanguage
            )
        }
        static func ask(start: String, end: String, duration: String) -> String {
            String(localized: "sharePlan.ask", defaultValue: "Please cover \(start)–\(end) so I can take my \(duration).", bundle: Bundle.appLanguage)
        }
        static func sendButton(_ caregiver: String) -> String {
            String(localized: "sharePlan.sendButton", defaultValue: "Send to \(caregiver)", bundle: Bundle.appLanguage)
        }
        static var finePrint: String {
            String(
                localized: "sharePlan.finePrint",
                defaultValue: "Sends a plain-language summary — no app needed on their side.",
                bundle: Bundle.appLanguage
            )
        }
        static func sentToast(day: String, caregiver: String) -> String {
            String(localized: "sharePlan.sentToast", defaultValue: "\(day) plan sent to \(caregiver)", bundle: Bundle.appLanguage)
        }
        static var daySentToday: String { String(localized: "sharePlan.daySent.today", defaultValue: "Today's", bundle: Bundle.appLanguage) }
        static var daySentTomorrow: String { String(localized: "sharePlan.daySent.tomorrow", defaultValue: "Tomorrow's", bundle: Bundle.appLanguage) }

        // The plain-text summary handed to the OS share sheet.
        static func exportHeading(_ day: String) -> String {
            String(localized: "sharePlan.export.heading", defaultValue: "🌸 Plan for \(day)", bundle: Bundle.appLanguage)
        }
        static var exportSchedule: String { String(localized: "sharePlan.export.schedule", defaultValue: "Schedule:", bundle: Bundle.appLanguage) }
        static var exportAppointments: String { String(localized: "sharePlan.export.appointments", defaultValue: "Appointments:", bundle: Bundle.appLanguage) }
        static var exportNothing: String { String(localized: "sharePlan.export.nothing", defaultValue: "Nothing scheduled yet.", bundle: Bundle.appLanguage) }
        static var exportFooter: String { String(localized: "sharePlan.export.footer", defaultValue: "Sent with love from MommysTime 💛", bundle: Bundle.appLanguage) }
        static func exportBlock(start: String, end: String, title: String) -> String {
            String(localized: "sharePlan.export.block", defaultValue: "• \(start)–\(end)  \(title)", bundle: Bundle.appLanguage)
        }
        static func exportAppointment(time: String, title: String) -> String {
            String(localized: "sharePlan.export.appointment", defaultValue: "• \(time)  \(title)", bundle: Bundle.appLanguage)
        }
        static func exportAppointmentLocation(_ location: String) -> String {
            String(localized: "sharePlan.export.appointmentLocation", defaultValue: " @ \(location)", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Appointments

    enum Appointments {
        static var title: String { String(localized: "appointments.title", defaultValue: "Appointment", bundle: Bundle.appLanguage) }
        static var emptyTitle: String { String(localized: "appointments.empty.title", defaultValue: "Nothing booked this day", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "appointments.empty.body",
                defaultValue: "Clinic visits, jabs, check-ups — add them here and they'll ride along in the plan you share.",
                bundle: Bundle.appLanguage
            )
        }
        static var fallbackName: String { String(localized: "appointments.fallbackName", defaultValue: "Appointment", bundle: Bundle.appLanguage) }
        static func removed(_ name: String) -> String {
            String(localized: "appointments.removed", defaultValue: "\(name) removed", bundle: Bundle.appLanguage)
        }
        static func cardSubtitle(time: String, location: String) -> String {
            String(localized: "appointments.card.subtitle", defaultValue: "\(time) · \(location)", bundle: Bundle.appLanguage)
        }

        static var sheetNewTitle: String { String(localized: "appointments.sheet.new", defaultValue: "New Appointment", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "appointments.sheet.edit", defaultValue: "Edit Appointment", bundle: Bundle.appLanguage) }
        static var sectionAppointment: String { String(localized: "appointments.section.appointment", defaultValue: "APPOINTMENT", bundle: Bundle.appLanguage) }
        static var sectionNotes: String { String(localized: "appointments.section.notes", defaultValue: "NOTES", bundle: Bundle.appLanguage) }
        static var titlePlaceholder: String { String(localized: "appointments.titlePlaceholder", defaultValue: "Title (e.g. Baby checkup)", bundle: Bundle.appLanguage) }
        static var dateAndTime: String { String(localized: "appointments.dateAndTime", defaultValue: "Date & time", bundle: Bundle.appLanguage) }
        static var locationPlaceholder: String { String(localized: "appointments.locationPlaceholder", defaultValue: "Location (optional)", bundle: Bundle.appLanguage) }
        static var notesPlaceholder: String { String(localized: "appointments.notesPlaceholder", defaultValue: "Anything to remember…", bundle: Bundle.appLanguage) }
        static var deleteButton: String { String(localized: "appointments.delete", defaultValue: "Delete appointment", bundle: Bundle.appLanguage) }
        static var deleteConfirm: String { String(localized: "appointments.delete.confirm", defaultValue: "Delete this appointment?", bundle: Bundle.appLanguage) }
        static var pickerDate: String { String(localized: "appointments.picker.date", defaultValue: "Date", bundle: Bundle.appLanguage) }
        static var pickerTime: String { String(localized: "appointments.picker.time", defaultValue: "Time", bundle: Bundle.appLanguage) }
    }

    // MARK: - Inventory

    enum Inventory {
        static var title: String { String(localized: "inventory.title", defaultValue: "Inventory", bundle: Bundle.appLanguage) }
        static var filterAll: String { String(localized: "inventory.filter.all", defaultValue: "All", bundle: Bundle.appLanguage) }
        static var filterLow: String { String(localized: "inventory.filter.low", defaultValue: "Needs refill", bundle: Bundle.appLanguage) }
        static func itemCount(_ n: Int) -> String {
            n == 1
                ? String(localized: "inventory.count.one", defaultValue: "\(n) ITEM", bundle: Bundle.appLanguage)
                : String(localized: "inventory.count.other", defaultValue: "\(n) ITEMS", bundle: Bundle.appLanguage)
        }
        static var allStocked: String { String(localized: "inventory.allStocked", defaultValue: "ALL STOCKED", bundle: Bundle.appLanguage) }
        static func needsRefillCount(_ n: Int) -> String {
            String(localized: "inventory.needsRefillCount", defaultValue: "\(n) NEEDS REFILL", bundle: Bundle.appLanguage)
        }
        static var left: String { String(localized: "inventory.left", defaultValue: "LEFT", bundle: Bundle.appLanguage) }
        static var needsRefill: String { String(localized: "inventory.needsRefill", defaultValue: "NEEDS REFILL", bundle: Bundle.appLanguage) }

        static var emptyLowTitle: String { String(localized: "inventory.empty.low.title", defaultValue: "Nothing needs refilling", bundle: Bundle.appLanguage) }
        static var emptyLowBody: String { String(localized: "inventory.empty.low.body", defaultValue: "Every item is above its warning level.", bundle: Bundle.appLanguage) }
        static var emptyTitle: String { String(localized: "inventory.empty.title", defaultValue: "Nothing tracked yet", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "inventory.empty.body",
                defaultValue: "Add whatever you keep running out of — and paste the link you reorder it from.",
                bundle: Bundle.appLanguage
            )
        }

        static var sheetNewTitle: String { String(localized: "inventory.sheet.new", defaultValue: "New item", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "inventory.sheet.edit", defaultValue: "Edit item", bundle: Bundle.appLanguage) }
        static var sectionItem: String { String(localized: "inventory.section.item", defaultValue: "ITEM", bundle: Bundle.appLanguage) }
        static var sectionPhoto: String { String(localized: "inventory.section.photo", defaultValue: "PHOTO", bundle: Bundle.appLanguage) }
        static var heroFallback: String { String(localized: "inventory.hero.fallback", defaultValue: "New item", bundle: Bundle.appLanguage) }
        static func onHand(_ n: Int) -> String {
            String(localized: "inventory.onHand", defaultValue: "×\(n) on hand", bundle: Bundle.appLanguage)
        }
        static func quantity(_ n: Int) -> String {
            String(localized: "inventory.quantity", defaultValue: "×\(n)", bundle: Bundle.appLanguage)
        }
        static var namePlaceholder: String { String(localized: "inventory.namePlaceholder", defaultValue: "Item name", bundle: Bundle.appLanguage) }
        static var inStock: String { String(localized: "inventory.inStock", defaultValue: "In stock", bundle: Bundle.appLanguage) }
        static var remindReorder: String { String(localized: "inventory.remindReorder", defaultValue: "Remind me to reorder", bundle: Bundle.appLanguage) }
        static var linkPlaceholder: String { String(localized: "inventory.linkPlaceholder", defaultValue: "Reorder link (paste a URL)", bundle: Bundle.appLanguage) }
        static var addPhoto: String { String(localized: "inventory.addPhoto", defaultValue: "Add a photo of this item", bundle: Bundle.appLanguage) }
        static var photoHint: String {
            String(
                localized: "inventory.photoHint",
                defaultValue: "A photo helps you spot the exact brand next time you reorder.",
                bundle: Bundle.appLanguage
            )
        }
        static var removeButton: String { String(localized: "inventory.remove", defaultValue: "Remove from inventory", bundle: Bundle.appLanguage) }
        static var fallbackName: String { String(localized: "inventory.fallbackName", defaultValue: "Item", bundle: Bundle.appLanguage) }
        static var toastNeedsName: String { String(localized: "inventory.toast.needsName", defaultValue: "Name the item first", bundle: Bundle.appLanguage) }
        static func toastAdded(_ name: String) -> String {
            String(localized: "inventory.toast.added", defaultValue: "\(name) added", bundle: Bundle.appLanguage)
        }
        static func toastUpdated(_ name: String) -> String {
            String(localized: "inventory.toast.updated", defaultValue: "\(name) updated", bundle: Bundle.appLanguage)
        }
        static func toastRemoved(_ name: String) -> String {
            String(localized: "inventory.toast.removed", defaultValue: "\(name) removed", bundle: Bundle.appLanguage)
        }
        /// Default category stamped on a new item — persisted, so not translated.
        static let defaultCategoryKey = "Other"
    }

    // MARK: - Pump tracker

    enum Pump {
        static var title: String { String(localized: "pump.title", defaultValue: "Pump Tracker", bundle: Bundle.appLanguage) }
        static var sideLeft: String { String(localized: "pump.side.left", defaultValue: "Left", bundle: Bundle.appLanguage) }
        static var sideRight: String { String(localized: "pump.side.right", defaultValue: "Right", bundle: Bundle.appLanguage) }
        static var sideBoth: String { String(localized: "pump.side.both", defaultValue: "Both", bundle: Bundle.appLanguage) }

        static var statusFirst: String { String(localized: "pump.status.first", defaultValue: "Log your first session", bundle: Bundle.appLanguage) }
        static var statusDue: String { String(localized: "pump.status.due", defaultValue: "Session due now", bundle: Bundle.appLanguage) }
        static func statusNext(_ countdown: String) -> String {
            String(localized: "pump.status.next", defaultValue: "Next in \(countdown)", bundle: Bundle.appLanguage)
        }
        static func countdownMinutes(_ m: Int) -> String {
            String(localized: "pump.countdown.minutes", defaultValue: "\(m)m", bundle: Bundle.appLanguage)
        }
        static var every: String { String(localized: "pump.every", defaultValue: "Pump every", bundle: Bundle.appLanguage) }
        static func intervalOption(_ h: Int) -> String {
            h == 1
                ? String(localized: "pump.interval.one", defaultValue: "\(h) hour", bundle: Bundle.appLanguage)
                : String(localized: "pump.interval.other", defaultValue: "\(h) hours", bundle: Bundle.appLanguage)
        }
        static func intervalPill(_ h: Int) -> String {
            String(localized: "pump.interval.pill", defaultValue: "\(h)h", bundle: Bundle.appLanguage)
        }
        static var logCTA: String { String(localized: "pump.logCTA", defaultValue: "Log a session", bundle: Bundle.appLanguage) }
        static var rhythmTitle: String { String(localized: "pump.rhythm.title", defaultValue: "Your pumping rhythm", bundle: Bundle.appLanguage) }
        static var rhythmSub: String { String(localized: "pump.rhythm.sub", defaultValue: "A week at a glance — steady beats perfect.", bundle: Bundle.appLanguage) }
        static var chartTitle: String { String(localized: "pump.chart.title", defaultValue: "ML PUMPED · LAST 7 DAYS", bundle: Bundle.appLanguage) }
        static var sessionsToday: String { String(localized: "pump.stat.sessionsToday", defaultValue: "sessions today", bundle: Bundle.appLanguage) }
        static var mlToday: String { String(localized: "pump.stat.mlToday", defaultValue: "ml today", bundle: Bundle.appLanguage) }

        static var historyTitle: String { String(localized: "pump.history.title", defaultValue: "Session History", bundle: Bundle.appLanguage) }
        static func historyRowTitle(_ side: String) -> String {
            String(localized: "pump.history.rowTitle", defaultValue: "\(side) side", bundle: Bundle.appLanguage)
        }
        static func historyRowDetail(ml: Int, duration: String) -> String {
            String(localized: "pump.history.rowDetail", defaultValue: "\(ml) ml · \(duration)", bundle: Bundle.appLanguage)
        }
        static func summaryCount(_ n: Int) -> String {
            n == 1
                ? String(localized: "pump.summary.count.one", defaultValue: "\(n) SESSION", bundle: Bundle.appLanguage)
                : String(localized: "pump.summary.count.other", defaultValue: "\(n) SESSIONS", bundle: Bundle.appLanguage)
        }
        static func summaryWithML(_ count: String, _ ml: Int) -> String {
            String(localized: "pump.summary.withML", defaultValue: "\(count) · \(ml) ML", bundle: Bundle.appLanguage)
        }

        static var sheetNewTitle: String { String(localized: "pump.sheet.new", defaultValue: "Log Session", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "pump.sheet.edit", defaultValue: "Edit Session", bundle: Bundle.appLanguage) }
        static var sectionSide: String { String(localized: "pump.section.side", defaultValue: "SIDE", bundle: Bundle.appLanguage) }
        static var sectionDetails: String { String(localized: "pump.section.details", defaultValue: "DETAILS", bundle: Bundle.appLanguage) }
        static var volumeLabel: String { String(localized: "pump.volume.label", defaultValue: "Volume expressed", bundle: Bundle.appLanguage) }
        static var unitML: String { String(localized: "pump.unit.ml", defaultValue: "ml", bundle: Bundle.appLanguage) }
        static var stepAmount: String { String(localized: "pump.step.amount", defaultValue: "10 ml", bundle: Bundle.appLanguage) }
        static var stepCaption: String { String(localized: "pump.step.caption", defaultValue: "steps", bundle: Bundle.appLanguage) }
        static var started: String { String(localized: "pump.started", defaultValue: "Started", bundle: Bundle.appLanguage) }
        static var duration: String { String(localized: "pump.duration", defaultValue: "Duration", bundle: Bundle.appLanguage) }
        static var alsoLogFeed: String { String(localized: "pump.alsoLogFeed", defaultValue: "Add to feed log too", bundle: Bundle.appLanguage) }
        static var noteDry: String {
            String(
                localized: "pump.note.dry",
                defaultValue: "Logging a dry session is fine — it still counts toward your rhythm.",
                bundle: Bundle.appLanguage
            )
        }
        static func note(amount: Int, duration: String, nextDue: String) -> String {
            String(
                localized: "pump.note",
                defaultValue: "That's \(amount) ml in \(duration). Next session due around \(nextDue).",
                bundle: Bundle.appLanguage
            )
        }
        static var toastLogged: String { String(localized: "pump.toast.logged", defaultValue: "Pump session logged", bundle: Bundle.appLanguage) }
        static var toastLoggedWithFeed: String { String(localized: "pump.toast.loggedWithFeed", defaultValue: "Session logged and added to feeds", bundle: Bundle.appLanguage) }
        /// Note stamped on the feed row a pump session creates — persisted.
        static let pumpedNoteKey = "pumped"
    }

    // MARK: - Feed log

    enum Feed {
        static var title: String { String(localized: "feed.title", defaultValue: "Feed Log", bundle: Bundle.appLanguage) }
        static var typeBreast: String { String(localized: "feed.type.breast", defaultValue: "Breast", bundle: Bundle.appLanguage) }
        static var typeBottle: String { String(localized: "feed.type.bottle", defaultValue: "Bottle", bundle: Bundle.appLanguage) }
        static var typeSolid: String { String(localized: "feed.type.solid", defaultValue: "Solid", bundle: Bundle.appLanguage) }

        static var noneLogged: String { String(localized: "feed.noneLogged", defaultValue: "No feeds logged yet", bundle: Bundle.appLanguage) }
        static func lastFeed(_ relative: String) -> String {
            String(localized: "feed.lastFeed", defaultValue: "Last feed \(relative)", bundle: Bundle.appLanguage)
        }
        static var every: String { String(localized: "feed.every", defaultValue: "Feed every", bundle: Bundle.appLanguage) }
        static func intervalOption(_ h: Int) -> String {
            h == 1
                ? String(localized: "feed.interval.one", defaultValue: "\(h) hour", bundle: Bundle.appLanguage)
                : String(localized: "feed.interval.other", defaultValue: "\(h) hours", bundle: Bundle.appLanguage)
        }
        static func intervalPill(_ h: Int) -> String {
            String(localized: "feed.interval.pill", defaultValue: "\(h)h", bundle: Bundle.appLanguage)
        }
        static var logCTA: String { String(localized: "feed.logCTA", defaultValue: "Log a feed", bundle: Bundle.appLanguage) }
        static var howTitle: String { String(localized: "feed.how.title", defaultValue: "How feeding is going", bundle: Bundle.appLanguage) }
        static var howSub: String { String(localized: "feed.how.sub", defaultValue: "A week at a glance — fed is fed.", bundle: Bundle.appLanguage) }
        static var chartTitle: String { String(localized: "feed.chart.title", defaultValue: "ML FED · LAST 7 DAYS", bundle: Bundle.appLanguage) }
        static var feedsToday: String { String(localized: "feed.stat.feedsToday", defaultValue: "feeds today", bundle: Bundle.appLanguage) }
        static var mlToday: String { String(localized: "feed.stat.mlToday", defaultValue: "ml today", bundle: Bundle.appLanguage) }

        static var historyTitle: String { String(localized: "feed.history.title", defaultValue: "Feed History", bundle: Bundle.appLanguage) }
        static var historyFallbackTitle: String { String(localized: "feed.history.fallbackTitle", defaultValue: "Feed", bundle: Bundle.appLanguage) }
        static func detailML(_ ml: Int) -> String {
            String(localized: "feed.detail.ml", defaultValue: "\(ml) ml", bundle: Bundle.appLanguage)
        }
        static func detailMinutes(_ m: Int) -> String {
            String(localized: "feed.detail.minutes", defaultValue: "\(m) min", bundle: Bundle.appLanguage)
        }
        static func detailMinutesSide(_ minutes: String, _ side: String) -> String {
            String(localized: "feed.detail.minutesSide", defaultValue: "\(minutes) · \(side)", bundle: Bundle.appLanguage)
        }
        static func summaryCount(_ n: Int) -> String {
            n == 1
                ? String(localized: "feed.summary.count.one", defaultValue: "\(n) FEED", bundle: Bundle.appLanguage)
                : String(localized: "feed.summary.count.other", defaultValue: "\(n) FEEDS", bundle: Bundle.appLanguage)
        }
        static func summaryWithML(_ count: String, _ ml: Int) -> String {
            String(localized: "feed.summary.withML", defaultValue: "\(count) · \(ml) ML", bundle: Bundle.appLanguage)
        }

        static var sheetNewTitle: String { String(localized: "feed.sheet.new", defaultValue: "Log Feed", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "feed.sheet.edit", defaultValue: "Edit Feed", bundle: Bundle.appLanguage) }
        static var sectionType: String { String(localized: "feed.section.type", defaultValue: "FEED TYPE", bundle: Bundle.appLanguage) }
        static var sectionSide: String { String(localized: "feed.section.side", defaultValue: "SIDE", bundle: Bundle.appLanguage) }
        static var sectionDetails: String { String(localized: "feed.section.details", defaultValue: "DETAILS", bundle: Bundle.appLanguage) }
        static var eyebrowBreast: String { String(localized: "feed.eyebrow.breast", defaultValue: "Time at the breast", bundle: Bundle.appLanguage) }
        static var eyebrowSolid: String { String(localized: "feed.eyebrow.solid", defaultValue: "Portion offered", bundle: Bundle.appLanguage) }
        static var eyebrowBottle: String { String(localized: "feed.eyebrow.bottle", defaultValue: "Bottle volume", bundle: Bundle.appLanguage) }
        static var unitMinutes: String { String(localized: "feed.unit.minutes", defaultValue: "min", bundle: Bundle.appLanguage) }
        static var unitGrams: String { String(localized: "feed.unit.grams", defaultValue: "g", bundle: Bundle.appLanguage) }
        static var unitML: String { String(localized: "feed.unit.ml", defaultValue: "ml", bundle: Bundle.appLanguage) }
        static var stepBreast: String { String(localized: "feed.step.breast", defaultValue: "5 min steps", bundle: Bundle.appLanguage) }
        static var stepSolid: String { String(localized: "feed.step.solid", defaultValue: "10 g steps", bundle: Bundle.appLanguage) }
        static var stepBottle: String { String(localized: "feed.step.bottle", defaultValue: "10 ml steps", bundle: Bundle.appLanguage) }
        static var time: String { String(localized: "feed.time", defaultValue: "Time", bundle: Bundle.appLanguage) }
        static var finished: String { String(localized: "feed.finished", defaultValue: "Baby finished the feed", bundle: Bundle.appLanguage) }
        static var noteBreast: String {
            String(
                localized: "feed.note.breast",
                defaultValue: "Breast feeds are tracked by time and side, not volume.",
                bundle: Bundle.appLanguage
            )
        }
        static var noteSolid: String {
            String(
                localized: "feed.note.solid",
                defaultValue: "Solids are logged by portion — handy once weaning starts.",
                bundle: Bundle.appLanguage
            )
        }
        static var noteBottle: String {
            String(
                localized: "feed.note.bottle",
                defaultValue: "Bottle volume counts toward today's ml total.",
                bundle: Bundle.appLanguage
            )
        }
        static func toastLogged(_ type: String) -> String {
            String(localized: "feed.toast.logged", defaultValue: "\(type) feed logged", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Growth log

    enum Growth {
        static var title: String { String(localized: "growth.title", defaultValue: "Growth Log", bundle: Bundle.appLanguage) }
        static var metricWeight: String { String(localized: "growth.metric.weight", defaultValue: "Weight", bundle: Bundle.appLanguage) }
        static var metricHeight: String { String(localized: "growth.metric.height", defaultValue: "Height", bundle: Bundle.appLanguage) }
        static var metricHead: String { String(localized: "growth.metric.head", defaultValue: "Head", bundle: Bundle.appLanguage) }
        static var unitKg: String { String(localized: "growth.unit.kg", defaultValue: "kg", bundle: Bundle.appLanguage) }
        static var unitCm: String { String(localized: "growth.unit.cm", defaultValue: "cm", bundle: Bundle.appLanguage) }

        static func heroValue(weight: String, height: String) -> String {
            String(localized: "growth.hero.value", defaultValue: "\(weight) kg · \(height) cm", bundle: Bundle.appLanguage)
        }
        static var measured: String { String(localized: "growth.measured", defaultValue: "Measured", bundle: Bundle.appLanguage) }
        static var addCTA: String { String(localized: "growth.addCTA", defaultValue: "Add a measurement", bundle: Bundle.appLanguage) }
        static var howTitle: String { String(localized: "growth.how.title", defaultValue: "How baby is growing", bundle: Bundle.appLanguage) }
        static var howSub: String { String(localized: "growth.how.sub", defaultValue: "A visit at a time — every clinic check, plotted.", bundle: Bundle.appLanguage) }
        static var chartWeight: String { String(localized: "growth.chart.weight", defaultValue: "WEIGHT · LAST 30 DAYS", bundle: Bundle.appLanguage) }
        static var chartHeight: String { String(localized: "growth.chart.height", defaultValue: "HEIGHT · LAST 30 DAYS", bundle: Bundle.appLanguage) }
        static var statWeight: String { String(localized: "growth.stat.weight", defaultValue: "weight (kg)", bundle: Bundle.appLanguage) }
        static var statHeight: String { String(localized: "growth.stat.height", defaultValue: "height (cm)", bundle: Bundle.appLanguage) }
        static var statHead: String { String(localized: "growth.stat.head", defaultValue: "head (cm)", bundle: Bundle.appLanguage) }

        static var emptyTitle: String { String(localized: "growth.empty.title", defaultValue: "No measurements yet", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "growth.empty.body",
                defaultValue: "Record your baby's weight, height and head size to watch them grow.",
                bundle: Bundle.appLanguage
            )
        }

        static var sheetNewTitle: String { String(localized: "growth.sheet.new", defaultValue: "Add Measurement", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "growth.sheet.edit", defaultValue: "Edit Measurement", bundle: Bundle.appLanguage) }
        static var sectionVisit: String { String(localized: "growth.section.visit", defaultValue: "THIS VISIT", bundle: Bundle.appLanguage) }
        static var eyebrowHead: String { String(localized: "growth.eyebrow.head", defaultValue: "Head circumference", bundle: Bundle.appLanguage) }
        static var stepHeight: String { String(localized: "growth.step.height", defaultValue: "0.5 cm steps", bundle: Bundle.appLanguage) }
        static var stepHead: String { String(localized: "growth.step.head", defaultValue: "0.1 cm steps", bundle: Bundle.appLanguage) }
        static var stepWeight: String { String(localized: "growth.step.weight", defaultValue: "0.1 kg steps", bundle: Bundle.appLanguage) }
        static var measuredOn: String { String(localized: "growth.measuredOn", defaultValue: "Measured on", bundle: Bundle.appLanguage) }
        static func valueKg(_ v: String) -> String {
            String(localized: "growth.value.kg", defaultValue: "\(v) kg", bundle: Bundle.appLanguage)
        }
        static func valueCm(_ v: String) -> String {
            String(localized: "growth.value.cm", defaultValue: "\(v) cm", bundle: Bundle.appLanguage)
        }
        static func noteGained(_ delta: String, since: String) -> String {
            String(localized: "growth.note.gained", defaultValue: "Up \(delta) kg since \(since). Growing beautifully.", bundle: Bundle.appLanguage)
        }
        static var noteFillIn: String {
            String(
                localized: "growth.note.fillIn",
                defaultValue: "Fill in all three while you're at the clinic — the chart needs every visit.",
                bundle: Bundle.appLanguage
            )
        }
        static var toastNeedsWeight: String { String(localized: "growth.toast.needsWeight", defaultValue: "Add a weight first", bundle: Bundle.appLanguage) }
        static var toastSaved: String { String(localized: "growth.toast.saved", defaultValue: "Measurement saved", bundle: Bundle.appLanguage) }

        static var historyTitle: String { String(localized: "growth.history.title", defaultValue: "Growth History", bundle: Bundle.appLanguage) }
        static var historyHeading: String { String(localized: "growth.history.heading", defaultValue: "Every measurement", bundle: Bundle.appLanguage) }
        static var historyEmpty: String { String(localized: "growth.history.empty", defaultValue: "No measurements logged yet", bundle: Bundle.appLanguage) }
        static var birth: String { String(localized: "growth.age.birth", defaultValue: "Birth", bundle: Bundle.appLanguage) }
        static var newborn: String { String(localized: "growth.age.new", defaultValue: "New", bundle: Bundle.appLanguage) }
        static func months(_ n: Int) -> String {
            String(localized: "growth.age.months", defaultValue: "\(n) mo", bundle: Bundle.appLanguage)
        }
        static func headDetail(_ v: String) -> String {
            String(localized: "growth.history.head", defaultValue: "head \(v) cm", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Wake window & sleep

    enum Wake {
        static var title: String { String(localized: "wake.title", defaultValue: "Wake Window", bundle: Bundle.appLanguage) }
        static var todaySoFar: String { String(localized: "wake.todaySoFar", defaultValue: "TODAY SO FAR", bundle: Bundle.appLanguage) }
        static var sleeping: String { String(localized: "wake.sleeping", defaultValue: "Baby is sleeping", bundle: Bundle.appLanguage) }
        static var awake: String { String(localized: "wake.awake", defaultValue: "Baby is awake", bundle: Bundle.appLanguage) }
        static var wokeUp: String { String(localized: "wake.wokeUp", defaultValue: "Baby woke up", bundle: Bundle.appLanguage) }
        static var fellAsleep: String { String(localized: "wake.fellAsleep", defaultValue: "Baby fell asleep", bundle: Bundle.appLanguage) }
        static func asleepSince(_ time: String) -> String {
            String(localized: "wake.asleepSince", defaultValue: "Asleep since \(time)", bundle: Bundle.appLanguage)
        }
        static func pastWindow(_ span: String) -> String {
            String(localized: "wake.pastWindow", defaultValue: "Past the usual \(span) window — nap soon", bundle: Bundle.appLanguage)
        }
        static func windowLeft(_ span: String) -> String {
            String(localized: "wake.windowLeft", defaultValue: "\(span) left of the usual window", bundle: Bundle.appLanguage)
        }
        static var toastAwake: String { String(localized: "wake.toast.awake", defaultValue: "Awake — window starts now", bundle: Bundle.appLanguage) }
        static var toastAsleep: String { String(localized: "wake.toast.asleep", defaultValue: "Sleeping — rest while you can", bundle: Bundle.appLanguage) }
        static var nothingToday: String { String(localized: "wake.nothingToday", defaultValue: "Nothing switched yet today", bundle: Bundle.appLanguage) }
        static var slept: String { String(localized: "wake.row.slept", defaultValue: "Slept", bundle: Bundle.appLanguage) }
        static var awakeRow: String { String(localized: "wake.row.awake", defaultValue: "Awake", bundle: Bundle.appLanguage) }
        static func row(kind: String, start: String, end: String) -> String {
            String(localized: "wake.row", defaultValue: "\(kind) · \(start) – \(end)", bundle: Bundle.appLanguage)
        }
    }

    enum Sleep {
        static var summaryTitle: String { String(localized: "sleep.summary.title", defaultValue: "Sleep Summary", bundle: Bundle.appLanguage) }
        static var sleptToday: String { String(localized: "sleep.stat.sleptToday", defaultValue: "slept today", bundle: Bundle.appLanguage) }
        static var napsToday: String { String(localized: "sleep.stat.napsToday", defaultValue: "naps today", bundle: Bundle.appLanguage) }
        static var averageWindow: String { String(localized: "sleep.stat.averageWindow", defaultValue: "avg wake window", bundle: Bundle.appLanguage) }
        static var longestNap: String { String(localized: "sleep.stat.longestNap", defaultValue: "longest nap", bundle: Bundle.appLanguage) }
        static var shapeTitle: String { String(localized: "sleep.shape.title", defaultValue: "The shape of the day", bundle: Bundle.appLanguage) }
        static var shapeSub: String { String(localized: "sleep.shape.sub", defaultValue: "Plum is sleep, cream is awake — 6am to midnight.", bundle: Bundle.appLanguage) }
        static var weekTitle: String { String(localized: "sleep.week.title", defaultValue: "Sleep this week", bundle: Bundle.appLanguage) }
        static var weekSub: String { String(localized: "sleep.week.sub", defaultValue: "Hours of sleep logged each day.", bundle: Bundle.appLanguage) }
        static var stripTicks: [String] {
            [
                String(localized: "sleep.strip.6am", defaultValue: "6am", bundle: Bundle.appLanguage),
                String(localized: "sleep.strip.11am", defaultValue: "11am", bundle: Bundle.appLanguage),
                String(localized: "sleep.strip.4pm", defaultValue: "4pm", bundle: Bundle.appLanguage),
                String(localized: "sleep.strip.8pm", defaultValue: "8pm", bundle: Bundle.appLanguage),
                String(localized: "sleep.strip.12am", defaultValue: "12am", bundle: Bundle.appLanguage),
            ]
        }
        static var insightEmpty: String {
            String(
                localized: "sleep.insight.empty",
                defaultValue: "Log a sleep and a wake and this page starts learning your baby's rhythm.",
                bundle: Bundle.appLanguage
            )
        }
        static func insight(average: String, window: String) -> String {
            String(
                localized: "sleep.insight",
                defaultValue: "Naps are averaging \(average) with about \(window) awake in between. Watching that window beats watching the clock.",
                bundle: Bundle.appLanguage
            )
        }
        static func spanMinutes(_ m: Int) -> String {
            String(localized: "sleep.span.minutes", defaultValue: "\(m)m", bundle: Bundle.appLanguage)
        }
        /// Zero-padded so a column of durations lines up — "1h 05m".
        static func spanHoursMinutes(_ h: Int, _ m: Int) -> String {
            String(localized: "sleep.span.hoursMinutes", defaultValue: "\(h)h \(String(format: "%02d", m))m", bundle: Bundle.appLanguage)
        }
        static func hoursDecimal(_ value: String) -> String {
            String(localized: "sleep.hoursDecimal", defaultValue: "\(value)h", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Recipes

    enum Recipes {
        static var title: String { String(localized: "recipes.title", defaultValue: "Recipes", bundle: Bundle.appLanguage) }
        static var categoryMommy: String { String(localized: "recipes.category.mommy", defaultValue: "Mommy", bundle: Bundle.appLanguage) }
        static var categoryBaby: String { String(localized: "recipes.category.baby", defaultValue: "Baby", bundle: Bundle.appLanguage) }

        static var heroBaby: String { String(localized: "recipes.hero.baby", defaultValue: "First foods, sorted", bundle: Bundle.appLanguage) }
        static var heroMommy: String { String(localized: "recipes.hero.mommy", defaultValue: "Real meals, fast", bundle: Bundle.appLanguage) }
        static var cookingFor: String { String(localized: "recipes.cookingFor", defaultValue: "Cooking for", bundle: Bundle.appLanguage) }
        static var cookingForBaby: String { String(localized: "recipes.cookingFor.baby", defaultValue: "baby", bundle: Bundle.appLanguage) }
        static var cookingForYou: String { String(localized: "recipes.cookingFor.you", defaultValue: "you", bundle: Bundle.appLanguage) }
        static var addCTA: String { String(localized: "recipes.addCTA", defaultValue: "Add your own recipe", bundle: Bundle.appLanguage) }
        static var captionBaby: String { String(localized: "recipes.caption.baby", defaultValue: "For baby", bundle: Bundle.appLanguage) }
        static var captionMommy: String { String(localized: "recipes.caption.mommy", defaultValue: "For you", bundle: Bundle.appLanguage) }
        static var captionBabySub: String { String(localized: "recipes.caption.baby.sub", defaultValue: "Gentle first tastes that freeze well in cubes.", bundle: Bundle.appLanguage) }
        static var captionMommySub: String {
            String(
                localized: "recipes.caption.mommy.sub",
                defaultValue: "One pot, few steps, nothing that needs two hands.",
                bundle: Bundle.appLanguage
            )
        }
        static func emptyTitle(_ category: String) -> String {
            String(localized: "recipes.empty.title", defaultValue: "No \(category) recipes yet", bundle: Bundle.appLanguage)
        }
        static var emptyBabyBody: String { String(localized: "recipes.empty.baby", defaultValue: "Save purées, first foods and toddler meals here.", bundle: Bundle.appLanguage) }
        static var emptyMommyBody: String { String(localized: "recipes.empty.mommy", defaultValue: "Save quick, nourishing meals for yourself here.", bundle: Bundle.appLanguage) }
        static func savedToast(_ name: String) -> String {
            String(localized: "recipes.toast.saved", defaultValue: "\(name) saved", bundle: Bundle.appLanguage)
        }
        static func prepMinutes(_ m: Int) -> String {
            String(localized: "recipes.prepMinutes", defaultValue: "\(m) min", bundle: Bundle.appLanguage)
        }

        // Detail
        static var fallbackTitle: String { String(localized: "recipes.detail.fallbackTitle", defaultValue: "Recipe", bundle: Bundle.appLanguage) }
        static var ingredients: String { String(localized: "recipes.detail.ingredients", defaultValue: "INGREDIENTS", bundle: Bundle.appLanguage) }
        static var method: String { String(localized: "recipes.detail.method", defaultValue: "METHOD", bundle: Bundle.appLanguage) }
        static var cookCTA: String { String(localized: "recipes.detail.cookCTA", defaultValue: "Cook this now", bundle: Bundle.appLanguage) }
        static var cookedCTA: String { String(localized: "recipes.detail.cookedCTA", defaultValue: "Done — nicely cooked", bundle: Bundle.appLanguage) }
        static var cookHint: String {
            String(
                localized: "recipes.detail.cookHint",
                defaultValue: "Adds a 30-minute cooking block to today's schedule.",
                bundle: Bundle.appLanguage
            )
        }
        static var cookedHint: String {
            String(
                localized: "recipes.detail.cookedHint",
                defaultValue: "Tap a step again if you want to run it back.",
                bundle: Bundle.appLanguage
            )
        }
        static var toastSaved: String { String(localized: "recipes.detail.toast.saved", defaultValue: "Saved to your recipes", bundle: Bundle.appLanguage) }
        static var toastUnsaved: String { String(localized: "recipes.detail.toast.unsaved", defaultValue: "Removed from saved", bundle: Bundle.appLanguage) }
        static var toastEnjoy: String { String(localized: "recipes.detail.toast.enjoy", defaultValue: "Enjoy it while it's hot", bundle: Bundle.appLanguage) }
        static var toastBlockAdded: String { String(localized: "recipes.detail.toast.blockAdded", defaultValue: "Cooking block added to today", bundle: Bundle.appLanguage) }
        static var cookBlockFallback: String { String(localized: "recipes.detail.cookBlock.fallback", defaultValue: "recipe", bundle: Bundle.appLanguage) }
        static func cookBlockTitle(_ name: String) -> String {
            String(localized: "recipes.detail.cookBlock.title", defaultValue: "Cook: \(name)", bundle: Bundle.appLanguage)
        }
        static func amount(_ number: String, _ unit: String) -> String {
            String(localized: "recipes.amount", defaultValue: "\(number) \(unit)", bundle: Bundle.appLanguage)
        }
        static func amountCount(_ number: String) -> String {
            String(localized: "recipes.amount.count", defaultValue: "×\(number)", bundle: Bundle.appLanguage)
        }

        // Yield units
        static func yield(_ n: Int, unit: String) -> String {
            String(localized: "recipes.yield", defaultValue: "\(n) \(unit)", bundle: Bundle.appLanguage)
        }
        static var unitServing: String { String(localized: "recipes.unit.serving", defaultValue: "serving", bundle: Bundle.appLanguage) }
        static var unitServings: String { String(localized: "recipes.unit.servings", defaultValue: "servings", bundle: Bundle.appLanguage) }
        static var unitPortion: String { String(localized: "recipes.unit.portion", defaultValue: "portion", bundle: Bundle.appLanguage) }
        static var unitPortions: String { String(localized: "recipes.unit.portions", defaultValue: "portions", bundle: Bundle.appLanguage) }
        static var unitFinger: String { String(localized: "recipes.unit.finger", defaultValue: "finger", bundle: Bundle.appLanguage) }
        static var unitFingers: String { String(localized: "recipes.unit.fingers", defaultValue: "fingers", bundle: Bundle.appLanguage) }
        static var unitPot: String { String(localized: "recipes.unit.pot", defaultValue: "pot", bundle: Bundle.appLanguage) }
        static var factMinutes: String { String(localized: "recipes.fact.minutes", defaultValue: "minutes", bundle: Bundle.appLanguage) }
        static var factKcal: String { String(localized: "recipes.fact.kcal", defaultValue: "kcal", bundle: Bundle.appLanguage) }
        static var factItem: String { String(localized: "recipes.fact.item", defaultValue: "item", bundle: Bundle.appLanguage) }
        static var factItems: String { String(localized: "recipes.fact.items", defaultValue: "items", bundle: Bundle.appLanguage) }

        // Ingredient measurement units
        static var unitGrams: String { String(localized: "recipes.measure.g", defaultValue: "g", bundle: Bundle.appLanguage) }
        static var unitMillilitres: String { String(localized: "recipes.measure.ml", defaultValue: "ml", bundle: Bundle.appLanguage) }
        static var unitTablespoon: String { String(localized: "recipes.measure.tbsp", defaultValue: "tbsp", bundle: Bundle.appLanguage) }
        static var unitTeaspoon: String { String(localized: "recipes.measure.tsp", defaultValue: "tsp", bundle: Bundle.appLanguage) }
        /// A plain count — "×2 bananas".
        static let unitCount = "×"

        // New recipe sheet
        static var newTitle: String { String(localized: "recipes.new.title", defaultValue: "New Recipe", bundle: Bundle.appLanguage) }
        static var namePlaceholder: String { String(localized: "recipes.new.namePlaceholder", defaultValue: "Recipe name", bundle: Bundle.appLanguage) }
        static var whySection: String { String(localized: "recipes.new.whySection", defaultValue: "WHY IT HELPS", bundle: Bundle.appLanguage) }
        static var whyPlaceholder: String { String(localized: "recipes.new.whyPlaceholder", defaultValue: "One line, for future you", bundle: Bundle.appLanguage) }
        static var ingredientPlaceholder: String { String(localized: "recipes.new.ingredientPlaceholder", defaultValue: "Ingredient", bundle: Bundle.appLanguage) }
        static var amountPlaceholder: String { String(localized: "recipes.new.amountPlaceholder", defaultValue: "Amount", bundle: Bundle.appLanguage) }
        static var stepPlaceholder: String { String(localized: "recipes.new.stepPlaceholder", defaultValue: "What happens in this step?", bundle: Bundle.appLanguage) }
        static var addIngredient: String { String(localized: "recipes.new.addIngredient", defaultValue: "+ Add ingredient", bundle: Bundle.appLanguage) }
        static var addStep: String { String(localized: "recipes.new.addStep", defaultValue: "+ Add step", bundle: Bundle.appLanguage) }
        static var newNoteIncomplete: String {
            String(
                localized: "recipes.new.note.incomplete",
                defaultValue: "Give it a name, one ingredient and one step — blank lines are dropped when you save.",
                bundle: Bundle.appLanguage
            )
        }
        static func newNote(ingredients: Int, steps: Int, collection: String) -> String {
            let i = ingredients == 1
                ? String(localized: "recipes.new.note.ingredientOne", defaultValue: "\(ingredients) ingredient", bundle: Bundle.appLanguage)
                : String(localized: "recipes.new.note.ingredientOther", defaultValue: "\(ingredients) ingredients", bundle: Bundle.appLanguage)
            let s = steps == 1
                ? String(localized: "recipes.new.note.stepOne", defaultValue: "\(steps) step", bundle: Bundle.appLanguage)
                : String(localized: "recipes.new.note.stepOther", defaultValue: "\(steps) steps", bundle: Bundle.appLanguage)
            return String(
                localized: "recipes.new.note",
                defaultValue: "\(i), \(s). It'll sit at the top of your \(collection) list.",
                bundle: Bundle.appLanguage
            )
        }
        static var toastNeedsName: String { String(localized: "recipes.new.toast.needsName", defaultValue: "Name your recipe first", bundle: Bundle.appLanguage) }
        static var toastNeedsIngredient: String { String(localized: "recipes.new.toast.needsIngredient", defaultValue: "Add at least one ingredient", bundle: Bundle.appLanguage) }
        static var toastNeedsStep: String { String(localized: "recipes.new.toast.needsStep", defaultValue: "Add at least one step", bundle: Bundle.appLanguage) }

        // A user's own recipe, rendered with the same layout as a curated one.
        static func ownTag(_ category: String) -> String {
            String(localized: "recipes.own.tag", defaultValue: "YOUR RECIPE · \(category)", bundle: Bundle.appLanguage)
        }
        static var ownWhy: String {
            String(
                localized: "recipes.own.why",
                defaultValue: "Your own recipe — saved so you never have to remember it again.",
                bundle: Bundle.appLanguage
            )
        }

        /// The four recipes seeded on first launch.
        ///
        /// `titleKey` is written to Core Data and keys the curated content, so it
        /// must stay in English; `title` is what she actually reads.
        enum Seed {
            static let oatBowlKey = "15-min oat bowl"
            static let porridgeKey = "One-pot chicken porridge"
            static let sweetPotatoKey = "Sweet potato mash"
            static let bananaFingersKey = "Banana oat fingers"

            static var oatBowlTitle: String { String(localized: "recipes.seed.oatBowl.title", defaultValue: "15-min oat bowl", bundle: Bundle.appLanguage) }
            static var porridgeTitle: String { String(localized: "recipes.seed.porridge.title", defaultValue: "One-pot chicken porridge", bundle: Bundle.appLanguage) }
            static var sweetPotatoTitle: String { String(localized: "recipes.seed.sweetPotato.title", defaultValue: "Sweet potato mash", bundle: Bundle.appLanguage) }
            static var bananaFingersTitle: String { String(localized: "recipes.seed.bananaFingers.title", defaultValue: "Banana oat fingers", bundle: Bundle.appLanguage) }

            static var oatBowlTag: String { String(localized: "recipes.seed.oatBowl.tag", defaultValue: "BREAKFAST · ONE POT", bundle: Bundle.appLanguage) }
            static var porridgeTag: String { String(localized: "recipes.seed.porridge.tag", defaultValue: "LUNCH · FREEZER FRIENDLY", bundle: Bundle.appLanguage) }
            static var sweetPotatoTag: String { String(localized: "recipes.seed.sweetPotato.tag", defaultValue: "FIRST FOODS · 6M+", bundle: Bundle.appLanguage) }
            static var bananaFingersTag: String { String(localized: "recipes.seed.bananaFingers.tag", defaultValue: "FINGER FOOD · 8M+", bundle: Bundle.appLanguage) }

            // Short badges on the recipe rows. As with the titles, the `…Key`
            // is what seeding stores; the other is what she reads.
            static let onePotKey = "one pot"
            static let freezerKey = "freezer friendly"
            static let sixMonthsKey = "6m+"
            static let eightMonthsKey = "8m+"

            static var onePotBadge: String { String(localized: "recipes.seed.badge.onePot", defaultValue: "one pot", bundle: Bundle.appLanguage) }
            static var freezerBadge: String { String(localized: "recipes.seed.badge.freezer", defaultValue: "freezer friendly", bundle: Bundle.appLanguage) }
            static var sixMonthsBadge: String { String(localized: "recipes.seed.badge.6m", defaultValue: "6m+", bundle: Bundle.appLanguage) }
            static var eightMonthsBadge: String { String(localized: "recipes.seed.badge.8m", defaultValue: "8m+", bundle: Bundle.appLanguage) }

            static var oatBowlWhy: String {
                String(
                    localized: "recipes.seed.oatBowl.why",
                    defaultValue: "Slow-release oats and a hit of protein — the kind of breakfast that holds until the next feed.",
                    bundle: Bundle.appLanguage
                )
            }
            static var porridgeWhy: String {
                String(
                    localized: "recipes.seed.porridge.why",
                    defaultValue: "One pot, barely any washing up, and it freezes beautifully — cook once, eat all week.",
                    bundle: Bundle.appLanguage
                )
            }
            static var sweetPotatoWhy: String {
                String(
                    localized: "recipes.seed.sweetPotato.why",
                    defaultValue: "Smooth, naturally sweet and gentle on new tummies — a lovely first taste.",
                    bundle: Bundle.appLanguage
                )
            }
            static var bananaFingersWhy: String {
                String(
                    localized: "recipes.seed.bananaFingers.why",
                    defaultValue: "Soft, self-feeding fingers with no added sugar — perfect for little hands learning to grip.",
                    bundle: Bundle.appLanguage
                )
            }

            // Ingredients
            static var rolledOats: String { String(localized: "recipes.ingredient.rolledOats", defaultValue: "Rolled oats", bundle: Bundle.appLanguage) }
            static var milkOrWater: String { String(localized: "recipes.ingredient.milkOrWater", defaultValue: "Milk or water", bundle: Bundle.appLanguage) }
            static var greekYoghurt: String { String(localized: "recipes.ingredient.greekYoghurt", defaultValue: "Greek yoghurt", bundle: Bundle.appLanguage) }
            static var bananaSliced: String { String(localized: "recipes.ingredient.bananaSliced", defaultValue: "Banana, sliced", bundle: Bundle.appLanguage) }
            static var peanutButter: String { String(localized: "recipes.ingredient.peanutButter", defaultValue: "Peanut butter", bundle: Bundle.appLanguage) }
            static var cinnamon: String { String(localized: "recipes.ingredient.cinnamon", defaultValue: "Cinnamon", bundle: Bundle.appLanguage) }
            static var chickenThigh: String { String(localized: "recipes.ingredient.chickenThigh", defaultValue: "Chicken thigh", bundle: Bundle.appLanguage) }
            static var rice: String { String(localized: "recipes.ingredient.rice", defaultValue: "Rice", bundle: Bundle.appLanguage) }
            static var water: String { String(localized: "recipes.ingredient.water", defaultValue: "Water", bundle: Bundle.appLanguage) }
            static var gingerSliced: String { String(localized: "recipes.ingredient.gingerSliced", defaultValue: "Ginger, sliced", bundle: Bundle.appLanguage) }
            static var springOnion: String { String(localized: "recipes.ingredient.springOnion", defaultValue: "Spring onion", bundle: Bundle.appLanguage) }
            static var salt: String { String(localized: "recipes.ingredient.salt", defaultValue: "Salt", bundle: Bundle.appLanguage) }
            static var sweetPotato: String { String(localized: "recipes.ingredient.sweetPotato", defaultValue: "Sweet potato", bundle: Bundle.appLanguage) }
            static var breastMilkOrFormula: String {
                String(
                    localized: "recipes.ingredient.breastMilkOrFormula",
                    defaultValue: "Breast milk or formula",
                    bundle: Bundle.appLanguage
                )
            }
            static var bananaRipe: String { String(localized: "recipes.ingredient.bananaRipe", defaultValue: "Banana, ripe", bundle: Bundle.appLanguage) }

            // Method
            static var oatBowlSteps: [String] {
                [
                    String(localized: "recipes.seed.oatBowl.step1", defaultValue: "Add the oats and milk to a small pot over medium heat.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.oatBowl.step2", defaultValue: "Stir for 4–5 minutes until creamy and thickened.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.oatBowl.step3", defaultValue: "Take off the heat and fold through the Greek yoghurt.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.oatBowl.step4", defaultValue: "Top with sliced banana, peanut butter and a dusting of cinnamon.", bundle: Bundle.appLanguage),
                ]
            }
            static var porridgeSteps: [String] {
                [
                    String(localized: "recipes.seed.porridge.step1", defaultValue: "Add the chicken, rice, water and ginger to a large pot.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.porridge.step2", defaultValue: "Bring to a boil, then lower to a gentle simmer.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.porridge.step3", defaultValue: "Cook for 25 minutes, stirring now and then, until thick.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.porridge.step4", defaultValue: "Shred the chicken, season with salt and scatter spring onion.", bundle: Bundle.appLanguage),
                ]
            }
            static var sweetPotatoSteps: [String] {
                [
                    String(localized: "recipes.seed.sweetPotato.step1", defaultValue: "Peel and dice the sweet potato into small cubes.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.sweetPotato.step2", defaultValue: "Steam for 8 minutes until very soft.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.sweetPotato.step3", defaultValue: "Mash with the milk until smooth, adding more to loosen.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.sweetPotato.step4", defaultValue: "Cool to just warm before serving.", bundle: Bundle.appLanguage),
                ]
            }
            static var bananaFingersSteps: [String] {
                [
                    String(localized: "recipes.seed.bananaFingers.step1", defaultValue: "Heat the oven to 180°C and line a small tray.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.bananaFingers.step2", defaultValue: "Mash the bananas, then stir in the oats to a thick dough.", bundle: Bundle.appLanguage),
                    String(localized: "recipes.seed.bananaFingers.step3", defaultValue: "Shape into finger lengths and place on the tray.", bundle: Bundle.appLanguage),
                    String(
                        localized: "recipes.seed.bananaFingers.step4",
                        defaultValue: "Bake for 15 minutes until set and lightly golden. Cool before serving.",
                        bundle: Bundle.appLanguage
                    ),
                ]
            }

            /// Seeded titles are stored in English; show the translated one.
            static func displayTitle(for stored: String?) -> String {
                switch stored {
                case oatBowlKey: return oatBowlTitle
                case porridgeKey: return porridgeTitle
                case sweetPotatoKey: return sweetPotatoTitle
                case bananaFingersKey: return bananaFingersTitle
                default: return stored ?? ""
                }
            }

            /// Same, for the short badge stored on the row.
            static func displayBadge(for stored: String?) -> String {
                switch stored {
                case onePotKey: return onePotBadge
                case freezerKey: return freezerBadge
                case sixMonthsKey: return sixMonthsBadge
                case eightMonthsKey: return eightMonthsBadge
                default: return stored ?? ""
                }
            }
        }
    }

    // MARK: - My Spending

    enum Spending {
        static var title: String { String(localized: "spending.title", defaultValue: "My Spending", bundle: Bundle.appLanguage) }
        /// Malaysian ringgit — the app's only market for now.
        static func currency(_ amount: String) -> String {
            String(localized: "spending.currency", defaultValue: "RM \(amount)", bundle: Bundle.appLanguage)
        }
        static var currencySymbol: String { String(localized: "spending.currencySymbol", defaultValue: "RM ", bundle: Bundle.appLanguage) }

        static var rangeWeek: String { String(localized: "spending.range.week", defaultValue: "This week", bundle: Bundle.appLanguage) }
        static var rangeMonth: String { String(localized: "spending.range.month", defaultValue: "This month", bundle: Bundle.appLanguage) }
        static var rangeAll: String { String(localized: "spending.range.all", defaultValue: "All time", bundle: Bundle.appLanguage) }
        static var eyebrowWeek: String { String(localized: "spending.eyebrow.week", defaultValue: "Spent this week", bundle: Bundle.appLanguage) }
        static var eyebrowMonth: String { String(localized: "spending.eyebrow.month", defaultValue: "Spent this month", bundle: Bundle.appLanguage) }
        static var eyebrowAll: String { String(localized: "spending.eyebrow.all", defaultValue: "Spent all time", bundle: Bundle.appLanguage) }
        static func eyebrowSuffix(_ eyebrow: String) -> String {
            String(localized: "spending.eyebrow.suffix", defaultValue: "\(eyebrow) ·", bundle: Bundle.appLanguage)
        }
        static func purchaseCount(_ n: Int) -> String {
            n == 1
                ? String(localized: "spending.purchases.one", defaultValue: "\(n) purchase", bundle: Bundle.appLanguage)
                : String(localized: "spending.purchases.other", defaultValue: "\(n) purchases", bundle: Bundle.appLanguage)
        }
        static var logCTA: String { String(localized: "spending.logCTA", defaultValue: "Log a purchase", bundle: Bundle.appLanguage) }
        static var whereTitle: String { String(localized: "spending.where.title", defaultValue: "Where it goes", bundle: Bundle.appLanguage) }
        static var compareEmpty: String { String(localized: "spending.compare.empty", defaultValue: "No purchases in this range yet.", bundle: Bundle.appLanguage) }
        static func compare(category: String, amount: String) -> String {
            String(localized: "spending.compare", defaultValue: "Biggest slice: \(category) at \(amount)", bundle: Bundle.appLanguage)
        }
        static var categoryEmptyTitle: String { String(localized: "spending.categoryEmpty.title", defaultValue: "Nothing logged yet", bundle: Bundle.appLanguage) }
        static var categoryEmptyBody: String {
            String(
                localized: "spending.categoryEmpty.body",
                defaultValue: "Add a purchase and you'll see where the money actually goes.",
                bundle: Bundle.appLanguage
            )
        }
        static var recent: String { String(localized: "spending.recent", defaultValue: "RECENT", bundle: Bundle.appLanguage) }
        static var viewAll: String { String(localized: "spending.viewAll", defaultValue: "View all", bundle: Bundle.appLanguage) }
        static var recentEmpty: String { String(localized: "spending.recent.empty", defaultValue: "Nothing logged in this range", bundle: Bundle.appLanguage) }
        static var fallbackName: String { String(localized: "spending.fallbackName", defaultValue: "Purchase", bundle: Bundle.appLanguage) }
        static func removed(_ name: String) -> String {
            String(localized: "spending.removed", defaultValue: "\(name) removed", bundle: Bundle.appLanguage)
        }
        static func rowMeta(category: String, date: String) -> String {
            String(localized: "spending.row.meta", defaultValue: "\(category) · \(date)", bundle: Bundle.appLanguage)
        }

        // Categories — raw values are persisted, labels are shown.
        static var categoryDiapers: String { String(localized: "spending.category.diapers", defaultValue: "Diapers", bundle: Bundle.appLanguage) }
        static var categoryClothes: String { String(localized: "spending.category.clothes", defaultValue: "Clothes", bundle: Bundle.appLanguage) }
        static var categoryFormula: String { String(localized: "spending.category.formula", defaultValue: "Formula", bundle: Bundle.appLanguage) }
        static var categoryFood: String { String(localized: "spending.category.food", defaultValue: "Food", bundle: Bundle.appLanguage) }
        static var categoryMedicine: String { String(localized: "spending.category.medicine", defaultValue: "Medicine", bundle: Bundle.appLanguage) }
        static var categoryOther: String { String(localized: "spending.category.other", defaultValue: "Other", bundle: Bundle.appLanguage) }

        // All purchases
        static var allTitle: String { String(localized: "spending.all.title", defaultValue: "All Purchases", bundle: Bundle.appLanguage) }
        static var everyPurchase: String { String(localized: "spending.all.every", defaultValue: "Every purchase", bundle: Bundle.appLanguage) }
        static var allDates: String { String(localized: "spending.all.allDates", defaultValue: "All dates", bundle: Bundle.appLanguage) }
        static var pickDate: String { String(localized: "spending.all.pickDate", defaultValue: "Pick a date", bundle: Bundle.appLanguage) }
        static var allEmpty: String { String(localized: "spending.all.empty", defaultValue: "Nothing logged yet", bundle: Bundle.appLanguage) }
        static var dayEmpty: String { String(localized: "spending.all.dayEmpty", defaultValue: "Nothing logged on this date", bundle: Bundle.appLanguage) }
        static func allTotal(count: Int, amount: String) -> String {
            let items = count == 1
                ? String(localized: "spending.all.itemOne", defaultValue: "\(count) ITEM", bundle: Bundle.appLanguage)
                : String(localized: "spending.all.itemOther", defaultValue: "\(count) ITEMS", bundle: Bundle.appLanguage)
            return String(localized: "spending.all.total", defaultValue: "\(items) · \(amount)", bundle: Bundle.appLanguage)
        }

        // Add purchase sheet
        static var sheetNewTitle: String { String(localized: "spending.sheet.new", defaultValue: "Add Purchase", bundle: Bundle.appLanguage) }
        static var sheetEditTitle: String { String(localized: "spending.sheet.edit", defaultValue: "Edit Purchase", bundle: Bundle.appLanguage) }
        static var sectionCategory: String { String(localized: "spending.section.category", defaultValue: "CATEGORY", bundle: Bundle.appLanguage) }
        static var sectionDetails: String { String(localized: "spending.section.details", defaultValue: "DETAILS", bundle: Bundle.appLanguage) }
        static var amountLabel: String { String(localized: "spending.amount.label", defaultValue: "Amount", bundle: Bundle.appLanguage) }
        static var amountStep: String { String(localized: "spending.amount.step", defaultValue: "RM 5 steps", bundle: Bundle.appLanguage) }
        static var titlePlaceholder: String { String(localized: "spending.titlePlaceholder", defaultValue: "What did you buy?", bundle: Bundle.appLanguage) }
        static var boughtOn: String { String(localized: "spending.boughtOn", defaultValue: "Bought on", bundle: Bundle.appLanguage) }
        static var alsoAddInventory: String { String(localized: "spending.alsoAddInventory", defaultValue: "Add to inventory too", bundle: Bundle.appLanguage) }
        static func noteFirst(_ category: String) -> String {
            String(localized: "spending.note.first", defaultValue: "First \(category) purchase logged in this range.", bundle: Bundle.appLanguage)
        }
        static func note(prior: String, category: String, total: String) -> String {
            String(
                localized: "spending.note",
                defaultValue: "You've spent \(prior) on \(category) so far. This takes it to \(total).",
                bundle: Bundle.appLanguage
            )
        }
        static var toastNeedsAmount: String { String(localized: "spending.toast.needsAmount", defaultValue: "Add an amount first", bundle: Bundle.appLanguage) }
        static var toastNeedsName: String { String(localized: "spending.toast.needsName", defaultValue: "Name the purchase first", bundle: Bundle.appLanguage) }
        static var toastLoggedWithInventory: String {
            String(
                localized: "spending.toast.loggedWithInventory",
                defaultValue: "Logged and added to inventory",
                bundle: Bundle.appLanguage
            )
        }
        static func toastLogged(_ amount: String) -> String {
            String(localized: "spending.toast.logged", defaultValue: "\(amount) logged", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Sync to Cloud

    enum Sync {
        static var title: String { String(localized: "sync.title", defaultValue: "Sync to Cloud", bundle: Bundle.appLanguage) }
        static var premiumBadge: String { String(localized: "sync.premiumBadge", defaultValue: "Premium feature", bundle: Bundle.appLanguage) }
        static var explainerTitle: String { String(localized: "sync.explainer.title", defaultValue: "Keep your data safe", bundle: Bundle.appLanguage) }
        static var explainerBody: String {
            String(
                localized: "sync.explainer.body",
                defaultValue: "Automatic cloud sync across your devices is coming soon. In the meantime, export a copy of everything and save it to Files or send it to yourself.",
                bundle: Bundle.appLanguage
            )
        }
        static var exportCTA: String { String(localized: "sync.exportCTA", defaultValue: "Export a backup", bundle: Bundle.appLanguage) }
        static var exportedCTA: String { String(localized: "sync.exportedCTA", defaultValue: "Backup saved", bundle: Bundle.appLanguage) }
        static var toastExported: String { String(localized: "sync.toast.exported", defaultValue: "Backup exported to Files", bundle: Bundle.appLanguage) }

        static var backupHeading: String { String(localized: "sync.backup.heading", defaultValue: "MommysTime backup", bundle: Bundle.appLanguage) }
        static var backupAppointments: String { String(localized: "sync.backup.appointments", defaultValue: "Appointments:", bundle: Bundle.appLanguage) }
        static var backupInventory: String { String(localized: "sync.backup.inventory", defaultValue: "Inventory:", bundle: Bundle.appLanguage) }
        static var backupGrowth: String { String(localized: "sync.backup.growth", defaultValue: "Growth:", bundle: Bundle.appLanguage) }
        static var backupFooter: String { String(localized: "sync.backup.footer", defaultValue: "Exported from MommysTime 🌸", bundle: Bundle.appLanguage) }
        static func backupAppointment(title: String, when: String) -> String {
            String(localized: "sync.backup.appointment", defaultValue: "• \(title) — \(when)", bundle: Bundle.appLanguage)
        }
        static func backupItem(name: String, quantity: Int, category: String) -> String {
            String(localized: "sync.backup.item", defaultValue: "• \(name) ×\(quantity) (\(category))", bundle: Bundle.appLanguage)
        }
        static func backupGrowthRow(when: String, weight: String, height: String) -> String {
            String(localized: "sync.backup.growthRow", defaultValue: "• \(when): \(weight) kg, \(height) cm", bundle: Bundle.appLanguage)
        }
        static func backupSpending(total: String, count: Int) -> String {
            String(localized: "sync.backup.spending", defaultValue: "Spending: \(total) total across \(count) expenses", bundle: Bundle.appLanguage)
        }
    }

    // MARK: - Community

    enum Village {
        static var title: String { String(localized: "village.title", defaultValue: "Community", bundle: Bundle.appLanguage) }
        static var topicAll: String { String(localized: "village.topic.all", defaultValue: "All", bundle: Bundle.appLanguage) }
        static var topicNights: String { String(localized: "village.topic.nights", defaultValue: "Nights", bundle: Bundle.appLanguage) }
        static var topicFeeding: String { String(localized: "village.topic.feeding", defaultValue: "Feeding", bundle: Bundle.appLanguage) }
        static var topicMeTime: String { String(localized: "village.topic.meTime", defaultValue: "Me-time", bundle: Bundle.appLanguage) }

        static func countLine(_ n: Int) -> String {
            n == 1
                ? String(localized: "village.countLine.one", defaultValue: "\(n) discussion · no advice unless you ask", bundle: Bundle.appLanguage)
                : String(localized: "village.countLine.other", defaultValue: "\(n) discussions · no advice unless you ask", bundle: Bundle.appLanguage)
        }
        static var emptyTitle: String { String(localized: "village.empty.title", defaultValue: "Nothing here yet", bundle: Bundle.appLanguage) }
        static func emptyBody(_ topic: String) -> String {
            String(localized: "village.empty.body", defaultValue: "Be the first to start a \(topic) discussion.", bundle: Bundle.appLanguage)
        }
        static func hugs(_ n: Int) -> String {
            String(localized: "village.hugs", defaultValue: "\(n) hugs", bundle: Bundle.appLanguage)
        }
        static var hugsYouToo: String { String(localized: "village.hugs.youToo", defaultValue: " · you too", bundle: Bundle.appLanguage) }
        static func replies(_ n: Int) -> String {
            n == 1
                ? String(localized: "village.replies.one", defaultValue: "\(n) reply", bundle: Bundle.appLanguage)
                : String(localized: "village.replies.other", defaultValue: "\(n) replies", bundle: Bundle.appLanguage)
        }
        static let previewEllipsis = "…"

        static var detailTitle: String { String(localized: "village.detail.title", defaultValue: "Discussion", bundle: Bundle.appLanguage) }
        static func replyCountHeading(_ n: Int) -> String {
            String(localized: "village.detail.replyCount", defaultValue: "\(n) REPLIES", bundle: Bundle.appLanguage)
        }
        static var composerPlaceholder: String { String(localized: "village.composer.placeholder", defaultValue: "Write a reply…", bundle: Bundle.appLanguage) }
        static var anonymousAuthor: String { String(localized: "village.anonymousAuthor", defaultValue: "You", bundle: Bundle.appLanguage) }
        static var toastWriteReply: String { String(localized: "village.toast.writeReply", defaultValue: "Write a reply first", bundle: Bundle.appLanguage) }
        static var toastReplyPosted: String { String(localized: "village.toast.replyPosted", defaultValue: "Reply posted", bundle: Bundle.appLanguage) }
        static var toastThreadPosted: String { String(localized: "village.toast.threadPosted", defaultValue: "Discussion posted to the community", bundle: Bundle.appLanguage) }

        static var newTitle: String { String(localized: "village.new.title", defaultValue: "New discussion", bundle: Bundle.appLanguage) }
        static var newConfirm: String { String(localized: "village.new.confirm", defaultValue: "Post", bundle: Bundle.appLanguage) }
        static var newTopic: String { String(localized: "village.new.topic", defaultValue: "TOPIC", bundle: Bundle.appLanguage) }
        static var newPrompt: String { String(localized: "village.new.prompt", defaultValue: "WHAT'S ON YOUR MIND?", bundle: Bundle.appLanguage) }
        static var newTitlePlaceholder: String { String(localized: "village.new.titlePlaceholder", defaultValue: "Give it a title", bundle: Bundle.appLanguage) }
        static var newBodyPlaceholder: String {
            String(
                localized: "village.new.bodyPlaceholder",
                defaultValue: "Tell the community a bit more — what happened, what you need.",
                bundle: Bundle.appLanguage
            )
        }
        static var newFinePrint: String {
            String(
                localized: "village.new.finePrint",
                defaultValue: "Posts show your first name only. No advice unless you ask — that's the house rule.",
                bundle: Bundle.appLanguage
            )
        }
        static var emptyBodyPlaceholder: String { String(localized: "village.new.emptyBody", defaultValue: "—", bundle: Bundle.appLanguage) }
        static func newMeta(_ ageBand: String) -> String {
            String(localized: "village.new.meta", defaultValue: "Baby \(ageBand) · just now", bundle: Bundle.appLanguage)
        }

        /// The three starter discussions dropped in the first time the tab opens.
        /// Written to Core Data once, in whatever language was active then.
        enum Seed {
            static var ainaName: String { String(localized: "village.seed.author.aina", defaultValue: "Aina", bundle: Bundle.appLanguage) }
            static var surayaName: String { String(localized: "village.seed.author.suraya", defaultValue: "Suraya", bundle: Bundle.appLanguage) }
            static var meiName: String { String(localized: "village.seed.author.mei", defaultValue: "Mei", bundle: Bundle.appLanguage) }
            static var hanaName: String { String(localized: "village.seed.author.hana", defaultValue: "Hana", bundle: Bundle.appLanguage) }
            static var priyaName: String { String(localized: "village.seed.author.priya", defaultValue: "Priya", bundle: Bundle.appLanguage) }
            static var nurulName: String { String(localized: "village.seed.author.nurul", defaultValue: "Nurul", bundle: Bundle.appLanguage) }

            static var nightsMeta: String { String(localized: "village.seed.nights.meta", defaultValue: "Baby 4 months · 2h ago", bundle: Bundle.appLanguage) }
            static var nightsTitle: String { String(localized: "village.seed.nights.title", defaultValue: "Third night of 3am wake-ups", bundle: Bundle.appLanguage) }
            static var nightsBody: String {
                String(
                    localized: "village.seed.nights.body",
                    defaultValue: "She settles in twenty minutes but I'm wide awake until five. Not looking for fixes — just needed to say it out loud somewhere that gets it.",
                    bundle: Bundle.appLanguage
                )
            }
            static var nightsReply1: String {
                String(
                    localized: "village.seed.nights.reply1",
                    defaultValue: "Sitting with you. Week three of the same here. It does end, but that doesn't make tonight easier.",
                    bundle: Bundle.appLanguage
                )
            }
            static var nightsReply2: String {
                String(
                    localized: "village.seed.nights.reply2",
                    defaultValue: "Saying it out loud counts. Hope you get a long stretch tonight.",
                    bundle: Bundle.appLanguage
                )
            }

            static var feedingMeta: String { String(localized: "village.seed.feeding.meta", defaultValue: "Baby 7 weeks · 5h ago", bundle: Bundle.appLanguage) }
            static var feedingTitle: String {
                String(
                    localized: "village.seed.feeding.title",
                    defaultValue: "Combi feeding and the guilt finally lifted",
                    bundle: Bundle.appLanguage
                )
            }
            static var feedingBody: String {
                String(
                    localized: "village.seed.feeding.body",
                    defaultValue: "Switched this week after six weeks of trying to do it all by breast. She's fed, she's growing, and I slept four hours straight for the first time. Posting in case someone needs permission.",
                    bundle: Bundle.appLanguage
                )
            }
            static var feedingReply1: String {
                String(
                    localized: "village.seed.feeding.reply1",
                    defaultValue: "I needed this today. Thank you for posting it.",
                    bundle: Bundle.appLanguage
                )
            }
            static var feedingReply2: String {
                String(
                    localized: "village.seed.feeding.reply2",
                    defaultValue: "Fed is fed. Four hours is huge — hope tonight gives you another.",
                    bundle: Bundle.appLanguage
                )
            }
            static var feedingReply3: String {
                String(
                    localized: "village.seed.feeding.reply3",
                    defaultValue: "Did your supply settle after? Asking because I'm a week behind you.",
                    bundle: Bundle.appLanguage
                )
            }

            static var meTimeMeta: String { String(localized: "village.seed.meTime.meta", defaultValue: "Baby 9 months · yesterday", bundle: Bundle.appLanguage) }
            static var meTimeTitle: String {
                String(
                    localized: "village.seed.meTime.title",
                    defaultValue: "Booked 40 minutes for a walk with no pram",
                    bundle: Bundle.appLanguage
                )
            }
            static var meTimeBody: String {
                String(
                    localized: "village.seed.meTime.body",
                    defaultValue: "First time since January. Put it in the app as a block so nobody could claim the slot. Came home a different person. What's your smallest win this week?",
                    bundle: Bundle.appLanguage
                )
            }
            static var meTimeReply1: String {
                String(
                    localized: "village.seed.meTime.reply1",
                    defaultValue: "A shower with the door closed. Genuinely.",
                    bundle: Bundle.appLanguage
                )
            }
            static var meTimeReply2: String {
                String(
                    localized: "village.seed.meTime.reply2",
                    defaultValue: "Blocking the slot is the trick. If it isn't in the app someone else takes the hour.",
                    bundle: Bundle.appLanguage
                )
            }
        }
    }

    // MARK: - Settings

    enum Settings {
        static var title: String { String(localized: "settings.title", defaultValue: "Settings", bundle: Bundle.appLanguage) }
        static var defaultUserName: String { String(localized: "settings.defaultUserName", defaultValue: "Nadia", bundle: Bundle.appLanguage) }
        static var babyFallback: String { String(localized: "settings.babyFallback", defaultValue: "Baby", bundle: Bundle.appLanguage) }
        static func profileSubtitle(baby: String, age: String) -> String {
            String(localized: "settings.profile.subtitle", defaultValue: "\(baby) · \(age)", bundle: Bundle.appLanguage)
        }
        static var premiumMember: String { String(localized: "settings.premiumMember", defaultValue: "PREMIUM MEMBER", bundle: Bundle.appLanguage) }
        static var freePlan: String { String(localized: "settings.freePlan", defaultValue: "FREE PLAN", bundle: Bundle.appLanguage) }

        static var sectionApp: String { String(localized: "settings.section.app", defaultValue: "APP", bundle: Bundle.appLanguage) }
        static var sectionSupport: String { String(localized: "settings.section.support", defaultValue: "SUPPORT", bundle: Bundle.appLanguage) }
        static var sectionAbout: String { String(localized: "settings.section.about", defaultValue: "ABOUT", bundle: Bundle.appLanguage) }

        static var rowDay: String { String(localized: "settings.row.day", defaultValue: "My day & scheduling", bundle: Bundle.appLanguage) }
        static var rowLanguage: String { String(localized: "settings.row.language", defaultValue: "Language", bundle: Bundle.appLanguage) }
        static var rowNotifications: String { String(localized: "settings.row.notifications", defaultValue: "Notifications", bundle: Bundle.appLanguage) }
        static var rowSync: String { String(localized: "settings.row.sync", defaultValue: "Sync to Cloud", bundle: Bundle.appLanguage) }
        static var rowSubscription: String { String(localized: "settings.row.subscription", defaultValue: "Subscription", bundle: Bundle.appLanguage) }
        static var rowFeedback: String { String(localized: "settings.row.feedback", defaultValue: "Send feedback", bundle: Bundle.appLanguage) }
        static var rowHelp: String { String(localized: "settings.row.help", defaultValue: "Help & FAQ", bundle: Bundle.appLanguage) }
        static var rowRate: String { String(localized: "settings.row.rate", defaultValue: "Rate Mommy's Time", bundle: Bundle.appLanguage) }
        static var rowRerun: String { String(localized: "settings.row.rerun", defaultValue: "Run setup again", bundle: Bundle.appLanguage) }
        static var rowPrivacy: String { String(localized: "settings.row.privacy", defaultValue: "Privacy policy", bundle: Bundle.appLanguage) }
        static var rowTerms: String { String(localized: "settings.row.terms", defaultValue: "Terms of use", bundle: Bundle.appLanguage) }
        static var premiumBadge: String { String(localized: "settings.premiumBadge", defaultValue: "PREMIUM", bundle: Bundle.appLanguage) }
        static var signOut: String { String(localized: "settings.signOut", defaultValue: "Sign out", bundle: Bundle.appLanguage) }
        static func footer(_ version: String) -> String {
            String(localized: "settings.footer", defaultValue: "Mommy's Time \(version)\nMade for mamas in Malaysia", bundle: Bundle.appLanguage)
        }

        static var toastAlreadyPremium: String { String(localized: "settings.toast.alreadyPremium", defaultValue: "You're already Premium, mama", bundle: Bundle.appLanguage) }
        static var toastHelp: String { String(localized: "settings.toast.help", defaultValue: "Help centre opens in the full build", bundle: Bundle.appLanguage) }
        static var toastRate: String { String(localized: "settings.toast.rate", defaultValue: "Store rating opens in the full build", bundle: Bundle.appLanguage) }
        static var toastPrivacy: String { String(localized: "settings.toast.privacy", defaultValue: "Privacy policy opens in the full build", bundle: Bundle.appLanguage) }
        static var toastTerms: String { String(localized: "settings.toast.terms", defaultValue: "Terms open in the full build", bundle: Bundle.appLanguage) }
        static var toastSignedOut: String {
            String(
                localized: "settings.toast.signedOut",
                defaultValue: "Signed out — in the full build this returns to login",
                bundle: Bundle.appLanguage
            )
        }

        // My day
        static var dayTitle: String { String(localized: "settings.day.title", defaultValue: "My day", bundle: Bundle.appLanguage) }
        static var daySection: String { String(localized: "settings.day.section", defaultValue: "YOUR DAY", bundle: Bundle.appLanguage) }
        static var dayStarts: String { String(localized: "settings.day.starts", defaultValue: "My day starts", bundle: Bundle.appLanguage) }
        static var dayEnds: String { String(localized: "settings.day.ends", defaultValue: "My day ends", bundle: Bundle.appLanguage) }
        static var dayHint: String { String(localized: "settings.day.hint", defaultValue: "The app only looks for me-time between these hours.", bundle: Bundle.appLanguage) }
        static var bedtime: String { String(localized: "settings.bedtime", defaultValue: "Kids' bedtime", bundle: Bundle.appLanguage) }
        static var bedtimeHint: String {
            String(
                localized: "settings.bedtime.hint",
                defaultValue: "Free time after bedtime gets a bonus — the house is quiet.",
                bundle: Bundle.appLanguage
            )
        }
        static var minimumGap: String { String(localized: "settings.minimumGap", defaultValue: "Minimum gap", bundle: Bundle.appLanguage) }
        static var minimumGapHint: String {
            String(
                localized: "settings.minimumGap.hint",
                defaultValue: "Gaps shorter than this won't be suggested — you deserve more than a rushed five minutes.",
                bundle: Bundle.appLanguage
            )
        }

        // Profile
        static var profileTitle: String { String(localized: "settings.profile.title", defaultValue: "My profile", bundle: Bundle.appLanguage) }
        static var profileInitialFallback: String { String(localized: "settings.profile.initialFallback", defaultValue: "?", bundle: Bundle.appLanguage) }
        static var profileSectionYou: String { String(localized: "settings.profile.section.you", defaultValue: "YOU", bundle: Bundle.appLanguage) }
        static var profileSectionBaby: String { String(localized: "settings.profile.section.baby", defaultValue: "BABY", bundle: Bundle.appLanguage) }
        static var profileName: String { String(localized: "settings.profile.name", defaultValue: "Your name", bundle: Bundle.appLanguage) }
        static var profileEmail: String { String(localized: "settings.profile.email", defaultValue: "Email", bundle: Bundle.appLanguage) }
        static var profileBabyName: String { String(localized: "settings.profile.babyName", defaultValue: "Baby's name", bundle: Bundle.appLanguage) }
        static var profileHint: String {
            String(
                localized: "settings.profile.hint",
                defaultValue: "Your community posts show your first name only.",
                bundle: Bundle.appLanguage
            )
        }

        // Feedback
        static var feedbackTitle: String { String(localized: "settings.feedback.title", defaultValue: "Send feedback", bundle: Bundle.appLanguage) }
        static var feedbackSend: String { String(localized: "settings.feedback.send", defaultValue: "Send", bundle: Bundle.appLanguage) }
        static var feedbackBlurb: String {
            String(
                localized: "settings.feedback.blurb",
                defaultValue: "Tell us what's working and what isn't. A real person reads every note.",
                bundle: Bundle.appLanguage
            )
        }
        static var feedbackKindLabel: String { String(localized: "settings.feedback.kindLabel", defaultValue: "WHAT KIND?", bundle: Bundle.appLanguage) }
        static var feedbackKindIdea: String { String(localized: "settings.feedback.kind.idea", defaultValue: "Idea", bundle: Bundle.appLanguage) }
        static var feedbackKindBroken: String { String(localized: "settings.feedback.kind.broken", defaultValue: "Something's broken", bundle: Bundle.appLanguage) }
        static var feedbackKindHi: String { String(localized: "settings.feedback.kind.hi", defaultValue: "Just saying hi", bundle: Bundle.appLanguage) }
        static var feedbackPlaceholder: String {
            String(
                localized: "settings.feedback.placeholder",
                defaultValue: "Write as much or as little as you like.",
                bundle: Bundle.appLanguage
            )
        }
        static func feedbackVersionNote(_ version: String) -> String {
            String(
                localized: "settings.feedback.versionNote",
                defaultValue: "Sent with app version \(version) so we know what you were using.",
                bundle: Bundle.appLanguage
            )
        }
        static var feedbackToast: String { String(localized: "settings.feedback.toast", defaultValue: "Thank you — feedback sent", bundle: Bundle.appLanguage) }
    }

    // MARK: - Premium

    enum Paywall {
        static var title: String { String(localized: "paywall.title", defaultValue: "Mommy's Time Premium", bundle: Bundle.appLanguage) }
        static var heroTitle: String { String(localized: "paywall.hero.title", defaultValue: "A little more help, mama", bundle: Bundle.appLanguage) }
        static func heroSub(_ count: String) -> String {
            String(
                localized: "paywall.hero.sub",
                defaultValue: "\(count) features that take the mental load off — yours for less than a tin of formula.",
                bundle: Bundle.appLanguage
            )
        }
        /// Spelled out so the headline can't drift when a perk is added.
        static var countWords: [String] {
            [
                String(localized: "paywall.count.0", defaultValue: "No", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.1", defaultValue: "One", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.2", defaultValue: "Two", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.3", defaultValue: "Three", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.4", defaultValue: "Four", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.5", defaultValue: "Five", bundle: Bundle.appLanguage),
                String(localized: "paywall.count.6", defaultValue: "Six", bundle: Bundle.appLanguage),
            ]
        }

        static var unlockLabel: String { String(localized: "paywall.unlock.label", defaultValue: "WHAT YOU UNLOCK", bundle: Bundle.appLanguage) }
        static var planLabel: String { String(localized: "paywall.plan.label", defaultValue: "CHOOSE A PLAN", bundle: Bundle.appLanguage) }

        static var perkWakeTitle: String { String(localized: "paywall.perk.wake.title", defaultValue: "Wake Window", bundle: Bundle.appLanguage) }
        static var perkWakeSub: String {
            String(
                localized: "paywall.perk.wake.sub",
                defaultValue: "Awake or asleep in one tap, with a sleep summary",
                bundle: Bundle.appLanguage
            )
        }
        static var perkRecipesTitle: String { String(localized: "paywall.perk.recipes.title", defaultValue: "Recipes", bundle: Bundle.appLanguage) }
        static var perkRecipesSub: String {
            String(
                localized: "paywall.perk.recipes.sub",
                defaultValue: "One-pot meals for you, first foods for baby",
                bundle: Bundle.appLanguage
            )
        }
        static var perkSpendingTitle: String { String(localized: "paywall.perk.spending.title", defaultValue: "My Spending", bundle: Bundle.appLanguage) }
        static var perkSpendingSub: String {
            String(
                localized: "paywall.perk.spending.sub",
                defaultValue: "See where the baby budget actually goes",
                bundle: Bundle.appLanguage
            )
        }
        static var perkSyncTitle: String { String(localized: "paywall.perk.sync.title", defaultValue: "Sync to Cloud", bundle: Bundle.appLanguage) }
        static var perkSyncSub: String {
            String(
                localized: "paywall.perk.sync.sub",
                defaultValue: "Your logs backed up and on every device",
                bundle: Bundle.appLanguage
            )
        }

        static var planMonthly: String { String(localized: "paywall.plan.monthly", defaultValue: "Monthly", bundle: Bundle.appLanguage) }
        static var planYearly: String { String(localized: "paywall.plan.yearly", defaultValue: "Yearly", bundle: Bundle.appLanguage) }
        static var planMonthlyLower: String { String(localized: "paywall.plan.monthly.lower", defaultValue: "monthly", bundle: Bundle.appLanguage) }
        static var planYearlyLower: String { String(localized: "paywall.plan.yearly.lower", defaultValue: "yearly", bundle: Bundle.appLanguage) }
        static var planMonthlySub: String { String(localized: "paywall.plan.monthly.sub", defaultValue: "Cancel any time", bundle: Bundle.appLanguage) }
        static var planYearlySub: String { String(localized: "paywall.plan.yearly.sub", defaultValue: "RM 5.90 a month, billed once", bundle: Bundle.appLanguage) }
        static var planMonthlyPrice: String { String(localized: "paywall.plan.monthly.price", defaultValue: "RM 9.90", bundle: Bundle.appLanguage) }
        static var planYearlyPrice: String { String(localized: "paywall.plan.yearly.price", defaultValue: "RM 70.80", bundle: Bundle.appLanguage) }
        static var saveTag: String { String(localized: "paywall.saveTag", defaultValue: "SAVE 40%", bundle: Bundle.appLanguage) }

        static var ctaOwned: String { String(localized: "paywall.cta.owned", defaultValue: "You're all set", bundle: Bundle.appLanguage) }
        static func cta(_ plan: String) -> String {
            String(localized: "paywall.cta", defaultValue: "Start with \(plan)", bundle: Bundle.appLanguage)
        }
        static var finePrintYearly: String {
            String(
                localized: "paywall.finePrint.yearly",
                defaultValue: "RM 70.80 billed yearly. Cancel any time before renewal.",
                bundle: Bundle.appLanguage
            )
        }
        static var finePrintMonthly: String {
            String(
                localized: "paywall.finePrint.monthly",
                defaultValue: "RM 9.90 billed monthly. Cancel any time.",
                bundle: Bundle.appLanguage
            )
        }
        static var restore: String { String(localized: "paywall.restore", defaultValue: "Restore a purchase", bundle: Bundle.appLanguage) }
        static var toastNoPurchase: String { String(localized: "paywall.toast.noPurchase", defaultValue: "No previous purchase found", bundle: Bundle.appLanguage) }
        static var toastUnlocked: String { String(localized: "paywall.toast.unlocked", defaultValue: "Premium unlocked — enjoy, mama", bundle: Bundle.appLanguage) }
    }

    // MARK: - Goals

    enum Goals {
        static var title: String { String(localized: "goals.title", defaultValue: "My Goals", bundle: Bundle.appLanguage) }
        static var emptyTitle: String { String(localized: "goals.empty.title", defaultValue: "What are you working on, mama?", bundle: Bundle.appLanguage) }
        static var emptyBody: String {
            String(
                localized: "goals.empty.body",
                defaultValue: "Learning to stitch? A new language? Coding? Add a goal and the app will help you find time for it.",
                bundle: Bundle.appLanguage
            )
        }
        static var emptyCTA: String { String(localized: "goals.empty.cta", defaultValue: "Add your first goal", bundle: Bundle.appLanguage) }
        static let defaultIcon = "🌸"
        static func rowMeta(target: Int, completed: Int) -> String {
            String(localized: "goals.row.meta", defaultValue: "\(target)× a week · \(completed) done", bundle: Bundle.appLanguage)
        }

        static var newTitle: String { String(localized: "goals.new.title", defaultValue: "New Goal", bundle: Bundle.appLanguage) }
        static var sectionGoal: String { String(localized: "goals.section.goal", defaultValue: "YOUR GOAL", bundle: Bundle.appLanguage) }
        static var sectionIcon: String { String(localized: "goals.section.icon", defaultValue: "PICK AN ICON", bundle: Bundle.appLanguage) }
        static var namePlaceholder: String { String(localized: "goals.namePlaceholder", defaultValue: "e.g. Learn to stitch", bundle: Bundle.appLanguage) }
        static func target(_ n: Int) -> String {
            String(localized: "goals.target", defaultValue: "Target: \(n)× a week", bundle: Bundle.appLanguage)
        }
        static func targetStepper(_ n: Int) -> String {
            String(localized: "goals.targetStepper", defaultValue: "Target: \(n)x a week", bundle: Bundle.appLanguage)
        }
        static var iconNote: String {
            String(
                localized: "goals.iconNote",
                defaultValue: "Icon set to be drawn in the illustrated style — flat swatches shown as placeholders.",
                bundle: Bundle.appLanguage
            )
        }
        static var toastNeedsName: String { String(localized: "goals.toast.needsName", defaultValue: "Name your goal first", bundle: Bundle.appLanguage) }
        static var toastAdded: String { String(localized: "goals.toast.added", defaultValue: "Goal added", bundle: Bundle.appLanguage) }

        static var editTitle: String { String(localized: "goals.edit.title", defaultValue: "Edit goal", bundle: Bundle.appLanguage) }
        static var thisWeek: String { String(localized: "goals.thisWeek", defaultValue: "This week", bundle: Bundle.appLanguage) }
        static var yourGoal: String { String(localized: "goals.yourGoal", defaultValue: "Your goal", bundle: Bundle.appLanguage) }
        static var pickIcon: String { String(localized: "goals.pickIcon", defaultValue: "Pick an icon", bundle: Bundle.appLanguage) }
        static var weekEmpty: String { String(localized: "goals.week.empty", defaultValue: "No sessions completed yet this week.", bundle: Bundle.appLanguage) }
        static func weekSummary(_ n: Int) -> String {
            n == 1
                ? String(
                    localized: "goals.week.summary.one",
                    defaultValue: "\(n) session completed this week — they add up here from every day.",
                    bundle: Bundle.appLanguage
                )
                : String(
                    localized: "goals.week.summary.other",
                    defaultValue: "\(n) sessions completed this week — they add up here from every day.",
                    bundle: Bundle.appLanguage
                )
        }
        static var deleteButton: String { String(localized: "goals.delete", defaultValue: "Delete goal", bundle: Bundle.appLanguage) }
        static var deleteConfirm: String { String(localized: "goals.delete.confirm", defaultValue: "Delete this goal?", bundle: Bundle.appLanguage) }
        static var deleteMessage: String {
            String(
                localized: "goals.delete.message",
                defaultValue: "Your booked me-time stays on your schedule, but it won't count towards a goal any more.",
                bundle: Bundle.appLanguage
            )
        }
    }

    // MARK: - Progress

    enum Progress {
        static var title: String { String(localized: "progress.title", defaultValue: "Progress", bundle: Bundle.appLanguage) }
        static var weekLabel: String { String(localized: "progress.weekLabel", defaultValue: "ME-TIME THIS WEEK", bundle: Bundle.appLanguage) }
        static var booked: String { String(localized: "progress.booked", defaultValue: "Booked and yours. Protect it.", bundle: Bundle.appLanguage) }
        static var nothingYet: String {
            String(
                localized: "progress.nothingYet",
                defaultValue: "This week is still young. Your time will come, mama.",
                bundle: Bundle.appLanguage
            )
        }
        static var reassurance: String {
            String(
                localized: "progress.reassurance",
                defaultValue: "No streaks, no guilt. Some weeks belong entirely to the kids — and that's okay. The app will keep finding pockets of time for you.",
                bundle: Bundle.appLanguage
            )
        }
    }

    // MARK: - Charts, calendars and histories

    enum Charts {
        static func peak(_ value: Int, _ unit: String) -> String {
            String(localized: "charts.peak", defaultValue: "peak \(value) \(unit)", bundle: Bundle.appLanguage)
        }
        static var nothingLogged: String { String(localized: "charts.nothingLogged", defaultValue: "nothing logged yet", bundle: Bundle.appLanguage) }
        static var today: String { String(localized: "charts.today", defaultValue: "Today", bundle: Bundle.appLanguage) }
        static var defaultUnit: String { String(localized: "charts.defaultUnit", defaultValue: "ml", bundle: Bundle.appLanguage) }
        static func trend(_ delta: String, _ unit: String) -> String {
            String(localized: "charts.trend", defaultValue: "\(delta) \(unit) this month", bundle: Bundle.appLanguage)
        }
        static let trendPlus = "+"
        static func latest(_ value: String, _ unit: String) -> String {
            String(localized: "charts.latest", defaultValue: "\(value) \(unit)", bundle: Bundle.appLanguage)
        }
        static func latestOn(_ date: String) -> String {
            String(localized: "charts.latestOn", defaultValue: "latest · \(date)", bundle: Bundle.appLanguage)
        }
    }

    enum CalendarCopy {
        static var week: String { String(localized: "calendar.week", defaultValue: "Week", bundle: Bundle.appLanguage) }
        static var month: String { String(localized: "calendar.month", defaultValue: "Month", bundle: Bundle.appLanguage) }
        /// Monday-first single-letter column heads.
        static var weekdayInitials: [String] {
            [
                String(localized: "calendar.weekday.mon", defaultValue: "M", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.tue", defaultValue: "T", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.wed", defaultValue: "W", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.thu", defaultValue: "T", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.fri", defaultValue: "F", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.sat", defaultValue: "S", bundle: Bundle.appLanguage),
                String(localized: "calendar.weekday.sun", defaultValue: "S", bundle: Bundle.appLanguage),
            ]
        }
        static func rangeSameMonth(start: String, end: String, month: String) -> String {
            String(localized: "calendar.range.sameMonth", defaultValue: "\(start) – \(end) \(month)", bundle: Bundle.appLanguage)
        }
        static func rangeAcrossMonths(start: String, startMonth: String, end: String, endMonth: String) -> String {
            String(
                localized: "calendar.range.acrossMonths",
                defaultValue: "\(start) \(startMonth) – \(end) \(endMonth)",
                bundle: Bundle.appLanguage
            )
        }
    }

    enum History {
        static var empty: String { String(localized: "history.empty", defaultValue: "Nothing logged on this day", bundle: Bundle.appLanguage) }
        static var noEntries: String { String(localized: "history.noEntries", defaultValue: "no entries", bundle: Bundle.appLanguage) }
    }
}
