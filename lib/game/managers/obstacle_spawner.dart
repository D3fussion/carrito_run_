import 'dart:math';
import 'package:carrito_run/game/components/obstacle_component.dart';
import 'package:flame/components.dart';

class ObstaclePattern {
  final List<ObstacleSpawnInfo> obstacles;
  final double duration; 
  
  ObstaclePattern({
    required this.obstacles,
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

class ObstacleSpawner extends Component with HasGameReference {
  final bool isLandscape;
  final double gameSpeed;
  final double minSpawnInterval;
  final double maxSpawnInterval;
  
  double _timeSinceLastSpawn = 0;
  double _nextSpawnTime = 0;
  final Random _random = Random();
  
  late List<ObstaclePattern> _patterns;
  
  final List<_PendingObstacle> _pendingObstacles = [];
  
  ObstacleSpawner({
    required this.isLandscape,
    this.gameSpeed = 200.0,
    this.minSpawnInterval = 1.5,
    this.maxSpawnInterval = 3.0,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializePatterns();
    _scheduleNextPattern();
  }

  void _initializePatterns() {
    _patterns = [
      // Patrón 1: Línea simple de 2 saltables
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.jumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.jumpable, delayFromStart: 0.8),
        ],
        duration: 1.5,
      ),
      
      // Patrón 2: Zigzag de no saltables
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 1, type: ObstacleType.nonJumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 3, type: ObstacleType.nonJumpable, delayFromStart: 0.6),
          ObstacleSpawnInfo(lane: 1, type: ObstacleType.nonJumpable, delayFromStart: 1.2),
        ],
        duration: 2.0,
      ),
      
      // Patrón 3: Muro con hueco (forzar cambio de carril)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 0, type: ObstacleType.nonJumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 1, type: ObstacleType.nonJumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 3, type: ObstacleType.nonJumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 4, type: ObstacleType.nonJumpable, delayFromStart: 0.0),
        ],
        duration: 1.5,
      ),
      
      // Patrón 4: Escalera de saltables
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 0, type: ObstacleType.jumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 1, type: ObstacleType.jumpable, delayFromStart: 0.3),
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.jumpable, delayFromStart: 0.6),
          ObstacleSpawnInfo(lane: 3, type: ObstacleType.jumpable, delayFromStart: 0.9),
          ObstacleSpawnInfo(lane: 4, type: ObstacleType.jumpable, delayFromStart: 1.2),
        ],
        duration: 2.0,
      ),
      
      // Patrón 5: Mixto - saltable seguido de muro
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.jumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 0, type: ObstacleType.nonJumpable, delayFromStart: 1.0),
          ObstacleSpawnInfo(lane: 1, type: ObstacleType.nonJumpable, delayFromStart: 1.0),
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.nonJumpable, delayFromStart: 1.0),
        ],
        duration: 2.5,
      ),
      
      // Patrón 6: Carriles alternos
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(lane: 0, type: ObstacleType.jumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 2, type: ObstacleType.jumpable, delayFromStart: 0.0),
          ObstacleSpawnInfo(lane: 4, type: ObstacleType.jumpable, delayFromStart: 0.0),
        ],
        duration: 1.5,
      ),
    ];
  }

  void _scheduleNextPattern() {
    _nextSpawnTime = minSpawnInterval + 
        _random.nextDouble() * (maxSpawnInterval - minSpawnInterval);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _timeSinceLastSpawn += dt;
    
    _pendingObstacles.removeWhere((pending) {
      pending.timeUntilSpawn -= dt;
      
      if (pending.timeUntilSpawn <= 0) {
        _spawnObstacle(pending.lane, pending.type);
        return true;
      }
      return false;
    });
    
    if (_timeSinceLastSpawn >= _nextSpawnTime) {
      _spawnPattern();
      _timeSinceLastSpawn = 0;
      _scheduleNextPattern();
    }
  }

  void _spawnPattern() {
    final pattern = _patterns[_random.nextInt(_patterns.length)];
    
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
