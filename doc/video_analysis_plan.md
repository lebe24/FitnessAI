# Workout Video Log & AI Form Analysis — Plan

> Let users save workout videos against a specific exercise, optionally have AI
> rate their **stance, form and tempo**, and browse their video history from the
> **Muscles trained** section of Analytics.

**Status:** Built (code, tests, backend) on 2026-11-02 — **not yet run on a device or against real clips**. See sections 17 and 18.
**Owner:** —
**Last updated:** 2026-11-02
**Supersedes:** the 2026-07-06 version (upload-only analyzer). Sections carried
forward from it are marked *(carried forward)*; the rest were rewritten after
testing the approach on a real gym clip (section 2).

---

## 1. Goal and scope

Three capabilities, built in this order:

1. **Per-exercise video log.** On the exercise page (`ExerciseHeroPage`, the
   screen for one exercise in a workout) add a **My Videos** section. The user
   records or picks a video, saves it against that exercise, and can add as many
   as they like. Each video can be played back and deleted.
2. **Optional AI form analysis, per video.** Tap **Analyse** on any saved video.
   The AI returns an overall **rating out of 10** with separate **stance**,
   **form** and **tempo** scores, a rep count, what was good, what to fix, and
   what it could *not* judge from the camera angle.
3. **Video history by muscle.** In Analytics → **Muscles trained** → tap a
   muscle → a **My Videos** section lists every saved video for that muscle,
   newest first, with ratings and the trend.

**Not in the first release:** live real-time coaching (Phase 2, section 15),
sharing or social features, video editing beyond trimming, cloud backup
(Phase 1b), and anything that reads as medical advice.

### The three user flows

**Save a video.** Exercise page → My Videos → Add → Record or Choose from
library → trim if longer than 60 s → Save. The video appears in the list with a
thumbnail, date and length.

**Analyse a video.** My Videos → a video → Analyse → short wait with progress →
result sheet: rating, stance / form / tempo, cues, limits. The result is stored
with the video, so reopening it is instant and free.

**Review by muscle.** Stats → Muscles trained → tap a muscle → My Videos →
tap a video to play it or reopen its analysis.

---

## 2. What the real test clip taught us

The approach was tested by hand on a real gym clip (`IMG_1294.MOV`): 2 min 28 s,
1080×1920 HEVC, **244 MB**, deadlifts filmed from behind at floor level. Stills
were pulled at 2 s, 0.5 s and 0.1 s steps and judged as the AI would. Every
finding below changes the design.

| What the clip showed | What it means for the feature |
|---|---|
| The whole pull lasts **about 0.5 s** inside a 2.5-minute clip | Evenly spaced frames (the old "6–10 keyframes") would miss the lift. Sampling must find the motion and sample finely there (section 5). |
| Most of the clip is **idle**: setup, resting, 10–11 s hinged over the bar | Detect the active segments and ignore the rest. Don't pay to analyse standing around. |
| **244 MB** for 2.5 minutes | Never upload video. Cap length, compress before saving, and send only still frames. |
| The lifter is only ~15 % of the frame | Crop to the person before encoding. A crop gave far more usable detail than the full frame. |
| **Other people** are in the shot (someone squatting in the rack) | The app must pick the right subject, and the privacy notice must mention bystanders. |
| Shot from **behind**: spine, bar path and knees can't be judged | Detect the camera view. When it's poor, say so and lower confidence instead of guessing. Coach people to film side-on **before** they record. |
| A big plate blocks the lower-left of the frame | Framing guide: keep the foreground clear. |
| **3 clean reps, then a 4th attempt where the bar never left the floor** | The analysis must report attempts as well as reps, and allow "incomplete rep". |
| The bar drops in under a second; reps are dead-stop with a 2–3 s reset | Tempo is worth scoring on its own, and the model needs timestamps to see it. |

**Success test for the whole feature:** given this clip, the system should name
the exercise as a deadlift, count 3 reps plus 1 failed attempt, report "rear
view: low confidence on spine and bar path", and flag the fast, uncontrolled
descent.

---

## 3. Decisions to make before building

Recommended answers are shown. Anything marked **needs your call** is also
listed in section 16.

| # | Decision | Options | Recommendation | Why |
|---|---|---|---|---|
| D1 | Where the video files live | A. on device only · B. cloud · C. device first, optional cloud backup later | **C.** Phase 1 stores on the device; backup comes in Phase 1b | Matches the privacy policy (progress photos stay on the device), costs nothing, no moderation burden. The trade-off: videos don't follow the user to a new phone until Phase 1b. |
| D2 | What the AI receives | whole video · still frames | **Still frames** chosen on the device | The models take images, not video. Uploading video is slow and expensive. |
| D3 | Which frames | evenly spaced · motion-based | **Motion-based** (section 5) | Evenly spaced frames missed the 0.5 s pull in the test. |
| D4 | Model | GPT-6 Luna · GPT-6.1 Sol | **Run both on the labelled test set (step 14), then pick.** Make it an env setting (`OPENAI_FORM_MODEL`). Default to Sol if Luna's quality gap is visible. | Both accept images and are available on the account. Sol costs about 20× more, so it must earn it. |
| D5 | Length limits | — | Save ≤ **60 s**; analyse ≤ **30 s** of active motion; store at ≤ 720p | The test clip was 148 s and 244 MB. |
| D6 | Paywall | all free · analysis premium | **Saving and playing free; analysis premium** with a fair-use cap (about 30 / month) | Analysis is the only part that costs money per use. Fits the existing `PremiumFeature` pattern. |
| D7 | Exercises supported first | all · a few | **Squat, deadlift, bench press, push-up.** Anything else gets a generic analysis with lower confidence. | Clear failure modes. The prompt can be tuned for each. |
| D8 | How a video maps to muscles | recompute each time · save at record time | **Save at record time**, using the same logic as the muscle map | History queries stay simple, and old videos don't shift if the logic changes. |

---

## 4. Architecture

### Data flow

```
EXERCISE PAGE  (ExerciseHeroPage → "My Videos")
  record / choose → trim ≤ 60 s → compress ≤ 720p
        → save file + thumbnail → index entry (muscles resolved now)

  tap "Analyse"
        → on-device sampler: find motion, pick 8–12 frames, crop to subject
        → POST /api/v1/analysis/form   (frames + exercise name; never the video)
                │
                ▼
          BACKEND (FastAPI)
          validate → vision model → check JSON schema → log token cost
                │
        ◄───────┘  FormAnalysis JSON
        → stored with the video → result sheet

ANALYTICS → Muscles trained → muscle detail → "My Videos"
        → reads the on-device index by muscle (no network)
```

### Data model (design level)

**ExerciseVideo** — one record per saved video:

- `id`, `recordedAt`, `durationSec`, `sizeBytes`
- `exerciseName` and `exerciseKey` (the normalised key already used by exercise
  history, so "Pull-Ups" and "pull up" group together)
- `muscles` — list of muscle slugs, resolved when saved (D8)
- `workoutDate` / `dayLabel` — which workout it came from, when known
- `filePath`, `thumbnailPath` — relative to the app documents folder
- `analysis` — optional **FormAnalysis**, plus `analysedAt` and the model used
- `note` — optional short text from the user

**FormAnalysis** — the stored result (shape in section 6).

### Storage on the device (D1)

- Files: `exercise_videos/<id>.mp4` and `<id>.jpg` under the app documents folder.
- Index: a local Hive box, following the pattern `BodyScanStorage` already uses.
- Deleting a video removes the file, thumbnail and index entry together.
- A startup check removes files with no index entry and entries with no file.
- A **Delete all my videos** control in Profile → Usage data (or a new storage
  row), and a note that deleting the app deletes the videos.
- Before saving, check free space and refuse politely when it is low.

### Cloud backup — Phase 1b (not in the first release)

Private Supabase Storage bucket, one folder per user; a metadata table with row
level security (`auth.uid() = user_id`) like the other user tables; signed URLs
for playback; storage policies scoped to the user's own folder. Needs a spend
check, a quota, and a privacy-policy update before it ships.

---

## 5. Choosing frames *(rewritten)*

The old plan sampled 6–10 evenly spaced keyframes. The test clip showed that
misses the movement. New approach, all on the device:

1. **Make a cheap motion map.** Decode the video at low resolution (about 8 fps,
   ~160 px wide, grey) and measure how much each frame differs from the last.
2. **Find the active segments.** Smooth the curve and keep stretches above a
   threshold. Idle time (standing, resting, setting up) drops out. If there is
   more than 30 s of activity, keep the strongest 30 s.
3. **Find the subject.** Take the largest moving region as the person. In a
   busy gym, let the user **tap the person once** to confirm. Crop to that
   person with a margin.
4. **Find the reps.** Peaks in the motion curve mark reps. Group frames by rep.
5. **Sample finely inside each rep.** Per rep, take 3–4 frames at the start,
   the extreme position, the middle and the top, at about 0.1–0.2 s spacing
   around the fast part. Add one setup frame before the first rep.
6. **Budget.** 8–12 frames in total. If there are many reps, sample the first,
   a middle and the last rep, and say so in the request.
7. **Encode.** Crop to the subject, long edge 512–768 px, JPEG, each frame
   labelled with its timestamp and rep number.

**Fallbacks:** if no clear motion is found, fall back to 8 evenly spaced frames
and mark the result low confidence. If the person can't be found, send the full
frame.

**How the frames are extracted:** use the platform's own decoder (on iOS,
`AVAssetImageGenerator` — the same tool used to analyse the test clip, with no
new dependency). Start with iOS. Android follows with its media retriever. An
existing plugin (such as `video_thumbnail`) is a possible shortcut; check it is
maintained before relying on it (step 6). Avoid `ffmpeg_kit_flutter`, which has
been retired.

*Optional later improvement:* Apple Vision body-pose detection would give
reliable rep counting and subject tracking on the device (see Phase 2).

---

## 6. AI response and rating *(rewritten)*

The client tells the model which exercise it is. The model must not guess the
exercise from nothing, but it should say so if the frames don't match.

### Camera view and confidence

The model first reports the **camera view**: `side`, `front`, `rear`,
`angled` or `unclear`. The view caps what can honestly be judged:

- **Side view:** spine, depth, bar path and knee angles can be judged.
- **Front view:** knee tracking and symmetry.
- **Rear view:** stance width and symmetry, not spine or bar path.

Anything it can't judge is **null**, not a guess, and goes in `limitations`.

### Response shape

```json
{
  "exercise": "conventional deadlift",
  "exercise_matches_request": true,
  "camera_view": "rear",
  "confidence": "low",
  "overall_score": 7,
  "stance_score": 8,
  "form_score": null,
  "tempo_score": 5,
  "summary": "Stable setup and clean lockouts. The bar is dropped rather than lowered.",
  "reps": { "completed": 3, "attempts": 4, "notes": "4th attempt: bar stayed on the floor" },
  "stance": ["Feet about hip-width and planted through every rep"],
  "form": ["Upper back looks rounded at setup — confirm with a side-on clip"],
  "tempo": ["Lift takes about half a second", "Bar reaches the floor in under a second"],
  "cues": [
    { "severity": "medium", "issue": "Bar lowered very fast", "fix": "Control the descent: hips back, bar close to the legs." }
  ],
  "good_points": ["Full lockout every rep", "Consistent starting position"],
  "limitations": ["Filmed from behind: spine position and bar path cannot be judged"]
}
```

### Rating rubric

- **Overall** (1–10) combines three category scores. Suggested weights: **form
  50 %, stance 25 %, tempo and control 25 %**, kept in the backend so they can
  be tuned without an app update.
- A category with no judgement (`null`) is left out and the rest are
  re-weighted. **Confidence** falls to `low` when the view is poor, and the
  overall score is shown with that caveat.
- Bands: **9–10** excellent · **7–8** good, small fixes · **5–6** needs work ·
  **below 5** form issues worth correcting. Scores are for guidance only.
- Cue `severity` is `high`, `medium` or `low` and drives colour and order.

### Tone and safety

- Say "this looks like…" rather than "you are doing this wrong".
- No medical language, no injury diagnosis. Always show: *general fitness
  guidance, not medical advice.*
- The backend checks the JSON against a schema. If it fails twice, the user
  sees "couldn't analyse this clip" and the usage is not counted.

---

## 7. UX spec

### 7.1 Exercise page

Order, top to bottom: title → Sets / Reps / **Log** → **History** (built on the
`exercise-history` branch) → **My Videos** → Instructions → Safety tip → **Video
Tutorials** (the existing YouTube section).

Name the new section **My Videos** so it is never confused with the YouTube
**Video Tutorials**.

**My Videos card states**
- Empty: "Record a set to check your form" + an **Add video** button.
- With videos: a horizontal row of thumbnail cards (date, length, rating chip or
  **Analyse**), then **Add video**.
- Analysing: the thumbnail dims with a progress ring and a Cancel option.
- Failed: a small retry action on the card.

**Add video sheet:** Record · Choose from library · Cancel.

### 7.2 Recording guide

Shown the first time, and available later through a "Tips" link:
film **from the side**, phone at **hip height** about **3 m** away, whole body
in frame, **nothing in front** of the lens, **one person**, phone steady. One
set per clip. This is the biggest quality lever (section 2).

### 7.3 Analysis result sheet

Rating ring (overall) → three bars (stance, form, tempo, with "can't judge" when
null) → confidence and camera-view note → rep summary → cues by severity → good
points → **What I couldn't judge** → re-run and share-free actions → the
disclaimer line.

### 7.4 Muscle detail — My Videos

In the muscle page reached from Analytics → Muscles trained, add **My Videos**
below the exercise list. Videos for that muscle, newest first, each showing
exercise, date and rating chip. A small trend line when there are 3 or more
rated videos. Optionally add a camera count badge to the rows in the Muscles
trained card.

### 7.5 States to design for

No permission to camera or library, low storage, a clip over the limit (trim
prompt), a clip with no motion, offline during analysis, backend timeout, and a
free user tapping Analyse (paywall).

---

## 8. Step-by-step build process

Branch: **`exercise-videos`**, created from `main` once `exercise-history` is
merged. Each step ends with something that works and is testable. Sizes are
rough solo estimates.

### Step 0 — Prerequisites *(S, 0.5 day)*
- **Goal:** settle the decisions and gather test material.
- **Do:** sign off D1–D8 (section 3). Collect 15–20 test clips across squat,
  deadlift, bench, push-up, including good, bad, side-on, rear and crowded.
  Keep `IMG_1294.MOV` as the benchmark. Extract small frame sets from them to
  use as test fixtures, so the repo never holds large videos.
- **Done when:** decisions are recorded in this doc and the clip set exists.

### Step 1 — Video model and on-device storage *(M, 1.5 days)*
- **Goal:** save, list and delete video records, with no UI yet.
- **Do:** add the `ExerciseVideo` model and a repository that keeps the index in
  Hive and the files in the documents folder. Include muscle resolution at save
  time (D8) and the startup cleanup of orphaned files.
- **Touches:** new `lib/domain/models/exercise_video.dart`, new
  `lib/data/services/video/exercise_video_storage.dart`, a registration in
  `di.dart`, storage init alongside the existing boxes.
- **Done when:** unit tests cover add, list by exercise, list by muscle, delete
  and orphan cleanup, including a file with no entry and an entry with no file.

### Step 2 — Packages and platform setup *(S, 0.5 day)*
- **Goal:** everything needed to play and capture video is in place.
- **Do:** add a playback package. Confirm `image_picker` handles video record
  and pick with a duration limit. Choose the frame-extraction approach (step 6).
  The iOS camera, microphone and photo-library usage strings **already exist**
  in `Info.plist`; reword them to mention workout videos. Check Android
  permissions.
- **Done when:** a throwaway screen plays a picked video on a real device.

### Step 3 — Capture, trim and compress *(L, 2 days)*
- **Goal:** turn a camera or library video into a small, saved clip.
- **Do:** record or pick; enforce the 60 s cap with a simple trim control;
  compress to ≤ 720p with a bitrate ceiling; generate a thumbnail; show
  progress; check free space first; save through step 1.
- **Done when:** the 148 s test clip becomes a trimmed 60 s clip under about
  40 MB, with a thumbnail, and the app stays responsive while it works.

### Step 4 — My Videos section on the exercise page *(L, 2 days)*
- **Goal:** the user can add, see and delete videos for one exercise.
- **Do:** build the section as its own widget in a new file
  (`exercise_videos_section.dart`) and slot it into `ExerciseHeroPage` under
  **History**. Add the add-sheet, the thumbnail row, delete with confirmation,
  and the recording-tips sheet. Mind the rule that the exercise key groups name
  variants together.
- **Done when:** on a device you can add three videos to Pull-Ups, see them
  after leaving and returning, and delete one. Widget tests cover empty, one,
  many and error states.

### Step 5 — Playback screen *(M, 1 day)*
- **Goal:** watch a saved video full screen.
- **Do:** player page with play/pause, scrubber and slow-motion speeds
  (0.25×, 0.5×), since form review is done frame by frame. Entry from the card.
- **Done when:** playback works for portrait and landscape clips and releases
  the video when closed.

### Step 6 — Frame sampler *(L, 3 days; the riskiest step, do a spike first)*
- **Goal:** pick the 8–12 most useful frames from a clip, on the device.
- **Do:** first a one-day spike to compare the platform decoder with a plugin
  and measure speed on a 60 s clip. Then implement the six steps of section 5:
  motion map, active segments, subject, reps, fine sampling, crop and encode.
  Keep the maths in plain Dart so it is unit-testable, with the platform
  decoder behind a small interface.
- **Done when:** on the benchmark clip the sampler finds **3 rep windows plus
  the failed attempt**, ignores the idle stretches, crops to the lifter, and
  finishes in under about 10 seconds on a real phone. Tests run on the saved
  fixture frames.

### Step 7 — Backend endpoint *(M, 2 days)*
- **Goal:** `POST /api/v1/analysis/form` returns a validated `FormAnalysis`.
- **Do:** add a route modelled on the existing analysis and equipment-scan
  routes; a response model; a **form-analyst agent** with its prompt (both the
  OpenAI path and the Anthropic mirror, like the other agents); schema
  validation with one retry; size and count limits on frames; authentication;
  rate limit per user; token cost recorded in the existing usage accounting
  (section 10). Frames are processed in memory and **not stored**.
- **Touches:** new `src/routes/api/form_analysis.py`, a models file, prompt and
  agent registration, route registration, a `form_model` setting.
- **Done when:** tests with fixture frames return valid JSON, reject bad input,
  and a real call on the benchmark frames produces the section 2 success test.
  Measure real token use per frame here and update section 10.

### Step 8 — Client analysis flow *(M, 1.5 days)*
- **Goal:** the Analyse button works end to end.
- **Do:** a `FormAnalysisService` (reusing the existing authenticated HTTP
  client), a state holder for idle → sampling → uploading → analysing → done /
  failed, cancellation, retry, and saving the result with the video. Long
  timeout with a clear "this can take a minute" message; the backend may be
  cold.
- **Done when:** analysing a saved video stores a result that survives an app
  restart, and a failure leaves the video untouched with a retry.

### Step 9 — Result UI *(L, 2 days)*
- **Goal:** the rating sheet from section 7.3.
- **Do:** rating ring, three bars with "can't judge" states, confidence and
  camera-view note, cues by severity, good points, limitations, re-run, and the
  disclaimer. Rating chip on the video card.
- **Done when:** the sheet renders the benchmark result correctly, including
  null scores, and widget tests cover high, low-confidence and failed states.

### Step 10 — History by muscle *(M, 1.5 days)*
- **Goal:** videos appear under Muscles trained.
- **Do:** a **My Videos** section in the muscle detail page, fed by the index
  query by muscle. Rating chips, optional trend, tap to play or reopen the
  analysis. Optionally a camera count badge in the Muscles trained card.
  Keep it visually and in naming separate from the existing YouTube tutorials.
- **Done when:** a video saved for Pull-Ups appears under back and biceps, with
  its rating, and deleting it removes it there too.

### Step 11 — Paywall and limits *(S, 1 day)*
- **Goal:** decisions D6 in the product.
- **Do:** add a premium feature for analysis; route the Analyse tap through the
  existing gate; free users can still save and watch. Add the monthly cap with a
  clear message, and a per-user rate limit on the backend.
- **Done when:** a free user sees the paywall on Analyse, a Pro user is stopped
  politely at the cap, and the cap resets monthly.

### Step 12 — Privacy and App Store *(S, 1 day)*
- **Goal:** the policy and store listing match what the feature does.
- **Do:** update the in-app and website privacy text (section 11), the App
  Privacy answers, and add a one-time notice before the first analysis. Add the
  "delete all my videos" control. Keep the website and app wording identical.
- **Done when:** both policies describe frames-not-video, bystanders and
  deletion, and the App Privacy checklist in `app-store-metadata.md` is updated.

### Step 13 — Analytics events *(S, 0.5 day)*
- **Goal:** see whether people use it.
- **Do:** add the events in section 12 and update `analytics-insights.md`.
- **Done when:** a funnel from video added → analysed → rating viewed can be
  built in PostHog.

### Step 14 — Validation *(L, 2 days)*
- **Goal:** know whether the ratings are trustworthy before shipping.
- **Do:** run the 15–20 clips through the full pipeline with each candidate
  model. Score the output against your own judgement: exercise correct, rep
  count correct, view detected, no invented claims, sensible rating. Pick the
  model (D4) and fix the prompt.
- **Done when:** at least **90 %** of clips get the exercise and view right,
  rep counts are within one rep, and no result states a spine or bar-path
  judgement on a rear or blocked view.

### Step 15 — Release *(S, 1 day)*
- **Goal:** ship carefully, because each analysis costs money.
- **Do:** put the feature behind a remote flag; release to TestFlight first;
  watch daily AI spend and the failure rate; then switch on for everyone.
- **Done when:** a week of TestFlight data shows cost per analysis near the
  estimate and no crashes from video handling.

**Rough total:** about **22 working days** (4–5 weeks solo). Steps 1–5 give a
usable video log on their own, so they can ship first and the analysis can follow.

---

## 9. Backend contract (summary)

- **Request:** `POST /api/v1/analysis/form`, multipart, authenticated. Fields:
  `exercise_name`, `frames[]` (JPEG, 8–12), `timestamps[]`, `rep_groups[]`,
  optional `camera_hint`. Reject more than 12 frames or any frame over about
  400 KB.
- **Response:** the FormAnalysis JSON in section 6, plus `model` and `usage`.
- **Errors:** 400 bad input, 401 unauthenticated, 429 over the cap or rate
  limit, 502 model failure after retry. A failed analysis must not count
  against the user's cap.
- **Not stored:** frames are used in memory and discarded. Log only counts and
  token usage, never images.
- **Existing patterns to follow:** the equipment-scan route for how images are
  received and passed to a model, and the model settings in `config.py` (a separate `form_model`).

---

## 10. Cost *(revised — the earlier table used GPT-4o prices)*

**Measured basis (October 2026 test):** one 1290×2796 image used **4,348 input
tokens** on the GPT-6 models. A cropped frame at about 768 px on the long edge
has roughly 9 % of that area, so expect about **400–700 tokens per frame**. This
is an estimate until step 7 measures it.

Per analysis (10 frames + about 1,000 prompt tokens + about 800 output tokens):

| Model | Prices (per 1M tokens) | Estimated cost per analysis |
|---|---|---|
| `gpt-6-luna` | $0.10 in / $0.50 out | about **$0.002** |
| `gpt-6.1-sol` | $2 in / $10 out | about **$0.02–0.03** (reasoning tokens may add some) |

At 1,000 users × 10 analyses a month (10,000 analyses): Luna about **$10–20**,
Sol about **$200–300**. With a 30-a-month cap, the worst case for one Pro user
on Sol is about **$0.90** against **$8.99** of revenue.

*(carried forward)* Wire the endpoint into the existing `/api/v1/usage` token
accounting so real cost is observed, not estimated. The cost table there needs
the GPT-6 rows (added in the pending backend model changes, not yet deployed).

---

## 11. Privacy and App Store *(updated)*

- **Videos stay on the device** by default, consistent with progress photos. The
  policy should say so.
- **Analysis sends selected still frames, not the video,** to the AI provider
  through the backend, and they are not kept. Verify the provider's current
  data-retention terms before writing this sentence.
- **Other people in the shot.** Add a notice before the first analysis: avoid
  filming others; frames are cropped to you where possible.
- **App Privacy answers:** Photos or Videos, linked to the user, purpose app
  functionality, not used for tracking. (Photos are already declared for meal
  and physique scans; confirm the video wording.)
- **Info.plist:** camera, microphone and photo-library strings **already
  exist**. Update the wording to mention workout videos.
- **Deleting data:** "delete all my videos" in the app; account deletion
  already clears server data, and the notice should say local videos are removed
  by deleting the app or using the control.
- Keep the in-app policy and the website policy **word-for-word identical**.

---

## 12. Analytics events to add

Following the existing event conventions (names in `analytics_events.dart`, no
personal data, nothing about the video content):

`exercise_video_added` (source: record | library, `duration_s`) ·
`exercise_video_played` · `exercise_video_deleted` ·
`form_analysis_started` (`frame_count`) · `form_analysis_completed`
(`overall_score`, `confidence`, `camera_view`, `duration_ms`) ·
`form_analysis_failed` (reason) · `form_analysis_result_viewed` ·
`muscle_videos_opened` (muscle).

---

## 13. Test and validation plan

- **Unit:** the model and storage (step 1); the sampler on fixture frames
  (step 6); response parsing including every null combination (steps 7–9).
- **Widget:** My Videos states, result sheet states, muscle videos section.
- **Backend:** schema validation, limits, error codes, that failed analyses are
  not counted, that nothing is stored.
- **Device matrix:** an older and a current iPhone; portrait and landscape; a
  60 s clip; low free storage; airplane mode during analysis.
- **Benchmark:** `IMG_1294.MOV` must meet the success test in section 2.
- **Acceptance (step 14):** the 90 % rule on the labelled clip set.

---

## 14. Risks and mitigations

| Risk | Mitigation |
|---|---|
| The model overstates what it can see (calls a spine "rounded" from behind) | Camera-view detection, nullable scores, a `limitations` list, and a validation rule in step 14 |
| The sampler misses the movement or picks the wrong person | Fallback to evenly spaced frames, tap-to-confirm subject, fixtures from real clips |
| Storage fills the phone | 60 s cap, 720p compression, free-space check, visible storage use, delete-all |
| AI cost grows faster than revenue | Premium analysis, monthly cap, per-user rate limit, env-switchable model, daily spend alert |
| Ratings feel arbitrary and users distrust them | Show the three sub-scores and the reasons, show confidence, keep the tone advisory |
| Injury-related complaints | Not medical advice wording, no diagnosis, cues phrased as suggestions |
| Videos lost on reinstall (D1) | Say so in the UI; offer cloud backup in Phase 1b |
| App Store review of video and camera features | Accurate usage strings, App Privacy answers, in-app notice |

---

## 15. Later phases

### Phase 1b — Cloud backup *(optional)*
Back up videos and results so they survive a new phone. Design in section 4.
Needs a quota, a spend check and a privacy update first.

### Phase 2 — Live coaching *(carried forward, unchanged in intent)*
Real-time cues while exercising, using on-device body-pose detection (ML Kit or
Apple Vision) for rep counting and joint angles. Frames are **not** streamed to
the cloud for the live loop: it is too slow and costly (about 1–3 s per round
trip). At the end of each set, send a short summary to the model for one piece
of coaching. This also gives reliable rep counting for the upload analyser
(step 6). A `/ws/form-check` WebSocket mirroring the gym-kit route is only
needed if streaming is chosen.

---

## 16. Open questions — need your call

1. **Where videos live (D1):** device only for the first release, with cloud
   backup later. Agree?
2. **Free or paid:** saving and playing free, analysis Pro-only with about 30 a
   month. Agree, or should a few analyses be free as a trial?
3. **Which model:** run both on the test set first, then decide. Is a cost
   ceiling per analysis (for example 3 cents) a hard rule?
4. **First exercises:** squat, deadlift, bench press, push-up. Add or swap any?
5. **Camera-angle strictness:** should the app *refuse* rear-view clips, or
   analyse them with the limits clearly shown (recommended)?
6. **Ratings in the muscle view:** show scores per video, a trend, or both?
7. **Who owns this:** the Owner line at the top is empty.

---

## 17. What was built (2026-11-02), and what is left

The recommended answer was taken for every open question in section 16: videos
on the device only, saving and playing free, analysis Pro-only with a cap of 30 a
month counted on the device, squat / deadlift / bench / push-up as the tuned exercises (anything else
gets the same prompt and the model says it is less sure), and **rear-view clips
are analysed with the limits shown, not refused**. Models: `OPENAI_FORM_MODEL`
defaults to the vision model (`gpt-6-luna`); step 14 decides whether it needs
`gpt-6.1-sol`.

### Step by step

| Step | State |
|---|---|
| 0 Prerequisites | **You:** collect the 15–20 test clips and keep `IMG_1294.MOV` as the benchmark. |
| 1 Model and storage | Done and unit tested. |
| 2 Packages and setup | Done: `video_player` added, Info.plist strings reworded. **Needs a device** to confirm playback. |
| 3 Capture, trim, compress | Done on iOS (`AVAssetExportSession`, 720p H.264). **Needs a device**: check the 148 s clip becomes a 60 s clip under about 40 MB. |
| 4 My Videos section | Done, widget tested. |
| 5 Playback | Done (0.25×, 0.5×, 1×; releases the decoder on close). **Needs a device.** |
| 6 Frame sampler | Done: maths in plain Dart with 23 tests on synthetic clips; native frame reader in Swift. **Needs the spike on a real phone:** speed on a 60 s clip, and the benchmark (3 reps plus the failed attempt). Thresholds in `SamplerConfig` are untuned guesses. |
| 7 Backend endpoint | Done, 42 tests. **Not deployed.** Writes nothing to the database: no migration is needed. |
| 8 Client flow | Done (`FormAnalysisRunner`: one analysis at a time, cancel, retry, survives leaving the page). |
| 9 Result UI | Done, widget tested including the rear-view / null-score benchmark result. |
| 10 History by muscle | Done: My Videos on the muscle page, with a trend from three rated videos. The camera-count badge on the Muscles trained card was **not** added. |
| 11 Paywall and limits | Done: `PremiumFeature.formAnalysis`, a monthly allowance of 30 counted on the device, and a per-minute limit on the server. See the caveat below. |
| 12 Privacy | Partly: in-app notice before the first analysis, delete-all page (Profile → Workout videos), Info.plist wording, store checklist. **The policy text in the app and on the website is not changed:** proposed wording is section 18, for you to approve. |
| 13 Analytics | Done, documented in `analytics-insights.md`. |
| 14 Validation | **Not done.** Needs the clips and a real model call. |
| 15 Release | **Not done.** No remote flag was added; the section is hidden on Android instead. |

### Where things are

App: `lib/domain/models/exercise_video.dart`, `lib/data/services/video/`
(`exercise_video_storage`, `video_tools`, `frame_sampler`, `video_import_service`,
`form_analysis_service`, `form_analysis_runner`, `video_notice_storage`),
`lib/ui/features/video/views/`, `lib/ui/features/profile/views/workout_videos_page.dart`,
`ios/Runner/VideoToolsChannel.swift`. Backend: `src/routes/api/form_analysis.py`,
`src/services/form_analysis.py`, `src/models/form_model.py`,
the `FORM_ANALYSIS_PROMPT`, and `FORM_*` settings in `config.py`. The app keeps the
monthly count in `lib/data/services/video/form_analysis_usage.dart`.

### Things that differ from the plan, or that need care

- **iOS only.** The section is hidden on Android (`videoToolsSupported`).
- **Nothing about an analysis is stored in Supabase.** The video, the thumbnail,
  the rating and the monthly count all live on the device. The server keeps no
  table for this; it only logs token counts.
- **So the monthly allowance (30) is a guide, not a wall.** It is counted on the
  device, and resets if the app is reinstalled or the app's data is cleared. Pro is
  also enforced only in the app, like the other premium features. The server's only
  hard limit is 3 analyses a minute per user. Worst case for one determined user is
  therefore bounded by that rate, not by a monthly number. If cost control needs to
  be exact, a server-side count (a small table) is the way, and was the first design.
- **The overall score is computed on the server** from stance 25 %, form 50 %,
  tempo 25 %, so the weights can change without an app update.
- **Tap-to-confirm the person** is not built as a screen. The sampler already
  returns up to three candidate regions (`FramePlan.candidates`) and can re-crop
  without decoding again (`FrameSampler.extract(plan, subject: …)`), so the UI is
  the only missing piece.
- **No camera hint is sent** (the plan allows one); the model decides the view.
- **To ship the backend:** deploy it. No migration. Optional env: `OPENAI_FORM_MODEL`,
  `OPENAI_FORM_REASONING_EFFORT`, `FORM_PROVIDER` / `ANTHROPIC_MODEL` (to use Claude),
  `FORM_ANALYSIS_PER_MINUTE`.

---

## 18. Proposed privacy-policy wording (for approval)

Nothing below is live. It is for the app and the website to carry **word for
word the same** (section 11). Confirm the provider's retention terms before the
sentence about not keeping frames is published.

> **Workout videos.** If you record or choose a workout video, it is stored only
> on your device. We do not upload it. Deleting the app deletes your videos, and
> you can delete them all at any time in Profile → Workout videos.
>
> **Form analysis.** If you ask for a form analysis, the app picks about 8 to 12
> still frames from the video, crops them around the person lifting where it can,
> and sends them to our AI provider through our servers to be rated. The frames
> are used to produce your rating and are not kept. Your rating is saved with the
> video on your device; we do not store it.
>
> **Other people.** Frames can include other people who are in the shot. Please
> avoid filming others.
>
> **Not medical advice.** Ratings are general fitness guidance, not medical advice.

---

## 19. First real run on the benchmark clip (2026-11-03)

`IMG_1294.MOV` (148 s, 1080×1920, deadlifts from behind) was run through the real
frame sampler (Dart code, with a macOS stand-in for the phone's native frame
reader) and the real endpoint (`gpt-6-luna`, local backend).

**What the clip taught the sampler (all fixed, with tests):**
- At about 140 s the lifter picks the phone up and the whole picture changes. That
  move was 10× stronger than any lift and set the activity threshold so high that
  the lifts were missed. Frames where more than 15 % of the picture changed are now
  treated as the camera moving, left out of the threshold, and never counted as
  activity. The lifts changed at most 7 % of the frame; the camera move 13–68 %.
- Hand-held footage flickers by about 0.012 everywhere; the noise floor is now 0.014.
- Activity at the start and end of a clip (starting the recording, walking over to
  stop it) is dropped by keeping only the 40 s stretch with the most separate
  bursts of movement.
- The crop box was the whole frame width: a plate at the edge of the frame was being
  joined to the lifter, and flicker counted as movement. Only significant changes
  now count and regions are joined only when close. The lifter is now a box about
  0.88 × 0.44 of the frame.
- Result: five bursts found at 93, 98, 103, 110 and 116 s, 10 frames chosen, 7 s
  on a Mac (the phone's speed is still to be measured).

**The endpoint's answer vs the section 2 success test:**

| Test | Result |
|---|---|
| Names the exercise as a deadlift | Pass |
| Rear view, no judgement of spine or bar path | Pass (form score `null`) |
| Rear view reported as low confidence | Was "medium"; the server now caps confidence by camera view (rear and unclear: low, angled: medium) |
| Flags the fast, uncontrolled descent | Pass, with timing from the frames |
| 3 reps plus 1 failed attempt | **Fail**: "0 clean reps, 2 attempts" |

Cost: 7,413 input and 2,501 output tokens for 10 frames, about $0.003 on Luna.
Time: 43 s.

**Why the rep count failed, and what to try:** five bursts were found but only reps
1, 3 and 5 were sampled, 3 frames each, so the model never saw reps 2 and 4. Options:
sample 2 frames on every rep when there are 5 or fewer (start and peak) instead of 3
on a few; raise the frame budget from 12 to about 16 (cost is roughly linear); or
stop asking the model to count reps and use the sampler's own count, which was
5 bursts here (3 lifts, the failed attempt and a final movement), passing it in the
request. Counting reps from the motion peaks is also how the plan's Phase 2 does it.

**Not yet compared:** the same frames on `gpt-6.1-sol` and on Claude.

