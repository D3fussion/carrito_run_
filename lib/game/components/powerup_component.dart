import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:carrito_run/game/states/game_state.dart';

class PowerupComponent extends SpriteComponent
    with HasGameRef<CarritoGame>, CollisionCallbacks {
  final PowerupType type;
  final bool isLandscape;

  final int lane;

  PowerupComponent({
    required this.type,
    required this.isLandscape,
    required this.lane,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(32, 32);
    _updatePosition();

    String spritePath = '';
    switch (type) {
      case PowerupType.magnet:
        spritePath = 'ui/icon_magnet.png';
        break;
      case PowerupType.shield:
        spritePath = 'ui/icon_shield.png';
        break;
      case PowerupType.multiplier:
        spritePath = 'ui/icon_2x.png';
        break;
    }

    sprite = await gameRef.loadSprite(spritePath);
    add(RectangleHitbox());
  }

  void _updatePosition() {
    final gameSize = gameRef.size;

    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      size = Vector2.all(laneHeight * 0.6);
      position.x = gameSize.x + size.x;
      position.y = (lane + 0.5) * laneHeight;
      anchor = Anchor.center;
    } else {
      final laneWidth = gameSize.x / 5;
      size = Vector2.all(laneWidth * 0.6);
      position.x = (lane + 0.5) * laneWidth;
      position.y = -size.y;
      anchor = Anchor.center;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.gameState.isGameOver) return;

    final speed = gameRef.gameState.currentSpeed;

    if (isLandscape) {
      position.x -= speed * dt / 4.0;

      if (position.x < -50) {
        removeFromParent();
      }
    } else {
      position.y += speed * dt / 4.0;

      if (position.y > gameRef.size.y + 50) {
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

    if (other is CarritoComponent) {
      gameRef.gameState.activatePowerup(type);

      gameRef.sfxManager.playPowerup();

      removeFromParent();
    }
  }
}
