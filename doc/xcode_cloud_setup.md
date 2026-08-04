# Xcode Cloud Setup

Xcode Cloud builds, tests, and ships the iOS app straight to TestFlight. The
repo side is done — this documents the console steps, which can only be
performed in Xcode or App Store Connect.

## What's already in the repo

| File | Purpose |
|---|---|
| `ios/ci_scripts/ci_post_clone.sh` | Installs Flutter, writes `.env`, runs `pub get` + `pod install` |
| `ios/ci_scripts/ci_post_xcodebuild.sh` | Generates TestFlight "What to Test" notes from commits |

Xcode Cloud discovers these by convention — no configuration needed. **They must
stay executable**; a non-executable script is silently skipped and the build
fails later with confusing Flutter errors.

## Why the post-clone script is mandatory

Xcode Cloud's macOS images have Xcode and CocoaPods but **no Flutter**. Without
the script, `xcodebuild` fails immediately — `Generated.xcconfig` doesn't exist
and no pods are installed.

There is also a subtler trap: `pubspec.yaml` bundles **`.env` as a Flutter
asset**, but `.env` is gitignored. A fresh clone has no `.env`, so the build
fails on a missing asset. The script recreates it from workflow environment
variables. This is the single most common reason a Flutter app "works locally,
fails on Xcode Cloud".

---

## Step 1 — Prerequisites

- Apple Developer Program membership (you have this — Team `7TH5U8BA6U`)
- The app record exists in App Store Connect with bundle id `com.betfit.ai.app`
- The repo is pushed to GitHub (`lebe24/FitnessAI`)

## Step 2 — Create the workflow

In **Xcode**: `Product ▸ Xcode Cloud ▸ Create Workflow`
(or App Store Connect ▸ your app ▸ **Xcode Cloud** tab)

1. Select the **Runner** app target
2. Grant access to the GitHub repository when prompted
3. Name the workflow, e.g. **TestFlight Release**

## Step 3 — Configure the workflow

**Start Conditions** — pick one:
- *Branch Changes* on `main` → builds every push
- *Tag Changes* matching `v*` → builds only on release tags (recommended; it
  mirrors the existing GitHub Actions release flow)

**Environment**
- macOS and Xcode: **latest release**
- ✅ Tick **Clean** only if you hit caching oddities — it slows every build

**Actions**
- **Archive** — Deployment Preparation: *TestFlight and App Store*
- Optionally add a **Test** action, though `flutter test` is already covered by
  GitHub Actions

**Post-Actions**
- **TestFlight Internal Testing** → select your internal tester group

## Step 4 — Environment variables (the important part)

In the workflow's **Environment** section, add each of these. **Tick "Secret"**
on everything except `BACKEND_BASE_URL` — secret values are hidden in logs and
unavailable to builds from forked PRs.

| Variable | Secret | Value |
|---|---|---|
| `SUPABASE_URL` | ✅ | from your `.env` |
| `SUPABASE_ANON_KEY` | ✅ | from your `.env` |
| `BACKEND_BASE_URL` | — | `https://fitness-agent-vjpfphelaa-uc.a.run.app/` |
| `OAUTH_WEB_CLIENT_ID` | ✅ | maps to `Oauth_webClientId` in `.env` |
| `OAUTH_IOS_CLIENT` | ✅ | from your `.env` |
| `OAUTH_ANDROID_CLIENT` | ✅ | from your `.env` |
| `YOUTUBE_API_KEY` | ✅ | from your `.env` |
| `YOUTUBE_RAPID_KEY` | ✅ | from your `.env` |
| `REVENUECAT_IOS_API_KEY` | ✅ | once RevenueCat is configured |
| `REVENUECAT_ANDROID_API_KEY` | ✅ | once RevenueCat is configured |

> Note the name change: the app reads `Oauth_webClientId`, but Xcode Cloud
> variable names should be conventional, so the workflow variable is
> `OAUTH_WEB_CLIENT_ID` and the script maps it across.

The build **fails fast** if `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing,
rather than shipping a build that can't authenticate.

## Step 5 — Signing

Xcode Cloud manages signing automatically — no certificates or provisioning
profiles to upload, unlike the GitHub Actions workflow. Just confirm the Runner
target uses **Automatically manage signing** with team `7TH5U8BA6U`.

## Step 6 — First build

Trigger manually from Xcode (`Product ▸ Xcode Cloud ▸ Start Build`) rather than
waiting on a push, so you can watch the logs.

Expect **15–25 minutes** for the first build — cloning the Flutter SDK and
precaching iOS artefacts dominates. Later builds reuse the cache and are faster.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Generated.xcconfig not found` | Post-clone script didn't run — check it's executable (`git update-index --chmod=+x`) |
| `Unable to load asset: .env` | Environment variables missing from the workflow |
| `pod: command not found` | Rare on current images; add `brew install cocoapods` to the script |
| CocoaPods `Encoding::CompatibilityError` | The script already exports `LANG`/`LC_ALL`; keep those lines |
| Build number collision | Xcode Cloud auto-increments via `CI_BUILD_NUMBER`; don't also bump `pubspec.yaml` |

## Relationship to GitHub Actions

`.github/workflows/release-ios.yml` does the same job. Keep **one** to avoid
duplicate TestFlight builds:

- **Xcode Cloud** — no signing secrets to manage, tighter Apple integration,
  free tier of 25 compute hours/month
- **GitHub Actions** — one place for iOS + Android + backend CI, but you
  maintain the certificate and provisioning secrets yourself

If you adopt Xcode Cloud, disable the tag trigger in `release-ios.yml` (leave
`workflow_dispatch` so it stays available as a fallback).
