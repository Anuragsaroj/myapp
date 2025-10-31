import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playTapSound() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;

    if (soundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/tap.mp3'));
    }
  }
}
