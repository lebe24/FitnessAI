<p align="center">
  <img src="assets/image/background-image.png" alt="BeFit AI banner" width="100%" />
</p>

<h1 align="center">BeFit AI</h1>
<p align="center"><strong>Your personal AI fitness coach — tailored workout plans, body composition analysis, and nutrition tracking in one app.</strong></p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-black">
  <img alt="Backend" src="https://img.shields.io/badge/Backend-FastAPI%20%2B%20Supabase-009688">
  <img alt="License" src="https://img.shields.io/badge/License-Proprietary-red">
</p>

---

## What is BeFit AI?

BeFit AI builds a personalised workout program from either a photo of your physique or a conversation with an AI coach, then helps you stick to it — tracking every session, your streak, and your nutrition along the way.

| Capability | Description |
|---|---|
| 📸 **Photo-based plan generation** | Upload a physique photo; AI vision analyses your body composition and generates a tailored training split |
| 💬 **AI chat-to-plan** | Or just talk to the coach — describe your goals and let it build the plan conversationally |
| 🏋️ **Workout tracking** | Log every exercise, set, and rep; sessions are saved as a single row per day with embedded AI feedback |
| 🔥 **Streaks** | Current/longest streak computed server-side and persisted to your active plan |
| 🍽️ **Nutrition scanning** | Photograph a meal to get a full macro/micro breakdown and workout-context advice |
| 🩻 **Body composition analysis** | Per-muscle-group development scoring, body fat %, posture, and symmetry analysis |
| 📊 **Progress tracking** | Saved programs, progress photos, weight/BMI/BMR, and workout history |
| 🌍 **Localization** | English and Spanish out of the box, switchable in-app with no restart |
| 🎙️ **Voice input** | Speech-to-text for logging sets hands-free during a workout |

## Tech Stack

**Client** — Flutter (Dart 3.9+), Clean Architecture (`data` / `domain` / `ui`), `provider` for state, `get_it` for DI, `go_router` for navigation, `hive` for local persistence.

**Backend** — FastAPI on Cloud Run, async SQLAlchemy + asyncpg over Supabase Postgres, Alembic migrations. AI calls (workout plans, body composition, nutrition, session feedback) are proxied server-side — no AI provider keys ever ship inside the client binary.

**Auth & data** — Supabase (email + Google Sign-In), Row Level Security on all user tables.

## Project Structure

```
lib/
├── data/          # Models, repository implementations, remote/local data sources
├── domain/        # Entities, repository interfaces, use cases
└── ui/
    ├── core/      # Theme, routing (go_router), DI (di.dart), locale, shared widgets
    └── features/  # One folder per feature
        └── <feature>/
            ├── view_models/   # ChangeNotifier ViewModels
            └── views/         # Widgets
```

See [CLAUDE.md](CLAUDE.md) for a deeper architectural reference — routing table, Hive boxes, the workout-session data model, and known gotchas (e.g. why file paths must never be stored as absolutes).

## Getting Started

### Prerequisites
- Flutter 3.x (Dart SDK ^3.9.0)
- A Supabase project (Postgres + Auth)
- The companion [backend service](#backend) running and reachable

### Setup

```bash
git clone https://github.com/lebe24/FitnessAI.git
cd FitnessAI
flutter pub get
```

Copy the environment template and fill in real values:

```bash
cp .env.example .env
```

| Variable | Purpose |
|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Supabase project connection |
| `SUPABASE_DATABASE_PASSWORD` | Direct DB access (migrations/tooling) |
| `BACKEND_BASE_URL` | FastAPI agent service base URL |
| `Oauth_webClientId`, `OAUTH_IOS_CLIENT`, `OAUTH_ANDROID_CLIENT` | Google Sign-In client IDs per platform |
| `YOUTUBE_API_KEY`, `YOUTUBE_RAPID_KEY` | Exercise demo video lookups |

Generate localized strings (required once, and again whenever `lib/l10n/*.arb` changes):

```bash
flutter gen-l10n
```

Run it:

```bash
flutter run
```

### Backend

This app's AI/agent endpoints live in a separate FastAPI service (not in this repo). The client never calls an AI provider directly — see `lib/ui/core/constants/constant.dart` for the expected endpoints (`/ws/chat`, `/ws/agent`, `/api/v1/...`).

## Testing

```bash
flutter test
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming, commit conventions, and PR expectations.

## License

Proprietary — All Rights Reserved. See [LICENSE](LICENSE).
