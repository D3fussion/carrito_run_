import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/fuel_canister_component.dart';
import 'package:carrito_run/game/components/gas_station_component.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';
import 'package:carrito_run/game/managers/background_manager.dart';
import 'package:carrito_run/game/managers/obstacle_spawner.dart';
import 'package:carrito_run/game/states/game_state.dart';

class CarritoGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        PanDetector,
        TapCallbacks,
        HasCollisionDetection {
  final GameState gameState;

  late BackgroundManager _backgroundManager;
  CarritoComponent? _carrito;
  ObstacleSpawner? _obstacleSpawner;

  bool _isLandscape = false;
  bool _isPlaying = false;
  bool _waitingForGasStation = false;
  bool _imagesPreloaded = false;

  bool _gameOverTriggered = false;

  int _currentTheme = 0;

  bool _hasDragged = false;
  Vector2? _panStartPosition;

  CarritoGame({required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _preloadImages();

    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    await _backgroundManager.loadInitialTheme(0);

    _isLandscape = size.x > size.y;

    pauseEngine();
  }

  void startGame() {
    _isPlaying = true;
    _gameOverTriggered = false;
    gameState.setPlaying(true);

    _updateCarrito();

    resumeEngine();
  }

  void resetGame() {
    _isPlaying = false;
    _gameOverTriggered = false;
    gameState.setPlaying(false);

    removeAll(children);
    _carrito = null;
    _obstacleSpawner = null;
    _currentTheme = 0;
    _waitingForGasStation = false;

    gameState.reset();

    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    _backgroundManager.loadInitialTheme(0);

    pauseEngine();

    overlays.add('StartScreen');
  }

  void restartInstant() {
    _isPlaying = false;
    _gameOverTriggered = false;

    removeAll(children);
    _carrito = null;
    _obstacleSpawner = null;
    _currentTheme = 0;
    _waitingForGasStation = false;

    gameState.reset();

    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    _backgroundManager.loadInitialTheme(0);

    startGame();
  }

  Future<void> _preloadImages() async {
    if (_imagesPreloaded) return;

    await images.loadAll([
      'gas_station_landscape.png',
      'gas_station_portrait.png',
      'carrito_landscape.png',
      'carrito_portrait.png',
      'coin.png',
      'fuel_canister.png',
      'obstacle_jumpable.png',
      'obstacle_nonjumpable.png',
      'explosion.png',
    ]);

    for (int i = 0; i < 5; i++) {
      try {
        await images.load('road_landscape_$i.png');
        await images.load('road_portrait_$i.png');
        await images.load('borders_landscape_$i.png');
        await images.load('borders_portrait_$i.png');
      } catch (e) {
        debugPrint("Faltan imágenes para el tema $i");
      }
    }
    _imagesPreloaded = true;
  }

  int _getThemeForSection(int section) {
    return (section - 1) % 5;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isPlaying) return;

    gameState.updateTime(dt);

    if (gameState.isGameOver && !_gameOverTriggered) {
      _gameOverTriggered = true;
      debugPrint("GAME OVER DETECTADO EN GAME.DART");

      Future.delayed(const Duration(milliseconds: 1500), () {
        pauseEngine();
        overlays.add('GameOverOverlay');
      });
    }

    if (gameState.shouldSpawnGasStation() && !_waitingForGasStation) {
      _waitingForGasStation = true;
      _obstacleSpawner?.setPaused(true);
      gameState.markGasStationSpawned();
      _spawnGasStation();
    }
  }

  void _spawnGasStation() {
    final nextThemeIndex = _getThemeForSection(gameState.currentSection + 1);

    final gasStation = GasStationComponent(
      isLandscape: _isLandscape,
      gameState: gameState,
      onReached: () {
        pauseEngine();
        overlays.remove('PauseButton');
        overlays.add('RefuelOverlay');
      },
      onPassCenter: () {
        gameState.advanceToNextLevel();
        _currentTheme = nextThemeIndex;
        _obstacleSpawner?.setTheme(_currentTheme);
      },
    );

    add(gasStation);
    _backgroundManager.startTransition(nextThemeIndex, gasStation);
  }

  void resumeAfterGasStation() {
    _waitingForGasStation = false;
    _obstacleSpawner?.setPaused(false);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final isCurrentlyLandscape = size.x > size.y;

    if (_isLandscape != isCurrentlyLandscape) {
      _isLandscape = isCurrentlyLandscape;
      if (_isPlaying) {
        _updateCarrito();
      }
    }
  }

  Future<void> _updateCarrito() async {
    children.whereType<CarritoComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.whereType<ObstacleSpawner>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.whereType<ObstacleComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.whereType<CoinComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.whereType<FuelCanisterComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.whereType<GasStationComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );

    await Future.delayed(Duration.zero);

    _carrito = CarritoComponent(
      isLandscape: _isLandscape,
      gameState: gameState,
    );
    add(_carrito!);

    _obstacleSpawner = ObstacleSpawner(
      isLandscape: _isLandscape,
      minSpawnInterval: 0.2,
      maxSpawnInterval: 0.5,
    );
    _obstacleSpawner!.setTheme(_currentTheme);
    add(_obstacleSpawner!);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!_isPlaying) return;
    _hasDragged = false;
    _panStartPosition = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!_isPlaying) return;
    _hasDragged = true;
    if (_carrito != null) {
      _carrito!.handleDrag(info.delta.global);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _hasDragged = false;
    _panStartPosition = null;
  }

  @override
  void onPanCancel() {
    _hasDragged = false;
    _panStartPosition = null;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_isPlaying) return;
    if (!_hasDragged && _carrito != null) {
      _carrito!.jump();
    }
  }
}
