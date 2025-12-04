import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/gas_station_component.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';
import 'package:carrito_run/game/components/terrain_component.dart';
import 'package:carrito_run/game/managers/background_manager.dart';
import 'package:carrito_run/game/managers/obstacle_spawner.dart';
import 'package:carrito_run/game/managers/scenario_manager.dart';
import 'package:carrito_run/game/managers/car_manager.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

class CarritoGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        PanDetector,
        TapCallbacks,
        HasCollisionDetection {
  final GameState gameState;
  final CarManager carManager;

  late BackgroundManager _backgroundManager;
  CarritoComponent? _carrito;
  ScenarioManager? _scenarioManager; // ⭐ NUEVO
  bool _isLandscape = false;
  ObstacleSpawner? _obstacleSpawner;
  bool _isPlaying = false;

  bool _hasDragged = false;
  Vector2? _panStartPosition;

  int _currentTheme = 0;
  bool _waitingForGasStation = false;
  bool _imagesPreloaded = false;

  CarritoGame({required this.gameState, required this.carManager}) {
    gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (gameState.isGameOver && _isPlaying) {
      _handleGameOver();
    }
    
    if (gameState.isOutOfFuel && _isPlaying) {
      _handleOutOfFuel();
    }
  }

  void _handleGameOver() {
    print('🎮 Game Over - Sin vidas');
    _isPlaying = false;
    gameState.setPlaying(false);
    pauseEngine();
    overlays.remove('PauseButton');
    overlays.add('GameOver');
  }

  void _handleOutOfFuel() {
    print('⛽ Game Over - Sin gasolina');
    gameState.loseLife();
    
    if (!gameState.isGameOver) {
      print('💔 Vida perdida por falta de gasolina');
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _preloadImages();

    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    await _backgroundManager.loadInitialTheme(0);

    // ⭐ NUEVO: Inicializar ScenarioManager
    _scenarioManager = ScenarioManager(gameState: gameState, initialScenarioId: 0);
    add(_scenarioManager!);

    _isLandscape = size.x > size.y;

    pauseEngine();
  }

  Future<void> _preloadImages() async {
    if (_imagesPreloaded) return;

    // Imágenes UI
    await images.loadAll([
      'ui/gas_station_landscape.png',
      'ui/gas_station_portrait.png',
      'ui/coin.png',
      'ui/powerup_fuel.png',
      'ui/powerup_heart.png',
      'obstacle_jumpable.png',
      'obstacle_nonjumpable.png',
    ]);

    // Carritos
    try {
      await images.loadAll([
        'carrito_landscape.png',
        'carrito_portrait.png',
      ]);
    } catch (e) {
      print('⚠️ Error cargando carritos: $e');
    }

    // Backgrounds
    for (int i = 0; i < 5; i++) {
      await images.load('road_landscape_$i.png');
      await images.load('road_portrait_$i.png');
      await images.load('borders_landscape_$i.png');
      await images.load('borders_portrait_$i.png');
    }

    _imagesPreloaded = true;
  }

  void resetGame() {
    _isPlaying = false;
    gameState.setPlaying(false);

    removeAll(children);
    _carrito = null;
    _obstacleSpawner = null;
    _currentTheme = 0;
    _waitingForGasStation = false;

    gameState.reset();
    _scenarioManager?.reset(); // ⭐ NUEVO

    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    _backgroundManager.loadInitialTheme(0);

    // ⭐ NUEVO: Recrear ScenarioManager
    _scenarioManager = ScenarioManager(gameState: gameState, initialScenarioId: 0);
    add(_scenarioManager!);

    pauseEngine();
  }

  int _getThemeForSection(int section) {
    return (section - 1) % 5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isPlaying) return;
    
    gameState.updateTime(dt);

    if (gameState.shouldSpawnGasStation() && !_waitingForGasStation) {
      _waitingForGasStation = true;
      _obstacleSpawner?.setPaused(true);
      gameState.markGasStationSpawned();
      _spawnGasStation();
    }
  }

  void _spawnGasStation() {
    final nextThemeIndex = _getThemeForSection(gameState.currentSection);

    // ⭐ NUEVO: Cambiar escenario
    _scenarioManager?.changeToSection(gameState.currentSection);

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

  void startGame() {
    _isPlaying = true;
    gameState.setPlaying(true);

    _updateCarrito();
    resumeEngine();
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
    children.whereType<GasStationComponent>().toList().forEach(
      (c) => c.removeFromParent(),
    );
    children.where((c) => c.runtimeType.toString().contains('PowerUp')).toList().forEach(
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
      gameSpeed: 200.0,
      gameState: gameState,
      scenarioManager: _scenarioManager!, // ⭐ NUEVO
    );
    _obstacleSpawner!.setTheme(_currentTheme);
    add(_obstacleSpawner!);
  }

  @override
  void onRemove() {
    gameState.removeListener(_onGameStateChanged);
    super.onRemove();
  }
}