# Moss

Moss is a calm, local-first day planner for people whose schedules are often
disrupted by urgent work. Add an urgent task and Moss proposes a revised plan,
shows exactly what moves, and lets you confirm or undo the change.

## Current MVP

- Manual tasks with duration and optional deadline
- Fixed meetings and lockable task blocks
- Automatic scheduling inside configurable work hours
- Urgent re-plan preview with moved-task diff, overflow and undo
- Persistent SQLite storage with soft deletion
- Local start/deadline notifications
- First-run onboarding, local event log and mock Moss Plus paywall
- Thai-first, warm light theme

All task, schedule and event data stays on the device. There are no accounts,
cloud services, AI APIs or real payments in this MVP.

## Run

```sh
flutter pub get
flutter run
```

Android is the primary target. iOS remains supported by the Flutter project but
requires cloud CI or a Mac for signing and device testing.

## Verify

```sh
flutter analyze
flutter test
```

The scheduler is a pure function under `lib/core/scheduler/`; unit tests cover
deadlines, fixed/locked blocks, overflow, UTC handling, determinism and urgent
re-plan diffs.

See `PLAN.md` for product scope, UX rules and release criteria.
