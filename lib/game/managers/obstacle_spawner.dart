import 'dart:math';
import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/fuel_canister_component.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';
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

class ObstacleSpawner extends Component with HasGameReference<CarritoGame> {
  final bool isLandscape;

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

  ObstacleSpawner({
    required this.isLandscape,
    double minSpawnInterval = 0.2,
    double maxSpawnInterval = 0.5,
  }) : minSpawnGap = minSpawnInterval,
       maxSpawnGap = maxSpawnInterval;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializePatterns();
    _nextSpawnTime = 1.0;
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    if (paused) {
      _pendingObstacles.clear();
      _pendingCoins.clear();
    }
  }

  void setTheme(int theme) {
    _currentTheme = theme % 5;
  }

  void _initializePatterns() {
    final basePatterns = [
      // 1. Salto Central (Bordes vacíos)
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

      // 2. Zigzag Central (Bordes vacíos)
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
          CoinSpawnInfo(lane: 2, delayFromStart: 1.2),
        ],
        duration: 2.0,
      ),

      // 3. La Torre Central (Bordes vacíos)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 1.5,
      ),

      // 4. Escalera Central (Bordes vacíos)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.3,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.6,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.3, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.6, isOnObstacle: true),
        ],
        duration: 2.0,
      ),

      // 5. Trampa Central Modificada (Bordes vacíos)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 1.0),
        ],
        duration: 2.5,
      ),

      // 6. La V (Bordes vacíos)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.3),
        ],
        duration: 1.5,
      ),

      // 7. El Embudo Suave
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
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.3),
        ],
        duration: 2.0,
      ),

      // 8. Muro Saltable Central
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 1.5,
      ),

      // 9. Bloqueo Central Saltable
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
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
        duration: 2.0,
      ),

      // 10. Lluvia Central
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.4,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 1.2,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 1.6,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.4, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.8, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 1.2, isOnObstacle: true),
          CoinSpawnInfo(lane: 1, delayFromStart: 1.6, isOnObstacle: true),
        ],
        duration: 2.5,
      ),
    ];

    final cityPatterns = [
      // 1. La Valla Doble con Salida (MODIFICADO)
      // Vallas en 1 y 3. Centro (2) tiene un obstáculo SALTABLE.
      // Puedes esquivar a los extremos (0 y 4) o saltar por el centro.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(
            lane: 2,
            delayFromStart: 0.0,
            isOnObstacle: true,
          ), // Premio por saltar
          CoinSpawnInfo(lane: 0, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 4, delayFromStart: 0.0),
        ],
        duration: 1.5,
      ),

      // 2. Campo Minado de Charcos (IGUAL)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.puddle,
            delayFromStart: 0.5,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.puddle,
            delayFromStart: 1.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.0),
        ],
        duration: 2.0,
      ),

      // 3. Salto Mojado (MODIFICADO)
      // Charco en carril 2, seguido INMEDIATAMENTE de un saltable.
      // Si pisas el charco, chocas con el saltable. Debes saltar TODO junto.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.4,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.4, isOnObstacle: true),
        ],
        duration: 2.0,
      ),

      // 4. Obras en la Vía (IGUAL)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.barrier,
            delayFromStart: 0.8,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.barrier,
            delayFromStart: 0.8,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.8),
        ],
        duration: 2.0,
      ),

      // 5. Parkour Urbano (NUEVO)
      // Serie de obstáculos saltables en zigzag.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.4,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.4, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.8, isOnObstacle: true),
        ],
        duration: 1.5,
      ),

      // 6. Barrera Escalonada con Trampa (MODIFICADO)
      // Vallas en escalera, pero el camino "libre" (carril 3) tiene un saltable sorpresa.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.barrier,
            delayFromStart: 0.4,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.barrier,
            delayFromStart: 0.8,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ), // ¡Sorpresa!
        ],
        coins: [
          CoinSpawnInfo(lane: 4, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.8, isOnObstacle: true),
        ],
        duration: 2.0,
      ),

      // 7. Trampa de Velocidad (IGUAL)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.barrier,
            delayFromStart: 0.6,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.barrier,
            delayFromStart: 0.6,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 0, delayFromStart: 0.6),
          CoinSpawnInfo(lane: 4, delayFromStart: 0.6),
        ],
        duration: 2.0,
      ),

      // 8. Piso Resbaladizo Mixto (MODIFICADO)
      // Agua en los lados, saltables en el centro.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 1.5,
      ),

      // 9. Construcción Masiva (IGUAL)
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.barrier,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.puddle,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.5),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.5),
        ],
        duration: 2.0,
      ),

      // 10. El Muro Saltable de Ciudad (NUEVO)
      // 3 carriles bloqueados por saltables (1, 2, 3).
      // Vallas en 0 y 4 un poco después.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.barrier,
            delayFromStart: 0.8,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.barrier,
            delayFromStart: 0.8,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 2.0,
      ),
    ];

    final forestPatterns = [
      // 1. El Sendero Oculto
      // Bloquea todo menos el carril 2. Si la niebla tapa el centro, te asustas.
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

      // 2. Troncos en la Oscuridad (Salto Doble)
      // Dos filas de troncos saltables. Si la niebla pasa, no ves la segunda fila.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
          // Segunda fila
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.jumpable,
            delayFromStart: 0.8,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.4),
        ], // Moneda en el hueco
        duration: 2.0,
      ),

      // 3. El Zigzag Fantasma
      // Obstáculos espaciados. La niebla se mueve lento, así que probablemente
      // tape uno de los tres mientras te mueves.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.5,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.nonJumpable,
            delayFromStart: 1.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 1, delayFromStart: 0.2),
          CoinSpawnInfo(lane: 3, delayFromStart: 0.7),
        ],
        duration: 2.0,
      ),

      // 4. Muro de Árboles con Salida Lateral
      // Centro bloqueado masivamente. Debes ir a los bordes.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 0, delayFromStart: 0.0),
          CoinSpawnInfo(lane: 4, delayFromStart: 0.0),
        ],
        duration: 1.5,
      ),

      // 5. Salto de Fe en el Bosque
      // Un solo tronco en el centro rodeado de árboles.
      // Requiere precisión.
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
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 0.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 1.5,
      ),

      // 6. La Jaula
      // Obstáculos en U. Te obliga a quedarte en el centro y esperar.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 1,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.5,
          ),
          ObstacleSpawnInfo(
            lane: 3,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.5,
          ),
        ],
        coins: [CoinSpawnInfo(lane: 2, delayFromStart: 0.5)],
        duration: 2.0,
      ),

      // 7. Escalera de Troncos
      // Si la niebla tapa la pantalla, no sabrás si el siguiente es tronco (saltar) o árbol (esquivar).
      // Aquí todos son troncos para ser justos, pero asusta.
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
          CoinSpawnInfo(lane: 2, delayFromStart: 0.6, isOnObstacle: true),
        ],
        duration: 2.0,
      ),

      // 8. Bloqueo 4-1
      // Solo un carril libre aleatorio (el 1 en este caso).
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
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
        coins: [CoinSpawnInfo(lane: 1, delayFromStart: 0.0)],
        duration: 1.5,
      ),

      // 9. Trampa de Niebla (Salto Retrasado)
      // Tronco en carril 2, pero aparece TARDÍO (delay 1.0).
      // Probablemente la niebla ya pasó y te lo revela de golpe.
      ObstaclePattern(
        obstacles: [
          ObstacleSpawnInfo(
            lane: 0,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 4,
            type: ObstacleType.nonJumpable,
            delayFromStart: 0.0,
          ),
          ObstacleSpawnInfo(
            lane: 2,
            type: ObstacleType.jumpable,
            delayFromStart: 1.0,
          ),
        ],
        coins: [
          CoinSpawnInfo(lane: 2, delayFromStart: 1.0, isOnObstacle: true),
        ],
        duration: 2.0,
      ),

      // 10. El Bosque Cerrado
      // Patrón denso. Árboles en 1 y 3, Troncos en 0, 2, 4.
      // Requiere identificar rápidamente qué es saltable y qué no.
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
            delayFromStart: 0.0,
          ),
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
          CoinSpawnInfo(lane: 2, delayFromStart: 0.0, isOnObstacle: true),
        ],
        duration: 2.0,
      ),
    ];

    _patternsByTheme = {
      0: basePatterns,
      1: cityPatterns,
      2: forestPatterns,
      3: basePatterns,
      4: basePatterns,
    };
  }

  void _scheduleNextPattern() {
    final baseGap =
        minSpawnGap + _random.nextDouble() * (maxSpawnGap - minSpawnGap);

    final multiplier = game.gameState.speedMultiplier;

    final adjustedGap = baseGap / multiplier;

    final adjustedDuration = _lastPatternDuration / multiplier;

    _nextSpawnTime = adjustedDuration + adjustedGap;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isPaused) return;

    final multiplier = game.gameState.speedMultiplier;

    _timeSinceLastSpawn += dt;

    double adjustedDt = dt * multiplier;

    _pendingObstacles.removeWhere((pending) {
      pending.timeUntilSpawn -= adjustedDt;
      if (pending.timeUntilSpawn <= 0) {
        _spawnObstacle(pending.lane, pending.type);
        return true;
      }
      return false;
    });

    _pendingCoins.removeWhere((pending) {
      pending.timeUntilSpawn -= adjustedDt;
      if (pending.timeUntilSpawn <= 0) {
        _spawnCoin(pending.lane, pending.isOnObstacle);
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
      theme: _currentTheme,
    );
    game.add(obstacle);
  }

  void _spawnCoin(int lane, bool isOnObstacle) {
    const double fuelChance = 0.03;

    if (_random.nextDouble() < fuelChance) {
      final canister = FuelCanisterComponent(
        isLandscape: isLandscape,
        lane: lane,
        isOnObstacle: isOnObstacle,
      );
      game.add(canister);
    } else {
      final coin = CoinComponent(
        isLandscape: isLandscape,
        lane: lane,
        isOnObstacle: isOnObstacle,
      );
      game.add(coin);
    }
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
