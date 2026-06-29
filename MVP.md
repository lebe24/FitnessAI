# BeFit — MVP Launch Plan
**Target launch: end of this week**  
**Version: 1.0.0** (bump from 0.1.0+7)

---

## What's Already Built

| Area | Status |
|---|---|
| Auth (Supabase email + Google Sign-In) | ✅ Done |
| Onboarding flow (goals, gender, stats) | ✅ Done |
| Plan generation — photo analysis path | ✅ Done |
| Plan generation — AI chat path | ✅ Done |
| Workout page with exercise tracking | ✅ Done |
| In-workout AI coach chat | ✅ Done |
| Streak tracking (Supabase backend) | ✅ Done |
| Weekly progress widget | ✅ Done |
| Nutrition scanner | ✅ Done |
| Body composition scan | ✅ Done |
| Saved programs page | ✅ Done |
| Profile page with stats | ✅ Done |
| Statistics page | ✅ Done |
| Activity page | ✅ Done |

---

## Launch Blocklist — Must fix before shipping

These are blocking. Do not submit to stores until all are green.

### P0 — Crashes / broken flows
- [ ] **Backend URL hardcoded / .env not set for production** — confirm `Constant.backendUrl` points to the production FastAPI server, not localhost
- [ ] **Supabase RLS** — verify all tables (`workout_sessions`, `exercise_logs`, `user_data`, `profiles`) have Row Level Security enabled and tested with a real non-admin user
- [ ] **Google Sign-In SHA fingerprint** — add release keystore SHA-1/SHA-256 to the Supabase OAuth config and Google Cloud Console
- [ ] **App version** — bump `pubspec.yaml` to `version: 1.0.0+1` for store submission
- [ ] **iOS bundle ID + provisioning** — confirm `com.yourcompany.fitness` matches App Store Connect, provisioning profile is Distribution
- [ ] **Android signing** — `build.gradle.kts` must reference the release keystore, not the debug key
- [ ] **`intl` missing from pubspec.yaml** — `saved_program.dart` uses `DateFormat`; add `intl: ^0.19.0` to dependencies

### P1 — Bad UX that will cause 1-star reviews
- [ ] **Empty states everywhere** — verify Activity page, Statistics page, and Workout page all show a helpful message when there's no data yet (new user first session)
- [ ] **Onboarding back-button traps** — test that tapping back on the final onboarding step doesn't push the user into a broken state
- [ ] **Network error handling** — wrap every AI generation call with a user-visible error message and a retry button; currently the app hangs silently if the backend is slow
- [ ] **Plan generation loading state** — the analysis page and chat-to-plan sheet need a visible timeout (>60s) with a "taking longer than usual" message
- [ ] **Logout clears local Hive data** — on logout, clear the `completed_workout_dates` Hive box so data doesn't bleed between accounts on shared devices

### P2 — Polish (do if time allows)
- [ ] App icon is set via `flutter_launcher_icons` — run `dart run flutter_launcher_icons` and verify on a real device
- [ ] Splash screen — run `dart run flutter_native_splash:create` and confirm branding matches
- [ ] Privacy Policy and Terms of Use pages — both are tapped in the profile settings and go nowhere; minimum: open a URL via `url_launcher`
- [ ] Support Email item in profile — wire `url_launcher` mailto link
- [ ] Remove `carousel_slider` dependency from `save_page.dart` if `SavedPage` is no longer used anywhere

---

## This Week — Day-by-Day

### Monday
- Fix all P0 blocklist items
- Set up production FastAPI instance (if not already on a server — Railway, Fly.io, or Render are fast to deploy)
- Enable Supabase RLS, test with a real account

### Tuesday
- Fix P1 blocklist items
- Full end-to-end test: new user → onboarding → both plan generation paths → workout → streak → profile
- Test on a physical iOS device and Android device (not simulator)

### Wednesday
- App Store screenshots (6.5" iPhone, 5.5" iPhone, 12.9" iPad if targeting iPad)
- Play Store screenshots (phone + tablet)
- Write App Store description and keywords (see section below)
- TestFlight build submitted for Apple review

### Thursday
- Address any TestFlight feedback
- Internal beta on Android (Google Play internal testing track)
- P2 polish items
- Bump build number and submit final iOS build if rejected

### Friday
- Go live on App Store (if approved — Apple averages 24–48h review)
- Go live on Google Play (internal → production rollout at 20%)
- Announce

---

## App Store Listing

**App Name:** BeFit — AI Fitness Coach

**Subtitle:** Workouts, Nutrition & Streaks

**Keywords (100 chars):** workout,fitness,AI coach,gym plan,nutrition,calories,streak,exercise tracker,bodybuilding,weight loss

**Description (short version):**
> BeFit uses AI to build a personalised workout program from a photo of your physique or a conversation with your coach. Track every session, maintain your streak, and scan your meals — all in one dark, focused app.

**Category:** Health & Fitness  
**Age Rating:** 4+  
**Price:** Free (or freemium — decide before submission)

---

## Metrics & Data to Track

### Core Loop Metrics (instrument these before launch)

These tell you whether the app is working as intended.

| Metric | How to measure | Target |
|---|---|---|
| **Onboarding completion rate** | `users who reach home / users who start onboarding` | > 70% |
| **Plan generation rate** | `plans generated / users who completed onboarding` | > 60% |
| **D1 retention** | users who open app again the next day | > 40% |
| **D7 retention** | users who open app 7 days after install | > 20% |
| **D30 retention** | users who open app 30 days after install | > 10% |
| **Workout completion rate** | `sessions marked complete / sessions started` | > 50% |
| **Streak length distribution** | avg streak, median, % with streak > 7 days | avg > 3 |
| **AI path split** | photo analysis vs chat-to-plan | observe |

### What Supabase Already Stores

Your backend is already tracking the right raw data — you just need to query it:

- `workout_sessions` — every session start, complete, and duration
- `exercise_logs` — every exercise logged per session (reps, sets, weight)
- Streak computed from `workout_sessions.is_completed` + `session_date`
- `user_data` / profiles — height, weight, goal, experience level

### What You Need to Add

**1. A simple events table in Supabase**

```sql
create table analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  event text not null,            -- 'plan_generated', 'workout_started', etc.
  properties jsonb default '{}',  -- { "method": "photo" | "chat", "goal": "..." }
  created_at timestamptz default now()
);
alter table analytics_events enable row level security;
create policy "insert own events" on analytics_events
  for insert with check (auth.uid() = user_id);
```

**2. 10 key events to fire from the app**

| Event name | Where to fire | Key properties |
|---|---|---|
| `onboarding_started` | Welcome screen → next tap | — |
| `onboarding_completed` | After decide step, before plan gen | `{ goal, gender, experience }` |
| `plan_generation_started` | Before AI call | `{ method: "photo"/"chat" }` |
| `plan_generation_completed` | After plan saved | `{ method, duration_secs }` |
| `plan_generation_failed` | On error | `{ method, error }` |
| `workout_started` | WorkoutPage initState | `{ day_label, exercise_count }` |
| `workout_completed` | _saveWorkout success | `{ duration_mins, exercises_done }` |
| `streak_updated` | completeWorkout success | `{ new_streak, previous_streak }` |
| `nutrition_scan_completed` | After nutrition analysis saved | `{ calories, health_score }` |
| `chat_message_sent` | ChatViewModel.sendMessage | `{ context: "onboarding"/"workout" }` |

**3. A single lightweight analytics service**

```dart
// lib/data/services/analytics/analytics_service.dart
class AnalyticsService {
  final SupabaseClient _client;
  AnalyticsService(this._client);

  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('analytics_events').insert({
        'user_id': userId,
        'event': event,
        'properties': properties ?? {},
      });
    } catch (_) {
      // Never crash the app for analytics.
    }
  }
}
```

Register as a lazy singleton in `di.dart` and inject where needed. Keep it fire-and-forget — never `await` it on the UI path.

### Post-Launch Dashboard Queries

Run these in the Supabase SQL editor after launch:

```sql
-- Daily active users (last 7 days)
select date(created_at) as day, count(distinct user_id) as dau
from analytics_events
where created_at > now() - interval '7 days'
group by 1 order by 1;

-- Onboarding funnel
select event, count(distinct user_id) as users
from analytics_events
where event in ('onboarding_started','onboarding_completed','plan_generation_completed')
group by 1;

-- Plan generation method split
select properties->>'method' as method, count(*) as count
from analytics_events
where event = 'plan_generation_completed'
group by 1;

-- Avg streak across all users
select round(avg(current_streak),1) as avg_streak,
       max(current_streak) as top_streak,
       count(*) as users_with_streak
from (
  select user_id,
         count(*) filter (where is_completed) as current_streak
  from workout_sessions
  group by 1
) s;

-- D1 retention
select
  count(distinct a.user_id) as new_users,
  count(distinct b.user_id) as returned_d1,
  round(100.0 * count(distinct b.user_id) / nullif(count(distinct a.user_id),0), 1) as d1_pct
from analytics_events a
left join analytics_events b
  on a.user_id = b.user_id
  and date(b.created_at) = date(a.created_at) + 1
where a.event = 'onboarding_completed'
  and date(a.created_at) = current_date - 1;
```

---

## Feature Freeze

Everything below this line is **post-launch v1.1**. Do not build it this week.

- Push notifications (workout reminders, streak warnings)
- Social / friend challenges
- Video exercise demonstrations (YouTube player is already wired — enable later)
- Google Maps gym finder (dependency is already in pubspec — activate post-launch)
- Subscription / paywall (freemium model)
- Apple Health / Google Fit integration
- Adjust workout plan flow (settings item is already there, tapped → no-op)
- Language switching

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Apple review rejection (GEMINI_API_KEY exposed in binary) | Medium | High | Move key server-side — never ship a raw API key in a Flutter app; all Gemini calls must go through your FastAPI backend |
| Backend goes down during demo / launch day | Medium | High | Add a `/health` endpoint; set up Uptime Robot free monitor |
| Supabase free tier limits hit | Low | Medium | Free tier gives 500MB DB + 2GB bandwidth — plenty for MVP; upgrade at 200 users |
| Streak bug causes wrong value on first login | High (seen) | Medium | Already fixed — backend is source of truth via `/api/v1/logs/streak` |

---

## One Thing That Will Kill Retention If Not Fixed

**Workout reminders are not implemented.** Users who don't come back the next day lose their streak silently. This is the single highest-leverage post-launch feature. Implement push notifications in v1.1 within the first week after launch.
