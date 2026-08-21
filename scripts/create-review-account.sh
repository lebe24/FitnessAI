#!/usr/bin/env bash
#
# Create the App Review demo account, already email-confirmed, and grant it
# complimentary access.
#
# Supabase's Admin API can create a user with email_confirm:true, which skips
# the confirmation mail entirely. That matters here because demo@abc.com is not
# a domain we control — a confirmation link would go nowhere and the reviewer
# could never sign in.
#
# The service role key is read from the environment and never printed, never
# written to a file, and never committed. Export it for the one command:
#
#   export SUPABASE_SERVICE_ROLE_KEY='...'      # Dashboard → Settings → API
#   ./scripts/create-review-account.sh
#
# Then unset it, and delete this script once the app is approved:
#
#   unset SUPABASE_SERVICE_ROLE_KEY
#
# Revoke the account's access later with:
#
#   ./scripts/create-review-account.sh --revoke
#
set -euo pipefail

EMAIL="${REVIEW_EMAIL:-demo@abc.com}"
PASSWORD="${REVIEW_PASSWORD:-123456789}"

# ── Preconditions ─────────────────────────────────────────────────────────────
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "✗ No .env in $(pwd) — run this from the FitnessAI repo." >&2
  exit 1
fi

SUPABASE_URL="$(grep -E '^SUPABASE_URL=' .env | cut -d= -f2- | tr -d '"'"'"' \r')"
if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "✗ SUPABASE_URL not found in .env" >&2
  exit 1
fi
SUPABASE_URL="${SUPABASE_URL%/}"

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  cat >&2 <<'MSG'
✗ SUPABASE_SERVICE_ROLE_KEY is not set.

  Dashboard -> Project Settings -> API Keys -> the SECRET key.
  It looks like  sb_secret_...   or, on older projects,  eyJ... (service_role)

    export SUPABASE_SERVICE_ROLE_KEY='sb_secret_...'

  Note: no trailing comment on that line. Some zsh setups do not treat # as a
  comment interactively and will try to run the rest as a command.

  This key bypasses row-level security. Keep it out of .env, out of git and
  out of the app, and unset it when you are done.
MSG
  exit 1
fi

# Fail fast on the public key. It is the one most easily to hand, and using it
# here would otherwise surface as an opaque 401 from the Admin API.
if [[ "${SUPABASE_SERVICE_ROLE_KEY}" == sb_publishable_* ]]; then
  cat >&2 <<'MSG'
✗ That is the PUBLISHABLE key, not the secret one.

  Publishable keys are the public client key and cannot use the Admin API.
  You need the key labelled "secret":

    Dashboard -> Project Settings -> API Keys -> secret

  It looks like  sb_secret_...   or, on older projects,  eyJ... (service_role)
MSG
  exit 1
fi

# Same check for the legacy anon JWT, compared against the one already in .env.
ANON_IN_ENV="$(grep -E '^SUPABASE_ANON_KEY=' .env 2>/dev/null | cut -d= -f2- | tr -d '"'"'"' \r' || true)"
if [[ -n "${ANON_IN_ENV:-}" && "${SUPABASE_SERVICE_ROLE_KEY}" == "${ANON_IN_ENV}" ]]; then
  echo "✗ That is the anon key from .env, not the secret key." >&2
  echo "  Dashboard -> Project Settings -> API Keys -> secret" >&2
  exit 1
fi

AUTH_HDR=(-H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}"
          -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
          -H "Content-Type: application/json")

# ── Helpers ───────────────────────────────────────────────────────────────────
json_get() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('$1','') or '')" 2>/dev/null || true; }

find_user_id() {
  curl -sS "${AUTH_HDR[@]}" \
    "${SUPABASE_URL}/auth/v1/admin/users?per_page=1000&filter=${EMAIL}" \
  | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit()
users = d.get('users', d if isinstance(d, list) else [])
for u in users:
    if (u.get('email') or '').lower() == '${EMAIL}'.lower():
        print(u.get('id', ''))
        break
"
}

# ── Revoke mode ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--revoke" ]]; then
  UID_FOUND="$(find_user_id)"
  if [[ -z "$UID_FOUND" ]]; then
    echo "✓ No account for ${EMAIL} — nothing to revoke."
    exit 0
  fi
  curl -sS -X PATCH "${AUTH_HDR[@]}" \
    "${SUPABASE_URL}/rest/v1/user_profiles?id=eq.${UID_FOUND}" \
    -H "Prefer: return=minimal" \
    -d '{"is_complimentary": false}' >/dev/null
  echo "✓ Revoked complimentary access for ${EMAIL}"
  echo "  The account still exists. Delete it in Dashboard → Authentication → Users."
  exit 0
fi

# ── 1. Create the user, already confirmed ─────────────────────────────────────
echo "──▶ creating ${EMAIL} (email_confirm: true)"

CREATE_BODY="$(python3 -c "
import json
print(json.dumps({
    'email': '${EMAIL}',
    'password': '${PASSWORD}',
    'email_confirm': True,
}))")"

RESPONSE="$(curl -sS -X POST "${AUTH_HDR[@]}" \
  "${SUPABASE_URL}/auth/v1/admin/users" -d "${CREATE_BODY}")"

USER_ID="$(printf '%s' "$RESPONSE" | json_get id)"

if [[ -z "$USER_ID" ]]; then
  # Most likely it already exists; that is fine and idempotent.
  MSG_TEXT="$(printf '%s' "$RESPONSE" | json_get msg)"
  [[ -z "$MSG_TEXT" ]] && MSG_TEXT="$(printf '%s' "$RESPONSE" | json_get message)"
  echo "  note: ${MSG_TEXT:-could not create}"
  USER_ID="$(find_user_id)"
  if [[ -z "$USER_ID" ]]; then
    echo "✗ Could not create or find ${EMAIL}." >&2
    echo "  Response: ${RESPONSE}" >&2
    exit 1
  fi
  echo "  using the existing account"
fi

echo "  user id: ${USER_ID}"

# ── 2. Grant complimentary access ─────────────────────────────────────────────
# Upsert rather than update: user_profiles rows are created lazily by the
# backend on first request, so the row may not exist yet.
echo "──▶ granting complimentary access"

GRANT_BODY="$(python3 -c "
import json
print(json.dumps([{'id': '${USER_ID}', 'is_complimentary': True}]))")"

HTTP_CODE="$(curl -sS -o /tmp/grant_out.json -w '%{http_code}' \
  -X POST "${AUTH_HDR[@]}" \
  "${SUPABASE_URL}/rest/v1/user_profiles?on_conflict=id" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d "${GRANT_BODY}")"

if [[ "$HTTP_CODE" =~ ^2 ]]; then
  echo "  ✓ is_complimentary = true"
else
  echo "  ✗ grant failed (HTTP ${HTTP_CODE})" >&2
  cat /tmp/grant_out.json >&2 || true
  echo >&2
  echo "  If the table is not exposed to the Data API, run this in the SQL editor:" >&2
  echo "    insert into user_profiles (id, is_complimentary)" >&2
  echo "    values ('${USER_ID}', true)" >&2
  echo "    on conflict (id) do update set is_complimentary = true;" >&2
  exit 1
fi

rm -f /tmp/grant_out.json

cat <<DONE

✓ Done.

  Email     ${EMAIL}
  Password  ${PASSWORD}
  User id   ${USER_ID}

  Sign in on a clean device. Profile → Billing should read
  "Pro · complimentary" — that label confirms the grant is live.

  When the app is approved:
    ./scripts/create-review-account.sh --revoke
    unset SUPABASE_SERVICE_ROLE_KEY
DONE


# export SUPABASE_SERVICE_ROLE_KEY='sb_publishable_dRrz7zeBXL70OjsGBH1YpQ_yNWvZFk2'   # Dashboard → Settings → API
# ./scripts/create-review-account.sh