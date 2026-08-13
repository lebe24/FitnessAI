import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final player = AudioPlayer();

  Future<void> play(String url) async {
    await player.setUrl(url);
    player.play();
  }

  /// Play a bundled asset, e.g. a short UI chime.
  ///
  /// Fire-and-forget: a sound effect must never break the interaction it
  /// accompanies, so failures are logged and swallowed. Uses its own
  /// short-lived player so it can overlap [play] without cutting it off.
  ///
  /// The session is set to *ambient* first. iOS otherwise defaults a player to
  /// `soloAmbient`, which would duck or pause whatever the user is listening
  /// to just to ring a one-second bell. Ambient also honours the ringer
  /// switch, so a silenced phone stays silent.
  static Future<void> playAsset(String assetPath) async {
    final effect = AudioPlayer();
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
      await effect.setAsset(assetPath);
      await effect.play();
    } catch (e) {
      debugPrint('AudioPlayerService.playAsset failed: $e');
    } finally {
      await effect.dispose();
    }
  }

  void pause() {
    player.pause();
  }

  void stop() {
    player.stop();
  }

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
}
