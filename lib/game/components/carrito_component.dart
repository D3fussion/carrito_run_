import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/collisions.dart';
import 'obstacle_component.dart';

class CarritoComponent extends PositionComponent
    with KeyboardHandler, HasGameReference, CollisionCallbacks {
  final bool isLandscape;
  int currentLane = 2;
  final int totalLanes = 5;
  Effect? _jumpEffect;

  late SpriteComponent _visualSprite;

  final double laneChangeDuration = 0.15;
  final double jumpDuration = 0.5;
  final double jumpScale = 1.3;
  final double platformScale = 1.15;

  bool _isMoving = false;
  bool _isJumping = false;
  bool _isOnObstacle = false;

  final double dragThreshold = 10.0;
  Vector2 _basePosition = Vector2.zero();

  CarritoComponent({required this.isLandscape});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    priority = 10;
    anchor = Anchor.center;

    _visualSprite = SpriteComponent(
      sprite: await game.loadSprite(
        isLandscape ? 'carrito_landscape.png' : 'carrito_portrait.png',
      ),
      anchor: Anchor.center,
    );

    _updateSize();

    add(RectangleHitbox());

    add(_visualSprite);

    _updatePosition();
    _basePosition = position.clone();
  }

  void _updateSize() {
    final gameSize = game.size;

    if (isLandscape) {
      final carritoHeight = gameSize.y * 0.15;
      size = Vector2(carritoHeight * 2, carritoHeight);
    } else {
      final carritoWidth = gameSize.x * 0.15;
      size = Vector2(carritoWidth, carritoWidth * 2);
    }

    if (_visualSprite != null) {
      _visualSprite.size = size;
      _visualSprite.position = size / 2;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateSize();
    _updatePosition();
    _basePosition = position.clone();
  }

  void _updatePosition() {
    final gameSize = game.size;

    if (isLandscape) {
      position.x = size.x / 2 + 50;
      position.y = _getLanePositionY(gameSize.y);
    } else {
      position.x = _getLanePositionX(gameSize.x);
      position.y = gameSize.y - (size.y / 2 + 50);
    }
  }

  double _getLanePositionX(double screenWidth) {
    final laneWidth = screenWidth / totalLanes;
    return (currentLane + 0.5) * laneWidth;
  }

  double _getLanePositionY(double screenHeight) {
    final laneHeight = screenHeight / totalLanes;
    return (currentLane + 0.5) * laneHeight;
  }

  void handleDrag(Vector2 delta) {
    if (_isMoving) return;

    if (isLandscape) {
      if (delta.y > dragThreshold) {
        _changeLane(1);
      } else if (delta.y < -dragThreshold) {
        _changeLane(-1);
      }
    } else {
      if (delta.x > dragThreshold) {
        _changeLane(1);
      } else if (delta.x < -dragThreshold) {
        _changeLane(-1);
      }
    }
  }

  void jump() {
    if (_isJumping) return;

    _isJumping = true;

    final startScale = _isOnObstacle ? platformScale : 1.0;
    final wasOnObstacle = _isOnObstacle;

    _jumpEffect =
        FunctionEffect<CarritoComponent>((target, progress) {
            final jumpCurve = 4 * progress * (1 - progress);
            final scaleValue =
                startScale + (jumpScale - startScale) * jumpCurve;

            _visualSprite.scale = Vector2.all(scaleValue);

            final height = 4 * progress * (1 - progress) * size.y * 0.5;
            print('Progreso: $progress, Altura: $height, Escala: $scaleValue');
          }, EffectController(duration: jumpDuration))
          ..onComplete = () {
            _isJumping = false;
            _jumpEffect = null;

            if (_isOnObstacle) {
              _visualSprite.scale = Vector2.all(platformScale);
            } else {
              _visualSprite.add(
                ScaleEffect.to(
                  Vector2.all(1.0),
                  EffectController(duration: 0.3, curve: Curves.easeInOut),
                ),
              );
            }
          };

    add(_jumpEffect!);

    if (wasOnObstacle) {
      _isOnObstacle = false;
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;

    if (!isKeyDown) {
      return true;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      jump();
      return false;
    }

    if (_isMoving) {
      return true;
    }

    if (isLandscape) {
      if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        _changeLane(1);
        return false;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        _changeLane(-1);
        return false;
      }
    } else {
      if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        _changeLane(1);
        return false;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        _changeLane(-1);
        return false;
      }
    }

    return true;
  }

  void _changeLane(int direction) {
    final newLane = currentLane + direction;

    if (newLane >= 0 && newLane < totalLanes) {
      currentLane = newLane;
      _animateToLane();
    }
  }

  void _animateToLane() {
    final gameSize = game.size;
    Vector2 targetPosition;

    if (isLandscape) {
      targetPosition = Vector2(position.x, _getLanePositionY(gameSize.y));
    } else {
      targetPosition = Vector2(_getLanePositionX(gameSize.x), position.y);
    }

    _isMoving = true;

    children.whereType<MoveToEffect>().forEach((effect) {
      if (effect.controller.duration == laneChangeDuration) {
        effect.removeFromParent();
      }
    });

    add(
      MoveToEffect(
        targetPosition,
        EffectController(duration: laneChangeDuration, curve: Curves.easeInOut),
        onComplete: () {
          _isMoving = false;
          _basePosition = position.clone();
        },
      ),
    );
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.jumpable && _isOnObstacle) {
        _isOnObstacle = false;

        if (!_isJumping) {
          _visualSprite.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.3, curve: Curves.easeInOut),
            ),
          );
        }

        debugPrint("Adios - dejando plataforma");
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.jumpable) {
        if (_isJumping) {
          print("hola - aterrizando en plataforma");
          _isOnObstacle = true;
          _stopJumpEffect();
          return;
        }
      }

      _handleCollision(other);
    }
  }

  void _stopJumpEffect() {
    if (_jumpEffect != null) {
      _jumpEffect!.removeFromParent();
      _jumpEffect = null;
      _isJumping = false;

      if (!_isOnObstacle) {
        _visualSprite.scale = Vector2.all(1.0);
      } else {
        _visualSprite.scale = Vector2.all(platformScale);
      }
    }
  }

  void _handleCollision(ObstacleComponent obstacle) {
    print('¡Colisión con obstáculo ${obstacle.type}!');
  }
}
