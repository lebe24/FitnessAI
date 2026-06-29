/// Cache manager for YouTube video data
/// Stores video data by exercise name to avoid redundant API calls
class YouTubeVideoCache {
  static final YouTubeVideoCache _instance = YouTubeVideoCache._internal();
  factory YouTubeVideoCache() => _instance;
  YouTubeVideoCache._internal();

  // Cache storage: exercise name -> video data
  final Map<String, dynamic> _cache = {};

  /// Get cached video data for an exercise
  /// Returns null if not cached
  dynamic getCachedVideos(String exerciseName) {
    return _cache[exerciseName];
  }

  /// Cache video data for an exercise
  void cacheVideos(String exerciseName, dynamic videoData) {
    _cache[exerciseName] = videoData;
  }

  /// Check if videos are cached for an exercise
  bool hasCachedVideos(String exerciseName) {
    return _cache.containsKey(exerciseName) && _cache[exerciseName] != null;
  }

  /// Clear cache for a specific exercise
  void clearCache(String exerciseName) {
    _cache.remove(exerciseName);
  }

  /// Clear all cached videos
  void clearAllCache() {
    _cache.clear();
  }

  /// Get all cached exercise names
  List<String> getCachedExerciseNames() {
    return _cache.keys.toList();
  }
}

