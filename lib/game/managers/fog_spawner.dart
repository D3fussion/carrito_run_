import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/fog_component.dart';

class FogSpawner extends Component with HasGameReference<CarritoGame> {
  final bool isLandscape;

  FogSpawner({required this.isLandscape});

  @override
  void update(double dt) {
    super.update(dt);

    bool isForestTheme = (game.gameState.currentSection - 1) % 5 == 2;

    if (!isForestTheme) {
      game.children.whereType<FogComponent>().forEach(
        (fog) => fog.removeFromParent(),
      );
      return;
    }

    bool hasActiveFog = game.children.whereType<FogComponent>().isNotEmpty;

    if (hasActiveFog) {
      return;
    }

    _spawnFog();
  }

  void _spawnFog() {
    game.add(FogComponent(isLandscape: isLandscape));
  }
}
