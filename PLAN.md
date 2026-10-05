# PLAN.md — Moss: Urgent-Task Rescheduling Planner

> **AI assistants: read this whole file before writing or changing any code.**
> This is the single source of truth. If a request conflicts with this file, say so and ask before acting.
> Work in small steps, one task at a time. Do not add anything listed under "OUT of scope".

---

## 1. Product in one paragraph

A mobile day planner for people who have a lot of work every day and get urgent tasks dropped on them.
The core moment: **an urgent task arrives → the app re-plans today in one tap → the user feels relief, not guilt.**
Everything else exists to support that moment.

- Target user: anyone with a heavy daily workload (office workers, freelancers, students, etc.). Messaging at launch targets one phrase: "for people whose work never stops".
- Tone: warm, calm, never blaming. Missed tasks roll forward. No red warnings.
- **Name: Moss** (chosen by the owner; store/domain/trademark availability NOT yet verified — see section 14). The name does not literally say "scheduling", so store listings must carry the meaning, e.g. subtitle "Moss: Urgent Task Planner" and a Thai tagline such as "งานด่วนเข้า ก็ยังไม่ลน". The name is international (plain English word); Thai is used for in-app copy and localized store text. Name idea "Steady" was dropped because it already exists in the stores. Brand feel: calm, soft, natural — fits the sage-green primary color (section 8). A moss/leaf motif can come later; keep the MVP visual minimal.
- Money (later, not in MVP): freemium + subscription (monthly/yearly), maybe cosmetic items. Free tier lets users experience the urgent re-plan a few times per week; paid unlocks unlimited re-plan, AI text/voice parsing, calendar sync, widgets, themes.

## 2. MVP goal and success gate

Goal: prove the "urgent task → one-tap re-plan" value with real users before building anything else.

Ship gate (measure after ~3 weeks of building + testing):
- 15 testers use it.
- At least 5 of 15 come back in week 2 **without being reminded**.
- Time from first app open to first task on the schedule: **under 2 minutes** (target: 2 taps after typing).
- Testers who see the mock paywall: count how many tap "subscribe" (fake door, no real payment in MVP).

If the gate fails, stop and revisit the idea before adding features.

## 3. Scope

### IN scope (MVP)
1. Manual task entry (title, duration, deadline).
2. Fixed blocks the user adds by hand (meetings/appointments, locked time).
3. "Today" home screen (hybrid: now-card + compact timeline + quick-add bar).
4. Scheduler (pure function) + urgent re-plan with diff preview and undo.
5. Local notifications (block start, before deadline).
6. Local storage only.
7. Mock paywall screen (fake door, tracks taps).
8. Light theme (dark theme later, but colors must already be theme variables).

### OUT of scope (do NOT add unless the owner explicitly asks)
- User accounts / login (Google, Apple, email), cloud sync, backend server.
- Google Calendar / any calendar sync.
- AI / LLM features, voice input (planned later, see section 11).
- Recurring/habit tasks, subtasks, projects, tags, teams, sharing.
- Real payments / RevenueCat / in-app purchases.
- Character system, cosmetics store, hand-drawn crayon illustration style (later).
- Web or desktop targets.

## 4. Tech stack and constraints

- **Flutter** (Dart). **Android first**; iOS added later via cloud CI (owner has no Mac). Every package added must support both Android and iOS — check before adding.
- Local DB: SQLite (`drift` preferred, `sqflite` acceptable).
- Notifications: `flutter_local_notifications` (local only, no server).
- State management: keep simple (Riverpod or Provider); pick one and stay consistent.
- **No hardcoded colors or text styles in widgets.** Use theme tokens (section 8) so dark mode can be added without touching every screen.
- Store all timestamps in **UTC**; convert to local time only for display.
- Every table uses **UUID string ids**, `updatedAt`, and soft delete (`deletedAt`) — so cloud/calendar sync can be added later without a rewrite.
- Ask before adding any new dependency, and say why.

## 5. Data model

```
Task    { id, title, durationMin, deadlineAt?, priority (1-3, default 2),
          status ('todo'|'done'|'dropped'), createdAt, updatedAt, deletedAt? }

Block   { id, kind ('task'|'fixed'), taskId?, title?, startAt, endAt,
          locked (bool), source ('local'|'google')?, externalId?, updatedAt, deletedAt? }
        // fixed = meeting/appointment typed in by the user; source/externalId reserved for later sync

Settings{ workdayStart, workdayEnd, bufferMin, timezone }

Notif   { id, blockId, type ('start'|'deadline'), fireAt, osNotifId }
```

Notes:
- `priority` is stored but hidden in the MVP UI (default 2). The scheduler orders by deadline first.
- A task's block is derived by the scheduler; users can lock a block to pin its time.

## 6. Scheduler spec (the heart of the app)

Implement as **pure functions** in their own module: no DB access, no `DateTime.now()` inside (pass `now` in). Same input must always give the same output.

### 6.1 `schedule(tasks, fixedBlocks, settings, now) -> { blocks, overflow }`
1. Consider only tasks with status `todo`. Horizon: today + next 7 days.
2. Order tasks by: deadline ascending (no deadline last) → priority descending → createdAt ascending.
3. For each task, place it in the **earliest free slot** that:
   - starts at or after `max(now rounded up to 5 min, workdayStart)`,
   - lies inside the workday window,
   - fits `durationMin` plus `bufferMin` after it,
   - does not overlap any fixed or locked block,
   - ends at or before `deadlineAt` if one exists.
4. If no slot satisfies the rules, put the task in `overflow` (never drop silently).
5. Tasks are not split across gaps in the MVP.
6. Round all start/end times to 5 minutes.

### 6.2 `insertUrgent(currentBlocks, newTask, fixedBlocks, settings, now) -> { proposal, diff }`
Goal: **minimum disruption** — keep existing blocks where they are whenever possible.
1. Candidate start times = each free-slot start from now onward, in time order.
2. For a candidate, tentatively place the new task, then push any overlapping **movable** (not fixed, not locked) blocks later, cascading, as long as each pushed block still meets its own deadline and stays inside the workday.
3. First candidate where everything fits wins.
4. If none works: return `overflow` containing the task that cannot fit, and let the UI explain (see section 7.3).
5. `diff = { added[], moved[{blockId, from, to}], unchanged[], overflow[] }`.

### 6.3 Required unit tests (write these before UI work)
- Empty day; single task lands at next 5-minute mark inside the workday.
- Two tasks with different deadlines are ordered by deadline.
- Task does not overlap a fixed block.
- Task that would straddle the end of the workday moves to the next day's start.
- Deadline too tight → task appears in `overflow`, not silently dropped.
- Locked block never moves.
- `insertUrgent` moves the fewest blocks; unchanged blocks keep identical start times.
- `insertUrgent` cascade: pushed block that would miss its deadline blocks that candidate.
- Crossing midnight and daylight/timezone change do not corrupt times (UTC storage).
- Determinism: run twice with the same input, results are equal.

## 7. Screens and UX

Principles: fewer decisions for the user; hidden complexity must be **explainable and editable**; guilt-free tone; one primary button per screen; from app open to first task on the schedule in ≤ 2 taps after typing.

### 7.1 Home (Today) — hybrid layout
Top to bottom:
1. Date (small) + title "ตอนนี้".
2. Done items collapsed to one muted line (e.g. "ประชุมทีม 09:00 · เสร็จแล้ว").
3. **Now card**: current block title, time range, "เหลืออีก X นาที", thin progress bar, secondary buttons "เสร็จแล้ว" and "พัก".
4. Section "ต่อจากนี้": compact timeline of next 3–4 blocks. **Free time gaps are collapsed into a single dashed row** ("ว่าง 1 ชม. 30 น.") — do not draw proportional empty space.
5. Bottom quick-add bar: text input "งานอะไรเข้ามา", mic button (disabled/hidden until voice is built), primary "+" button.
6. Optional "ดูทั้งวัน" link if more than 4 upcoming blocks.

### 7.2 Add task (manual first)
MVP form fields: title (text), duration (chips 15/30/60/90 + custom), deadline (chips: today evening / tomorrow / pick date). No priority picker in the UI.
Later (AI phase): a single text field that pre-fills these same fields, each editable via a pencil icon; the duration guess is labelled "เดา" (guess). **The manual form is the fallback and the edit UI — keep it.**

### 7.3 Urgent re-plan confirmation
- Header "จัดตารางใหม่แล้ว"; reassurance line "ทันแน่นอน" (only when nothing overflows).
- Show **only what changed**: added block (highlighted) and moved blocks ("13:00 → 15:00"). Unchanged blocks are not listed.
- Link "ทำไมจัดแบบนี้" opens a short explanation (which blocks moved and why: deadline / lock).
- One primary button "ตกลง". After confirming, show an **undo bar "เลิกทำ"** for a few seconds.
- If overflow: calm message, e.g. "เวลาไม่พอก่อนเดดไลน์ — ขยับเดดไลน์ หรือลดเวลางานอื่น?" with 2 clear options. Never use red or blame language.

### 7.4 Tone rules
- Missed or late tasks roll forward automatically; never show "overdue" in red.
- Copy is short, kind, Thai. Avoid guilt words. Celebrate finished tasks lightly.

## 8. Design tokens (light theme, define as theme variables)

| Token | Value | Use |
|---|---|---|
| background | `#FBF6EC` | screen background (decided: cream, not pure white) |
| onBackground | `#3A2F2A` | main text |
| primary | `#4A7A58` | primary buttons (white text on it) |
| nowFill | `#FBE3D3` | "now" card fill |
| nowBorder | `#E0946F` | "now" card border |
| urgentAccent | `#D9743F` | urgent highlights — **border/tint only, never a filled button with white text** (contrast) |

- Text contrast must meet WCAG AA (4.5:1 for normal text). Re-check any new color pair.
- Dark theme (later): warm dark gray background around `#1F1B18`, off-white text, slightly lighter green/orange to keep contrast. Do not just invert colors.
- Never use red for urgency or errors in normal flows.

## 9. Notifications spec

- Local notifications only. Two kinds: block start, and X minutes before deadline (default 60).
- Whenever blocks change: cancel the old notifications for that block and schedule new ones; store `osNotifId`.
- iOS keeps roughly 64 pending local notifications at most: **schedule only the next 48 hours** and re-schedule every time the app opens.
- Ask for notification permission **after the first task is added**, not on first launch.
- Android: test on real devices from at least two brands (battery optimization and exact-alarm rules differ). Reliability of notifications is the top technical risk — test it early.

## 10. Roadmap

**Week 1 — foundation**
- Day 1: project setup, SQLite schema + migrations, repositories (create/update/soft-delete/query by day), default Settings.
- Day 2: Home screen with mock data (now card, compact timeline, collapsed gaps).
- Day 3: manual add-task form + `schedule` function with the tests from 6.3.
- Day 4: local notifications (start + deadline), permission flow.
- Day 5: fixed blocks, edit/delete/complete; every change re-runs the scheduler and refreshes notifications.
- Day 6–7: real-device testing (2+ phones), midnight/timezone cases, notification-after-app-closed check, bug buffer.

Week 1 pass criteria: add 5 tasks and see them placed correctly; notifications fire on time with the app closed; overflow shows as "not enough time", never vanishes; scheduler tests all pass.

**Week 2 — the differentiator**
- `insertUrgent` + diff + confirmation screen + undo + "why" explanation.
- Mock paywall screen; minimal event tracking (see 12).
- First-run onboarding (short).

**Week 3 — polish + test**
- Warm visual polish and copy pass; performance and notification checks.
- Get an iOS build onto TestFlight (owner has no Mac → cloud CI such as Codemagic + Apple Developer Program). Start Apple Developer enrollment early.
- Release to 15 testers; measure against the gate in section 2.

**After the gate passes (not before)**
AI text parsing → voice input → optional login + cloud backup → Google Calendar sync → recurring tasks → real payments → dark theme → hand-drawn crayon style, characters, cosmetics.

## 11. Later: AI parsing (do not build yet)

- The scheduler stays algorithmic. AI only converts a sentence into `{title, durationMin, deadlineAt}` and pre-fills the manual form.
- Cost per parse is tiny (about 300 input + 60 output tokens); choose the model by **Thai accuracy, latency, reliability**, not lowest price.
- Never put an API key in the app. A tiny proxy server holds the key and rate-limits per device.
- Model selection method: run 30–50 realistic Thai sentences through 2–3 cheap models, compare correct-parse rate, pick the best, keep the model swappable.
- Sample test sentences (expected parse is title / duration / deadline):
  1. "ส่งสไลด์ให้ลูกค้าก่อนสี่โมง" → ส่งสไลด์ให้ลูกค้า / 45 นาที (guess) / วันนี้ 16:00
  2. "ประชุมกับลูกค้าสี่โมงเย็นวันศุกร์" → fixed block Fri 16:00
  3. "ส่งงานพรุ่งนี้บ่ายสอง" → deadline tomorrow 14:00
  4. "ตอบอีเมลครึ่งชั่วโมง" → 30 นาที, no deadline
  5. "ทุ่มนึงโทรหาแม่" → today 19:00
  6. "อ่านเอกสารสองชั่วโมงก่อนเที่ยงพรุ่งนี้" → 120 นาที, deadline tomorrow 12:00
- Voice: try the phone's built-in speech recognition first (free); test Thai accuracy before paying for a service.

## 12. Metrics (minimal)

Track at least: first-open time, time to first task, tasks added, urgent re-plan taps, re-plan confirmed vs cancelled, undo taps, days active, mock paywall views and taps.
**Open decision:** how to collect these from testers without a backend (simple exported log vs a light analytics SDK). Decide before Week 2.

## 13. Working rules for AI assistants

1. Read this file first every session. If unsure, ask instead of guessing.
2. One small task per request (e.g. "build Home screen from mock data"). Never "build the whole app".
3. Only one tool edits the code at a time (Antigravity / Gemini / ChatGPT / Claude — no parallel edits).
4. Commit to git after every working step, with a clear message, so changes can be rolled back.
5. Do not add features, packages, accounts, or backend beyond this plan.
6. The scheduler must have tests and must stay a pure function.
7. Review carefully by hand: time and timezone code, notification code, anything touching the DB schema.
8. No hardcoded colors/text styles; use theme tokens.
9. State assumptions explicitly when the spec is silent.

## 14. Risks and open decisions

- **Tester devices:** most planned testers use iPhone, but the MVP is Android first. Either recruit ~10 Android testers or get the iOS TestFlight build working before Week 3.
- iOS without a Mac: needs cloud CI + Apple Developer Program; debugging iOS-only bugs is harder. Add crash/log reporting early.
- Notification reliability on Android OEMs and iOS limits.
- Thai voice accuracy (unknown until tested).
- AI cost/proxy needed later (breaks the "local only" simplicity).
- Store fees: Apple Small Business Program must be enrolled manually; Google Play fee structure changed in 2026 — check official docs before modelling profit.
- Undecided: app name, analytics method. (Decided: cream background.)
