import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/carrito_component.dart';

class CoinComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<CarritoGame> {
  final bool isLandscape;
  final int lane;
  final bool isOnObstacle;

  CoinComponent({
    required this.isLandscape,
    required this.lane,
    this.isOnObstacle = false,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite('coin.png');
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
      final coinSize = laneHeight * 0.5;
      size = Vector2.all(coinSize);
    } else {
      final laneWidth = gameSize.x / 5;
      final coinSize = laneWidth * 0.5;
      size = Vector2.all(coinSize);
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
    if (game.gameState.isGameOver) return;

    if (game.gameState.isMagnetActive) {
      final player = game.children.whereType<CarritoComponent>().firstOrNull;
      if (player != null) {
        final direction = (player.position - position).normalized();
        const magnetSpeed = 800.0;

        position += direction * magnetSpeed * dt;

        if (position.distanceTo(player.position) < 50) {
          game.gameState.addCoin();
          game.sfxManager.playCoin();
          removeFromParent();
          return;
        }
      }
    }

    super.update(dt);

    final currentSpeed = game.gameState.currentSpeed;

    if (isLandscape) {
      if (!game.gameState.isMagnetActive) position.x -= currentSpeed * dt;

      if (position.x < -size.x) {
        removeFromParent();
      }
    } else {
      if (!game.gameState.isMagnetActive) position.y += currentSpeed * dt;

      if (position.y > game.size.y + size.y) {
        removeFromParent();
      }
    }
  }
}
