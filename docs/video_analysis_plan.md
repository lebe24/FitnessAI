# Workout Video Analysis — Implementation Plan

> AI-powered exercise form analysis for BeFit AI. Users upload (or record) a
> workout clip and receive structured form feedback; a later phase adds live
> real-time coaching.

**Status:** Planning
**Owner:** —
**Last updated:** 2026-07-06

---

## 1. Goal

Let users get AI feedback on their exercise form. Two delivery modes, shipped in
phases:

| Mode | Description | Phase |
|---|---|---|
| **Upload / record** | User submits a recorded clip → AI returns form feedback | 1 (ship first) |
| **Live coaching** | Real-time form cues while exercising | 2 |

The upload mode is a self-contained, demoable feature that reuses existing
infrastructure. Live mode is a larger effort gated on on-device pose detection.

---

## 2. Why this is feasible now

The backend already exposes `/ws/gymkit` — a WebSocket that accepts **text +
base64 image frames** for gym-equipment coaching. A form analyzer is the same
shape: stream frames, receive AI feedback. The gymkit route is the reference
implementation to mirror.

Key constraint: **LLMs do not ingest raw video.** Both `gpt-4o` and Claude accept
image sequences. The client samples keyframes from the video and sends them as
an ordered set of images. Video decoding / frame sampling happens on-device.

---

## 3. Architecture

### Phase 1 — Upload analyzer (REST or WS)

```
Flutter                              Backend (FastAPI)              AI provider
───────                              ─────────────────              ───────────
1. Pick / record video
2. Sample 6–10 keyframes
   (image_picker + video frames)
3. Base64-encode frames  ──────────► POST /api/v1/analysis/form
                                     4. Build multimodal prompt
                                        (frames + system prompt) ──► gpt-4o vision
                                     5. Parse structured JSON  ◄──── form feedback
6. Render feedback UI    ◄────────── 200 { FormAnalysis }
7. (optional) persist result
   to Supabase workout_session
```

**Recommendation:** use a REST endpoint (`POST /api/v1/analysis/form`) for the
upload mode — it's stateless, cacheable, and simpler than a WS. Reserve the WS
pattern for Phase 2 live streaming.

### Phase 2 — Live coaching

```
Flutter                                          Backend / AI
───────                                          ────────────
Camera stream
  → on-device pose detection (ML Kit / Vision)   [runs locally, free, real-time]
  → compute rep count + joint angles
  → real-time on-screen cues (no network)
  → at end of set: send set summary  ──────────► LLM generates coaching commentary
```

Live mode does **not** stream every frame to the cloud (too costly / laggy —
~1–3 s round trip). On-device pose estimation handles the real-time loop; the
LLM only produces an end-of-set summary (1 call per set).

---

## 4. Frame sampling strategy

Form is judged on a few key positions, not every frame. Sampling is the biggest
cost and quality lever.

- **Target 6–10 keyframes per analysis**, not 1 frame/sec.
- Prefer frames at rep extremes: top, bottom, and midpoint of the movement.
- Downscale frames to ~512–768px on the long edge before encoding (smaller
  payload, lower image-token cost, sufficient for body-position analysis).
- Cap total upload size; reject clips longer than ~30 s in Phase 1.

---

## 5. AI response schema

Request the model to return structured JSON so the UI can render it
deterministically.

```json
{
  "exercise": "barbell squat",
  "overall_score": 7,
  "summary": "Good depth and tempo. Main issue is knees caving inward under load.",
  "form_cues": [
    {
      "severity": "high",
      "issue": "Knees caving inward (valgus) on the ascent",
      "fix": "Push knees out over your toes; think 'spread the floor'."
    },
    {
      "severity": "medium",
      "issue": "Slight forward torso lean at the bottom",
      "fix": "Keep chest up and brace your core before descending."
    }
  ],
  "good_points": [
    "Consistent depth below parallel",
    "Controlled eccentric tempo"
  ],
  "rep_count": 5
}
```

Field notes:
- `overall_score` — 1–10, drives a headline number in the UI.
- `severity` — `high` | `medium` | `low`, drives cue colour/ordering.
- `rep_count` — best-effort; on-device pose detection is more reliable in Phase 2.

---

## 6. Cost estimate

Cost is dominated by **image tokens**. Levers: frame count and detail level.

Per analysis (8 keyframes + ~500 tok prompt + ~500 tok response):

| Config | Image tokens | ~Cost / analysis |
|---|---|---|
| gpt-4o-mini, low detail | ~22,700 | ~$0.004 |
| gpt-4o, low detail | ~680 | ~$0.007 |
| gpt-4o, high detail | ~6,600 | ~$0.02 |
| gpt-4o, high detail, 15 frames | ~11,500 | ~$0.035 |

At 1,000 users × 10 analyses/month = 10,000 analyses:

| Config | Monthly AI cost |
|---|---|
| gpt-4o-mini, low detail | ~$40 |
| gpt-4o, high detail (8 frames) | ~$220 |
| gpt-4o, high detail (15 frames) | ~$350 |

> Pricing basis: ~$0.15 / $0.60 per 1M tokens (mini) and ~$2.50 / $10 (gpt-4o).
> Verify against OpenAI's current pricing before committing — rates change.

**Recommendation:** use `gpt-4o` at low/medium detail with 6–10 frames. It reads
body position far better than mini and is *cheaper* at low detail (85 vs ~2,833
image tokens/frame). Budget **~½ cent to 3.5 cents per analysis**.

---

## 7. Token usage tracking

The backend already has `/api/v1/usage` tracking OpenAI token cost by date.
Wire the form-check endpoint into the same accounting so real per-request cost
is observable instead of estimated.

---

## 8. App Store / privacy considerations

Video + camera features get stricter App Store review. Required before submission:

- `NSCameraUsageDescription` — clear justification for camera access.
- `NSPhotoLibraryUsageDescription` — for picking existing videos.
- Privacy nutrition label must disclose that workout video/photos are sent to a
  server for AI analysis (data type: **Photos/Video**, used for app functionality,
  not tracking).
- Consider an in-UI notice that frames are uploaded for analysis.

---

## 9. Implementation checklist

### Phase 1 — Upload analyzer
- [ ] Backend: `POST /api/v1/analysis/form` endpoint (mirror `analysis.py` /
      gymkit multimodal prompt handling)
- [ ] Backend: `FormAnalysis` Pydantic response model + structured-output prompt
- [ ] Backend: wire endpoint into `/api/v1/usage` token accounting
- [ ] Flutter: video pick/record (extend `image_picker`, add `camera` if recording)
- [ ] Flutter: frame sampling + downscale + base64 encode util
- [ ] Flutter: `FormAnalysisService` (Dio, reuses shared auth interceptor)
- [ ] Flutter: results UI (score, cue list by severity, good points)
- [ ] Flutter: entry point in the exercise flow (button on exercise/workout page)
- [ ] iOS: add camera + photo library usage strings to Info.plist
- [ ] Test: sandbox clips across exercises; validate JSON parsing edge cases

### Phase 2 — Live coaching
- [ ] Evaluate ML Kit Pose Detection (Android/iOS) vs Apple Vision
- [ ] On-device rep counting + joint-angle cue engine
- [ ] Real-time on-screen cue overlay
- [ ] End-of-set summary call to LLM
- [ ] Backend: `/ws/form-check` WS endpoint (mirror `ws_gymkit`) if streaming needed

---

## 10. Open questions

- Which exercises to support first? (Recommend starting with squat, deadlift,
  push-up, bench — high-value, clear form failure modes.)
- Persist analyses to `workout_sessions` (alongside `workout_logs` / `feedback`)
  or keep ephemeral in Phase 1?
- Free vs Premium gating — is form analysis a premium feature? (Ties into the
  billing work; likely a strong premium hook given per-analysis cost.)
