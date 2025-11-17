class GreetingHelper {
  /// Returns a greeting based on the current time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }
  
  /// Returns an emoji based on the time of day
  static String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return '☀️'; // Sun for morning
    } else if (hour >= 12 && hour < 17) {
      return '🌤️'; // Sun with cloud for afternoon
    } else if (hour >= 17 && hour < 21) {
      return '🌆'; // Cityscape for evening
    } else {
      return '🌙'; // Moon for night
    }
  }
}

