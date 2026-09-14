# Mommy's Time 💛

An iOS app for busy moms: plan your day around the kids and the house, and let the app find the pockets of time that belong to *you* — for learning to stitch, coding, reading, or whatever your goal is.

**Everything stays on the phone.** SwiftUI + Core Data, no backend, no accounts, no tracking.

## How it works

Three tabs — **Home**, **Community** and **Settings** — with everything else one tap away from the Home grid.

- **Daily Task** — build your day from quick templates (school run, nap time, cooking…) on a week/month calendar. Blocks can repeat daily.
- **Find my time ✨** — scans the day for free gaps and ranks the top 3. Quiet-time blocks (naps, school hours) count as *free time with a bonus* — the kids are settled, so those windows score higher, as does time after the kids' bedtime. A gap right after a big chore scores lower.
- **Logs** — pump, feed and growth, each with a seven-day chart and a day-by-day history.
- **Wake Window** — one tap flips the baby between awake and asleep; every switch lands in the sleep log, and the chart button opens a summary of the day's shape.
- **Soothing sounds** — brown noise, generated on the fly, a tap from the Home grid.
- **Community** — discussions with other mums, with hugs instead of upvotes. No advice unless you ask.
- **Premium** — Wake Window, Recipes, My Spending and Sync to Cloud.

## Running it

Open `MommysTime.xcodeproj` in Xcode (16+), pick an iPhone simulator, press ▶︎.

## Structure

- `Theme.swift` / `DesignKit.swift` — the "Avocation" palette and the shared chips, sheet headers, steppers and cards
- `TimeFinder.swift` — the gap-finding and scoring engine (pure logic, no UI)
- `BlockCategory.swift` — block categories, quick-add templates, `ScheduleBlock` helpers
- `CalendarCard.swift` / `LogCharts.swift` / `LogHistoryView.swift` — the calendar, chart and history surfaces the log screens share
- `WakeWindowView.swift` — the awake/asleep switch and the sleep summary
- `SootheNoise.swift` — the white-noise generator behind the Home soothe button
- `MommysTime.xcdatamodeld` — Core Data model: `ScheduleBlock`, `VillageThread`, `PumpSession`, `FeedSession`, `GrowthEntry`, …
- `HomeView` / `VillageView` / `SettingsView` — the three tabs; everything else is pushed or presented from them
