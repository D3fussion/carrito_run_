import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';

class FogComponent extends SpriteComponent with HasGameReference<CarritoGame> {
  final bool isLandscape;

  FogComponent({required this.isLandscape});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite('fog.png');

    priority = 20;

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();
  }

  void _updateSize() {
    final gameSize = game.size;
    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      size = Vector2(laneHeight * 1.5, gameSize.y);
    } else {
      final laneWidth = gameSize.x / 5;
      size = Vector2(gameSize.x, laneWidth * 1.5);
    }
  }

  void _updatePosition() {
    final gameSize = game.size;
    if (isLandscape) {
      position.x = gameSize.x + size.x;
      position.y = gameSize.y / 2;
    } else {
      position.x = gameSize.x / 2;
      position.y = -size.y;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final fogSpeed = game.gameState.currentSpeed * 0.5;

    if (isLandscape) {
      position.x -= fogSpeed * dt;
      if (position.x < -size.x) removeFromParent();
    } else {
      position.y += fogSpeed * dt;
      if (position.y > game.size.y + size.y) removeFromParent();
    }
  }
}
