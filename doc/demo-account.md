# App Review demo account

The reviewer needs an account that signs in with **email and password** and has
every gated feature open. This is how that works, and why it is not done by
granting an entitlement in RevenueCat.

## How access is granted

`user_profiles.is_complimentary` — a manual flag, exposed on
`GET /api/v1/billing/status`, which the app treats as unlocking everything on
its own.

`AccessPolicy.canUse()` is `revenueCatEntitlement || complimentaryGrant`. An
OR, never an AND: a granted account needs no purchase, and a paying user never
loses access because the backend is slow or unreachable.

### Why not RevenueCat, and why not `is_premium`

- **A RevenueCat dashboard grant** works, but it is a manual step someone has
  to remember to make before every submission and revoke afterwards, and it
  lives outside the repo where nobody can see it.
- **`is_premium`** is owned by the RevenueCat webhook. Setting it by hand holds
  until the next event for that user arrives and overwrites it — for a reviewer
  that means access vanishing partway through review, which is close to the
  worst failure mode available.

`is_complimentary` is written by nothing automated, so it survives every
subscription event.

---

## Setting it up

### 1. Create the account in the app

On a clean device, sign up with **email** — not Google. A reviewer cannot
complete an OAuth flow for an account they have no credentials to.

Suggested: `reviewer@YOUR-DOMAIN`, with a password you are willing to put in
App Store Connect in plain text.

### 2. Finish onboarding and generate a plan

So the reviewer lands on the home screen rather than in a plan generation that
may time out against a cold backend.

### 3. Grant access

Find the user, then set the flag:

```sql
-- Confirm you have the right row first.
select id, email, is_premium, access_tier, is_complimentary
from user_profiles
where email = 'reviewer@YOUR-DOMAIN';

-- Grant.
update user_profiles
set is_complimentary = true
where email = 'reviewer@YOUR-DOMAIN';
```

Takes effect on the next launch or sign-in — the app refreshes this when auth
settles.

### 4. Verify on a clean device

Delete the app, reinstall, sign in as the reviewer and open all six:

- Nutrition scanner (Home → scan a meal)
- Body composition (Home → body scan)
- Motivation (Home → Your Motivation → pick a tone → Motivate me now)
- AI coach (Coach tab)
- Equipment scan (Workout → scan equipment)
- Video tutorials (any exercise → Video Tutorials → tap one)

Any paywall you see is one the reviewer will see. Profile → Billing should read
**"Pro · complimentary"** — that label is the proof the grant is live, since a
non-granted account shows nothing there.

---

## Afterwards

The grant does not expire. Revoke it when you no longer need it:

```sql
update user_profiles set is_complimentary = false
where email = 'reviewer@YOUR-DOMAIN';
```

Keep it on while the app is live if you expect re-reviews for updates — a
reviewer hitting a paywall on a routine update is the same rejection as on
first submission.

## Other uses

The same flag covers comped users and support goodwill: a refund you would
rather handle by keeping someone's access on, a beta tester, a partner. It is
one row and one boolean, and it never interferes with a real subscription —
if the user later subscribes, `AccessPolicy` reports their actual plan rather
than the grant.
