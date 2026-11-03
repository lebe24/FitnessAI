# Workout Timer & Pacing Analysis — Plan

> When a workout starts, offer to **monitor the time**. If the user agrees, run an
> overall workout timer and a timer for each exercise, show them on the workout
> list and exercise pages, record the real times when the workout is saved, and
> finish with an AI analysis of the **overall time and each exercise's time**.

**Status:** Built on branch `workout-timer` (2026-11-01), then **removed from the code on 2026-11-02** because it did not work on a real device. The code is saved in `~/Documents/Developer/backups/befit-workout-timer-2026-11-02/` (see its README). This plan and the "What was built" section remain as the design record.
**Owner:** the user (project owner)
**Last updated:** 2026-11-02

---

## 1. Goal and scope

The flow, as requested:

1. The user taps **Start Workout** and lands on the list of exercises
   (`WorkoutPage`). A **prompt** asks whether to **monitor the time** of the
   workout, with two choices: **Monitor** or **Skip**.
2. **Monitor** starts a **general (overall) timer** for the whole workout.
3. When the user opens a specific exercise to log it, a **timer for that
   exercise** starts. It stops **only when the user taps Mark Complete** on the
   exercise page, and that time is logged with the exercise.
4. A **timer display** appears on the list page (overall timer and one per
   exercise).
5. When the overall workout is done, the app **runs an analysis of the overall
   time and each exercise's time**, at the end of the workout session.

**Not in the first release:** a rest timer between *sets*, lock-screen / Dynamic
Island timers, Apple Watch, spoken announcements, and per-set timing. See
section 15.

### The three user flows

**Start.** Start Workout → workout list → "Track your workout time?" →
**Monitor** (timer starts, header shows it running) or **Skip** (no time is
recorded at all).

**Do an exercise.** Tap the exercise → its timer starts and shows on the page →
log sets → **Mark Complete** → timer stops, the time appears on that exercise's
row in the list, and the overall timer keeps running.

**Finish.** Last exercise completed → overall timer stops → a short
"Workout complete" summary (total time, time per exercise) → analysis sheet
including a **Timing** section → streak updates as today.

---

## 2. How a workout finishes today

Reading the current code shows why this feature is worth doing: the numbers the
analysis uses are typed in by hand or guessed.

| Today | Problem | What the timer changes |
|---|---|---|
| After the last exercise a dialog asks the user to **type the workout's duration** in minutes | Relies on memory. The Stats screen's "Total Time" card carries a *"Tap to improve accuracy…"* prompt, a sign this number is not trusted | The duration is **measured** |
| A second dialog asks for **average rest in seconds**, prefilled with "average time between exercise completions" | That figure is exercise time **plus** rest, so it overstates rest. A 6-minute exercise with 1 minute of rest reads as 7 minutes of "rest" | Rest is measured as the real gap **between** exercises |
| Logging an exercise from its page saves a one-exercise session with **`durationMins: 0`** | Zero-minute sessions drag every duration average down | The measured exercise time is saved |
| The AI session analysis receives only `duration_mins` and `avg_rest_secs` | It can't say *which* exercise was slow | It receives per-exercise times and computed metrics |
| An exercise can be ticked off from the list without opening it | Nothing is known about it | Marked "not timed" and left out of timing stats |

---

## 3. Behaviour spec

### 3.1 Timers

| Timer | Starts when | Pauses when | Stops when |
|---|---|---|---|
| **Overall** | The user taps **Monitor** on the prompt | The user taps Pause on the list page | The last exercise is completed, or the user taps **Finish workout** early |
| **Exercise** | The user **opens** that exercise (to log it) | The overall timer is paused (they pause together) | The user taps **Mark Complete** on the exercise page |

The exercise timer is a *part of* the overall one, so pausing the workout pauses
both, and the totals always reconcile.

### 3.2 Rules that keep the numbers honest

1. **Clock time, not tick counting.** Each timer stores *when it started* and
   *how long it was paused*. Elapsed = now − start − paused. That is why it stays
   correct when the phone locks, the app is backgrounded, or the app is killed
   and reopened (section 5).
2. **Only one exercise timer runs at a time.** The list already forces
   exercises in order ("Complete the previous exercise first"), which makes this
   natural.
3. **Leaving an exercise page without completing it** (back button) **does not
   stop its timer** — it stops only on Mark Complete, as requested. The list row
   shows it as *In progress* with a live time, so it is never invisible.
4. **Rest = the gap between exercises.** Time from one Mark Complete to the next
   exercise being opened is the transition/rest time. Time before the first
   exercise is "setup".
5. **A timer left running for too long is suspicious.** If one exercise timer
   passes a limit (suggested 20 minutes), the app asks "Still on this exercise?"
   and lets the user correct the finish time.
6. **Skip means the app records no time.** No timers run, and there are no
   per-exercise times and no rest figures. **At the end, the user can type
   their own total workout time**, and that number is what runs the analysis
   (overall time only; section 6.5). If they decline to enter one, the workout
   finishes with no duration (an unknown duration, never a recorded 0) and no
   analysis, as today.
7. **Past or future days are not timed.** The prompt only appears for today's
   workout. Backfilling an old day behaves like Skip: no timers, with the option
   to type a total at the end.
8. **The overall time is calculated with the exercise timers.** When the
   workout ends, the overall time is checked against the exercise times:
   overall active time = time inside exercises + gaps between exercises + setup
   (pauses excluded). The summary and the analysis use these reconciled figures,
   so the parts always add up to the whole. Any difference (for example, an
   exercise ticked off without timing) is shown as "not timed", never hidden.
9. **The analysis runs on the timing automatically** at the end of a monitored
   workout, using the overall time and every exercise's time (section 7).

### 3.3 States

Overall timer: `not started → running ⇄ paused → finished`.
Each exercise: `not timed → in progress → completed` (or `completed, not timed`
when ticked off from the list without opening).

---

## 4. Decisions to make before building

Recommended answers shown. The open ones were confirmed on 2026-11-01; see
section 4a.

| # | Decision | Options | Recommendation | Why |
|---|---|---|---|---|
| D1 | What **Skip** does | no timers at all · overall only | **No timers; the user can type their own total at the end** — **confirmed** | Matches "monitor or skip" as one choice, and keeps skip simple |
| D2 | Leaving an exercise page without completing | keep timer running · pause · stop | **Keep running** (your spec), shown as *In progress*, plus the 20-minute check-in | It follows your rule that only Mark Complete stops it |
| D3 | Exercise ticked off from the list without opening | time it from the last completion · mark "not timed" | **Not timed** | Any guess would be invented data |
| D4 | End of the overall timer | stops on the last Mark Complete · user taps Finish | **Both:** auto-stop on the last exercise, and a Finish button for ending early | Matches "when the overall workout is done" and covers a cut-short session |
| D5 | Pause | no · yes | **Yes**, on the list page | Phone calls and gym queues are real; pausing keeps rest honest |
| D6 | Ask every time? | always ask · remember the choice | **Ask, with a setting** in Profile: *Ask each time / Always monitor / Never* | A prompt on every workout becomes friction fast |
| D7 | Where analysis numbers come from | the AI computes them · code computes them, AI explains | **Code computes the numbers; the AI explains them** | Arithmetic must be exact; the model should interpret |
| D8 | Where timing is stored | new table · inside what exists | **Inside what exists** (session times + a field per exercise entry) | No database migration needed (section 5) |
| D9 | Free or paid | gated · free | **Free**, like today's session analysis | No new per-use cost beyond the analysis that already exists |

### 4a. Decisions confirmed (2026-11-01)

| # | Decision | Outcome |
|---|---|---|
| D1 | **Skip** | The app records **no time**: no timers, no per-exercise times, no rest figure. At the end the user can **type their own total time**, and that number **runs the analysis** (overall time only) |
| D2 | Leaving an exercise page without completing | Timer **keeps running**; the row shows *In progress*, with the 20-minute check-in |
| D3 | Exercise ticked off from the list | **Not timed** |
| D4 | Pause | **Yes**, on the overall timer; it pauses the active exercise timer too |
| D5 | Ask every time | **Yes**, with a Profile setting: *Ask each time / Always monitor / Never* |
| D6 | End of the overall timer | **Stops** on the last Mark Complete (and via **Finish workout** for ending early). The overall time is **calculated together with the exercise timers** (rule 8), and the **AI then runs its analysis on that timing** |

What these change in the plan:

- **Skip + your own time.** A skipped workout ends with one question, "How long
  was your workout?". The typed number is saved as the duration and runs the
  analysis, with no per-exercise breakdown (steps 6, 7, 9, 10).
- **Typed minutes are not timer data.** They count toward Total Time, but the
  session has no per-exercise times, which is also how the app tells a typed
  duration from a measured one (no extra column needed).
- **Declining to type a time** saves no duration (never 0) and runs no
  analysis, so Stats must treat a missing or zero duration as *unknown*
  (steps 7 and 11).
- **The typed average-rest dialog is retired** for everyone. Its suggested value
  was misleading (section 2), and the measured gaps replace it for monitored
  workouts. Skipped workouts are asked for the total time only.
- **Monitored workouts** gain the reconciliation check (steps 6 and 8).

---

## 5. Architecture and data

### 5.1 Pieces

```
WorkoutPage (list)
  ├─ prompt sheet: Monitor / Skip
  ├─ WorkoutTimer  (overall: start time, paused total, state)
  ├─ ExerciseTimers (one record per exercise: opened at, completed at, paused)
  └─ header chip + per-row chips

ExerciseHeroPage ── opens an exercise → ExerciseTimers.start(i)
                 └─ Mark Complete    → ExerciseTimers.stop(i)

Finish → WorkoutTiming (all of the above) ──► save session ──► analysis request
```

A single small **timing service** owns the rules in section 3 so the pages only
display state. It reads the clock through an interface, so tests can move time
forward without waiting.

### 5.2 The timing record

**ExerciseTiming**, one per exercise: name, order, `openedAt`, `completedAt`,
`pausedSeconds`, `activeSeconds` (computed), `restBeforeSeconds` (computed), and
a flag for "completed but not timed".

**WorkoutTiming**, one per workout: `monitored` (true/false), `startedAt`,
`endedAt`, `pausedSeconds`, `state`, plus its list of exercise timings.

### 5.3 Surviving the app being closed

The workout already keeps a **draft** (completed exercises, order, logged sets,
completion times) so progress survives a kill. The timing state is added to the
same draft:

- Written only when something *happens* (start, pause, resume, open, complete),
  never every second.
- On reopening the workout, the draft restores the timers and they continue
  correctly from the clock.
- Drafts without timing (older versions) load as "not monitored".

### 5.4 What gets saved

No database migration is needed:

- **Session:** `duration_mins` from the measured active time (instead of the
  typed number, instead of 0), and the real start and end times. The table
  already has `started_at` and `completed_at`; today the server fills them with
  "now", so the app should send the real ones.
- **Per exercise:** the exercise entries are stored as JSON inside the session,
  so each can carry extra fields: `duration_sec` and `rest_before_sec`. The
  existing readers (volume, history, muscle map) ignore unknown fields.
- **Backend check:** the request models must be told about the new optional
  fields, otherwise they may be dropped on the way in. This is a small change but must
  not be forgotten (step 7).
- **Old app versions** keep working: the new fields are optional everywhere.

### 5.5 Time rules

- The workout's **date** is the date it *started*, so a session that runs past
  midnight stays on one day.
- Timers use elapsed durations, so a time-zone change or daylight-saving change
  mid-workout cannot corrupt them. If the device clock is changed manually
  during a workout, show a warning rather than trust the result.

---

## 6. UX spec

### 6.1 The prompt

A bottom sheet shown once on arrival at today's workout:

> **Track your workout time?**
> We'll time the whole workout and each exercise, then show you where the time
> went.
> **[ Monitor ]  [ Skip ]**
> *Skip: we won't time anything. You can enter your own total time at the end
> to get your analysis.*
> *(small link)* Change this in Profile

Not shown when: the workout already has timing in its draft (resume), the day is
not today, the preference is set to Always or Never, or the workout is finished.

### 6.2 Workout list page

- **Header:** a timer chip showing the overall time (`mm:ss`, then `h:mm:ss`),
  with **Pause / Resume** and, when appropriate, **Finish workout**. A paused
  workout looks different (dimmed chip, "Paused").
- **Each exercise row:** *done* → its time (`6:12`); *in progress* → a live
  ticking time with an "In progress" label; *upcoming* → no time; *completed
  without timing* → a dash.
- Only the visible chips update each second; nothing else rebuilds.

### 6.3 Exercise page

A small timer chip in the top bar (next to the exercise number) showing this
exercise's time, and the overall time in a smaller secondary style. **Mark
Complete** stops it, with the time shown briefly ("Pull-Ups · 6:12").

### 6.4 Finish summary

A short sheet before the analysis: total time, time spent exercising vs between
exercises, and the time for each exercise. A **Fix time** option lets the user
correct a mistake (for example, forgot to stop). Then **See analysis**.

**Skipped workouts** get a smaller prompt instead:

> **How long was your workout?**
> `[ minutes ]`  **[ Run analysis ]**  *Finish without a time*

Entering a time saves it as the workout's duration and runs the analysis. The
fallback *Finish without a time* saves nothing and runs no analysis. The streak
updates either way.

### 6.5 Analysis sheet

The existing analysis sheet gains a **Timing** section (section 7.4), in three
forms:

| Workout | Timing section |
|---|---|
| Monitored | Full: overall time, exercising vs between, each exercise, the gaps |
| Skipped, with a typed total | **Overall time only** and what it suggests; no per-exercise bars |
| Skipped, no time entered | No analysis is run |

### 6.6 Settings

Profile gets **Workout timer: Ask each time / Always monitor / Never**.

### 6.7 States to design for

First open with no draft; resumed after a kill; paused; very long exercise
(check-in); exercise ticked off from the list; exercise added or reordered
mid-workout; workout ended early; analysis fails (the summary still shows);
large text and VoiceOver (announce on demand, not every second).

---

## 7. Metrics and the AI analysis

### 7.1 Metrics computed in code (D7)

| Metric | Meaning |
|---|---|
| **Total time** | start to end |
| **Paused time** | time the workout was paused |
| **Active time** | total − paused |
| **Exercise time** | each exercise, from opened to Mark Complete, minus pauses |
| **Between-exercise time** | gaps between exercises; the first gap is "setup" |
| **Exercising share** | exercise time ÷ active time |
| **Seconds per set** | exercise time ÷ sets logged: one set's work **plus its rest** |
| **Outliers** | an exercise more than 2× the median of the others; a gap over 5 minutes |
| **Versus history** | total and per-exercise time against this user's recent sessions of the same day or focus, when enough history exists |

**An honest limit.** The timers measure *exercises* and the *gaps between
them*. They do **not** measure the rest between *sets* inside an exercise.
"Seconds per set" is a useful stand-in because it is work plus rest, but the
analysis must call it that and must not claim to know the exact rest between
sets.

### 7.2 What the AI receives

The metrics above (as a small table), the plan (exercises, sets, reps), the
workout focus, and the plan's own rest guideline (for example "90 seconds
between sets"). It is told to use **only these numbers** and not to invent
others.

### 7.3 Prompt contract

- Compare each exercise's time with the others and with the plan's rest
  guideline (using seconds per set).
- Judge the between-exercise gaps and the setup time.
- Say what the pattern suggests (long transitions, one slow exercise, speeding
  up or slowing down later in the session).
- Phrase findings as observations and suggestions, never as health claims.
- Return the existing fields (so older app versions keep working) **plus** a
  timing section.

### 7.4 Response additions

A timing block alongside the existing analysis, with: a one-sentence overall
pacing summary; a verdict per exercise (`longer than usual`, `typical`,
`shorter than usual`, or `not timed`) with a short reason; a verdict on the
between-exercise time; and one or two specific tips. The existing
`rest_feedback` is now based on measured gaps, not a typed number.

The numbers shown on screen come from **code**; only the wording comes from the
model.

### 7.5 When there is little data

With fewer than three timed exercises, or no history, the analysis says so and
keeps to observations about this session only.

With **only a typed total time**, the analysis uses that one number together
with the plan (how many exercises and sets, the focus) and the plan's rest
guideline. It makes no claim about individual exercises or the gaps between
them, because none were measured, and it does not use a rest figure at all.

---

## 8. Step-by-step build process

Branch: **`workout-timer`**, from `main` after `exercise-history` is merged
(the history feature will later show "last time: 6:12" on the exercise page).
Sizes are rough solo estimates.

### Step 0 — Sign off the spec *(done — see 4a)*
- **Goal:** settle D1–D9 and the wording of the prompt.
- **Done when:** the decisions are recorded in this doc. *(Done 2026-11-01.)*

### Step 1 — Timing model and clock rules *(M, 1.5 days)*
- **Goal:** the rules in section 3 exist as plain, testable code with no screens.
- **Do:** the `ExerciseTiming` / `WorkoutTiming` records and a timing service
  that applies the rules: start, pause, resume, open exercise, complete exercise,
  finish. The clock is injected so tests can fast-forward.
- **Touches:** new `lib/domain/models/workout_timing.dart`; new
  `lib/data/services/workout_log/workout_timer_service.dart`; one registration in
  `di.dart`.
- **Done when:** unit tests cover pause and resume totals, an exercise running
  while the workout pauses, back-out without completing, ticking off from the
  list, completing out of order after a reorder, a very long exercise, and a
  run across midnight.

### Step 2 — Persist in the workout draft *(S, 1 day)*
- **Goal:** timers survive a kill and a restart.
- **Do:** extend the existing draft with the timing state, backward-compatible
  with drafts that have none; save only on events; restore when the workout page
  reopens; discard a stale draft from a previous day.
- **Touches:** `workout_draft_storage.dart`; the draft handling in
  `workout_page.dart`.
- **Done when:** a test starts a workout, completes two exercises, simulates a
  restart, and the elapsed times continue correctly; an old draft loads without
  error.

### Step 3 — The Monitor / Skip prompt *(S, 1 day)*
- **Goal:** the question appears at the right moment, once.
- **Do:** a bottom sheet on arrival at today's workout, with the rules from
  section 6.1; the Profile setting (D6); remember the choice for that workout.
- **Touches:** the start of `workout_page.dart`; `profile_page.dart` (new row);
  a small preference store beside the other app settings.
- **Done when:** the prompt shows for today, not for a past day, not on resume,
  and not when the preference is Always or Never.

### Step 4 — Overall timer on the list page *(M, 1.5 days)*
- **Goal:** the running workout clock, with pause.
- **Do:** the header chip with Pause, Resume and Finish, driven by the service
  through one shared ticker so only the chip repaints. Paused and running
  appearances.
- **Touches:** `_WorkoutHeader` in `workout_page.dart`.
- **Done when:** the chip keeps correct time after backgrounding the app for
  several minutes, and pausing freezes both the overall and the active exercise
  timers.

### Step 5 — Exercise timers and the per-row display *(L, 2 days)*
- **Goal:** each exercise is timed from open to Mark Complete.
- **Do:** start the timer when the exercise page opens; stop it on Mark Complete;
  show the time on the exercise page and on the list row; handle back-out (shown
  as In progress), ticking off from the list (not timed), reorder and add;
  the 20-minute check-in.
- **Touches:** `exercise_hero_page.dart` (top bar chip), `_ExerciseItem` and the
  completion path in `workout_page.dart`.
- **Done when:** opening, leaving and returning to an exercise keeps one
  continuous time; completing stops it; the list row matches the page.

### Step 6 — Finish flow *(M, 1.5 days)*
- **Goal:** the end of the workout uses measured times.
- **Do:** when the last exercise is completed (or Finish is tapped), stop the
  timers and show the finish summary (section 6.4). For monitored workouts this
  **replaces** the typed-duration and typed-rest dialogs. Skipped workouts get
  the single "How long was your workout?" prompt (section 6.4) instead; the
  rest dialog is retired. Add the reconciliation check (rule 8) and **Fix
  time**.
- **Touches:** `_completeExercise`, `_showDurationDialog`, `_showRestTimeDialog`
  in `workout_page.dart`.
- **Done when:** a monitored workout never asks the user to type a duration or
  rest; a skipped workout asks only for the total time, and entering it runs
  the analysis; declining it saves no duration and runs no analysis; the
  summary's parts add up to the overall time in every test session.

### Step 7 — Save the real times *(M, 1.5 days)*
- **Goal:** the timing is stored with the session.
- **Do:** send the measured `duration_mins`, real start and end times, and each
  exercise's `duration_sec` and `rest_before_sec`. The exercise page's own save
  keeps sending `0` minutes (see "What changed" below: the server **adds** minutes
  per day, so sending any there would double-count). On the backend, add the
  optional fields to the request models and make sure they persist.
- **Touches:** `workout_log_remote_service.dart`; backend
  `src/routes/api/workout_logs.py` (new optional fields).
- **Skipped workouts:** if the user typed a total, send it as the duration
  (with no per-exercise times). If they declined, send **no** duration (not
  `0`). The backend currently defaults a missing duration to 0, so it must
  accept "none", and anything that averages durations must treat a missing or
  zero duration as *unknown*.
- **Done when:** a saved session round-trips with all times, an old app build
  still saves successfully, and the existing readers (volume, history, muscle
  map) are unaffected.

### Step 8 — Timing metrics *(M, 1.5 days)*
- **Goal:** the numbers in section 7.1 as tested code.
- **Do:** compute total, paused, active, per-exercise, between-exercise, shares,
  seconds per set, outliers, and the comparison with recent history. Provide a
  clear "not enough data" result.
- **Done when:** tests use hand-calculated sessions and match to the second,
  including a session with a not-timed exercise and a paused workout.

### Step 9 — Backend analysis *(M, 2 days)*
- **Goal:** the analysis uses the real timing.
- **Do:** extend the workout-session analysis request with the timing metrics and
  the plan's rest guideline; update the prompt and add the timing block to the
  response; keep every existing field; validate the shape; keep the old inputs
  working for old app versions. Also accept the **overall-time-only** request
  (a typed total, no timing block) and leave the rest figure out of the prompt
  instead of sending 0.
- **Touches:** `src/routes/api/analysis.py`, the session-analysis prompt, the
  response model, tests.
- **Done when:** with real timing the analysis names the slow exercise and the
  long gaps using the given numbers only; with only a typed total it comments
  on the overall time and makes no per-exercise claims; with an old-style
  request it still returns the existing fields.

### Step 10 — Timing section in the analysis sheet *(M, 1.5 days)*
- **Goal:** show where the time went.
- **Do:** a Timing section: overall time, exercising vs between split, a simple
  bar per exercise with its verdict, the gap verdict and the tips. For a typed
  total only, show just the overall time and its comment.
- **Touches:** `_WorkoutAnalysisSheet` and the analysis response parsing in
  `workout_session_analysis_service.dart`.
- **Done when:** the sheet renders a normal session, a session with a not-timed
  exercise, and a skipped workout with a typed total correctly.

### Step 11 — Use the new data elsewhere *(M, 1.5 days)*
- **Goal:** the timer improves the rest of the app.
- **Do:** show last time's duration on the exercise page's History entries; make
  the Stats screen's **Total Time** use the measured durations; show durations
  in the workout history list.
- **Typed totals** count toward Total Time (they are the user's own figure).
  Sessions with **no** duration are left out of Total Time and averages rather
  than counted as zero.
- **Done when:** the "Tap to improve accuracy…" warning stops appearing for
  users whose sessions were timed, and skipped sessions no longer pull the
  averages down.

### Step 12 — Polish and settings *(S, 1 day)*
- **Goal:** it feels finished.
- **Do:** haptics on start, pause and complete; light and dark; large text and
  VoiceOver (announce on demand); an optional local reminder if a timer has run
  for a very long time while the app is closed.
- **Done when:** the accessibility review is clean.

### Step 13 — Analytics events *(S, 0.5 day)*
- **Goal:** see whether people use it.
- **Do:** the events in section 11; update `analytics-insights.md`.
- **Done when:** a funnel from prompt shown → Monitor chosen → workout finished
  can be built.

### Step 14 — Test matrix *(M, 1.5 days)*
- **Goal:** the times are correct in real use.
- **Do:** the scenarios in section 13, compared with a real stopwatch.
- **Done when:** the timer is within one second of the stopwatch over a 30-minute
  workout, including a background period, a pause and a restart.

### Step 15 — Release *(S, 0.5 day)*
- **Do:** ship in a TestFlight build; watch for timing bugs and analysis failures;
  then release.

**Rough total:** about **20 working days** (4 weeks solo). Steps 1–6 give a working timer on
their own; the analysis (steps 8–10) follows.

---

## 9. Backend contract (summary)

- **Workout save** (existing endpoint): new optional fields — session start and
  end times, and per exercise `duration_sec` and `rest_before_sec`. The server
  should sanity-check them (end after start, nothing negative, nothing
  implausibly long) and fall back to "now" if they are missing.
- **Analysis** (`POST /api/v1/analysis/workout-session`): new optional timing
  input and a timing block in the response; **all existing fields stay**, so
  older app versions are unaffected.
- **Errors:** invalid timing is ignored for the analysis rather than rejecting
  the whole request — the user should still get their analysis.

---

## 10. Edge cases

| Situation | Behaviour |
|---|---|
| Phone locks or the app is backgrounded | Nothing to do; time is computed from the clock when the app returns |
| App is killed mid-workout | Timers restore from the draft and continue correctly |
| User leaves an exercise page without completing | Timer keeps running; row shows *In progress* |
| Exercise left running for 20+ minutes | "Still on this exercise?" with a chance to correct the finish time |
| Exercise ticked off from the list | "Not timed"; excluded from timing stats |
| Exercise added or reordered mid-workout | A new timing slot is created; the data follows the exercise, not its position |
| Workout cut short | **Finish workout** ends it; untimed or unstarted exercises are simply absent |
| Past or future day | No prompt; behaves like Skip (optional typed total at the end) |
| Passes midnight | Dated by its start |
| Time-zone or daylight-saving change | Unaffected (elapsed durations) |
| Device clock changed by hand | Warn; do not silently accept an impossible result |
| Skip chosen | No timers or per-exercise times. At the end: "How long was your workout?" — a typed total runs the analysis; declining saves no duration and runs no analysis |
| Analysis request fails | The finish summary still shows; the analysis can be retried |
| Offline at the end | Save locally as the draft does today, and sync as other data does |

---

## 11. Analytics events to add

Following the existing conventions (names in `analytics_events.dart`, no
personal data):

`timer_prompt_shown` · `timer_choice` (`monitor` | `skip`, `remembered`) ·
`workout_timer_paused` · `workout_timer_resumed` · `exercise_timer_completed`
(`duration_s`, bucketed) · `workout_finished` (`total_s`, `exercises_timed`,
`ended_early`) · `timer_check_in_shown` ·
`timing_analysis_viewed` · `manual_duration_entered` (`minutes`, bucketed) ·
`manual_duration_declined`.

---

## 12. Privacy

Timing is workout data of the same kind already stored (dates, durations, sets).
It is saved with the session and covered by the existing policy wording on what
you log. No new category is collected, so no new App Privacy answer is needed.
Add the new events to the "usage data" description only if they carry anything
beyond counts.

---

## 13. Test plan

- **Unit:** the timing rules (step 1), metrics (step 8), draft persistence
  (step 2), and the save payload (step 7).
- **Widget:** the prompt, the header chip, the row chips, the finish summary and
  the Timing section.
- **Backend:** accepts and persists the new fields; rejects nonsense; old-style
  requests still work; analysis uses only the supplied numbers.
- **Real-device scenarios:** a 30-minute workout checked against a stopwatch;
  background for 30 minutes; pause for 5 minutes; kill and reopen mid-exercise;
  reorder and add mid-workout; a workout across midnight; low-power mode; a
  large-text setting.

---

## 14. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Timers drift or lose time in the background | Use clock timestamps, never tick counts |
| Users forget to stop an exercise | 20-minute check-in and **Fix time** |
| The prompt becomes annoying | The Profile setting and remembering the choice |
| The AI misreads timing (treats a gap as rest between sets) | Code computes the numbers, the prompt states what each number means, and the "honest limit" in 7.1 is enforced in the prompt |
| Old app versions break after the backend change | All new fields optional; old inputs still accepted |
| Time shown while the exercise page covers the list gets stale | Single shared ticker; chips read from the service |
| Measured durations disagree with old typed ones in history | Only new sessions carry exercise times; mixed history is handled as "not timed" |

---

## 15. Later phases

- **Rest timer between sets** with auto-start, a countdown and haptics, which
  would finally measure the rest the current design can only infer.
- **Lock-screen Live Activity / Dynamic Island** showing the running workout.
- **Apple Watch** companion.
- **Per-set timing** for tempo and time-under-tension.
- **Spoken announcements** ("two minutes rest left").

---

## 16. Open questions

**None.** All questions are answered (section 4a). Two points were my
interpretation of your answers and are worth a glance before building:

1. **Skip + typed time:** I read "allow the user to input his own timer as the
   end to run the analysis" as: the user types their *total* workout time at the
   end of a skipped workout, and that runs the analysis (overall time only). If
   they decline, no analysis runs, as today.
2. **Rest dialog retired:** the typed average-rest question goes away for
   everyone, since its suggested value was misleading. Skipped workouts are
   asked for the total time only.

---

## 17. What was built, and what changed

Everything in steps 1–11 and 13 is built; steps 12 (polish), 14 (stopwatch test
matrix) and 15 (release) remain. These are the places the build departed from, or
learned something the plan didn't know.

**The server adds minutes, per day.** `POST /logs/sessions/complete` keeps one
session per user and date, appends the new `workout_logs`, and **adds**
`duration_mins`. So the exercise page's own save must keep sending `0` minutes,
and each exercise's time travels as `duration_sec` on the entry written when the
workout is completed — never as session minutes. `duration_mins` in the database
is a non-null integer defaulting to 0, so **0 means unknown** everywhere.

**The sets and the time are on different rows.** Sets are saved by the exercise
page when the exercise is logged; the time is saved with the completion save. The
exercise history therefore matches the two by exercise name within a session
rather than reading both from one row.

**Skip.** Skip records nothing. At the end the user can type a total, which saves
that duration and runs the analysis on the overall time only, or choose *Finish
without a time*, which saves with 0 minutes and runs no analysis. The old rest
dialog is gone: for a timed workout the gaps are measured, and for an untimed one
there is nothing to ask.

**A Save button is always available.** Once every exercise is done, or a timed
workout was ended early, a *Save workout* bar stays on the list until the workout
is saved. This also fixes a dead end that existed before: cancelling the time
dialog used to leave a finished workout with no way to save it.

**Ending early** saves only the exercises that were completed.

**Wall-clock arithmetic.** Times are computed from timestamps, not by counting
ticks, so a backgrounded or killed app loses nothing. Pauses and corrections are
merged before they are subtracted, so time that is both paused and trimmed is only
removed once.

**Server checks.** The server now accepts `started_at` and `completed_at` and uses
them only when plausible (end not in the future or older than 36 hours, start
before the end by less than a day); otherwise it keeps its own clock. A second
save on the same day widens the window. Per-exercise `duration_sec` and
`rest_before_sec` are range-checked (0 to 24 hours) and omitted from the stored
entry when not measured, so untimed workouts keep exactly their old shape.

**Analysis.** The request gained an optional `timing` object made only of numbers
and fixed labels (the pace labels are a closed set, so free text can't ride in on
it) and `avg_rest_secs` became optional. The response gained an optional
`timing_analysis` block (summary, notes on exercises that ran long or short, gap
feedback, tips). The app does all the arithmetic and comparisons; the model only
explains them. Old clients and old responses both still work.

**Bug found while testing.** The Monitor / Skip sheet was capped at 9/16 of the
screen height and overflowed on small phones. It is now scroll-controlled.

### Tests

- App: timing rules, draft persistence, preference and prompt decisions, metrics,
  analytics, history matching, the timer widgets, and a flow test that drives the
  real workout page (prompt → timing → finish → save → analysis, ending early,
  failed save, Skip, and typing a total).
- Backend: entry shape, request validation, timing text for the prompt, the prompt
  and its JSON schema, and the plausibility checks.
- Not yet tested: a real stopwatch comparison over a 30-minute workout (step 14).
  The flow test cannot open the exercise page, so per-exercise timing through the
  real page needs a pass on a device.

### Still to do

- Deploy the backend (not yet deployed since the greenlet fix; services need a
  rebuild and `gcloud run services replace`).
- Step 12: haptics on start and complete, VoiceOver pass, large text.
- Step 14: the stopwatch comparison on a device.
- Optionally pass the person's usual total (`typicalTotal`) from history so the
  analysis can compare against it; the plumbing exists, the app doesn't send it yet.

