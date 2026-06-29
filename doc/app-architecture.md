# BeFit AI — App Architecture

## System Overview

BeFit AI is a cross-platform fitness app with a Flutter mobile frontend, a FastAPI backend on Google Cloud Run, and Supabase handling authentication. App data is stored directly in Supabase Postgres via SQLAlchemy from the backend — not through the Supabase REST client.

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (iOS/Android)                │
└──────────┬──────────────────────────┬───────────────────────┘
           │                          │
           ▼                          ▼
┌──────────────────┐      ┌───────────────────────┐
│  Supabase Auth   │      │  FastAPI  (Cloud Run)  │
│                  │      │                        │
│ • Google OAuth   │      │ • Business logic       │
│ • JWT tokens     │      │ • AI agents (OpenAI)   │
│ • Session mgmt   │      │ • REST endpoints       │
│ • User metadata  │      │ • WebSocket chat       │
└──────────────────┘      └──────────┬─────────────┘
                                     │
                          JWT validated on every
                          protected route via
                          SUPABASE_JWT_SECRET
                                     │
                                     ▼
                    ┌────────────────────────────────┐
                    │      Supabase Postgres          │
                    │  (direct TCP — no REST client) │
                    │                                 │
                    │  ┌─────────────────────────┐   │
                    │  │  Supabase-managed        │   │
                    │  │  • auth.users            │   │
                    │  │  • motivation_content    │   │
                    │  └─────────────────────────┘   │
                    │                                 │
                    │  ┌─────────────────────────┐   │
                    │  │  FastAPI-managed (ORM)   │   │
                    │  │  • user_profiles         │   │
                    │  │  • workout_plans         │   │
                    │  │  • nutrition_logs        │   │
                    │  │  • chat_history          │   │
                    │  │  • body_scans            │   │
                    │  └─────────────────────────┘   │
                    └────────────────────────────────┘
```

---

## Data Flow

### Auth Flow
```
Flutter → Google Sign-In SDK
        → Supabase.signInWithIdToken()
        → Supabase returns JWT
        → Flutter stores JWT (in memory / secure storage)
        → JWT sent as Authorization: Bearer <token> on every FastAPI request
```

### App Data Flow
```
Flutter → FastAPI  (Authorization: Bearer <jwt>)
             │
             ├── 1. Validate JWT  (python-jose + SUPABASE_JWT_SECRET)
             ├── 2. Extract user_id from JWT sub claim
             └── 3. SQLAlchemy async session → Supabase Postgres
                       (pooler connection — no idle cost)
```

### AI Agent Flow
```
Flutter → POST /api/v1/plans/workout  (image + user metrics)
        → FastAPI → OpenAI GPT-4o (vision + generation)
        → Structured WorkoutPlanEntity returned
        → Flutter saves to local Hive box + optionally syncs to DB
```

---

## Flutter Architecture

BeFit AI Flutter follows **layered MVVM** with strict separation across three root layers.

```
lib/
├── data/           # External-facing: API models, services, repository impls
├── domain/         # Business core: entities, repo interfaces, use cases
├── ui/             # Presentation: ViewModels, views, routing, DI
└── main.dart
```

### 1. Domain Layer (`lib/domain/`)

Zero Flutter dependencies — pure Dart.

```
domain/
├── models/             # Immutable domain entities
│   ├── user.dart
│   ├── workout_plan.dart
│   ├── workout_day_mapping.dart
│   ├── stored_fitness_plan.dart
│   ├── nutrition_analysis.dart
│   ├── stored_nutrition_analysis.dart
│   ├── profile.dart
│   ├── exercise.dart
│   ├── youtube_video.dart
│   ├── chat_message.dart
│   ├── chat_response.dart
│   └── image.dart
├── repositories/       # Abstract interfaces (contracts)
│   ├── auth_repository.dart
│   ├── home_repository.dart
│   ├── user_data_repository.dart
│   ├── nutrition_repository.dart
│   ├── profile_repository.dart
│   ├── storage_repository.dart
│   ├── exercise_repository.dart
│   ├── youtube_repository.dart
│   └── chat_repository.dart
└── use_cases/
    ├── auth/           sign_in_google, sign_out, get_current_user, delete_account
    ├── home/           upload_image_usecase, get_base_info_usecase
    ├── fitness/        get_user_streak, get_completed_dates,
    │                   update_workout_completion, get_user_data
    ├── nutrition/      analyze_food, save_analysis, get_all_analyses,
    │                   get_analysis_by_id, delete_analysis
    ├── profile/        get_profile_usecase
    ├── storage/        save_plan, get_all_plans, get_plan_by_id,
    │                   delete_plan, update_sync_status, get_unsynced
    ├── exercise/       search_exercises, get_exercise_by_id, search_youtube_videos
    └── chat/           connect_chat, disconnect_chat, send_message
```

**Rules:**
- Domain models are the single source of truth passed between layers.
- Repository interfaces define the contract; implementations live in `data/`.
- Use cases contain the only business logic allowed outside ViewModels.

---

### 2. Data Layer (`lib/data/`)

Implements domain contracts and owns all I/O.

```
data/
├── models/             # API/persistence models (map to/from domain models)
│   ├── auth/           user_model.dart
│   ├── home/           workout_plan_model.dart, image_model.dart
│   ├── nutrition/      nutrition_analysis_model.dart, stored_nutrition_analysis_model.dart
│   ├── profile/        profile_model.dart
│   ├── storage/        stored_fitness_plan_model.dart
│   ├── exercise/       exercise_model.dart
│   ├── youtube/        youtube_video_model.dart
│   ├── chat/           chat_message_model.dart, chat_response_model.dart
│   └── onboarding/     onboarding_data.dart
├── services/
│   ├── auth/           auth_remote_service.dart
│   ├── home/           home_remote_service.dart
│   ├── fitness/        user_data_remote_service.dart
│   ├── nutrition/      nutrition_remote_service.dart, nutrition_local_service.dart
│   ├── profile/        profile_local_service.dart
│   ├── storage/        local_storage_service.dart, file_storage_service.dart
│   ├── api/            exercise_remote_service.dart, youtube_remote_service.dart,
│   │                   agent_remote_service.dart, supabase_remote_service.dart
│   └── chat/           chat_remote_service.dart, chat_history_storage.dart
└── repositories/
    ├── auth_repository_impl.dart
    ├── home_repository_impl.dart
    ├── user_data_repository_impl.dart
    ├── nutrition_repository_impl.dart
    ├── profile_repository_impl.dart
    ├── storage_repository_impl.dart
    ├── exercise_repository_impl.dart
    ├── youtube_repository_impl.dart
    └── chat_repository_impl.dart
```

**Rules:**
- Services are stateless wrappers for a single external concern.
- Repositories consume services, transform data models → domain models, handle caching/retry.
- No Flutter UI code in this layer.

---

### 3. UI Layer (`lib/ui/`)

```
ui/
├── core/
│   ├── di.dart                 # GetIt wiring
│   ├── common_lib.dart         # Barrel re-exports
│   ├── constants/              # Asset paths, app constants, env vars
│   ├── theme/                  # Colors (AppPalete), typography, ThemeData
│   ├── routes/app_router.dart  # GoRouter + ScreenPaths
│   └── widgets/                # Shared widgets (AppWidgets, greeting, ChatThemeScope)
└── features/
    ├── auth/                   # Google sign-in
    ├── home/                   # Camera upload + AI analysis flow
    ├── fitness/
    │   ├── views/
    │   │   ├── home_page.dart          # Main fitness home (renamed from fitness_page)
    │   │   ├── workout_page.dart       # Day workout detail
    │   │   ├── exercise_hero_page.dart # Exercise detail + workout log dialog
    │   │   ├── fitness_page_method.dart # Chat modal (chatModal function)
    │   │   ├── workout_modal.dart
    │   │   ├── save_page.dart
    │   │   ├── motivate_page.dart
    │   │   └── streak_sheet.dart
    │   └── view_models/fitness_view_model.dart
    ├── nutrition/              # Food scan + nutrition output
    ├── chat/                   # ChatViewModel, ChatMessageBubble, ChatThemeScope
    ├── onboarding/             # 8-step onboarding + chat_screen.dart (AI coach chat)
    ├── profile/                # User profile + personal details
    ├── activity/               # Workout history
    ├── analytic/               # Statistics
    ├── splash/
    └── welcome/
```

---

## MVVM Pattern

```
┌──────────────────┐     reads/calls     ┌──────────────────────┐
│      View        │ ─────────────────► │     ViewModel         │
│  (Consumer<VM>)  │                     │  (ChangeNotifier)     │
│                  │ ◄──────────────── │  exposes properties   │
└──────────────────┘   notifyListeners   └──────────┬───────────┘
                                                     │ calls
                                              ┌──────▼────────┐
                                              │  Use Cases    │
                                              └──────┬────────┘
                                                     │ calls
                                              ┌──────▼────────┐
                                              │  Repository   │
                                              └──────┬────────┘
                                                     │ calls
                                              ┌──────▼────────┐
                                              │   Service     │
                                              └───────────────┘
```

### ViewModel Contract

```dart
class FeatureViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  FeatureData? _data;

  bool get isLoading => _isLoading;
  String? get error => _error;
  FeatureData? get data => _data;

  Future<void> loadData() async {
    _isLoading = true; _error = null;
    notifyListeners();
    try {
      _data = await _useCase();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## Dependency Injection

All dependencies wired in `lib/ui/core/di.dart` using **GetIt**.

| Registration | Used For |
|---|---|
| `registerLazySingleton` | Services, Repositories, Use Cases |
| `registerFactory` | ViewModels (fresh instance per route) |

---

## Routing

Navigation via **GoRouter**. All paths centralised on `ScreenPaths`.

| Path | Screen |
|---|---|
| `/` | SplashScreen |
| `/welcome` | Welcome |
| `/login` | AuthLoginPage |
| `/onboarding` | OnboardingScreen |
| `/analysis` | AnalysisPage |
| `/home` | HomeScreen (shell with bottom nav) |
| `/workout` | WorkoutPage |
| `/nutrition` | NutritionPage |
| `/nutrition-analysis` | AnalysisOutputPage |
| `/workout-plan-detail` | WorkoutPlanDetailPage |

---

## State Management

| Package | Role |
|---|---|
| `provider` | `ChangeNotifierProvider` / `Consumer` — reactive UI |
| `get_it` | Service locator |
| `go_router` | Declarative navigation |
| `hive_flutter` | Local persistence (plans, nutrition, dates, chat history) |
| `supabase_flutter` | Auth only (JWT + Google OAuth) |
| `image_picker` | Camera + gallery access |

---

## Key Design Decisions

1. **Supabase auth only.** Supabase handles Google OAuth and JWT. All app data reads/writes go through FastAPI → SQLAlchemy → Supabase Postgres directly. The Flutter app never writes app data directly to Supabase.

2. **JWT forwarding pattern.** Flutter sends the Supabase JWT in `Authorization: Bearer` on every FastAPI request. FastAPI validates it using `SUPABASE_JWT_SECRET` — no extra Supabase API call needed.

3. **Local-first for workout data.** Plans and nutrition analyses are saved to Hive immediately for offline access. Sync to the backend DB happens asynchronously.

4. **ViewModel per feature, not per screen.** A single `FitnessViewModel` is shared across `HomePage`, `WorkoutPage`, and `SavePage`.

5. **Factory registration for ViewModels.** Prevents stale state across navigation. Each route gets a fresh instance.

6. **Side effects outside the builder.** Navigation and SnackBars are handled via `addListener` in `initState`, never inside a `Consumer` builder.

7. **Private widget classes.** Every distinct UI section is its own `StatelessWidget` or `StatefulWidget` private class — no inline builder methods.

8. **Design tokens per file.** Each feature file declares its own `const Color` tokens (`_kLime`, `_kCard`, etc.) at the top rather than reaching into `AppPalete`.
