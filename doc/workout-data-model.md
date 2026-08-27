# Workout session data — analysis and proposed model

Based on an export of 9 real sessions (`workout_sessions_rows.csv`).

## What the data looks like today

Everything a session records lives in one JSONB column, `workout_sessions.workout_logs`.

```
id, user_id, workout_plan_id, session_date, day_label, duration_mins,
is_completed, notes, started_at, completed_at, workout_logs, feedback
```

### 1. The column holds two different things at once

Of 75 entries across the 9 sessions:

| | count |
|---|---|
| entries carrying **set data** (what was performed) | 39 |
| entries carrying **coaching text** (what was prescribed) | 36 |
| duplicate exercise names within a single session | 28 |

The same exercise appears twice — once as the plan, once as the record — and
nothing in the row distinguishes them except whether `notes` happens to start
with `set 1:`. "lat pulldown" is two entries; so is every other exercise.

### 2. Set data is free text

All **147 set records** are encoded as a string:

```
"set 1: 10 reps @ 113kg | set 2: 10 reps @ 107kg | set 3: 14 reps @ 93kg"
```

To answer "what did I lift last week" the app has to parse prose. Nothing
prevents a malformed value being written, and nothing can index it.

### 3. `order_index` does not order anything

Every *performed* entry has `order_index: 0`. Only the *planned* entries are
numbered 0..n. Exercise order for what actually happened is lost — the array
order is all there is.

### 4. `reps` means four different things

| meaning | count | examples |
|---|---|---|
| range | 52 | `8–12`, `10-15` |
| fixed count | 15 | `12`, `15` |
| per-side count | 6 | `10 per leg`, `15 each side` |
| **a duration, not reps** | 2 | `30 sec` |

En-dash and hyphen are both used — 34 and 20 occurrences — in the same field.

### 5. Fields that are never populated

- `workout_plan_id` — **null in all 9 rows**, so no session is linked to the
  plan that produced it
- `notes` — null in all 9 rows
- `equipment`, `muscle_group` — null on every entry, though the muscle groups
  are sitting in the notes text (`"shoulders, upper back | Focus on ..."`)
- `feedback` — `{}` on 4 of 9

### 6. Integrity problems

- 4 sessions are `is_completed = true` with `duration_mins = 0`
- `day_label` blank on 4 of 9 while `session_date` is always present — it is
  derivable, so it should not be stored separately and allowed to disagree
- Outliers no constraint would have caught: `115 reps @ 22kg` (a typo for 15),
  `20 reps @ 190kg` on a dumbbell shrug

### 7. There is already a table for this

`exercise_logs` exists — `exercise_name`, `muscle_group`, `equipment`,
`order_index`, a `sets` JSONB, `total_sets`, `completed_sets`,
`total_volume_kg` — and **nothing writes to it**. The right shape was designed
and then bypassed.

---

## Proposed model

Three tables, splitting **prescription** from **performance**, and making a set
a row rather than a substring.

```
workout_sessions          one per training day
   └── session_exercises  one per exercise in that session
          └── exercise_sets   one per set performed
```

### `workout_sessions` — keep, minus what belongs elsewhere

| column | type | note |
|---|---|---|
| `id` | uuid pk | |
| `user_id` | uuid fk | |
| `workout_plan_id` | uuid fk | **populate it** — currently always null |
| `session_date` | date | |
| `started_at` / `completed_at` | timestamptz | |
| `duration_mins` | int | derive from the timestamps; stop storing 0 |
| `is_completed` | bool | |
| `notes` | text | the user's own note |
| `feedback` | jsonb | AI output, write-once, read whole — fine as JSONB |

Drop `day_label` (derivable from `session_date`) and `workout_logs`.

### `session_exercises` — what was asked for

| column | type | note |
|---|---|---|
| `id` | uuid pk | |
| `session_id` | uuid fk → sessions | `on delete cascade` |
| `order_index` | int | **not null** — position in the session |
| `exercise_name` | text | |
| `muscle_group` | text | currently buried in notes text |
| `equipment` | text | |
| `prescribed_sets` | int | |
| `prescribed_reps_min` / `_max` | int | a range becomes two columns |
| `prescribed_duration_sec` | int | for holds — planks, not reps |
| `is_per_side` | bool | "10 per leg" is not 10 reps |
| `coaching_cue` | text | "Keep your elbows high." |

`unique (session_id, order_index)` stops the duplication above.

### `exercise_sets` — what actually happened

| column | type | note |
|---|---|---|
| `id` | uuid pk | |
| `session_exercise_id` | uuid fk | `on delete cascade` |
| `set_number` | int | |
| `reps` | int | null for a timed hold |
| `duration_sec` | int | null for a rep set |
| `weight_kg` | numeric(6,2) | null for bodyweight |
| `is_completed` | bool | a logged 0-rep set is a skipped set |

`unique (session_exercise_id, set_number)`, plus
`check (reps is not null or duration_sec is not null)`.

**Volume, total sets and completed sets stop being stored.** They are
`sum(reps × weight_kg)` over this table — derive them in a view so they cannot
drift from the sets they summarise.

---

## What this buys

Queries that are impossible against the blob today, and one line each after:

- volume per session, per week, per muscle group
- estimated 1RM and best set per exercise over time
- "am I progressing on bench press" — a chart, not a text search
- adherence: prescribed sets vs completed sets
- the AI coach reading structured history instead of re-parsing prose

Computed from the export, to show the data is already there:

| date | exercises | sets | volume |
|---|---|---|---|
| 2026-08-15 | 7 | 26 | 12,278 kg |
| 2026-08-18 | 5 | 18 | 39,030 kg |
| 2026-08-21 | 7 | 20 | 21,280 kg |
| 2026-08-25 | 6 | 18 | 26,306 kg |

---

## Migrating

The existing rows are recoverable. A parser written against this export
converted **147 of 147 set records (100%)**, including the awkward ones —
`30 sec`, `10 per leg`, `8–10`, and `10each side` with the missing space.

Suggested order, so nothing is lost and nothing breaks at once:

1. Add the two tables. Leave `workout_logs` in place.
2. Backfill from `workout_logs` with the parser; keep the original column as
   the source of truth until the counts agree.
3. Write to both for one release.
4. Move reads over — analytics first, since it benefits most.
5. Drop `workout_logs` once a release has shipped with nothing reading it.

Step 2 is reversible at every point, which matters because this is the user's
training history: it cannot be regenerated if it is lost.
