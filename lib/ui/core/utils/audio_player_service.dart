import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final player = AudioPlayer();

  Future<void> play(String url) async {
    await player.setUrl(url);
    player.play();
  }

  void pause() {
    player.pause();
  }

  void stop() {
    player.stop();
  }

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
}
