# Contributing

This is a private, proprietary project. This guide is for the internal team and any
contractors with repo access — not a general open-source contribution guide.

## Branching

- `main` is always shippable. Don't push directly to it for anything beyond trivial fixes.
- Branch names: `feature/<short-description>`, `fix/<short-description>`, `chore/<short-description>`.

## Commits

Keep commit messages short, imperative, and focused on *why* over *what*:

```
Fix streak calculation when session spans midnight
Add billing UI shell to profile settings
```

Avoid bundling unrelated changes into a single commit.

## Pull Requests

- Keep PRs scoped to one feature/fix where possible — large mixed PRs are hard to review.
- Include a one-line summary of what changed and why, plus a short test plan (what you ran,
  what you checked manually).
- Run `flutter analyze` and `flutter test` before requesting review.

## Code Style

- Follow the existing Clean Architecture layering (`data` / `domain` / `ui`) — see
  [CLAUDE.md](CLAUDE.md) for the full architectural reference.
- Match the existing dark/lime BeFit design tokens when adding UI (see any recent `views/*.dart`
  file for the `_kBg` / `_kCard` / `_kLime` pattern).
- No new third-party dependency without checking if something already in `pubspec.yaml` covers
  the need.

## Environment

Never commit `.env`. Use `.env.example` as the source of truth for which keys the app expects,
and keep it updated if you add a new `dotenv.env['...']` reference in `constant.dart`.

## Localization

If you add user-facing strings to a localized screen, add the key to **both**
`lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`, then run `flutter gen-l10n` before committing.
