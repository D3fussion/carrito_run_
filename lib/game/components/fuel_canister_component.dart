import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';

class FuelCanisterComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<CarritoGame> {
  final bool isLandscape;
  final int lane;
  final bool isOnObstacle;

  FuelCanisterComponent({
    required this.isLandscape,
    required this.lane,
    this.isOnObstacle = false,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite('fuel_canister.png');

    priority = isOnObstacle ? 8 : 5;

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();

    add(RectangleHitbox());
  }

  void _updateSize() {
    final gameSize = game.size;
    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      final itemSize = laneHeight * 0.6;
      size = Vector2.all(itemSize);
    } else {
      final laneWidth = gameSize.x / 5;
      final itemSize = laneWidth * 0.6;
      size = Vector2.all(itemSize);
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
