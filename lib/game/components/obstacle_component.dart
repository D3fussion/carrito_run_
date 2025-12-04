import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:carrito_run/game/game.dart';
import 'package:flame_audio/flame_audio.dart';

enum ObstacleType {
  jumpable, // Plataformas elevadas (Cajas, etc)
  nonJumpable, // Muros altos (No pasables)
  puddle, // Charco (Piso, efecto slow) <--- NUEVO
  barrier, // Valla (Saltable o No, definiremos como No Saltable o Alto)
  snowball, // Bola de nieve
  geyser, // Geiser de fuego (Dos estados, prendido y apagado)
}

class ObstacleComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference<CarritoGame> {
  final bool isLandscape;
  final int lane;
  final ObstacleType type;
  final int theme;

  bool isGeyserActive = false;
  double _geyserTimer = 0.0;
  final double _geyserCycleDuration = 2.0;

  Sprite? _geyserActiveSprite;
  Sprite? _geyserInactiveSprite;

  ObstacleComponent({
    required this.isLandscape,
    required this.lane,
    required this.type,
    required this.theme,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    String spriteName;

    if (type == ObstacleType.geyser) {
      _geyserActiveSprite = await game.loadSprite('geyser_active.png');
      _geyserInactiveSprite = await game.loadSprite('geyser_inactive.png');

      _geyserTimer =
          (DateTime.now().millisecondsSinceEpoch % 2000) /
          1000.0 *
          _geyserCycleDuration;

      if (_geyserTimer > _geyserCycleDuration / 2) {
        sprite = _geyserActiveSprite;
        isGeyserActive = true;
      } else {
        sprite = _geyserInactiveSprite;
        isGeyserActive = false;
      }
      spriteName = 'geyser_active.png';
    } else {
      switch (type) {
        case ObstacleType.jumpable:
          spriteName = 'obstacle_jumpable_$theme.png';
          break;

        case ObstacleType.nonJumpable:
          spriteName = 'obstacle_nonjumpable_$theme.png';
          break;

        case ObstacleType.puddle:
          spriteName = 'puddle.png';
          break;

        case ObstacleType.barrier:
          spriteName = 'barrier.png';
          break;

        case ObstacleType.snowball:
          spriteName = 'snowball.png';
          break;

        case ObstacleType.geyser:
          spriteName = 'obstacle_nonjumpable_$theme.png';
          break;
      }
    }

    try {
      sprite = await game.loadSprite(spriteName);
    } catch (e) {
      // Fallback al tema 0 si falta la imagen del tema actual
      if (type == ObstacleType.jumpable)
        sprite = await game.loadSprite('obstacle_jumpable_0.png');
      if (type == ObstacleType.nonJumpable)
        sprite = await game.loadSprite('obstacle_nonjumpable_0.png');
    }

    priority = (type == ObstacleType.puddle) ? 2 : 5;

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

    double moveSpeed = game.gameState.currentSpeed;

    if (type == ObstacleType.snowball) {
      moveSpeed *= 1.8;
    }

    if (isLandscape) {
      position.x -= moveSpeed * dt;
      if (position.x < -size.x) removeFromParent();
    } else {
      position.y += moveSpeed * dt;
      if (position.y > game.size.y + size.y) removeFromParent();
    }

    if (type == ObstacleType.geyser) {
      _geyserTimer += dt;

      if (_geyserTimer >= _geyserCycleDuration * 2) {
        _geyserTimer = 0;
      }

      if (_geyserTimer < _geyserCycleDuration) {
        if (!isGeyserActive) {
          isGeyserActive = true;
          sprite = _geyserActiveSprite;

          if (position.y > 0 && position.y < game.size.y) {
            FlameAudio.play('geyser.wav', volume: 0.5);
          }
        }
      } else {
        if (isGeyserActive) {
          isGeyserActive = false;
          sprite = _geyserInactiveSprite;
        }
      }
    }
  }
}
