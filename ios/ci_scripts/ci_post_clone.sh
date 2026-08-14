#!/bin/sh

# Xcode Cloud — post-clone setup for a Flutter app.
#
# Xcode Cloud images ship with Xcode and CocoaPods but know nothing about
# Flutter, so this script installs the SDK and generates everything the
# Xcode build needs before xcodebuild runs.
#
# Xcode Cloud finds this automatically at ios/ci_scripts/ci_post_clone.sh
# (a ci_scripts directory beside the Xcode project, or at the repo root).
# It must stay executable — chmod +x, committed with the exec bit.

set -e

# Pinned so CI matches local development. Bump deliberately, not by drift.
FLUTTER_VERSION="3.41.9"

echo "──▶ Installing Flutter $FLUTTER_VERSION"
git clone https://github.com/flutter/flutter.git \
    --depth 1 --branch "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"
flutter --version

cd "$CI_PRIMARY_REPOSITORY_PATH"

# ── .env ─────────────────────────────────────────────────────────────────────
# pubspec.yaml bundles .env as a Flutter asset, but it is gitignored — so the
# clone has no .env and `flutter build` would fail on the missing asset.
# Rebuild it here from Xcode Cloud environment variables (set them as
# *secret* in the workflow's Environment settings).
echo "──▶ Writing .env from build environment"
cat > .env <<ENVFILE
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
BACKEND_BASE_URL=${BACKEND_BASE_URL}
Oauth_webClientId=${OAUTH_WEB_CLIENT_ID}
OAUTH_IOS_CLIENT=${OAUTH_IOS_CLIENT}
OAUTH_ANDROID_CLIENT=${OAUTH_ANDROID_CLIENT}
YOUTUBE_API_KEY=${YOUTUBE_API_KEY}
YOUTUBE_RAPID_KEY=${YOUTUBE_RAPID_KEY}
REVENUECAT_IOS_API_KEY=${REVENUECAT_IOS_API_KEY}
REVENUECAT_ANDROID_API_KEY=${REVENUECAT_ANDROID_API_KEY}
ENVFILE

# Fail loudly now rather than shipping a build that can't reach Supabase.
if [ -z "${SUPABASE_URL}" ] || [ -z "${SUPABASE_ANON_KEY}" ]; then
  echo "✗ SUPABASE_URL / SUPABASE_ANON_KEY are not set in the Xcode Cloud"
  echo "  workflow environment. The app cannot authenticate without them."
  exit 1
fi

# ── Flutter dependencies ─────────────────────────────────────────────────────
echo "──▶ Precaching iOS artefacts"
flutter precache --ios

echo "──▶ flutter pub get"
flutter pub get

# Generates ios/Flutter/Generated.xcconfig and the plugin registrant that the
# Xcode project reads. --config-only skips the actual compile, which Xcode
# Cloud performs itself.
echo "──▶ Generating Xcode configuration"
APP_VERSION=$(grep '^version:' "$REPO/pubspec.yaml" | awk '{print $2}')
echo "──▶ stamping APP_VERSION=$APP_VERSION"
flutter build ios --config-only --release --no-codesign \
  --dart-define=APP_VERSION="$APP_VERSION"

# ── CocoaPods ────────────────────────────────────────────────────────────────
echo "──▶ pod install"
cd ios
# LANG must be UTF-8 or CocoaPods can crash while formatting output.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
pod install

echo "✓ Post-clone setup complete"
