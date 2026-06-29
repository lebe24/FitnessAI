# FitnessAI (BEFIT AI) — Session Context

**Last updated:** 2026-06-16  
**Project path:** `/Users/lebemac/Documents/Developer/flutter Apps/FitnessAI`  
**Backend path:** `/Users/lebemac/Documents/Developer/codes/backend_befit`  
**App name:** BEFIT - AI (`com.betfit.ai.app`)  
**Flutter target:** iPhone 16e simulator (`8117D2AD-A2FF-4D37-AC9D-1CC6FFCEE051`)

---

## Project Overview

Flutter + Dart cross-platform fitness app (iOS, Android, macOS, Web) backed by a
Python FastAPI server running in Docker.

| Layer | Technology |
|---|---|
| UI framework | Flutter / Dart |
| State management | Provider / ChangeNotifier (active layer) |
| Routing | `go_router` |
| DI | `get_it` |
| Auth / DB | Supabase |
| AI backend | FastAPI + OpenAI Agents SDK / Anthropic SDK (Docker, port 8080) |
| Local storage | Hive |
| HTTP client | Dio |
| Auth flows | Google Sign-In + Supabase email |
| Speech | `speech_to_text: ^7.4.0` |

### Architecture — Flutter

```
lib/
├── app/        ← old BLoC layer (not active, not deleted)
├── ui/         ← active MVVM / ChangeNotifier layer
├── domain/     ← shared entities, repositories, use-cases
└── data/       ← remote services, local services, repositories, models
```

`lib/main.dart` boots from `lib/ui/core/di.dart` and `lib/ui/core/routes/app_router.dart`.

### Architecture — Backend

```
src/
├── routes/api/          ← FastAPI routers (plans, analysis, motivation, health)
├── services/            ← business-logic services (one file per concern)
│   ├── workout_plan_service.py   ← dedicated service
│   └── services.py               ← legacy AgentService (analysis, nutrition, motivation)
├── lib/
│   ├── runner_factory.py         ← dispatches to OpenAI or Anthropic
│   ├── anthropic_runner.py
│   ├── prompt.py                 ← all AI prompt templates
│   └── agents.py / anthropic_agents.py
├── models/agent_model.py         ← Pydantic response models
└── tools/tools.py                ← vision + YouTube search tools
```

---

## 1. Environment Setup — CocoaPods

### Fix applied
1. Built **libyaml 0.2.5** from source → `~/.local`
2. Installed **rbenv** via git clone → `~/.rbenv`
3. Compiled **Ruby 3.3.11** via rbenv
4. Installed **CocoaPods 1.16.2**
5. Ran `pod install` in `ios/` and `macos/`
6. Added to `~/.zshrc`:
   ```bash
   export PATH="$HOME/.rbenv/bin:$PATH"
   eval "$(rbenv init - zsh)"
   export LANG=en_US.UTF-8
   ```

### To run the app
```bash
export PATH="$HOME/flutter/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(~/.rbenv/bin/rbenv init - bash)"
export LANG=en_US.UTF-8
cd "/Users/lebemac/Documents/Developer/flutter Apps/FitnessAI"
flutter run -d "8117D2AD-A2FF-4D37-AC9D-1CC6FFCEE051"
```

---

## 2. Backend Setup

### Running the backend
```bash
cd /Users/lebemac/Documents/Developer/codes/backend_befit
docker compose up --build          # first run
docker compose up                  # subsequent runs
```
Backend runs on **port 8080** with uvicorn hot-reload.

### Environment variables (`backend_befit/.env`)
```
OPENAI_API_KEY=...
RAPIDAPI_KEY=...
DATABASE_URL=postgresql://postgres.rmfgbhyzwblkhureofus:<password>@aws-0-eu-west-1.pooler.supabase.com:6543/postgres
SUPABASE_JWT_SECRET=...
```

### API versioning
All endpoints are under `/api/v1/`. Key routes:

| Method | Path | Service |
|---|---|---|
| POST | `/api/v1/plans/workout` | `WorkoutPlanService.generate()` |
| POST | `/api/v1/plans/saved` | Save plan to DB |
| GET  | `/api/v1/plans/saved` | List saved plans |
| GET/PUT/DELETE | `/api/v1/profile` | User profile CRUD |
| POST | `/api/v1/analysis/body-composition` | Body analysis |
| POST | `/api/v1/analysis/nutrition` | Nutrition analysis |
| POST | `/api/v1/motivation/quote` | Motivation quote |
| POST/GET/DELETE | `/api/v1/nutrition/logs` | Nutrition logs |
| POST/GET/DELETE | `/api/v1/scans` | Body scans |
| POST/GET/DELETE | `/api/v1/chat/messages` | Chat history |
| WS | `/ws/chat` | Fitness coaching |
| WS | `/ws/nutrition` | Nutrition coaching |
| GET | `/api/v1/health` | Full status |

---

## 3. Supabase Database

### Project ref: `rmfgbhyzwblkhureofus` | Region: `eu-west-1`

### Connection
- **Direct connection** (`db.*.supabase.co:5432`) — blocked in Docker (IP allowlist required)
- **Transaction Pooler** (`aws-0-eu-west-1.pooler.supabase.com:6543`) — use this in `DATABASE_URL`
- SQLAlchemy requires `statement_cache_size=0` in `connect_args` when using the transaction pooler (PgBouncer limitation)

### Tables (all have RLS ON)

| Table | Key columns | FK |
|---|---|---|
| `user_profiles` | `id` (= auth UUID), name, email, gender, dob, height_cm, weight_kg, goal, experience, workout_days | — |
| `workout_plans` | `id`, `user_id`, `plan_data` (JSONB), goal, focus, is_active, is_synced | → user_profiles |
| `workout_sessions` | `id`, `user_id`, `workout_plan_id`, session_date, duration_mins, is_completed | → user_profiles, workout_plans |
| `exercise_logs` | `id`, `user_id`, `session_id`, exercise_name, sets_data (JSONB) | → user_profiles, workout_sessions |
| `nutrition_logs` | `id`, `user_id`, `analysis_data` (JSONB), health_score, calories | → user_profiles |
| `chat_history` | `id`, `user_id`, role, content, channel, session_id | → user_profiles |
| `body_scans` | `id`, `user_id`, `analysis_data` (JSONB), body_fat_pct, muscle_mass_kg, bmi | → user_profiles |

### RLS Policies (each table has 2)
- `authenticated` users: full CRUD on own rows (`auth.uid() = user_id`)
- `service_role`: bypass RLS (for backend inserts)

### Auth trigger
```sql
-- Auto-creates user_profiles row on new Supabase auth sign-up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### JWT verification (`src/core/security.py`)
Auto-detects algorithm from JWT header:
- **HS256**: verifies with `SUPABASE_JWT_SECRET`
- **RS256/ES256**: fetches JWKS from `{iss}/.well-known/jwks.json` (cached 1 hour)

---

## 4. Flutter Data Flow — Profile & Onboarding Sync

### Problem (fixed)
All tables FK-reference `user_profiles.id`. If no row exists, every insert fails silently.

### Fix
1. **Auth trigger** in Supabase auto-creates `user_profiles` row on sign-up
2. **`AuthRepositoryImpl._buildAndSyncUser()`** calls `profileRemote.upsertProfile()` on every sign-in
3. Onboarding fields (gender, dob, height, weight, goal, experience, workout_days) are read from `ProfileLocalDataSource` (Hive) and included in the upsert

```dart
// auth_repository_impl.dart
final onboarding = await profileLocal.getOnboardingData();
await profileRemote.upsertProfile(ProfileEntity(
  name: entity.name, email: entity.email, avatarUrl: entity.avatarUrl,
  gender: onboarding?.gender, dob: onboarding?.dob,
  height: onboarding?.height, weight: onboarding?.weight,
  goal: onboarding?.goal, experience: onboarding?.experience,
  workoutDays: onboarding?.workoutDays,
));
```

### DI wiring
```dart
AuthRepositoryImpl(sl(), sl(), sl())
//                  ^remote  ^profileRemote  ^profileLocal
```

---

## 5. Flutter Data Flow — Workout Plan Sync

### Problem (fixed)
`StorageRepositoryImpl.saveFitnessPlan()` only wrote to Hive. Backend `workout_plans` table was always empty.

### Fix
New `WorkoutPlanSyncDataSource` (`lib/data/services/storage/workout_plan_sync_service.dart`) calls `POST /api/v1/plans/saved` after every local save.

```dart
// storage_repository_impl.dart — saveFitnessPlan()
await localDataSource.saveFitnessPlan(storedPlan);        // always first
try {
  final cloudId = await syncDataSource.saveToCloud(plan: workoutPlan, ...);
  // marks isSynced: true, cloudId set
} catch (_) { /* non-fatal — local plan survives */ }
```

---

## 6. Speech-to-Text (Exercise Log Dialog)

**File:** `lib/ui/features/fitness/views/exercise_hero_page.dart`  
**Package:** `speech_to_text: ^7.4.0`

### iOS permissions (`Info.plist`)
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>BeFit AI uses speech recognition to fill in your workout sets by voice.</string>
<key>NSMicrophoneUsageDescription</key>
<string>BeFit AI needs microphone access for voice input during workouts.</string>
```

### Behaviour
- Tap mic → waveform animation replaces set rows; live transcript shows as you speak
- **Keeps listening indefinitely** — when the OS ends an utterance segment, `_restartListening()` immediately opens a new session (`_userStopped` guard prevents restart loops)
- `pauseFor: 30s` — long enough to survive natural pauses
- Tap stop → captures full `_liveText`, calls `_parseAndFill()`, waveform hides, set fields populate
- Dialog stays open so user can review before saving

### Parser (`_parseAndFill`)
Handles two spoken formats:
- **Explicit:** `"set 1 80 kg 10 reps set 2 75 kilos 8 reps"` (regex with set number)
- **Implicit:** `"80 kilos 10 reps 75 kilos 8 reps"` (pairs in order)

### State fields
```dart
bool _isListening   // waveform visible
bool _userStopped   // prevents auto-restart after explicit stop
double _soundLevel  // 0.0–1.0, drives waveform bar height
String _liveText    // interim transcript, shown live as user speaks
String _statusText  // error messages
```

---

## 7. Runtime Bugs Fixed (historical)

| Bug | Fix |
|---|---|
| `!_dirty` assertion (`ChangeNotifierProvider<FitnessViewModel>`) | `loadFitnessPlans()` moved inside `addPostFrameCallback` |
| `MediaQuery.of()` on deactivated widget | Added `if (!mounted) return;` |
| Supabase `public.user_data` table not found | Redirected `UserDataRepositoryImpl` to use `WorkoutLogRemoteDataSource` |
| `RangeError` crash on launch (nonce generator) | Added missing `W` to 62-char alphabet in `di.dart` |
| Pydantic `plan` field missing (HTTP 500 on OpenAI 429) | Route handlers check `result["status"] == "error"` before model validation |
| Docker `DATABASE_URL` missing → 503 | Added `DATABASE_URL` and `SUPABASE_JWT_SECRET` to `docker-compose.yml` |
| JWT RS256 vs HS256 mismatch → 401 | `security.py` auto-detects alg; fetches JWKS for RS256/ES256 |
| Transaction pooler prepared statement error | Added `statement_cache_size=0` to `database.py` connect_args |
| STT stops abruptly mid-speech | `onStatus` now calls `_restartListening()` instead of setting `_isListening=false` |

---

## 8. DI Registration Summary (`lib/ui/core/di.dart`)

```dart
// Auth — 3 args now (added ProfileLocalDataSource)
AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<ProfileRemoteDataSource>(), sl<ProfileLocalDataSource>())

// Storage — 3 args now (added WorkoutPlanSyncDataSource)
StorageRepositoryImpl(
  localDataSource: sl(), fileDataSource: sl(), syncDataSource: sl()
)

// New registrations
sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl());
sl.registerLazySingleton<WorkoutPlanSyncDataSource>(() => WorkoutPlanSyncDataSourceImpl());
sl.registerLazySingleton<WorkoutLogRemoteDataSource>(() => WorkoutLogRemoteDataSourceImpl());
sl.registerLazySingleton<UserDataRepository>(() => UserDataRepositoryImpl(sl<WorkoutLogRemoteDataSource>()));
```

---

## 9. Known Open Issues

| Issue | Status | Notes |
|---|---|---|
| iOS UIScene lifecycle migration warning | ⚠️ Open | Follow https://flutter.dev/to/uiscene-migration |
| `FitnessViewModel.loadFitnessPlans()` in `app_router.dart` | ⚠️ Open | `..loadFitnessPlans()` in `create:` — `!_dirty` risk |
| Emoji in `summary.dart` | ⚠️ Open | `_SummaryRow` emoji needs `inherit: false` fix |
| WebSocket uses `ws://` not `wss://` | ⚠️ Open | Update for production |
| Cloud Run deployment | ⚠️ Pending | Add `DATABASE_URL` + `SUPABASE_JWT_SECRET` to Cloud Run env vars; run `alembic upgrade head` |

---

## 10. File Map (all changed files)

```
lib/
├── ui/
│   ├── core/
│   │   └── di.dart                                ← AuthRepositoryImpl 3 args; WorkoutPlanSyncDataSource; WorkoutLogRemoteDataSource; UserDataRepositoryImpl
│   └── features/
│       ├── fitness/views/exercise_hero_page.dart  ← STT: mic button, waveform, live transcript, restart-on-done
│       ├── home/views/result_modal.dart           ← triggers SaveFitnessPlanUsecase on plan ready
│       ├── onboarding/views/goal.dart             ← emoji fix
│       ├── onboarding/views/chat_screen.dart      ← Claude.ai-style redesign
│       └── chat/views/chat_message_bubble.dart    ← redesign + markdown
├── data/
│   ├── services/
│   │   ├── profile/
│   │   │   ├── profile_remote_service.dart        ← upsertProfile with all onboarding fields
│   │   │   └── profile_local_service.dart         ← wraps OnboardingStorage.loadOnboardingData()
│   │   ├── storage/
│   │   │   └── workout_plan_sync_service.dart     ← NEW: POST /api/v1/plans/saved
│   │   └── workout_plan/
│   │       └── workout_plan_remote_service.dart   ← pure HTTP client
│   ├── repositories/
│   │   ├── auth_repository_impl.dart              ← _buildAndSyncUser includes onboarding fields; ProfileLocalDataSource injected
│   │   ├── storage_repository_impl.dart           ← saveFitnessPlan syncs to backend after local save
│   │   ├── profile_repository_impl.dart           ← syncToRemote() calls remote upsert
│   │   ├── home_repository_impl.dart              ← model conversion + _validateResponse
│   │   └── user_data_repository_impl.dart         ← uses WorkoutLogRemoteDataSource (user_data table removed)
│   └── models/home/workout_plan_model.dart        ← full rewrite for new backend schema
├── domain/
│   └── repositories/home_repository.dart         ← removed getWorkoutPlan()
pubspec.yaml                                      ← flutter_markdown, speech_to_text added

ios/Runner/Info.plist                             ← NSSpeechRecognitionUsageDescription added

backend_befit/
├── .env                                          ← DATABASE_URL uses eu-west-1 transaction pooler
├── docker-compose.yml                            ← DATABASE_URL + SUPABASE_JWT_SECRET added
└── src/
    ├── core/
    │   ├── database.py                           ← statement_cache_size=0; lazy engine init
    │   └── security.py                           ← RS256/HS256 auto-detect; JWKS cache
    ├── models/db/
    │   ├── user_profile.py
    │   ├── workout_plan.py
    │   ├── workout_session.py
    │   ├── exercise_log.py
    │   ├── nutrition_log.py
    │   ├── chat_history.py
    │   └── body_scan.py
    └── routes/api/
        ├── profile.py                            ← GET/PUT/DELETE /api/v1/profile
        ├── workout_plans_db.py                   ← CRUD /api/v1/plans/saved
        ├── nutrition_logs.py                     ← CRUD /api/v1/nutrition/logs
        ├── body_scans.py                         ← CRUD /api/v1/scans
        ├── chat_history.py                       ← CRUD /api/v1/chat/messages
        ├── plans.py                              ← POST /api/v1/plans/workout
        ├── analysis.py
        └── motivation.py
```
