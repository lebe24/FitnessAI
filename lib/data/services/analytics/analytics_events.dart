/// Every analytics event the app sends, in one place.
///
/// Names are snake_case and past tense (something *happened*), so the PostHog
/// event list reads as a story. Keep this file the single source of truth: a
/// stray string literal at a call site is how the same action ends up recorded
/// under two names and the funnel stops adding up.
///
/// What is allowed in properties is decided by [AnalyticsSanitizer], not by
/// good intentions at the call site.
abstract final class AnalyticsEvents {
  // ── Account ────────────────────────────────────────────────────────────────
  static const signedIn = 'signed_in'; //          method
  static const signedUp = 'signed_up'; //          method
  static const signedOut = 'signed_out';
  static const accountDeleted = 'account_deleted';

  // ── Onboarding and plan generation ─────────────────────────────────────────
  static const welcomeCtaTapped = 'welcome_cta_tapped'; //             action: get_started | login
  static const onboardingStepViewed = 'onboarding_step_viewed'; //     step, index, direction
  static const onboardingStepCompleted = 'onboarding_step_completed'; // step, index
  static const onboardingAnswered = 'onboarding_answered'; //          step, value (never free text)
  static const onboardingPathChosen = 'onboarding_path_chosen'; //     path
  static const planGenerateTapped = 'plan_generate_tapped';
  static const trialOfferClosed = 'trial_offer_closed'; //             entitled
  static const planGenerationStarted = 'plan_generation_started'; // goal, days_per_week, experience
  static const planGenerated = 'plan_generated'; //                    duration_ms, goal, days_per_week
  static const planGenerationFailed = 'plan_generation_failed'; //     duration_ms, status_code

  // ── Training ───────────────────────────────────────────────────────────────
  static const workoutSaved = 'workout_saved'; //     exercise_count, duration_mins
  static const workoutCompleted = 'workout_completed'; // duration_mins, streak

  // ── Home screen ────────────────────────────────────────────────────────────
  static const tabViewed = 'tab_viewed'; //                 tab: home | coach | stats | profile
  static const homeCardTapped = 'home_card_tapped'; //      card, locked
  static const scanPhotoSelected = 'scan_photo_selected'; // kind: meal | body | physique, source
  static const motivationGenerated = 'motivation_generated'; // tone, success

  // ── Scans and AI ───────────────────────────────────────────────────────────
  static const mealScanned = 'meal_scanned'; //       success
  static const bodyScanned = 'body_scanned'; //       success
  static const chatMessageSent = 'chat_message_sent'; // length, has_image

  // ── Muscle map ─────────────────────────────────────────────────────────────
  static const muscleMapOpened = 'muscle_map_opened';
  static const muscleDetailOpened = 'muscle_detail_opened'; // muscle
  static const muscleAdvisorAsked = 'muscle_advisor_asked'; //   muscle

  // ── Money ──────────────────────────────────────────────────────────────────
  static const paywallShown = 'paywall_shown'; //     feature
  static const paywallClosed = 'paywall_closed'; //   feature, purchased
  static const purchaseResult = 'purchase_result'; // outcome, product
  static const restoreResult = 'restore_result'; //   restored
  static const trialOfferShown = 'trial_offer_shown';
  static const trialEndingShown = 'trial_ending_shown';

  // ── Privacy ────────────────────────────────────────────────────────────────
  // Sent once, just before collection stops, so the opt-out rate is visible.
  static const analyticsOptedOut = 'analytics_opted_out';
}

/// Decides what may leave the device.
///
/// The rule is *no personal data in events*. An identifier ties events together
/// (the Supabase user id); everything else describes behaviour, not people.
/// Free text — chat messages, notes, exercise names a user typed — is never
/// sent, only its length, because that text is where names, injuries and
/// health details end up.
abstract final class AnalyticsSanitizer {
  /// Property names that are dropped whatever their value.
  static const blockedKeys = <String>{
    'email',
    'name',
    'first_name',
    'last_name',
    'phone',
    'password',
    'token',
    'message',
    'text',
    'notes',
    'note',
    'image',
    'image_path',
    'photo',
    'url',
    'address',
  };

  static const _maxString = 100;

  /// Returns only the properties that are safe to send: non-null scalars with
  /// non-personal names, and strings that are short and contain no `@`.
  static Map<String, Object> clean(Map<String, Object?>? props) {
    if (props == null || props.isEmpty) return const {};
    final out = <String, Object>{};
    props.forEach((key, value) {
      if (value == null) return;
      if (blockedKeys.contains(key.toLowerCase())) return;
      if (value is bool || value is num) {
        out[key] = value;
      } else if (value is String) {
        if (value.length > _maxString) return;
        if (value.contains('@')) return; // looks like an email address
        out[key] = value;
      } else if (value is Enum) {
        out[key] = value.name;
      }
      // Lists, maps and arbitrary objects are dropped: they are how whole
      // records (a workout, a profile) end up in an analytics payload.
    });
    return out;
  }
}
