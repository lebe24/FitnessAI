# FitnessAI — Claude Context

## Project Overview
Flutter fitness app (package: `fitness`) that combines AI-powered workout planning, nutrition scanning, and progress tracking. Backend is Supabase; AI features call a custom agent API.

## Architecture
Clean architecture with three layers:

```
lib/
├── data/          # Models, repository impls, remote datasources
├── domain/        # Entities, repository interfaces, use cases
└── ui/
    ├── core/      # Theme, routing, DI (GetIt via di.dart), shared widgets
    └── features/  # One folder per feature (auth, home, fitness, nutrition, chat, onboarding, profile, …)
        └── <feature>/
            ├── view_models/   # ChangeNotifier ViewModels
            └── views/         # Stateless/Stateful widgets
```

State management: `provider` (ChangeNotifier). DI: `get_it` via `lib/ui/core/di.dart` (`sl<T>()`).

## Routing (`lib/ui/core/routes/app_router.dart`)
Uses `go_router`, configured via `ScreenPaths.appRouter`. `context.push(...)` works from any
screen regardless of whether it was reached via `go_router` or a plain `Navigator.push`
(`MaterialPageRoute`) — the `GoRouter` instance is app-wide. Key routes:

| Path | Screen |
|------|--------|
| `/` | SplashScreen |
| `/welcome` | Welcome |
| `/login` | AuthLoginPage |
| `/onboarding` | OnboardingScreen |
| `/analysis` | AnalysisPageWithData (loads OnboardingData from storage, wraps AnalysisPage) |
| `/onboarding-analysis` | Same as `/analysis` (re-uses `AnalysisPageWithData`) |
| `/home` | HomePage |
| `/settings` | SettingsPage |
| `/workout` | WorkoutPage (`extra: {workoutDay, date}`) |
| `/nutrition` | NutritionPage |
| `/nutrition-analysis` | AnalysisOutputPage |
| `/workout-plan-detail` | WorkoutPlanDetailPage (`extra: {storedPlan}`) |
| `/chat` | ChatScreen (`extra: {userId, userName, workoutPlan, onboardingData}`) |

Several pages reached via `Navigator.push(MaterialPageRoute(...))` (e.g. `PersonalDetailsPage`,
`AdjustWorkoutPlanPage`, `SavedProgramPage`) still successfully call `context.push('/analysis')` /
`context.push('/workout-plan-detail', extra: ...)` internally — this is the established pattern,
not a bug.

## Design System
- **Accent colour**: `_lime = Color(0xFFCCFF00)` — used for highlights, selected states, CTA glows
- **Dark surfaces**: `0xFF060705` (top), `0xFF0D0F14` (bottom), `0xFF0A0C12` (sheet)
- **Fonts**: `GoogleFonts.poppins` (headings, buttons), `GoogleFonts.inter` (body, captions)
- **Theme**: `AppTheme.whiteThemeMode` in `lib/ui/core/theme/theme.dart` — no global `fontFamily` set
- **Animations**: `flutter_animate` everywhere; standard delays 200 ms → 600 ms stagger

## Key Asset Paths (`lib/ui/core/constants/assets.dart`)
```dart
ImagePath.appLogo       // assets/logo/app-logo.png
ImagePath.loginCover    // assets/image/login-cover.jpg
ImagePath.googleLogo    // assets/logo/google_logo.png
```

## Auth (`lib/ui/features/auth/`)
- `AuthLoginPage` — sign-in screen; dark cinematic layout (WelcomeView-inspired)
  - Split gradient background, ShaderMask hero image fade, `AnimatedPositioned` content
  - Top bar: back button (left) + centred logo (no app-name text)
  - Google sign-in + Gmail/email toggle form
  - `resizeToAvoidBottomInset: false`; keyboard handled via `viewInsets.bottom`
- `SignUp` (in `auth_page.dart`) — embedded in onboarding flow via `BaseStepLayout`
- `AuthViewModel` — `ChangeNotifier`; exposes `signInWithGoogle()`, `signInWithGmail(email)`, `isLoading`, `error`, `isAuthenticated`, `user`

## Onboarding (`lib/ui/features/onboarding/`)
Multi-step flow driven by `OnboardingViewModel`. Steps in order:
`gender → workoutDays → goal → experience → heightAndWeight → dob → signup → summary → motivationQuote`

All steps use `BaseStepLayout` (in `share_screen.dart`).  
`GoalStep` uses emoji preset cards (`🔥 💪 ⚖️ 🎨`) — emoji Text widgets need `fontFamilyFallback` to render correctly on iOS 26+.

## Backend (separate repo: `codes/backend_befit`)
FastAPI service backed by Supabase Postgres (SQLAlchemy async ORM, asyncpg, Alembic migrations).
Supabase JWT auth — `user_id` is always resolved server-side from the token, never trusted from
the request body. AI calls (workout plans, body composition, nutrition, workout-session feedback)
go through this backend, not directly from the Flutter client to an AI provider.

### `workout_sessions` table — one row per day, not per exercise
Each day's session is a single row. Exercises and AI feedback are embedded as JSONB rather than
living in separate child tables:
- `workout_logs` (JSONB array) — `[{name, sets, reps, notes?, muscle_group?, equipment?, order_index}]`
- `feedback` (JSONB object) — written by the AI session-analysis agent after the workout completes
- `POST /api/v1/logs/sessions/complete` **upserts by `user_id + session_date`** — calling it twice
  for the same day appends to `workout_logs` instead of creating a duplicate row. Always go through
  this endpoint for saving a session; don't create rows directly.
- `current_streak` / `longest_streak` live on the **active `workout_plans` row**, not computed
  client-side — recalculated server-side in `_update_plan_streak()` whenever a session completes.
- The old `exercise_logs` child table still exists in the DB (kept for historical rows) but is no
  longer written to or relied on by current code.

### Workout plan model casting
`WorkoutPlanModel`/`WorkoutPlanDataModel` (and their nested `WeeklySplitModel`, `WorkoutDayModel`,
`ExerciseModel`, `TrainingGuidelinesModel`, `NutritionGuidelinesModel`) each expose a safe
`.fromEntity()` / `.fromData()` / `.fromSplit()` / `.fromDay()` / `.fromExercise()` /
`.fromGuidelines()` factory that promotes a plain domain entity to the model subtype without an
unsafe cast. **Never write `(plan as WorkoutPlanModel)`** — the runtime type is frequently the
plain domain entity (e.g. when it round-trips through a use case), and a hard cast throws
`type WorkoutPlanEntity is not a subtype of WorkoutPlanModel`. Use the factory instead.

## Local storage (Hive)
Initialized in `lib/data/services/storage/storage_init.dart`. Key boxes: `onboarding_data`,
`fitness_plans`, `nutrition_analyses`, `progress_photos`, `body_scans`, `completed_workout_dates`.

### Gotcha: never persist absolute file paths
`getApplicationDocumentsDirectory()`'s absolute path prefix (the iOS sandbox container UUID) is
**not guaranteed stable across app sessions**, even though the relative folder layout underneath
it survives. Two past bugs were caused by storing the absolute path directly in Hive
(`ProgressPhoto.localPath`, `StoredFitnessPlanEntity.imagePath`) — the file silently became
unreachable after a restart and the UI fell back to a placeholder/broken-image icon.

Fix pattern now in place:
- `ProgressPhotoService.saveImageFile()` and `FileStorageDataSourceImpl.saveImageFile()` both
  return a path **relative** to the documents dir (e.g. `"fitness_images/123_photo.jpg"`).
- `lib/data/services/storage/image_path_resolver.dart` — `ImagePathResolver.resolve(storedPath)`
  rebuilds an absolute path against the *current* session's documents dir, using the known
  subfolder name (`fitness_images/`, `progress_photos/`) as an anchor. It also self-heals legacy
  rows that still hold an old absolute path.
- Any widget rendering a stored image (`_PlanImage` in `saved_program.dart`, `_HeroBanner` in
  `workout_plan_detail_page.dart`, `_PhotoStrip` in `statistics_page.dart`) must resolve through
  `ImagePathResolver` (or `ProgressPhotoService.getAllPhotos()`, which resolves internally) before
  calling `File(...).exists()` / `Image.file(...)`. Don't add a new `Image.file(File(storedPath))`
  call without resolving first.

## Localization (`flutter gen-l10n`)
Official Flutter tooling, not a third-party package. Configured via `l10n.yaml` at the repo root
with `synthetic-package: false`, so generated code is **visible and committable** at
`lib/l10n/generated/app_localizations.dart` rather than hidden in `.dart_tool/`.

- Source strings live in `lib/l10n/app_en.arb` (template) and `lib/l10n/app_<code>.arb` per
  language. `pubspec.yaml` has `flutter: generate: true`, so `flutter pub get` (or
  `flutter gen-l10n` directly) regenerates `AppLocalizations` whenever an `.arb` file changes.
  **The generated file must be produced by running one of those commands before the app
  compiles** — it isn't hand-written.
- Supported locales: `kSupportedLocales` in `lib/ui/core/locale/locale_provider.dart`. Add a
  language by adding a `Locale(...)` there + an `app_<code>.arb` file with the same keys as
  `app_en.arb`.
- `LocaleProvider` (registered in `di.dart` as a GetIt singleton, provided once at the root in
  `main.dart` via `ChangeNotifierProvider.value`) holds the user's chosen `Locale` and persists it
  to Hive via `LocaleStorage` (box `app_settings`, key `locale_code`). `null` locale means "follow
  system locale" (default until the user picks one in Settings).
- `lib/ui/features/profile/views/language_settings_page.dart` is the user-facing language picker,
  reached from Profile → General → Language. Calling `localeProvider.setLocale(...)` rebuilds the
  whole `MaterialApp.router` subtree live — no restart needed.
- Usage in widgets: `final t = AppLocalizations.of(context)!;` then `t.someKey`. Only
  `profile_page.dart` and `language_settings_page.dart` are localized so far (proof-of-concept
  slice) — most of the app still has hardcoded English strings. Extending coverage to another
  screen means: add keys to both `.arb` files, run `flutter gen-l10n`, then swap the hardcoded
  `Text('...')` for `Text(t.yourKey)`.

## Profile feature (`lib/ui/features/profile/`)
- `PersonalDetailsPage` — read-only profile display; computes BMI (with category + colour-coded
  gauge) and BMR (Mifflin-St Jeor) client-side from the stored height/weight/age/gender, since the
  backend doesn't expose these as derived fields.
- `AdjustWorkoutPlanPage` — lets the user edit the inputs that drive plan generation (goal,
  experience, training days, gender, height, weight). Reuses the same option presets as the
  onboarding flow (`goal.dart`, `experience.dart`). On submit it persists the changes via
  `OnboardingStorage.saveOnboardingData()` then routes to `/analysis` (`AnalysisPageWithData`),
  which reads that same storage and lets the user generate a fresh plan from a new physique photo.
  This page does **not** call any "update plan" API directly — regeneration always goes through
  the photo-analysis flow.

## Notes
- iOS target: tested on iOS 26.2 beta — several platform-specific fixes applied (see recent commits)
- Supabase is the auth + data backend
- YouTube integration for workout videos (`youtube_player_flutter`)
- Hive for local persistence — see "Local storage (Hive)" above for the absolute-path gotcha
