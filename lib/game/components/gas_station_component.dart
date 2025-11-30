import 'package:flame/components.dart';
import 'package:carrito_run/game/states/game_state.dart';

class GasStationComponent extends SpriteComponent with HasGameReference {
  final bool isLandscape;
  final double gameSpeed;
  final GameState gameState;
  final Function() onReached;

  bool _hasTriggered = false;
  bool _hasSwitchedTheme = false;

  GasStationComponent({
    required this.isLandscape,
    required this.gameSpeed,
    required this.gameState,
    required this.onReached,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite(
      isLandscape ? 'gas_station_landscape.png' : 'gas_station_portrait.png',
    );

    priority = 1;
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

    if (isLandscape) {
      position.x = gameSize.x + size.x / 2;
      position.y = gameSize.y / 2;
    } else {
      position.x = gameSize.x / 2;
      position.y = -size.y / 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final gameSize = game.size;

    if (isLandscape) {
      position.x -= gameSpeed * dt;

      if (!_hasTriggered && position.x <= 100) {
        _hasTriggered = true;
        onReached();
      }

      if (!_hasSwitchedTheme && position.x <= gameSize.x / 2) {
        _hasSwitchedTheme = true;
      }

      if (position.x < -size.x) {
        removeFromParent();
      }
    } else {
      position.y += gameSpeed * dt;

      if (!_hasTriggered && position.y >= game.size.y - 150) {
        _hasTriggered = true;
        onReached();
      }

      if (!_hasSwitchedTheme && position.y >= gameSize.y / 2) {
        _hasSwitchedTheme = true;
      }

      if (position.y > game.size.y + size.y) {
        removeFromParent();
      }
    }
  }
}
