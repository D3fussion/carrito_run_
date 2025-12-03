import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:carrito_run/game/states/game_state.dart';

/// Tipos de power-ups disponibles
enum PowerUpType {
  fuel, // ⛽ Recarga de gasolina parcial
  extraLife, // ❤️ Vida extra
}

/// Componente de power-up que puede ser recolectado por el carrito
class PowerUpComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  final bool isLandscape;
  final int lane;
  final PowerUpType type;
  final double gameSpeed;
  final GameState gameState;

  PowerUpComponent({
    required this.isLandscape,
    required this.lane,
    required this.type,
    required this.gameState,
    this.gameSpeed = 200.0,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 🖼️ IMÁGENES REQUERIDAS:
    // assets/ui/powerup_fuel.png - Lata de gasolina (relación 1:1, 64x64px)
    // assets/ui/powerup_heart.png - Corazón (relación 1:1, 64x64px)
    //
    // Temporalmente usa colores de placeholder
    sprite = await _loadSpriteForType();

    priority = 6; // Mayor que obstáculos pero menor que carrito

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();

    add(RectangleHitbox());
  }

  Future<Sprite> _loadSpriteForType() async {
    // Intentar cargar sprite específico, si no existe usar placeholder
    try {
      switch (type) {
        case PowerUpType.fuel:
          // 🖼️ Cargar: assets/images/ui/powerup_fuel.png
          return await game.loadSprite('ui/powerup_fuel.png');
        case PowerUpType.extraLife:
          // 🖼️ Cargar: assets/images/ui/powerup_heart.png
          return await game.loadSprite('ui/powerup_heart.png');
      }
    } catch (e) {
      // Si no existe la imagen, usa coin.png como placeholder
      print('⚠️ Power-up sprite no encontrado, usando placeholder');
      return await game.loadSprite('ui/coin.png');
    }
  }

  void _updateSize() {
    final gameSize = game.size;

    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      // Power-ups son un poco más grandes que monedas (0.6 vs 0.5)
      final powerUpSize = laneHeight * 0.6;
      size = Vector2.all(powerUpSize);
    } else {
      final laneWidth = gameSize.x / 5;
      final powerUpSize = laneWidth * 0.6;
      size = Vector2.all(powerUpSize);
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

    // ⭐ Animación de rotación suave (opcional)
    angle += dt * 2.0; // Gira lentamente

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

  /// Aplica el efecto del power-up cuando es recolectado
  void applyEffect() {
    switch (type) {
      case PowerUpType.fuel:
        // ⛽ Recarga 25% de gasolina
        gameState.addFuel(gameState.maxFuel * 0.25);
        break;
      case PowerUpType.extraLife:
        // ❤️ Gana una vida (máximo 3)
        gameState.gainLife();
        break;
    }
  }
}
