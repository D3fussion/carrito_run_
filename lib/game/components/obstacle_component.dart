import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';

enum ObstacleType {
  jumpable, // Plataformas elevadas (Cajas, etc)
  nonJumpable, // Muros altos (No pasables)
  puddle, // Charco (Piso, efecto slow) <--- NUEVO
  barrier, // Valla (Saltable o No, definiremos como No Saltable o Alto) <--- NUEVO
}

class ObstacleComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<CarritoGame> {
  final bool isLandscape;
  final int lane;
  final ObstacleType type;
  final int theme;

  ObstacleComponent({
    required this.isLandscape,
    required this.lane,
    required this.type,
    required this.theme,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    String spriteName;

    switch (type) {
      case ObstacleType.jumpable:
        spriteName = 'obstacle_jumpable_$theme.png';
        break;

      case ObstacleType.nonJumpable:
        spriteName = 'obstacle_nonjumpable_$theme.png';
        break;

      case ObstacleType.puddle:
        spriteName = 'puddle.png';
        break;

      case ObstacleType.barrier:
        spriteName = 'barrier.png';
        break;
    }

    try {
      sprite = await game.loadSprite(spriteName);
    } catch (e) {
      // Fallback al tema 0 si falta la imagen del tema actual
      if (type == ObstacleType.jumpable)
        sprite = await game.loadSprite('obstacle_jumpable_0.png');
      if (type == ObstacleType.nonJumpable)
        sprite = await game.loadSprite('obstacle_nonjumpable_0.png');
    }

    priority = (type == ObstacleType.puddle) ? 2 : 5;

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();

    add(RectangleHitbox());
  }

  void _updateSize() {
    final gameSize = game.size;
    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      final obstacleSize = laneHeight * 0.8;
      size = Vector2.all(obstacleSize);
    } else {
      final laneWidth = gameSize.x / 5;
      final obstacleSize = laneWidth * 0.8;
      size = Vector2.all(obstacleSize);
    }
  }

  void _updatePosition() {
    final gameSize = game.size;
    if (isLandscape) {
      position.x = gameSize.x + size.x;
      position.y = _getLanePositionY(gameSize.y);
    } else {
      position.x = _getLanePositionX(gameSize.x);
      position.y = -size.y;
    }
  }

  double _getLanePositionX(double screenWidth) {
    final laneWidth = screenWidth / 5;
    return (lane + 0.5) * laneWidth;
  }

  double _getLanePositionY(double screenHeight) {
    final laneHeight = screenHeight / 5;
    return (lane + 0.5) * laneHeight;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final currentSpeed = game.gameState.currentSpeed;

    if (isLandscape) {
      position.x -= currentSpeed * dt;
      if (position.x < -size.x) removeFromParent();
    } else {
      position.y += currentSpeed * dt;
      if (position.y > game.size.y + size.y) removeFromParent();
    }
  }
}
