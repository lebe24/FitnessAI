import 'package:fitness/app/api/data/helpers/youtube_video_cache.dart';
import 'package:fitness/app/api/domain/usecases/search_youtube_videos_usecase.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/home/domain/entities/workout_plan_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ======= Exercise Hero Page ========

class ExerciseHeroPage extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final VoidCallback onComplete;
  

  const ExerciseHeroPage({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onComplete,
  });

  @override
  State<ExerciseHeroPage> createState() => _ExerciseHeroPageState();
}

class _ExerciseHeroPageState extends State<ExerciseHeroPage> {
  bool isViewing = false;
  dynamic videoContent;
  bool _isLoadingVideos = false;
  String? _errorMessage;
  final YouTubeVideoCache _videoCache = YouTubeVideoCache();
  
  List<Color> _getGradientColors() {
    return [
      const Color(0xFF2C3E50).withOpacity(0.8),
      const Color(0xFF34495E).withOpacity(0.9),
      Colors.black.withOpacity(0.9),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Check cache when page initializes
    _loadCachedVideos();
  }

  /// Load videos from cache if available
  void _loadCachedVideos() {
    final cachedData = _videoCache.getCachedVideos(widget.exercise.name);
    if (cachedData != null) {
      setState(() {
        videoContent = cachedData;
        // If videos were previously viewed, restore that state
        if (videoContent != null && videoContent is Map) {
          final contents = videoContent['contents'];
          if (contents != null && (contents as List).isNotEmpty) {
            isViewing = true;
            debugPrint('Loaded ${contents.length} videos from cache');
          }
        }
      });
    }
  }

  Future<void> _loadVideos() async {
    // Check cache first
    if (_videoCache.hasCachedVideos(widget.exercise.name)) {
      final cachedData = _videoCache.getCachedVideos(widget.exercise.name);
      setState(() {
        videoContent = cachedData;
        _isLoadingVideos = false;
        isViewing = true;
      });
      
      if (videoContent != null && videoContent is Map) {
        final contents = videoContent['contents'];
        if (contents != null) {
          debugPrint('Loaded ${contents.length} videos from cache');
        }
      }
      return;
    }

    // If not in cache, fetch from API
    setState(() {
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    try {
      final youtubeUsecase = sl<SearchYouTubeVideosUsecase>();
      final result = await youtubeUsecase(widget.exercise.name, maxResults: 10);
      
      // Cache the result
      _videoCache.cacheVideos(widget.exercise.name, result);
      
      setState(() {
        videoContent = result;
        _isLoadingVideos = false;
        isViewing = true;
      });

      if (videoContent != null && videoContent is Map) {
        final contents = videoContent['contents'];
        if (contents != null) {
          debugPrint('Loaded ${contents.length} videos from API and cached');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingVideos = false;
      });
      debugPrint('Error loading videos: $e');
    }
  }

  void _openYouTubeVideo(String videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _YouTubePlayerModal(videoId: videoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Exercise ${widget.exerciseIndex + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Exercise content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Exercise name
                      Text(
                        widget.exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sets and reps info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppPallete.whiteColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppPallete.whiteColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${widget.exercise.sets}',
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.whiteColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sets',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPallete.whiteColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppPallete.whiteColor.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  widget.exercise.reps,
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.whiteColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reps',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppPallete.whiteColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.exercise.notes != null) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Instructions',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppPallete.whiteColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppPallete.whiteColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.exercise.notes!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppPallete.whiteColor.withOpacity(0.9),
                              height: 1.6,
                            ),
                          ),
                        ),
                        
                      ],
                      const SizedBox(height: 40),
                      Text('Make sure to follow the instructions carefully to avoid injury and maximize effectiveness.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppPallete.whiteColor.withOpacity(0.7),
                          ),
                        ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppPallete.whiteColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppPallete.whiteColor.withOpacity(0.2),
                                width: 1,
                              ),
                          ),
                          child:Center(
                            child: Text("Access Similar Exercises Tutorials",
                               textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppPallete.whiteColor.withOpacity(0.9),
                                height: 1.6,
                              ),
                            ),
                          )),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "View Video Tutorials",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!isViewing)
                        _videoPlaceholderCard()
                      else if (_isLoadingVideos)
                        _buildLoadingIndicator()
                      else if (_errorMessage != null)
                        _buildErrorWidget()
                      else if (videoContent != null && videoContent is Map)
                        _buildVideosList()
                      else
                        _buildNoVideosWidget(),
                    ],
                  ),
                ),
              ),
              
              
              // Complete button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppPallete.borderColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppPallete.whiteColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Complete Exercise',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppPallete.whiteColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.whiteColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppPallete.whiteColor),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 12),
          Text(
            'Failed to load videos',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppPallete.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppPallete.whiteColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadVideos,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                color: AppPallete.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVideosWidget() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppPallete.whiteColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.whiteColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: AppPallete.whiteColor.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No videos found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppPallete.whiteColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    try {
      final contents = videoContent['contents'] as List<dynamic>?;
      if (contents == null || contents.isEmpty) {
        return _buildNoVideosWidget();
      }

      return SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: contents.length,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final video = contents[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _videoCard(video),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error building videos list: $e');
      return _buildErrorWidget();
    }
  }

  Widget _videoCard(dynamic video) {
    // Extract video data from RapidAPI response format
    String videoThumbnail = '';
    String videoId = '';
    String? videoTitle;

    try {
      if (video is Map && video.containsKey('video')) {
        final videoData = video['video'] as Map?;
        if (videoData != null) {
          // Extract videoId
          videoId = videoData['videoId'] as String? ?? '';

          // Extract thumbnail - try index 1 first, then 0, then any available
          final thumbnails = videoData['thumbnails'] as List?;
          if (thumbnails != null && thumbnails.isNotEmpty) {
            // Try to get thumbnail at index 1 (higher quality), fallback to 0
            final thumbnail1 = thumbnails.length > 1 ? thumbnails[1] as Map? : null;
            final thumbnail0 = thumbnails.isNotEmpty ? thumbnails[0] as Map? : null;
            final thumbnail = thumbnail1 ?? thumbnail0;
            videoThumbnail = thumbnail?['url'] as String? ?? '';
          }

          // Extract title if available
          videoTitle = videoData['title'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error parsing video data: $e');
    }

    return GestureDetector(
      onTap: videoId.isNotEmpty ? () => _openYouTubeVideo(videoId) : null,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: AppPallete.whiteColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPallete.whiteColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Thumbnail
              if (videoThumbnail.isNotEmpty)
                Image.network(
                  videoThumbnail,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppPallete.whiteColor.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.video_library_outlined,
                          color: AppPallete.whiteColor,
                          size: 48,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: AppPallete.whiteColor.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.video_library_outlined,
                      color: AppPallete.whiteColor,
                      size: 48,
                    ),
                  ),
                ),
              // Play button overlay
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
              // Title overlay at bottom
              if (videoTitle != null && videoTitle!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Text(
                      videoTitle!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.whiteColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Container _videoPlaceholderCard() {
    return Container(
                      width: double.infinity,
                      height: 200,
                      padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppPallete.whiteColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppPallete.whiteColor.withOpacity(0.2),
                            width: 1,
                          ),
                      ),
                      child:IconButton(
                        color: Colors.transparent,
                        onPressed: (){
                          setState(() {
                            isViewing = true;
                          });

                          _loadVideos();
                        }, 
                        icon: const Icon(
                    Icons.play_circle_outline,
                          color: AppPallete.whiteColor,
                          size: 48,)
                    ));
  }
}

/// YouTube Player Modal Widget
class _YouTubePlayerModal extends StatefulWidget {
  final String videoId;

  const _YouTubePlayerModal({required this.videoId});

  @override
  State<_YouTubePlayerModal> createState() => _YouTubePlayerModalState();
}

class _YouTubePlayerModalState extends State<_YouTubePlayerModal> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        loop: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      // Handle player state changes if needed
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Video Tutorial',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // YouTube Player
              Expanded(
                child: YoutubePlayerBuilder(
                  onExitFullScreen: () {
                    // Handle exit fullscreen
                  },
                  player: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                    onReady: () {
                      setState(() {
                        _isPlayerReady = true;
                      });
                    },
                  ),
                  builder: (context, player) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: player,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}