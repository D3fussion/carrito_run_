import 'package:flame/components.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/game.dart';

class GasStationComponent extends SpriteComponent
    with HasGameReference<CarritoGame> {
  final bool isLandscape;
  final GameState gameState;
  final Function() onReached;

  final Function() onPassCenter;

  bool _hasTriggered = false;
  bool _hasPassedCenter = false;

  GasStationComponent({
    required this.isLandscape,
    required this.gameState,
    required this.onReached,
    required this.onPassCenter,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite(
      isLandscape ? 'gas_station_landscape.png' : 'gas_station_portrait.png',
    );
    priority = 20;
    _updateSize();
    anchor = Anchor.center;
    _updatePosition();
  }

  void _updateSize() {
    final gameSize = game.size;
    if (isLandscape) {
      final height = gameSize.y;
      final width = height * 0.4;
      size = Vector2(width, height);
    } else {
      final width = gameSize.x;
      final height = width * 0.4;
      size = Vector2(width, height);
    }
  }

  void _updatePosition() {
    final gameSize = game.size;
    const double safetyBuffer = 400.0;

    if (isLandscape) {
      position.x = gameSize.x + (size.x / 2) + safetyBuffer;
      position.y = gameSize.y / 2;
    } else {
      position.x = gameSize.x / 2;
      position.y = -(size.y / 2) - safetyBuffer;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final currentSpeed = game.gameState.currentSpeed;
    final gameSize = game.size;

    if (isLandscape) {
      position.x -= currentSpeed * dt;

      if (!_hasTriggered && position.x <= 100) {
        _hasTriggered = true;
        game.sfxManager.play('car_stop.wav');
        onReached();
      }

      if (!_hasPassedCenter && position.x <= gameSize.x / 2) {
        _hasPassedCenter = true;
        onPassCenter();
      }

      if (position.x < -size.x) removeFromParent();
    } else {
      position.y += currentSpeed * dt;

      if (!_hasTriggered && position.y >= game.size.y - 150) {
        _hasTriggered = true;
        onReached();
      }

      if (!_hasPassedCenter && position.y >= gameSize.y / 2) {
        _hasPassedCenter = true;
        onPassCenter();
      }

      if (position.y > game.size.y + size.y) removeFromParent();
    }
  }
}
