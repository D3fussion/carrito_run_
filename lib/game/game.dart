import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:carrito_run/game/components/gas_station_component.dart';
import 'package:carrito_run/game/managers/obstacle_spawner.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class CarritoGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        PanDetector,
        TapCallbacks,
        HasCollisionDetection {
  final GameState gameState;

  ParallaxComponent? _parallaxComponent;
  CarritoComponent? _carrito;
  bool _isLandscape = false;
  ObstacleSpawner? _obstacleSpawner;

  bool _hasDragged = false;
  Vector2? _panStartPosition;

  int _lastSection = 0;
  int _currentTheme = 0;
  int _lastAppliedTheme = -1;
  bool _waitingForGasStation = false;

  bool _imagesPreloaded = false;

  CarritoGame({required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _preloadImages();

    pauseEngine();
  }

  Future<void> _preloadImages() async {
    if (_imagesPreloaded) return;

    await images.loadAll([
      'road_landscape.png',
      'road_portrait.png',
      'borders_landscape.png',
      'borders_portrait.png',
      'gas_station_landscape.png',
      'gas_station_portrait.png',
      // Agregar aquí más imágenes de temas:
      // 'road_landscape_theme1.png',
      // 'road_landscape_theme2.png',
      // etc.
    ]);

    _imagesPreloaded = true;
  }

  void resetGame() {
    removeAll(children);
    _parallaxComponent = null;
    _carrito = null;
    _obstacleSpawner = null;
    _lastSection = 0;
    _currentTheme = 0;
    _lastAppliedTheme = -1;
    _waitingForGasStation = false;
    gameState.reset();
    pauseEngine();
  }

  int _getThemeForSection(int section) {
    return (section - 1) % 5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    gameState.updateTime(dt);

    if (gameState.shouldSpawnGasStation() && !_waitingForGasStation) {
      _lastSection = gameState.currentSection;
      _waitingForGasStation = true;

      _obstacleSpawner?.setPaused(true);

      gameState.markGasStationSpawned();
      _spawnGasStation();
    }

    final newTheme = _getThemeForSection(gameState.currentSection);
    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;

      if (_currentTheme != _lastAppliedTheme) {
        _changeTheme();
        _lastAppliedTheme = _currentTheme;
      }
    }
  }

  void _changeTheme() {
    _updateParallaxForTheme();
    _obstacleSpawner?.setTheme(_currentTheme);
  }

  void _spawnGasStation() {
    final gasStation = GasStationComponent(
      isLandscape: _isLandscape,
      gameSpeed: 200.0,
      gameState: gameState,
      onReached: () {
        pauseEngine();
        overlays.remove('PauseButton');
        overlays.add('RefuelOverlay');
      },
    );

    add(gasStation);
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
      _updateParallaxForTheme();
      _updateCarrito();
    } else if (_parallaxComponent == null) {
      _updateParallaxForTheme();
      _updateCarrito();
    }
  }

  @override
  void onPanStart(DragStartInfo info) {
    _hasDragged = false;
    _panStartPosition = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
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
    if (!_hasDragged && _carrito != null) {
      _carrito!.jump();
    }
  }

  Future<void> _updateCarrito() async {
    if (_carrito != null) {
      remove(_carrito!);
    }

    if (_obstacleSpawner != null) {
      remove(_obstacleSpawner!);
    }

    _carrito = CarritoComponent(
      isLandscape: _isLandscape,
      gameState: gameState,
    );
    await add(_carrito!);

    _obstacleSpawner = ObstacleSpawner(
      isLandscape: _isLandscape,
      gameSpeed: 200.0,
      minSpawnInterval: 2.0,
      maxSpawnInterval: 4.0,
    );
    _obstacleSpawner!.setTheme(_currentTheme);
    await add(_obstacleSpawner!);
  }

  Future<void> _updateParallaxForTheme() async {
    if (_parallaxComponent != null) {
      remove(_parallaxComponent!);
    }

    final roadImage = _isLandscape ? 'road_landscape.png' : 'road_portrait.png';
    final bordersImage = _isLandscape
        ? 'borders_landscape.png'
        : 'borders_portrait.png';

    final layers = await Future.wait([
      loadParallaxLayer(
        ParallaxImageData(roadImage),
        velocityMultiplier: Vector2(1.3, 1.3),
        alignment: Alignment.center,
        fill: _isLandscape ? LayerFill.height : LayerFill.width,
        repeat: _isLandscape ? ImageRepeat.repeatX : ImageRepeat.repeatY,
      ),
      loadParallaxLayer(
        ParallaxImageData(bordersImage),
        velocityMultiplier: Vector2(1.0, 1.0),
        alignment: Alignment.center,
        fill: _isLandscape ? LayerFill.height : LayerFill.width,
        repeat: _isLandscape ? ImageRepeat.repeatX : ImageRepeat.repeatY,
      ),
    ]);

    final parallax = ParallaxComponent(
      parallax: Parallax(
        layers,
        baseVelocity: _isLandscape ? Vector2(-80, 0) : Vector2(0, 80),
      ),
      priority: -1,
    );

    _parallaxComponent = parallax;
    add(_parallaxComponent!);
  }
}
