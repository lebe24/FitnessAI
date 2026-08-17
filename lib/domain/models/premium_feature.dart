/// The features that require an active subscription or trial.
///
/// Everything gated names itself here rather than checking a bare boolean at
/// the call site. Two reasons:
///
///  * It is a complete, greppable list of what is behind the paywall. When
///    someone asks "what do I get for paying?", this enum is the answer, and
///    it cannot drift from the marketing copy without the drift being obvious.
///  * Every feature currently maps to the same tier, but that will not stay
///    true forever. When one moves — say nutrition becomes free to drive
///    installs — it changes in [AccessPolicy], not in six widgets.
enum PremiumFeature {
  /// Photograph a meal, get calories and macros back.
  nutritionScanner,

  /// Body-composition estimate from a progress photo.
  bodyComposition,

  /// AI-written motivation in a chosen tone, on a schedule.
  motivation,

  /// The coaching chat that knows the user's plan and history.
  agentChat,

  /// Point the camera at a machine to get exercises for it.
  equipmentScan,

  /// Demonstration videos attached to an exercise.
  videoTutorial,
}

extension PremiumFeatureCopy on PremiumFeature {
  /// Shown as the paywall headline when this feature is what the user tapped.
  /// Naming the specific thing they wanted converts better than a generic
  /// "Upgrade to Pro".
  String get title => switch (this) {
        PremiumFeature.nutritionScanner => 'Scan your meals',
        PremiumFeature.bodyComposition => 'Track your composition',
        PremiumFeature.motivation => 'Get your daily push',
        PremiumFeature.agentChat => 'Ask your coach',
        PremiumFeature.equipmentScan => 'Scan any machine',
        PremiumFeature.videoTutorial => 'Watch the movement',
      };

  String get pitch => switch (this) {
        PremiumFeature.nutritionScanner =>
          'Point your camera at a plate and get calories and macros back in seconds.',
        PremiumFeature.bodyComposition =>
          'See how your body is actually changing, from a single photo.',
        PremiumFeature.motivation =>
          'Your coach writes each message from your own goal, streak and training.',
        PremiumFeature.agentChat =>
          'Ask anything about your plan, your form or your recovery — and get an answer that fits you.',
        PremiumFeature.equipmentScan =>
          'Point your camera at a machine and get exercises you can do on it right now.',
        PremiumFeature.videoTutorial =>
          'Watch how every movement should look before you load the bar.',
      };
}
