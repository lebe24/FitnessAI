# Analytics — what is recorded and how to read it

Product analytics is PostHog (US cloud). Every event is sent by `Analytics.track(...)`
(`lib/data/services/analytics/`), named in `analytics_events.dart`, and passed through
`AnalyticsSanitizer`, which drops personal data. Users can switch it off in
**Profile → Usage data**.

**Never recorded:** name, email, photos, message or note text, gender, age, height,
weight, body measurements. The typed "custom goal" is recorded only as `custom`.

Every event also carries `access_tier` (`free` / `trial` / `paid` / `complimentary`) and
`$screen_name`. **Filter out your own phone** before reading any chart: PostHog →
*Settings → Project → Internal & test users filters* (match your person, or
`access_tier = complimentary`).

## Events

| Area | Event | Properties |
|---|---|---|
| Welcome | `welcome_cta_tapped` | `action`: get_started \| login |
| Onboarding | `onboarding_step_viewed` | `step`, `index`, `direction` (start \| forward \| back) |
| | `onboarding_step_completed` | `step`, `index` |
| | `onboarding_answered` | `step` (goal \| workoutDays \| experience), `value` |
| | `onboarding_path_chosen` | `path` |
| | `plan_generate_tapped` | — |
| | `plan_generation_started` / `plan_generated` / `plan_generation_failed` | goal, split, `duration_ms`, `status_code` |
| | `trial_offer_shown` / `trial_offer_closed` | `entitled` |
| Account | `signed_in`, `signed_up` | `method` |
| | `signed_out`, `account_deleted` | — |
| Navigation | `tab_viewed` | `tab`: home \| coach \| stats \| profile |
| Home cards | `home_card_tapped` | `card`, `locked` |
| Scans | `scan_photo_selected` | `kind`: meal \| body \| physique, `source` |
| | `meal_scanned`, `body_scanned` | `success` |
| Coach | `chat_message_sent` | `length`, `has_image` |
| | `motivation_generated` | `tone`, `success` |
| Training | `workout_saved` | `exercise_count`, `duration_mins` |
| | `workout_completed` | `duration_mins`, `streak` |
| Muscle map | `muscle_map_opened`, `muscle_detail_opened`, `muscle_advisor_asked` | `muscle` |
| Money | `paywall_shown` / `paywall_closed` | `source`, `purchased`, `result` |
| | `purchase_result`, `restore_result` | `outcome`, `product`, `restored` |
| | `trial_ending_shown` | `days_left` |

`home_card_tapped.card` values: `nutrition_scanner`, `body_composition`, `motivation`,
`muscle_map`, `workout_program`, `streak`.

## Insights to build in PostHog

1. **Onboarding funnel** (Product analytics → Funnel, ordered):
   `welcome_cta_tapped` (action = get_started) → `onboarding_step_viewed` (step = goal)
   → (step = signup) → (step = decide) → `plan_generate_tapped` → `plan_generated`
   → `trial_offer_shown`. The biggest drop is the step to fix first.
2. **Where people stall in onboarding** (Trends, bar): `onboarding_step_completed`,
   break down by `step`, ordered by `index`.
3. **Who is signing up** (Trends, pie): `onboarding_answered`, break down by `value`,
   one chart each for `step` = goal, workoutDays, experience.
4. **Home screen usage** (Trends, bar): `home_card_tapped` broken down by `card`.
   Add a second breakdown by `locked` to see how many taps hit the paywall.
5. **Scan funnels**: `home_card_tapped` (card = nutrition_scanner, locked = false) →
   `scan_photo_selected` (kind = meal) → `meal_scanned` (success = true). Same for
   `body_composition` → `scan_photo_selected` (kind = body) → `body_scanned`.
6. **Paywall by feature** (Funnel): `paywall_shown` → `paywall_closed` (purchased =
   true), broken down by `source` — which locked feature actually sells.
7. **Tab usage** (Trends): `tab_viewed` broken down by `tab`.
8. **Plan generation health**: `plan_generated` vs `plan_generation_failed`, and the
   average of `duration_ms`.
