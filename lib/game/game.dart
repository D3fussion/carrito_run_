import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:carrito_run/game/components/gas_station_component.dart';
import 'package:carrito_run/game/managers/background_manager.dart';
import 'package:carrito_run/game/managers/obstacle_spawner.dart';
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

  late BackgroundManager _backgroundManager;
  CarritoComponent? _carrito;
  bool _isLandscape = false;
  ObstacleSpawner? _obstacleSpawner;

  bool _hasDragged = false;
  Vector2? _panStartPosition;

  int _currentTheme = 0;
  bool _waitingForGasStation = false;
  bool _imagesPreloaded = false;

  CarritoGame({required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _preloadImages(); // Asegúrate de tener tus imágenes 0, 1, 2...

    // Inicializamos el manager
    _backgroundManager = BackgroundManager();
    await add(_backgroundManager);

    // Cargamos el primer tema
    await _backgroundManager.loadInitialTheme(0);

    pauseEngine();
  }

  Future<void> _preloadImages() async {
    if (_imagesPreloaded) return;

    // Cargar assets base
    await images.loadAll([
      'gas_station_landscape.png',
      'gas_station_portrait.png',
      'carrito_landscape.png',
      'carrito_portrait.png',
      'coin.png',
      'obstacle_jumpable.png',
      'obstacle_nonjumpable.png',
    ]);

    // Cargar assets de temas (0 al 4)
    for (int i = 0; i < 5; i++) {
      await images.load('road_landscape_$i.png');
      await images.load('road_portrait_$i.png');
      await images.load('borders_landscape_$i.png');
      await images.load('borders_portrait_$i.png');
    }

    _imagesPreloaded = true;
  }

  void resetGame() {
    _carrito = null;
    _obstacleSpawner = null;
    _currentTheme = 0;
    removeAll(children);
    remove(_backgroundManager);
    _backgroundManager = BackgroundManager();
    add(_backgroundManager);
    _backgroundManager.loadInitialTheme(0);
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
      _waitingForGasStation = true;
      _obstacleSpawner?.setPaused(true);
      gameState.markGasStationSpawned();
      _spawnGasStation();
    }

    // NOTA: Eliminamos la lógica de cambio de tema automático aquí
    // Ahora lo maneja la gasolinera.
  }

  void _spawnGasStation() {
    final nextThemeIndex = _getThemeForSection(gameState.currentSection);

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

    // AQUI ESTÁ LA CLAVE:
    // Le decimos al manager que inicie la transición visual usando esta gasolinera
    _backgroundManager.startTransition(nextThemeIndex, gasStation);
  }

  void resumeAfterGasStation() {
    _waitingForGasStation = false;
    _obstacleSpawner?.setPaused(false);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Solo actualizamos variables de estado, el BackgroundManager se redimensiona solo
    final isCurrentlyLandscape = size.x > size.y;
    if (_isLandscape != isCurrentlyLandscape) {
      _isLandscape = isCurrentlyLandscape;
      _updateCarrito();
      // Si cambias de orientación drásticamente, podrías querer recargar el fondo
      // o dejar que el manager maneje el resize (ya lo hace en su código).
    }
  }

  // ... (MÉTODOS DE INPUT: onPanStart, onPanUpdate, etc. se mantienen igual) ...
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
    if (_carrito != null) remove(_carrito!);
    if (_obstacleSpawner != null) remove(_obstacleSpawner!);

    _carrito = CarritoComponent(
      isLandscape: _isLandscape,
      gameState: gameState,
    );
    await add(_carrito!);

    _obstacleSpawner = ObstacleSpawner(
      isLandscape: _isLandscape,
      gameSpeed: 200.0,
    );
    _obstacleSpawner!.setTheme(_currentTheme);
    await add(_obstacleSpawner!);
  }
}
