# BeFit AI — Project Context

**Last updated:** 2026-06-22
**Version:** 0.1.0+7 → target 1.0.0+1 for launch

## Overview

**BeFit AI** is a Flutter-based personal fitness assistant that uses AI to generate personalised workout plans from body photos, analyse food nutrition, and provide real-time coaching via chat.

- **Package name:** `fitness` | **Display name:** Befit AI
- **Platforms:** iOS, Android
- **State management:** `provider` (ChangeNotifier ViewModels)
- **DI:** `get_it` service locator
- **Navigation:** `go_router` v16
- **Backend:** FastAPI in Docker (port 8080)
- **Auth:** Supabase (Google OAuth + JWT)
- **Database:** Supabase Postgres — via FastAPI + SQLAlchemy asyncpg (transaction pooler, port 6543)

---

## System Architecture

```
Flutter App
  ├── Auth flows       →  Supabase Auth (Google OAuth, JWT)
  └── All app data     →  FastAPI (Docker / Cloud Run)
                              └── SQLAlchemy (asyncpg, statement_cache_size=0)
                                    └── Supabase Postgres (transaction pooler, eu-west-1:6543)
```

**JWT flow:** Flutter receives a Supabase JWT on login → sends as `Authorization: Bearer <token>` → FastAPI auto-detects alg (HS256 uses `SUPABASE_JWT_SECRET`; RS256/ES256 fetches JWKS from Supabase, cached 1 hour) → extracts `user_id` from `sub` claim.

**Database connection:** Use the **Transaction Pooler** URL (`aws-0-eu-west-1.pooler.supabase.com:6543`) — not the direct connection. SQLAlchemy requires `statement_cache_size=0` in `connect_args`.

---

## Flutter Architecture

Clean Architecture with MVVM presentation layer.

```
Domain (pure Dart)
  └── Entities, Repository interfaces, Use cases

Data (I/O)
  └── API/local models, Service implementations, Repository implementations

UI (Presentation)
  └── ViewModels (ChangeNotifier), Views, Routes
```

State flows: View → ViewModel → Use case → Repository → Service → Remote/Local.

---

## Flutter Directory Structure

```
lib/
├── main.dart
├── data/
│   ├── models/
│   │   ├── auth/user_model.dart
│   │   ├── home/workout_plan_model.dart
│   │   ├── onboarding/onboarding_data.dart
│   │   ├── profile/profile_model.dart
│   │   └── storage/stored_fitness_plan_model.dart
│   ├── repositories/
│   │   ├── auth_repository_impl.dart           # upserts profile + onboarding on every sign-in
│   │   ├── home_repository_impl.dart
│   │   ├── profile_repository_impl.dart
│   │   ├── storage_repository_impl.dart        # local save + cloud sync on plan save
│   │   ├── user_data_repository_impl.dart      # uses WorkoutLogRemoteDataSource
│   │   └── workout_log_repository_impl.dart
│   └── services/
│       ├── api/
│       ├── auth/auth_remote_service.dart
│       ├── chat/
│       │   ├── chat_remote_data_source.dart    # WebSocket
│       │   ├── chat_history_storage.dart       # Hive; key = {userId}_{context}_{date}
│       │   └── chat_plan_service.dart          # POST /api/v1/plans/from-chat (authenticated Dio)
│       ├── nutrition/
│       ├── profile/
│       │   ├── profile_local_service.dart
│       │   └── profile_remote_service.dart
│       ├── storage/
│       │   ├── local_storage_service.dart
│       │   ├── file_storage_service.dart
│       │   └── workout_plan_sync_service.dart  # POST /api/v1/plans/saved
│       └── workout_plan/
│           └── workout_plan_remote_service.dart
├── domain/
│   ├── models/
│   ├── repositories/
│   └── use_cases/
└── ui/
    ├── core/
    │   ├── di.dart
    │   ├── routes/app_router.dart
    │   └── constants/
    └── features/
        ├── auth/
        ├── chat/
        │   └── view_models/chat_view_model.dart  # chatContext field ('onboarding'/'workout')
        ├── fitness/
        │   ├── view_models/
        │   │   ├── fitness_view_model.dart        # streak from backend; _disposed guard
        │   │   └── workout_log_view_model.dart
        │   └── views/
        │       ├── home_page.dart                 # weekly progress card replaces saved data card
        │       ├── workout_page.dart              # calls FitnessViewModel.completeWorkout()
        │       ├── exercise_hero_page.dart        # STT mic + waveform + log dialog
        │       ├── streak_sheet.dart
        │       └── saved_program.dart             # renamed from save_page.dart; workout plans only
        ├── home/
        │   └── views/home_screen.dart             # _pages as late final field (not getter)
        ├── nutrition/
        ├── onboarding/
        │   └── views/
        │       ├── chat_screen.dart               # Perplexity-style; GeneratePlanFab
        │       └── decide.dart                    # passes onboardingData in route extra
        └── profile/
            └── views/profile_page.dart            # full dark redesign; SavedProgramPage navigation
```

---

## Routing

| Path | Screen |
|---|---|
| `/` | SplashScreen |
| `/welcome` | Welcome |
| `/login` | AuthLoginPage |
| `/onboarding` | OnboardingScreen |
| `/home` | HomeScreen (bottom nav shell) |
| `/workout` | WorkoutPage (wraps FitnessViewModel provider) |
| `/chat` | ChatScreen — instanceName: 'onboarding'; receives OnboardingData via extra |
| `/nutrition` | NutritionPage |
| `/nutrition-analysis` | AnalysisOutputPage |
| `/workout-plan-detail` | WorkoutPlanDetailPage |
| `/onboarding-analysis` | AnalysisPageWithData |

---

## Features

### Bottom Nav Shell (`home_screen.dart`)
Four tabs rendered as `late final List<Widget> _pages` (initialised in `initState` — **not a getter**). This is critical: a getter recreates providers on every `setState`, which disposes `FitnessViewModel` mid-flight and causes `ChangeNotifier` assertion errors.

```
Tab 0 — FitnessHomePage  (ChangeNotifierProvider<FitnessViewModel>)
Tab 1 — ActivityPage
Tab 2 — StatisticsPage
Tab 3 — ProfilePage      (creates its own MultiProvider internally)
```

### Home Page (`home_page.dart`)
- Date strip, greeting, streak badge → opens `StreakSheet`
- Nutrition Scanner card
- Body Composition scan card
- Motivation banner
- **Weekly Progress card** — shows Mon–Sun day dots coloured by: completed (lime check), today (white dot), planned+missed (red), future planned (faint ring). Driven by `FitnessViewModel.completedDates` and `workoutMappings`.

### Streak Tracking
**Source of truth: backend** (`GET /api/v1/logs/streak`).

`FitnessViewModel._loadStreak()` — hits backend first, falls back to Hive cache.  
`FitnessViewModel.completeWorkout(date, {durationMins})` — creates a session + marks it complete via backend, then re-fetches streak. Hive updated for calendar display only.  
`FitnessViewModel` has `_disposed` guard on all `notifyListeners()` calls.

### Chat — Separated Contexts
Two fully independent chat instances, each with their own WebSocket and Hive history:

| instanceName | Context | History key pattern |
|---|---|---|
| `'onboarding'` | Decide.dart → ChatScreen; pre-plan conversation | `{userId}_onboarding_{date}` |
| `'workout'` | WorkoutPage → FitnessChatModal; in-session coach | `{userId}_workout_{date}` |

DI registration: both as `sl.registerFactory<ChatViewModel>()` with named instance. Each factory creates its own `ChatRepositoryImpl` + `ChatRemoteDataSourceImpl` (isolated WebSocket).

### Chat → Plan Generation (`chat_screen.dart`)
`_GeneratePlanFab` appears when messages exist. Tap → `_PlanGenerationSheet`:
1. Builds transcript: `"User: …\nCoach: …"`
2. Calls `ChatPlanService.generateFromChat()` → `POST /api/v1/plans/from-chat`
3. `WorkoutPlanModel.fromJson(raw)` → `SaveFitnessPlanUsecase(workoutPlan: plan, imageFilePath: null)`
4. On success → navigate to `/home`

### Profile Page (`profile_page.dart`)
Full dark redesign. Hero header with gradient avatar, name, email, goal pill, stats row (height/weight/days). Edit button → `PersonalDetailsPage`. Saved data card → `SavedProgramPage`. Settings groups with icon containers and dividers.

`MultiProvider` creates `ProfileViewModel` + `FitnessViewModel` + (removed) `NutritionViewModel`.  
`_SavedDataCard` navigates with `ChangeNotifierProvider.value(value: fitnessVm)` → `SavedProgramPage`.

### Saved Programs Page (`saved_program.dart`)
Renamed from `save_page.dart`. **Workout plans only** — nutrition data removed. Vertical list of `_PlanCard` widgets showing goal, days/week, training split, duration, creation date. Tap → `/workout-plan-detail`. Empty state with lime icon. Staggered `flutter_animate` entrance.

### Profile Sync
Every sign-in calls `PUT /api/v1/profile` with auth fields **and** onboarding data (gender, dob, height_cm, weight_kg, goal, experience, workout_days) from Hive. Ensures `user_profiles` FK row exists before any other table insert.

Supabase auth trigger auto-creates row on first sign-up:
```sql
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Workout Plan Sync
`StorageRepositoryImpl.saveFitnessPlan()` writes to Hive first (offline-safe), then `POST /api/v1/plans/saved`. Cloud failure is non-fatal.

### Speech-to-Text (Exercise Log Dialog)
**File:** `exercise_hero_page.dart`
- Mic button toggles continuous listening; waveform animation (7 sine bars) replaces set rows
- `onStatus: 'done'/'notListening'` → `_restartListening()` (100ms delay) — never drops mid-sentence
- `_userStopped` flag prevents restart loops
- Parser handles explicit (`"set 1 80 kg 10 reps"`) and implicit (`"80 kg 10 reps"`) formats

---

## Backend

### REST Endpoints

| Method | Path | Description |
|---|---|---|
| GET/PUT/DELETE | `/api/v1/profile` | User profile |
| POST | `/api/v1/plans/workout` | Generate AI workout plan (photo) |
| POST | `/api/v1/plans/from-chat` | Generate AI workout plan (conversation) |
| POST/GET/PATCH/DELETE | `/api/v1/plans/saved` | Saved workout plans |
| POST/GET | `/api/v1/logs/sessions` | Workout sessions |
| PATCH/DELETE | `/api/v1/logs/sessions/{id}` | Complete / delete session |
| POST/GET | `/api/v1/logs/sessions/{id}/exercises` | Exercise logs |
| GET | `/api/v1/logs/streak` | Current + longest streak |
| POST/GET/DELETE | `/api/v1/nutrition/logs` | Nutrition logs |
| POST/GET/DELETE | `/api/v1/scans` | Body scans |
| POST | `/api/v1/analysis/nutrition` | Food photo analysis |
| POST | `/api/v1/motivation/quote` | Motivation quote |
| GET | `/api/v1/health` | Health status |
| WS | `/ws/chat` | Fitness coaching chat |

### `POST /api/v1/plans/from-chat` — FromChatRequest
```python
class FromChatRequest(BaseModel):
    conversation: str   # "User: …\nCoach: …" formatted transcript
    goal: str = ""
    gender: str = ""
    height: str = ""
    weight: str = ""
    experience: str = ""
    duration: str = ""
    training_split: str = ""
    extra_info: str = ""
```
Calls `WorkoutPlanService.generate_from_text()` — injects conversation as physique analysis text, runs same retry pipeline as photo path.

### Database — Supabase Postgres

**Project ref:** `rmfgbhyzwblkhureofus` | **Region:** `eu-west-1`

| Table | Key columns | Notes |
|---|---|---|
| `user_profiles` | id (auth UUID), name, email, gender, dob, height_cm, weight_kg, goal, experience, workout_days | Auto-created by auth trigger |
| `workout_plans` | id, user_id, plan_data (JSONB), goal, focus, is_active, is_synced | Synced from Flutter on plan save |
| `workout_sessions` | id, user_id, workout_plan_id, session_date, duration_mins, is_completed | Streak computed from this table |
| `exercise_logs` | id, user_id, session_id, exercise_name, sets_data (JSONB) | |
| `nutrition_logs` | id, user_id, analysis_data (JSONB), health_score, calories | |
| `chat_history` | id, user_id, role, content, channel, session_id | channel: "fitness" or "nutrition" |
| `body_scans` | id, user_id, analysis_data (JSONB), body_fat_pct, muscle_mass_kg, bmi | |

All tables: **RLS ON**, 2 policies each (`authenticated` own-rows + `service_role` bypass).

---

## DI Registration (`lib/ui/core/di.dart`)

```dart
// Auth — 3 args
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(sl(), sl(), sl()),
);

// Storage — 3 args (local, file, sync)
sl.registerLazySingleton<StorageRepository>(
  () => StorageRepositoryImpl(localDataSource: sl(), fileDataSource: sl(), syncDataSource: sl()),
);

// Chat — two named factory instances (each gets its own WebSocket)
sl.registerFactory<ChatViewModel>(
  () => makeChatViewModel('onboarding'), instanceName: 'onboarding');
sl.registerFactory<ChatViewModel>(
  () => makeChatViewModel('workout'), instanceName: 'workout');

// FitnessViewModel — factory with WorkoutLogRepository injected
sl.registerFactory(() => FitnessViewModel(
  getAllFitnessPlansUsecase: sl(),
  workoutLogRepository: sl(),   // ← streak from backend
));

// Key singletons
sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl());
sl.registerLazySingleton<ProfileLocalDataSource>(() => ProfileLocalDataSourceImpl());
sl.registerLazySingleton<WorkoutPlanSyncDataSource>(() => WorkoutPlanSyncDataSourceImpl());
sl.registerLazySingleton<WorkoutLogRemoteDataSource>(() => WorkoutLogRemoteDataSourceImpl());
sl.registerLazySingleton<WorkoutLogRepository>(() => WorkoutLogRepositoryImpl(sl()));
sl.registerLazySingleton<UserDataRepository>(
  () => UserDataRepositoryImpl(sl<WorkoutLogRemoteDataSource>()));
```

---

## UI Design System

- **Accent:** `#CCFF00` (lime / `_kLime`)
- **Background:** `#0A0C12` (`_kBg` / `_kSurface`)
- **Card:** `#111318` (`_kCard`)
- **Border:** `#1E2330` (`_kBorder`)
- **Dim white:** `Color(0x80FFFFFF)` (`_kDimWhite` / `_kDim`)
- **Fonts:** Poppins (headings/numbers), Inter (body/labels)
- **Pattern:** file-level `const Color` tokens, private widget classes
- **API:** always `withValues(alpha:)` — never `withOpacity()` (deprecated)
- **Chat:** wrap in `ChatThemeScope(palette: ChatPalette.dark)`

---

## Environment Variables

### Flutter (`.env`)

| Key | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase publishable key |
| `BACKEND_BASE_URL` | FastAPI base URL (`http://localhost:8080` dev; production URL for release) |
| `YOUTUBE_RAPID_KEY` | RapidAPI key for YouTube |
| `Oauth_webClientId` / `OAUTH_IOS_CLIENT` / `OAUTH_ANDROID_CLIENT` | Google OAuth |

### Backend (`.env`)

| Key | Purpose |
|---|---|
| `OPENAI_API_KEY` | OpenAI API key |
| `RAPIDAPI_KEY` | RapidAPI key for YouTube |
| `DATABASE_URL` | `postgresql://postgres.<ref>:<pw>@aws-0-eu-west-1.pooler.supabase.com:6543/postgres` |
| `SUPABASE_JWT_SECRET` | From Supabase → Project Settings → API → JWT Secret |

---

## Running the App

```bash
export PATH="$HOME/flutter/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
eval "$(~/.rbenv/bin/rbenv init - bash)"
export LANG=en_US.UTF-8
cd "/Users/lebemac/Documents/Developer/flutter Apps/FitnessAI"
flutter run -d "8117D2AD-A2FF-4D37-AC9D-1CC6FFCEE051"   # iPhone 16e simulator
```

```bash
# Backend
cd /Users/lebemac/Documents/Developer/codes/backend_befit
docker compose up --build   # first run
docker compose up           # subsequent
```

---

## Runtime Bugs Fixed (historical)

| Bug | Fix |
|---|---|
| `!_dirty` ChangeNotifier assertion on tab switch | `_pages` in `home_screen.dart` changed from getter to `late final` field in `initState` |
| `FitnessViewModel` disposed then `notifyListeners()` called | Added `_disposed` bool + `dispose()` override; all `notifyListeners()` guarded with `if (!_disposed)` |
| Streak always zero | `_loadStreak()` now hits `GET /api/v1/logs/streak` first (backend = source of truth); Hive is cache only |
| Streak not updating on workout completion | `workout_page.dart._saveWorkout()` now calls `FitnessViewModel.completeWorkout(date, durationMins: ...)` which creates + completes a backend session |
| Two chat screens sharing same WebSocket + Hive history | Named DI factories (`'onboarding'`/`'workout'`); Hive key namespaced `{userId}_{context}_{date}` |
| `_SavedDataCard` column overflow (82px constraint) | Removed `mainAxisAlignment: spaceBetween`, switched to `mainAxisAlignment: center` with fixed gaps; card height 130px |
| `pages` getter disposing providers on tab switch | Changed to `late final List<Widget> _pages` in `initState` |
| `HomeRepositoryImpl._validateResponse` is private | Removed call; rely on `WorkoutPlanModel.fromJson()` to throw on invalid data |
| `local function starts with underscore` lint | Renamed `_makeChatViewModel` → `makeChatViewModel` |
| Supabase `public.user_data` table not found | `UserDataRepositoryImpl` redirected to use `WorkoutLogRemoteDataSource` |
| JWT RS256 vs HS256 mismatch → 401 | `security.py` auto-detects alg; fetches JWKS for RS256/ES256 |
| Transaction pooler prepared statement error | `statement_cache_size=0` in `database.py` connect_args |
| STT stops abruptly mid-speech | `onStatus` calls `_restartListening()` instead of setting `_isListening=false` |

---

## Known Open Issues

| Issue | Status | Notes |
|---|---|---|
| `intl` missing from `pubspec.yaml` | ⚠️ **Fix before launch** | `saved_program.dart` uses `DateFormat`; add `intl: ^0.19.0` |
| WebSocket uses `ws://` not `wss://` | ⚠️ Fix before launch | Update `Constant` for production |
| Gemini / AI API key in Flutter binary | ⚠️ Fix before launch | All AI calls must route through FastAPI — never call AI APIs directly from Flutter |
| `UpdateWorkoutCompletionUsecase` is a no-op | ℹ️ By design | Session completion uses `FitnessViewModel.completeWorkout()` → backend; usecase kept for interface compatibility |
| iOS UIScene lifecycle migration warning | ⚠️ Open | https://flutter.dev/to/uiscene-migration |
| Push notifications not implemented | ⚠️ Post-launch v1.1 | Highest-leverage retention feature |
| `Adjust workout plan` settings item | ⚠️ Post-launch | Taps → no-op |
| `Language` settings item | ⚠️ Post-launch | Taps → no-op |
| Cloud Run deployment | ⚠️ Pending | Add env vars; run `alembic upgrade head` |

---

## Launch Checklist (see MVP.md)

See `MVP.md` in the project root for the full day-by-day launch plan, App Store listing copy, analytics instrumentation guide (`analytics_events` table + 10 key events), and post-launch SQL dashboard queries.

Key pre-launch actions:
1. Add `intl: ^0.19.0` to `pubspec.yaml`
2. Point `BACKEND_BASE_URL` to production FastAPI server
3. Switch WebSocket from `ws://` to `wss://`
4. Verify Supabase RLS on all tables with a non-admin user
5. Add release keystore SHA to Google Cloud Console + Supabase OAuth
6. Bump `version: 1.0.0+1` in `pubspec.yaml`
