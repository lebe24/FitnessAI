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

  /// The body map, and the tutorials found by tapping a muscle.
  muscleMap,

  /// Adding a movement of your own to a day in the plan.
  addExercise,

  /// The volume trend across logged sessions.
  trainingVolume,

  /// Rewriting the plan around a changed goal or new stats.
  adjustPlan,

  /// AI rating of stance, form and tempo from a video of a set. Saving and
  /// watching your own videos is free; only the analysis, which costs money
  /// each time, is behind this.
  formAnalysis,

  /// Recording, keeping and watching your own workout videos, on the exercise
  /// page and under each muscle.
  exerciseVideos,

  /// What you lifted the last times you did an exercise, and the "same as last
  /// time" shortcut in the log dialog.
  exerciseHistory,

  /// A body goal, a weight log, tape measurements and the muscle development
  /// map that guides what to train.
  bodyTracking,

  /// AI advice on the body goal, written from the user's own logs and training.
  goalAdvice,

  /// A coach's second look at each automatic plan update before it is applied.
  coachReview,

  /// On the exercise page: what weight and reps to use, whether the session has
  /// enough, and extra exercises to add.
  exerciseCoach,

  /// The bot that estimates a session's energy and chats about it, including
  /// choosing its name and look.
  energyChat,
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
        PremiumFeature.muscleMap => 'Train by muscle',
        PremiumFeature.addExercise => 'Make the day yours',
        PremiumFeature.trainingVolume => 'See if it is working',
        PremiumFeature.adjustPlan => 'Rebuild your plan',
        PremiumFeature.formAnalysis => 'Check your form',
        PremiumFeature.exerciseVideos => 'Film your sets',
        PremiumFeature.exerciseHistory => 'Beat your last session',
        PremiumFeature.bodyTracking => 'Track your body goal',
        PremiumFeature.goalAdvice => 'Get advice on your goal',
        PremiumFeature.coachReview => 'Have your coach check every change',
        PremiumFeature.exerciseCoach => 'Get coached on every set',
        PremiumFeature.energyChat => 'See what you burned',
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
        PremiumFeature.muscleMap =>
          'Tap any muscle on the body and get tutorials that train it.',
        PremiumFeature.addExercise =>
          'Add your own movements to any training day and keep them in the plan.',
        PremiumFeature.trainingVolume =>
          'Watch your total load move across sessions, so you know the training is going somewhere.',
        PremiumFeature.adjustPlan =>
          'Change your goal, your days or your stats and have the whole plan rewritten around them.',
        PremiumFeature.formAnalysis =>
          'Film a set and get your stance, form and tempo rated, with what to fix first.',
        PremiumFeature.exerciseVideos =>
          'Record your sets, keep them on your phone, and watch them back in slow motion.',
        PremiumFeature.exerciseHistory =>
          'See what you lifted last time and how it compares, so every set has a number to beat.',
        PremiumFeature.bodyTracking =>
          'Set a goal to lose weight, gain weight or build muscle. Log your weight and measurements and see which muscles to focus on.',
        PremiumFeature.goalAdvice =>
          'Your coach reads your weight trend, measurements and training, then tells you what to change to reach your goal.',
        PremiumFeature.coachReview =>
          'Before your plan changes, your coach reviews each update against your goal and eases off anything too much, too soon.',
        PremiumFeature.exerciseCoach =>
          'See what weight and reps to use today, know when you have done enough, and get extra exercises that fit your goal.',
        PremiumFeature.energyChat =>
          'Your own bot works out the energy each workout used and answers your questions about it.',
      };
}
