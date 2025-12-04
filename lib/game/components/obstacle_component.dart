import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum ObstacleType {
  jumpable,
  nonJumpable,
}

class ObstacleComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  final bool isLandscape;
  final int lane;
  final ObstacleType type;
  final double gameSpeed;
  final String? customSprite; // ⭐ NUEVO

  ObstacleComponent({
    required this.isLandscape,
    required this.lane,
    required this.type,
    this.gameSpeed = 200.0,
    this.customSprite, // ⭐ NUEVO
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ⭐ NUEVO: Usar sprite custom si existe, sino fallback a default
    final spritePath = customSprite ??
        (type == ObstacleType.jumpable
            ? 'obstacle_jumpable.png'
            : 'obstacle_nonjumpable.png');

    try {
      sprite = await game.loadSprite(spritePath);
    } catch (e) {
      print('⚠️ No se pudo cargar sprite: $spritePath, usando fallback');
      // Fallback a sprites default
      sprite = await game.loadSprite(
        type == ObstacleType.jumpable
            ? 'obstacle_jumpable.png'
            : 'obstacle_nonjumpable.png',
      );
    }

    priority = 5;

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

    if (isLandscape) {
      position.x -= gameSpeed * dt;

      if (position.x < -size.x) {
        removeFromParent();
      }
    } else {
      position.y += gameSpeed * dt;

      if (position.y > game.size.y + size.y) {
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
  }
}