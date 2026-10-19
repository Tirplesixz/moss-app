# LockDay clean-room product analysis

This document records what was observed from the user-supplied LockDay 1.9.0
IPA and how those observations inform Moss. It is intentionally limited to
product behavior and information architecture. Moss does not reuse LockDay
code, artwork, branding, or copy.

## Evidence

- `EV-IPA-01` (`ev_8b5be7d4fef305fc5fd79c2e0e41badaba180a82a8a9ff6ad8f60f3f6e8bfb6e`):
  complete ZIP inventory summary, 505 nodes and 411 files.
- `EV-IPA-02` (`ev_534937983df6469a866e998294c3df4b2898e6c4a1f3c527bde41549adea9426`):
  Apple application graph. It identifies one native iOS application, one
  widget extension, Firebase analytics frameworks, and RevenueCat resources.
- `EV-IPA-03` (`ev_a4ce6be51326a854a94412c408343b7f4ae4658ea7fa638b74e632bf32791d39`):
  contained extraction of every regular file from the IPA.
- `EV-RES-01`: shipped localization keys and guide media from `EV-IPA-03`.
  This includes explicit labels for Matrix, Calendar, Lock Screen, Notes,
  widgets, appearance, reminders, onboarding, and task editing.
- `EV-META-01`: XML `Info.plist` from `EV-IPA-03`, identifying iOS 17+, iPhone
  portrait, iPad multi-orientation support, calendar permissions, background
  notifications/audio, multi-scene support, and a custom URL scheme.

## Observed product structure

1. The Eisenhower Matrix is the primary task model, not a secondary filter.
2. Calendar is a second view of the same day and separates scheduled,
   all-day, due, and completed items.
3. Lock Screen and Home Screen widgets are first-class output surfaces.
4. Task creation is intentionally short: title, date, optional time, matrix,
   note, reminder, and repeat.
5. Appearance is a persisted System / Light / Dark preference.
6. Onboarding explains value before asking for calendar and notification
   permissions.
7. Empty states tell the user the next action instead of showing blank grids.

## Moss decisions

- Keep four stable destinations: Today, Calendar, Lock Screen, and Settings.
- Preserve destination state with an indexed shell.
- Treat matrix quadrant as the user-facing priority source of truth.
- Keep task, calendar block, and notification persistence behind repositories.
- Persist appearance alongside other application settings.
- Use Moss tokens, Thai copy, typography, and original assets.
- Keep motion short and functional, and honor reduced-motion preferences.

## Inferences

- The widget extension and wallpaper resources suggest that Lock Screen output
  is generated from the same task/calendar store. This is an inference from
  bundle structure and strings, not runtime observation.
- Firebase is likely used for product analytics and RevenueCat for purchases.
  Presence in the bundle does not prove which events or purchase rules run.

## Unknowns and limits

- No runtime behavior was observed. An iOS IPA cannot be executed on the
  available Android emulator.
- The Windows REA host has no Mach-O deep-analysis provider: Hopper requires
  macOS, and the available Ghidra integration does not accept arm64 Mach-O.
- Static resources do not establish internal algorithms, server contracts,
  analytics payloads, or exact navigation transitions.
