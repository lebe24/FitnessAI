# App Store Connect — Listing Copy

App: **Befit AI** · Bundle ID `com.betfit.ai.app`

| | |
|---|---|
| Subscription group | `22317248` |
| Products | `com.betfit.ai.pro.monthly`, `com.betfit.ai.pro.yearly` |
| Entitlement | `Befit AI - fitness Pro` |
| Introductory offer | 1 week free trial — **verified applying in sandbox** |

Fields below are ready to paste. Anything in `«guillemets»` needs a real value
from you — those are the ones I cannot invent.

---

## Subtitle (30 char limit)

> AI training that adapts

*Not in your list, but it sits under the app name in search results and is one
of the strongest ranking signals Apple gives you. Don't leave it blank.*

---

## Promotional Text (170 char limit)

> Your plan shouldn't stay the same while you change. BeFit rebuilds your training every session — around the workouts you actually finish, not the ones you skip.

*Editable any time without submitting a new build, unlike the description.
Use it for launch offers and seasonal pushes.*

---

## Description (4,000 char limit)

Most training plans are written once and never look at you again.

Befit AI writes yours, then keeps rewriting it. Every session you log feeds
back in — the lifts you added weight to, the ones you struggled with, the week
you missed entirely. The plan you get next week is built from the training you
actually did, not the training you meant to do.

BUILT AROUND YOU IN TWO MINUTES
Answer a few questions — your goal, your experience, the days you can train,
the equipment you can reach. No forty-question intake form. You get a complete
split with sets, reps, loads and progression before you've finished your
coffee.

TRAINING THAT KEEPS UP
• Plans rebuilt from your logged sessions, not a fixed template
• Push/pull/legs, upper/lower or full-body — matched to the days you train
• Progression that responds when you get stronger, and backs off when life
  gets in the way
• Swap any movement when the rack is taken or the gym is missing a machine

LOGGING THAT DOESN'T INTERRUPT YOUR SET
• Sets, reps and weight in a couple of taps
• Your session survives a force-quit — nothing is lost mid-workout
• Rest timers and exercise demonstrations where you need them

A COACH THAT ANSWERS BACK
Ask why a lift is programmed the way it is, how to fix your form, what to do
about a nagging shoulder, or what to eat after training. Your coach knows your
plan, your history and your goal, so the answer fits you rather than a generic
article.

SEE WHETHER IT'S WORKING
• Training volume, streaks and per-exercise trends over time
• Progress photos stored privately on your device
• Body composition insight from a photo
• Weekly and monthly views that show the direction, not just the numbers

NUTRITION WITHOUT THE DATABASE SEARCH
Photograph your plate. Calories and macros come back in seconds — no scrolling
through twelve versions of the same meal.

MOTIVATION IN A VOICE YOU CHOOSE
Pick the tone that gets you moving — calm and disciplined, or loud and
relentless — and pick when it arrives. Your coach writes each message from your
own stats: your goal, your streak, the session you did yesterday.

WHO IT'S FOR
Beginners who want to walk into a gym knowing exactly what to do. Lifters who
are tired of rewriting spreadsheets. Anyone who has followed a plan for three
weeks and then quietly stopped because it stopped fitting.

SUBSCRIPTION
Befit AI is free to download and free to build your first plan. Full access to
adaptive plans, unlimited logging, coach chat, nutrition tracking and analytics
requires a subscription.

Payment is charged to your Apple Account at confirmation of purchase.
Subscriptions renew automatically unless auto-renew is turned off at least 24
hours before the end of the current period. Your account is charged for renewal
within 24 hours prior to the end of the current period. You can manage your
subscription and turn off auto-renewal in your Apple Account settings after
purchase.

Terms of Use: https://befit.ai/terms
Privacy Policy: https://befit.ai/privacy

Questions or feedback? emmanuel.philipel@yahoo.com — a person reads every one.

---

## Keywords (100 char limit, comma-separated)

> workout,gym,ai trainer,strength,training plan,exercise,lifting,tracker,muscle,nutrition,coach

**Rules worth knowing:**

- Do **not** repeat words already in your app name or subtitle — Apple indexes
  those separately and repeats waste characters.
- No spaces after commas. Every space costs one of your 100.
- No plurals of words you already have; Apple matches stems.
- Never use competitor names. It is a rejection, and a legal problem.

---

## Support contact

The address above and in the App Review table is **emmanuel.philipel@yahoo.com**, standing in until
`support@befit.ai` receives mail. It lives in exactly two places in code —
`Constant.supportEmail` in the app and `CONTACT` in `befit_web/lib/legal.ts` —
and has to be changed in App Store Connect at the same time.

---

## Support URL (required)

> https://befit.ai/support

Apple checks this loads and is relevant. `/support` now exists and answers the
questions people actually write in about — cancelling, restoring a purchase,
deleting an account — with the contact address on it.

---

## Marketing URL (optional)

> https://befit.ai

---

## Copyright

> 2026 «Your registered name or company»

Format is year + owner, no `©` symbol — App Store Connect adds it. Use the
same legal entity that holds the developer account.

---

## App Review Information

**Sign-in required:** YES. Everything is behind auth, and six features are
behind a subscription — a reviewer without both will be blocked and reject.

| Field | Value |
|---|---|
| First name | «...» |
| Last name | «...» |
| Phone | «+44 ...» |
| Email | emmanuel.philipel@yahoo.com |
| Demo account username | `demo@abc.com` |
| Demo account password | `123456789` |

### Preparing the demo account — do this before submitting

1. **Create it in the app**, on a clean device, using email sign-in. Do not use
   a Google account: the reviewer cannot complete a Google OAuth flow they have
   no credentials for.
2. **Complete onboarding and generate a plan.** The reviewer should land on the
   home screen, not in a plan generation that may time out on a cold backend.
3. **Grant it access** with one update — see `doc/demo-account.md`:

   ```sql
   update user_profiles set is_complimentary = true
   where email = 'demo@abc.com';
   ```

   This step is not optional. Six features are gated, and without it the
   reviewer meets a paywall on every one.

   Note it is `is_complimentary`, not `is_premium`. The latter belongs to the
   RevenueCat webhook and would be overwritten by the next subscription event,
   taking the reviewer's access with it.
4. **Verify on a clean device** — delete the app, reinstall, sign in as the
   reviewer, and open each of the six gated features. Any paywall you see is
   one the reviewer will see.

### Notes for the reviewer

> BeFit AI builds a personalised training plan from a short onboarding flow,
> then adapts it based on the workouts you log.
>
> GETTING STARTED
> 1. Sign in with the demo account above using **email** sign-in.
> 2. The account has onboarding completed and a plan generated, so you land on
>    the home screen.
> 3. To see onboarding itself, use Profile → Delete Account and sign up again
>    with any email.
>
> SUBSCRIPTION AND FREE TRIAL
> The app is free to download and free to build your first plan. These features
> require a subscription: nutrition scanner, body composition, AI coach chat,
> equipment scan, exercise videos, and daily motivation.
>
> A 1-week free trial is offered before the first plan is generated, and the
> paywall is also reachable from Profile → Billing and from any locked feature.
> Purchases go through StoreKit, managed by RevenueCat. Restore Purchases is on
> the paywall footer and on the Billing screen. Please use a Sandbox Apple
> Account if you wish to test a purchase.
>
> **The demo account already has the subscription granted**, so every feature
> is open without buying anything.
>
> WHAT TO TRY
> • Home → tap a training day to open the session and log a set
> • Home → "Your Motivation" → pick a tone → "Motivate me now" (AI-generated)
> • Coach tab → ask anything about your plan
> • Nutrition → photograph any meal for calories and macros
> • Analytics → training volume, streaks and session history
> • My Programs → "Reassign" to switch which program drives the calendar
>
> AI CONTENT
> Plans, coaching replies and motivational messages are generated by a language
> model on our backend. Nothing is user-generated or shared between accounts, so
> there is no user-to-user content to moderate. The app gives general fitness
> guidance and makes no medical claims.
>
> CAMERA AND PHOTOS
> Used for meal photos, body-composition photos and equipment scanning. Progress
> photos are stored on the device. Permission is requested in context, and every
> one of these features is optional.
>
> Anything unclear, email emmanuel.philipel@yahoo.com and we will respond same day.


---

## Before you hit Submit

### Done

- [x] **Demo account** — `demo@abc.com`, confirmed, `is_complimentary = true`
- [x] **Email sign-in** exists, so the reviewer can actually use those
      credentials (the app was Google-only until recently)
- [x] **Single subscription group** — monthly and yearly now share `22317248`,
      so a user cannot hold both or claim two trials
- [x] **1-week free trial configured** — a sandbox purchase came back with
      `offerType 1`, `offerDiscountType FREE_TRIAL`, `offerPeriod P7D`, `price 0`
- [x] **No secrets in the IPA** — the bundled `.env` carries only the Supabase
      URL and anon key and the two RevenueCat public SDK keys, all of which are
      public by design. No `.p8`, `.p12` or service-account file is in the
      archive, and the Dart binary contains no secret-shaped strings.

### Still blocking

- [ ] **RevenueCat In-App Purchase Key** — currently rejected with
      `INVALID_APPLE_SUBSCRIPTION_KEY` (7234). Until it is accepted, Apple
      completes purchases but RevenueCat cannot validate them, so no entitlement
      is granted. Check the bundle ID in RevenueCat reads `com.betfit.ai.app`
      exactly — note **betfit**, not befit — and that the file uploaded is
      `SubscriptionKey_*.p8` from Users and Access → Integrations → In-App
      Purchase, not `AuthKey_*.p8`.
      *This blocks launch, not review: the demo account does not use RevenueCat.*
- [ ] **`/terms` and `/privacy` need real content** — the description and the
      support page both link to them and reviewers follow links
- [ ] **Paywall must show** Restore, auto-renewal terms, and Terms/Privacy
      links, or it is rejected under Guideline 3.1.1
- [ ] **Review screenshot** on each subscription (min 640×920)
- [ ] **Screenshots** for 6.9" and 6.5" displays
- [ ] **App Privacy questionnaire** — must match what the app collects: camera,
      photos, health and fitness data, identifiers
- [x] **Price tier confirmed** — the yearly product is **US$79.99**, so the
      ₦129,900 (~US$85) sandbox charge was the right tier converted, not a
      figure out by 10×. The marketing site now advertises the same number.
- [x] **Monthly tier confirmed** — **US$8.99**. The app's offline fallback was
      already right; the marketing site said $9.99 and has been corrected.

### Housekeeping after approval

- [ ] Revoke the demo grant: `./scripts/create-review-account.sh --revoke`
- [ ] Delete `scripts/create-review-account.sh`
- [ ] Rotate any credential that was exposed during setup

---

## Keeping secrets out of the build

`.env` is declared as a Flutter asset, so **it ships inside the IPA** and can be
read straight out of the archive:

```
Payload/Runner.app/Frameworks/App.framework/flutter_assets/.env
```

Only client identifiers belong in it. `.env.example` documents which, and why.
Server-side secrets live in Secret Manager and are referenced from
`services.yaml` in the backend repo.

To audit any build before uploading:

```bash
cd /tmp && rm -rf ipa_check && mkdir ipa_check && cd ipa_check
unzip -q "$(ls ~/Documents/Developer/flutter-apps/FitnessAI/build/ios/ipa/*.ipa | head -1)"
grep -oE '^[A-Z_]+=' Payload/Runner.app/Frameworks/App.framework/flutter_assets/.env
find Payload -type f \( -name '*.p8' -o -name '*.p12' -o -name '*.pem' \)
```

The first command should list only public keys. The second should print nothing.
