import 'dart:math';
import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';
import 'package:carrito_run/game/components/powerup_component.dart';
import 'package:carrito_run/game/managers/scenario_manager.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:flame/components.dart';

class ObstaclePattern {
  final List<ObstacleSpawnInfo> obstacles;
  final List<CoinSpawnInfo> coins;
  final double duration;

  ObstaclePattern({
    required this.obstacles,
    this.coins = const [],
    required this.duration,
  });
}

class ObstacleSpawnInfo {
  final int lane;
  final ObstacleType type;
  final double delayFromStart;

  ObstacleSpawnInfo({
    required this.lane,
    required this.type,
    this.delayFromStart = 0.0,
  });
}

class CoinSpawnInfo {
  final int lane;
  final double delayFromStart;
  final bool isOnObstacle;

  CoinSpawnInfo({
    required this.lane,
    this.delayFromStart = 0.0,
    this.isOnObstacle = false,
  });
}

class ObstacleSpawner extends Component with HasGameReference {
  final bool isLandscape;
  final double gameSpeed;
  final GameState gameState;

  final double minSpawnGap;
  final double maxSpawnGap;

  double _timeSinceLastSpawn = 0;
  double _nextSpawnTime = 0;

  double _lastPatternDuration = 0.0;

  final Random _random = Random();

  late Map<int, List<ObstaclePattern>> _patternsByTheme;
  int _currentTheme = 0;
  bool _isPaused = false;

  final List<_PendingObstacle> _pendingObstacles = [];
  final List<_PendingCoin> _pendingCoins = [];
  final List<_PendingPowerUp> _pendingPowerUps = [];

  // ⭐ Sistema de power-ups aleatorios
  double _timeSinceLastPowerUp = 0;
  final double _powerUpMinInterval = 8.0;  // Mínimo 8 segundos entre power-ups
  final double _powerUpMaxInterval = 15.0; // Máximo 15 segundos
  double _nextPowerUpTime = 10.0;
  
  // Probabilidades de spawn
  final double _fuelPowerUpChance = 0.80;  // 80% gasolina
  final double _lifePowerUpChance = 0.20;  // 20% vida extra

  ObstacleSpawner({
    required this.isLandscape,
    required this.gameState,
    this.gameSpeed = 200.0,
    double minSpawnInterval = 0.5,
    double maxSpawnInterval = 1.5, required ScenarioManager scenarioManager,
  })  : minSpawnGap = minSpawnInterval,
        maxSpawnGap = maxSpawnInterval;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializePatterns();
    _nextSpawnTime = 1.0;
    _scheduleNextPowerUp();
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    if (paused) {
      _pendingObstacles.clear();
      _pendingCoins.clear();
      _pendingPowerUps.clear();
    }
  }

  void setTheme(int theme) {
    _currentTheme = theme % 5;
  }

  void _scheduleNextPowerUp() {
    _nextPowerUpTime = _powerUpMinInterval +
        _random.nextDouble() * (_powerUpMaxInterval - _powerUpMinInterval);
  }

  void _initializePatterns() {
    final basePatterns = [
      // Patrón 1 (Duración 1.5)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.8, isOnObstacle: true),
        ],
        duration: 1.5,
      ),
      // Patrón 2 (Duración 2.0)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.6,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.2,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.6),
          CoinSpawnInfo(lane: 3, delayFromStart: 1.2),
        ],
        duration: 2.0,
      ),
      // Patrón 3 (Duración 1.5)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [CoinSpawnInfo(lane: 2, delayFromStart: 0.0)],
        duration: 1.5,
      ),
      // Patrón 4 (Duración 2.0)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.3,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.6,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.9,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.jumpable,
            delayFromStart: 1.2,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 0, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 1, delayFromStart: 0.3, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.6, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.9, isOnObstacle: true),
          CoinSpawnInfo(lane: 4, delayFromStart: 1.2, isOnObstacle: true),
        ],
        duration: 2.0,
      ),
      // Patrón 5 (Duración 2.5)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 1.0),
        ],
        duration: 2.5,
      ),
      // Patrón 6 (Duración 1.5)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.0),
        ],
        duration: 1.5,
      ),
    ];

    _patternsByTheme = {
      0: basePatterns,
      1: basePatterns,
      2: basePatterns,
      3: basePatterns,
      4: basePatterns,
    };
  }

  void _scheduleNextPattern() {
    final randomGap =
        minSpawnGap + _random.nextDouble() * (maxSpawnGap - minSpawnGap);

    _nextSpawnTime = _lastPatternDuration + randomGap;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isPaused) return;

    _timeSinceLastSpawn += dt;
    _timeSinceLastPowerUp += dt;

    // ⭐ Actualizar power-ups pendientes
    _pendingPowerUps.removeWhere((pending) {
      pending.timeUntilSpawn -= dt;
      if (pending.timeUntilSpawn <= 0) {
        _spawnPowerUp(pending.lane, pending.type);
        return true;
      }
      return false;
    });

    // Actualizar obstáculos pendientes
    _pendingObstacles.removeWhere((pending) {
      pending.timeUntilSpawn -= dt;
      if (pending.timeUntilSpawn <= 0) {
        _spawnObstacle(pending.lane, pending.type);
        return true;
      }
      return false;
    });

    // Actualizar monedas pendientes
    _pendingCoins.removeWhere((pending) {
      pending.timeUntilSpawn -= dt;
      if (pending.timeUntilSpawn <= 0) {
        _spawnCoin(pending.lane, pending.isOnObstacle);
        return true;
      }
      return false;
    });

    // ⭐ Spawn de power-ups aleatorios
    if (_timeSinceLastPowerUp >= _nextPowerUpTime) {
      _spawnRandomPowerUp();
      _timeSinceLastPowerUp = 0;
      _scheduleNextPowerUp();
    }

    // Spawn de patrones de obstáculos
    if (_timeSinceLastSpawn >= _nextSpawnTime) {
      _spawnPattern();
      _timeSinceLastSpawn = 0;
      _scheduleNextPattern();
    }
  }

  // ⭐ NUEVO: Spawn de power-up aleatorio
  void _spawnRandomPowerUp() {
    final randomLane = _random.nextInt(5); // Carril aleatorio (0-4)
    final randomValue = _random.nextDouble();
    
    final powerUpType = randomValue < _fuelPowerUpChance
        ? PowerUpType.fuel
        : PowerUpType.extraLife;

    print('✨ Spawning power-up: $powerUpType en carril $randomLane');
    _spawnPowerUp(randomLane, powerUpType);
  }

  void _spawnPattern() {
    final patterns = _patternsByTheme[_currentTheme]!;
    final pattern = patterns[_random.nextInt(patterns.length)];

    _lastPatternDuration = pattern.duration;

    for (final obstacleInfo in pattern.obstacles) {
      if (obstacleInfo.delayFromStart == 0) {
        _spawnObstacle(obstacleInfo.lane, obstacleInfo.type);
      } else {
        _pendingObstacles.add(
          _PendingObstacle(
            lane: obstacleInfo.lane,
            type: obstacleInfo.type,
            timeUntilSpawn: obstacleInfo.delayFromStart,
          ),
        );
      }
    }

    for (final coinInfo in pattern.coins) {
      if (coinInfo.delayFromStart == 0) {
        _spawnCoin(coinInfo.lane, coinInfo.isOnObstacle);
      } else {
        _pendingCoins.add(
          _PendingCoin(
            lane: coinInfo.lane,
            isOnObstacle: coinInfo.isOnObstacle,
            timeUntilSpawn: coinInfo.delayFromStart,
          ),
        );
      }
    }
  }

  void _spawnObstacle(int lane, ObstacleType type) {
    final obstacle = ObstacleComponent(
      isLandscape: isLandscape,
      lane: lane,
      type: type,
      gameSpeed: gameSpeed,
    );
    game.add(obstacle);
  }

  void _spawnCoin(int lane, bool isOnObstacle) {
    final coin = CoinComponent(
      isLandscape: isLandscape,
      lane: lane,
      gameSpeed: gameSpeed,
      isOnObstacle: isOnObstacle,
    );
    game.add(coin);
  }

  // ⭐ NUEVO: Spawn de power-up
  void _spawnPowerUp(int lane, PowerUpType type) {
    final powerUp = PowerUpComponent(
      isLandscape: isLandscape,
      lane: lane,
      type: type,
      gameState: gameState,
      gameSpeed: gameSpeed,
    );
    game.add(powerUp);
  }
}

class _PendingObstacle {
  final int lane;
  final ObstacleType type;
  double timeUntilSpawn;

  _PendingObstacle({
    required this.lane,
    required this.type,
    required this.timeUntilSpawn,
  });
}

class _PendingCoin {
  final int lane;
  final bool isOnObstacle;
  double timeUntilSpawn;

  _PendingCoin({
    required this.lane,
    required this.isOnObstacle,
    required this.timeUntilSpawn,
  });
}

// ⭐ NUEVO: Clase para power-ups pendientes
class _PendingPowerUp {
  final int lane;
  final PowerUpType type;
  double timeUntilSpawn;

  _PendingPowerUp({
    required this.lane,
    required this.type,
    required this.timeUntilSpawn,
  });
}