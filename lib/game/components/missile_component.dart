import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';

class MissileComponent extends SpriteComponent
    with HasGameReference<CarritoGame>, CollisionCallbacks {
  final bool isLandscape;
  final double speed = 800.0;

  MissileComponent({
    required this.isLandscape,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite('missile.png');
    if (!isLandscape) {
      angle = -1.5708;
    }

    add(RectangleHitbox());
    priority = 20;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isLandscape) {
      position.x += speed * dt;
      if (position.x > game.size.x + 100) removeFromParent();
    } else {
      position.y -= speed * dt;
      if (position.y < -100) removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is ObstacleComponent) {
      other.removeFromParent();
      removeFromParent();
    }
  }
}
