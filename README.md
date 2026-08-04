# Mommy's Time 💛

An iOS app for busy moms: plan your day around the kids and the house, and let the app find the pockets of time that belong to *you* — for learning to stitch, coding, reading, or whatever your goal is.

**Everything stays on the phone.** SwiftUI + Core Data, no backend, no accounts, no tracking.

## How it works

- **Today** — build your day from quick templates (school run, nap time, cooking…). Blocks can repeat daily.
- **Find my time ✨** — scans the day for free gaps and ranks the top 3. Quiet-time blocks (naps, school hours) count as *free time with a bonus* — the kids are settled, so those windows score higher, as does time after the kids' bedtime. A gap right after a big chore scores lower.
- **Goals** — what you're working on, with a gentle weekly target. Booking a suggested slot puts your me-time on the schedule like any other block.
- **Progress** — weekly me-time total per goal. No streaks, no guilt.

## Running it

Open `MommysTime.xcodeproj` in Xcode (16+), pick an iPhone simulator, press ▶︎.

## Structure

- `TimeFinder.swift` — the gap-finding and scoring engine (pure logic, no UI)
- `BlockCategory.swift` — block categories, quick-add templates, `ScheduleBlock` helpers
- `MommysTime.xcdatamodeld` — Core Data model: `ScheduleBlock`, `Goal`, `MeTimeSession`
- `TodayView` / `FindTimeSheet` / `GoalsView` / `WeeklyProgressView` / `SettingsView` — the four tabs and sheets
