import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  
  late final AudioPlayer _audioPlayer;

  SoundService._internal() {
    _audioPlayer = AudioPlayer();
  }

  /// Plays the default notification sound.
  Future<void> playNotificationSound() async {
    try {
      if (kIsWeb) {
        // On web, sometimes audio autoplay is blocked unless interacted with,
        // but we still attempt to play it.
        await _audioPlayer.play(AssetSource('sounds/notification.wav'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/notification.wav'));
      }
    } catch (e) {
      debugPrint('Failed to play notification sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
