import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class MusicManager {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _outroPlayer = AudioPlayer();

  bool _isDisposed = false;
  StreamSubscription? _indexSubscription;

  void setVolume(double volume) {
    _musicPlayer.setVolume(volume);
    _uiPlayer.setVolume(volume);
    _outroPlayer.setVolume(volume);
  }

  Future<void> playUiMusic(String filename) async {
    _isDisposed = false;

    try {
      await stopGameMusic();

      if (_uiPlayer.playing) {
        await _uiPlayer.stop();
      }

      if (_outroPlayer.playing) {
        await _outroPlayer.stop();
      }

      debugPrint("🎵 UI Music: Cargando $filename");
      await _uiPlayer.setAsset('assets/audio/$filename');
      await _uiPlayer.setLoopMode(LoopMode.one);
      await _uiPlayer.setVolume(0.5);
      await _uiPlayer.play();

      debugPrint("🎵 UI Music: Reproduciendo $filename");
    } catch (e) {
      debugPrint("❌ Error UI Music: $e");
    }
  }

  Future<void> startGameMusic() async {
    _isDisposed = false;
    debugPrint("🎵 MusicManager: Iniciando música del juego...");

    await _uiPlayer.stop();
    await stopGameMusic();

    try {
      await _indexSubscription?.cancel();

      final playlist = [
        AudioSource.asset('assets/audio/music_intro2.wav'),
        AudioSource.asset('assets/audio/music_loop.wav'),
      ];

      await _musicPlayer.setAudioSources(playlist, initialIndex: 0);
      await _musicPlayer.setVolume(0.5);

      bool loopActivated = false;
      _indexSubscription = _musicPlayer.sequenceStateStream.listen((
        state,
      ) async {
        if (state != null &&
            state.currentIndex == 1 &&
            !loopActivated &&
            !_isDisposed) {
          loopActivated = true;

          await Future.delayed(Duration(milliseconds: 50));

          if (!_isDisposed) {
            await _musicPlayer.setLoopMode(LoopMode.one);
            debugPrint("🎵 Loop infinito activado en track 1!");
          }
        }
      });

      await _musicPlayer.play();
      debugPrint("🎵 Iniciando intro -> loop!");
    } catch (e) {
      debugPrint("❌ Error música del juego: $e");
    }
  }

  Future<void> stopGameMusic() async {
    debugPrint("🎵 MusicManager: Deteniendo música del juego...");

    await _indexSubscription?.cancel();
    await _musicPlayer.stop();
    await _musicPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> playGameOver() async {
    _isDisposed = true;
    debugPrint("🎵 MusicManager: Game Over");

    try {
      await _indexSubscription?.cancel();
      await _musicPlayer.stop();
      await _uiPlayer.stop();

      await _outroPlayer.setAsset('assets/audio/music_outro.wav');
      await _outroPlayer.setVolume(0.6);
      await _outroPlayer.play();

      debugPrint("🎵 Reproduciendo Outro...");
    } catch (e) {
      debugPrint("❌ Error playing outro: $e");
    }
  }

  Future<void> stop() async {
    debugPrint("🎵 MusicManager: Deteniendo toda la música...");

    await _indexSubscription?.cancel();
    await _musicPlayer.stop();
    await _uiPlayer.stop();
    await _outroPlayer.stop();
    await _musicPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> dispose() async {
    _isDisposed = true;

    await _indexSubscription?.cancel();
    await _musicPlayer.dispose();
    await _uiPlayer.dispose();
    await _outroPlayer.dispose();

    debugPrint("🎵 MusicManager: Disposed");
  }
}
