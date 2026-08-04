#!/bin/sh

# Xcode Cloud — runs after xcodebuild finishes.
#
# Populates the TestFlight "What to Test" notes from the commit history so
# testers see what changed without anyone writing release notes by hand.

set -e

# Only meaningful for archive actions that produce a TestFlight build.
if [ "$CI_XCODEBUILD_ACTION" != "archive" ]; then
  echo "Not an archive action ($CI_XCODEBUILD_ACTION) — skipping test notes."
  exit 0
fi

if [ -z "$CI_APP_STORE_SIGNED_APP_PATH" ]; then
  echo "No signed app produced — skipping test notes."
  exit 0
fi

NOTES_DIR="$CI_PRIMARY_REPOSITORY_PATH/TestFlight"
mkdir -p "$NOTES_DIR"

cd "$CI_PRIMARY_REPOSITORY_PATH"
# Subject lines since the previous build, minus the Co-Authored-By trailers.
COMMITS=$(git log -15 --pretty=format:"• %s" | grep -v "Co-Authored-By" || true)

cat > "$NOTES_DIR/WhatToTest.en-US.txt" <<NOTES
Build ${CI_BUILD_NUMBER} — ${CI_BRANCH:-unknown branch}

Recent changes:
${COMMITS}
NOTES

echo "✓ Wrote TestFlight notes for build ${CI_BUILD_NUMBER}"
