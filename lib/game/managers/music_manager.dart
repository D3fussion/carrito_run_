import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class MusicManager {
  AudioPlayer? _introPlayer;
  AudioPlayer? _loopPlayer;
  bool _isDisposed = false;

  void setVolume(double volume) {
    _introPlayer?.setVolume(volume);
    _loopPlayer?.setVolume(volume);
  }

  Future<void> startMusic() async {
    _isDisposed = false;
    debugPrint("🎵 MusicManager: Iniciando secuencia...");

    // 1. Limpieza previa
    await stop();

    try {
      // 2. Reproducimos el INTRO usando FlameAudio
      // Guardamos la instancia que Flame crea automáticamente
      _introPlayer = await FlameAudio.play('music_intro.ogg', volume: 0.5);

      // 3. Le ponemos el listener AL MISMO reproductor que está sonando
      _introPlayer?.onPlayerComplete.listen((event) async {
        debugPrint("🎵 INTRO TERMINADO. Iniciando Loop...");
        _loopPlayer = await FlameAudio.loop('music_loop.ogg', volume: 0.5);
      });
    } catch (e) {
      debugPrint("❌ Error reproduciendo Intro: $e");
    }
  }

  Future<void> playGameOver() async {
    _isDisposed = true;
    debugPrint("🎵 MusicManager: Game Over");

    await _introPlayer?.stop();
    await _loopPlayer?.stop();

    try {
      await FlameAudio.play('music_outro.ogg', volume: 0.6);
    } catch (e) {
      debugPrint("Error playing outro: $e");
    }
  }

  Future<void> stop() async {
    _isDisposed = true;
    try {
      await _introPlayer?.stop();
      _introPlayer = null;

      await _loopPlayer?.stop();
      _loopPlayer = null;
    } catch (e) {
      // Ignorar errores de disposición
    }
  }
}
