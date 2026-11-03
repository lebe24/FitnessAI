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
| Exercise page | `exercise_viewed` | `exercise_index`, `sets`, `muscle` |
| | `exercise_history_loaded` | `status` (ok \| empty \| failed), `entries` |
| | `exercise_log_opened` | context fields, `had_previous` |
| | `exercise_log_voice` | `result` (started \| parsed \| failed), `sets_filled` |
| | `exercise_log_same_as_last` | context fields |
| | `exercise_log_incomplete` | context fields, `missing_sets` |
| | `exercise_log_saved` | context fields, `used_voice`, `used_last_time` |
| | `exercise_log_save_failed`, `exercise_log_dismissed` | context fields |
| | `exercise_completed` | context fields, `logged`, `seconds_on_page` |
| | `exercise_left` | context fields, `logged`, `seconds_on_page` |
| | `exercise_leave_prompt` | `choice` (save \| discard \| dismissed) |
| | `exercise_tutorials_loaded` | `success`, `cached`, `count` |
| | `exercise_tutorial_opened` | context fields |
| | `exercise_history_opened` | `sessions` |
| Workout videos | `exercise_video_added` | `source` (record \| library), `duration_s` |
| | `exercise_video_played`, `exercise_video_deleted` | `analysed` (deleted only) |
| | `form_analysis_started` | `frame_count` |
| | `form_analysis_completed` | `overall_score`, `confidence`, `camera_view`, `duration_ms` |
| | `form_analysis_failed` | `reason` (offline \| timeout \| monthlyCap \| rateLimited \| couldNotAnalyse \| signedOut \| badRequest \| other) |
| | `form_analysis_result_viewed` | `overall_score` |
| | `muscle_videos_opened` | `muscle` |
| Muscle map | `muscle_map_opened`, `muscle_detail_opened`, `muscle_advisor_asked` | `muscle` |
| Money | `paywall_shown` / `paywall_closed` | `source`, `purchased`, `result` |
| | `purchase_result`, `restore_result` | `outcome`, `product`, `restored` |
| | `trial_ending_shown` | `days_left` |

**Exercise page context fields** are `exercise_index`, `sets` and `muscle` (one of
the muscle map's fixed slugs, or `unknown`). The exercise **name is never sent**:
users can add their own exercises, and that name is free text. Read the page by
*muscle* instead of by exercise.

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
9. **Exercise page funnel** (Funnel, ordered): `exercise_viewed` →
   `exercise_log_opened` → `exercise_log_saved` → `exercise_completed`. Break down
   by `muscle` to see which muscle groups people log, and which they skip.
10. **Logging friction** (Trends): `exercise_log_incomplete` (people tapping Save
    with missing weight or reps) against `exercise_log_saved`; and
    `exercise_log_dismissed` against `exercise_log_opened` for people who open the
    box and close it.
11. **Do the new logging helpers help?** `exercise_log_saved` broken down by
    `used_voice` and `used_last_time`, plus `exercise_log_voice` by `result` to see
    how often voice parsing fails.
12. **Is history being used?** `exercise_history_loaded` by `status` (a high
    `failed` share means a load problem), `exercise_history_opened` for "See all",
    and `exercise_log_opened` by `had_previous`.
13. **Time on each exercise** (Trends, average): `exercise_completed` →
    `seconds_on_page`, broken down by `muscle`. Compare with `exercise_left` to see
    where people give up.
14. **Tutorial demand** (Funnel): `exercise_tutorials_loaded` →
    `exercise_tutorial_opened`, with `paywall_shown` where `source` is
    `videoTutorial` showing how many hit the paywall.
15. **Is the video log used?** (Funnel, ordered): `exercise_video_added` →
    `form_analysis_started` → `form_analysis_completed` →
    `form_analysis_result_viewed`. Break `exercise_video_added` down by `source`.
    The gap between added and started is people who record but never analyse
    (or hit the paywall: see `paywall_shown` with `source` = `formAnalysis`).
16. **Is the analysis trustworthy and cheap enough?** (Trends): `form_analysis_failed`
    against `form_analysis_completed`, by `reason`; and `form_analysis_completed`
    broken down by `camera_view` and `confidence`. A large share of `rear` or `low`
    means people are not following the filming tips.
17. **Do people come back to their videos?** `exercise_video_played` per
    `exercise_video_added`, and `muscle_videos_opened` by `muscle`.
