import 'package:fitness/app/api/data/datasources/agent_remote_datasource.dart';
import 'package:fitness/app/api/data/datasources/supabase_remote_datasource.dart';
import 'package:fitness/app/core/constant/assets.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/core/utils/audio_player_service.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutter/material.dart';

class MotivatePage extends StatefulWidget {
  const MotivatePage({super.key});

  @override
  State<MotivatePage> createState() => _MotivatePageState();
}

class _MotivatePageState extends State<MotivatePage> {
  final audioService = AudioPlayerService();
  final supabaseDataSource = sl<SupabaseRemoteDataSource>();
  final agentDataSource = sl<AgentRemoteDataSource>();
  final getProfileUseCase = sl<GetProfileUseCase>();
  final getCurrentUser = sl<GetCurrentUser>();
  
  String? _quote;
  String? _imageUrl;
  String? _generatedQuote;
  bool _isLoading = true;
  bool _isGeneratingQuote = false;

  @override
  void initState() {
    super.initState();
    _initializeMotivation();
  }

  Future<void> _initializeMotivation() async {
    try {
      final profile = await getProfileUseCase();
      final gender = profile.gender ?? 'male'; // Default to 'Male' if gender is null
      await loadMotivation(gender);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading motivation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadMotivation(String gender) async {
    try {
      final content = await supabaseDataSource.getMotivation(gender);
      
      if (content != null) {
        // Use 'photo_tone' if 'quote' doesn't exist (based on CSV structure)
        final quote = content['quote'] as String? ?? 
                      content['photo_tone'] as String?;
        final imageUrl = content['image_url'] as String?;
        final audio = content['audio_file'] as String?;
        
        if (mounted) {
          setState(() {
            _quote = quote;
            _imageUrl = imageUrl;
            _isLoading = false;
          });
          
          // Generate AI quote based on the photo_tone
          if (quote != null && quote.isNotEmpty) {
            await _generateAIMotivationQuote(quote);
          }
          
          if (audio != null && audio.isNotEmpty) {
            await playMotivation(audio);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading motivation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAIMotivationQuote(String message) async {
    try {
      setState(() {
        _isGeneratingQuote = true;
      });

      final user = getCurrentUser();
      final userName = user?.name ?? user?.email ?? 'User';
      
      final generatedQuote = await agentDataSource.generateMotivationQuote(
        userName: userName,
        tone: 'soft motivation',
        message: message,
      );

      if (mounted) {
        setState(() {
          _generatedQuote = generatedQuote;
          _isGeneratingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingQuote = false;
        });
        debugPrint('Error generating AI quote: $e');
        // Don't show error to user, just use the original quote
      }
    }
  }

  Future<void> playMotivation(String audioUrl) async {
    try {
      await audioService.play(audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MotivatePage with imageUrl: $_imageUrl and quote: $_quote');
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    ImagePath.unstoppable,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                },
                              )
                            : Image.asset(
                                ImagePath.unstoppable,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            // Original quote/photo_tone
                            if (_quote != null && _quote!.isNotEmpty)
                              Text(
                                _quote!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            // AI Generated quote
                            if (_isGeneratingQuote)
                              const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              Builder(
                                builder: (context) {
                                  final generatedQuote = _generatedQuote;
                                  if (generatedQuote != null && generatedQuote.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Text(
                                        generatedQuote,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.07,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                // Action when button is pressed
                await audioService.play("https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3");
              },
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.volume_off, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}