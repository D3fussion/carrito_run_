import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class SfxManager {
  final List<AudioPlayer> _players = [];
  final int _poolSize = 15;
  int _currentIndex = 0;

  bool _isMuted = false;

  SfxManager() {
    _initPool();
  }

  void _initPool() async {
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      _players.add(player);
    }
  }

  Future<void> play(
    String filename, {
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    if (_isMuted) return;

    try {
      final player = _players[_currentIndex];
      _currentIndex = (_currentIndex + 1) % _poolSize;

      if (player.playing) {
        await player.stop();
      }

      await player.setAsset('assets/audio/$filename');
      await player.setVolume(volume);

      try {
        if (pitch != 1.0) {
          await player.setPitch(pitch);
        } else {
          await player.setPitch(1.0);
        }
      } catch (e) {
        debugPrint("Error: $e");
      }

      await player.play();
    } catch (e) {
      debugPrint("❌ Error SFX ($filename): $e");
    }
  }

  Future<void> playCoin() async {
    final random = Random();
    double pitch = 0.9 + random.nextDouble() * 0.3;
    await play('coin.wav', volume: 0.5, pitch: pitch);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      for (var p in _players) p.stop();
    }
  }

  void dispose() {
    for (var player in _players) {
      player.dispose();
    }
    _players.clear();
  }
}
