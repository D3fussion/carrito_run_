import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/collisions.dart';
import 'obstacle_component.dart';
import 'package:carrito_run/game/game.dart';

class CarritoComponent extends PositionComponent
    with KeyboardHandler, HasGameReference<CarritoGame>, CollisionCallbacks {
  final bool isLandscape;
  final GameState gameState;

  int currentLane = 2;
  final int totalLanes = 5;
  Effect? _jumpEffect;

  SpriteComponent? _visualSprite;

  double get laneChangeDuration => 0.15 / game.gameState.speedMultiplier;

  final double jumpDuration = 0.5;
  final double jumpScale = 1.3;
  final double platformScale = 1.15;

  bool _isMoving = false;
  bool _isJumping = false;
  bool _isOnObstacle = false;

  double _jumpGraceTimer = 0.0;
  double _hitGraceTimer = 0.0;

  final double dragThreshold = 10.0;
  Vector2 _basePosition = Vector2.zero();

  final Set<ObstacleComponent> _platformsInContact = {};

  CarritoComponent({required this.isLandscape, required this.gameState});

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

    add(_visualSprite!);

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
      _visualSprite!.size = size;
      _visualSprite!.position = size / 2;
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
      if (delta.y > dragThreshold)
        _changeLane(1);
      else if (delta.y < -dragThreshold)
        _changeLane(-1);
    } else {
      if (delta.x > dragThreshold)
        _changeLane(1);
      else if (delta.x < -dragThreshold)
        _changeLane(-1);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_jumpGraceTimer > 0) _jumpGraceTimer -= dt;
    if (_hitGraceTimer > 0) _hitGraceTimer -= dt;
  }

  void jump() {
    if (_isJumping) return;

    _isJumping = true;
    _jumpGraceTimer = 0.2;

    final startScale = _isOnObstacle ? platformScale : 1.0;
    const endScale = 1.0;

    if (_isOnObstacle) {
      _isOnObstacle = false;
    }

    _jumpEffect =
        FunctionEffect<CarritoComponent>((target, progress) {
            final currentBaseScale =
                startScale + (endScale - startScale) * progress;
            final jumpCurve = 4 * progress * (1 - progress);
            final jumpImpulse = (jumpScale - 1.0) * jumpCurve;

            _visualSprite?.scale = Vector2.all(currentBaseScale + jumpImpulse);
          }, EffectController(duration: jumpDuration))
          ..onComplete = () {
            _isJumping = false;
            _jumpEffect = null;

            if (_isOnObstacle) {
              _visualSprite?.scale = Vector2.all(platformScale);
            } else {
              _visualSprite?.scale = Vector2.all(1.0);
            }
          };

    add(_jumpEffect!);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;
    if (!isKeyDown) return true;
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      jump();
      return false;
    }
    if (_isMoving) return true;
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
      if (effect.controller.duration == laneChangeDuration)
        effect.removeFromParent();
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
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is CoinComponent) {
      gameState.addCoin();
      other.removeFromParent();
      return;
    }

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.jumpable) {
        if (_jumpGraceTimer > 0) return;

        if (_isJumping) {
          _platformsInContact.add(other);
          _isOnObstacle = true;
          _stopJumpEffect();
          return;
        } else if (_isOnObstacle) {
          _platformsInContact.add(other);
          return;
        }
      }

      _handleCollision(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is ObstacleComponent && other.type == ObstacleType.jumpable) {
      _platformsInContact.remove(other);

      if (_platformsInContact.isEmpty && _isOnObstacle) {
        _isOnObstacle = false;

        if (!_isJumping) {
          _visualSprite?.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.3, curve: Curves.easeInOut),
            ),
          );
        }
      }
    }
  }

  void _stopJumpEffect() {
    if (_jumpEffect != null) {
      _jumpEffect!.removeFromParent();
      _jumpEffect = null;
      _isJumping = false;

      children.whereType<ScaleEffect>().forEach((e) => e.removeFromParent());

      _visualSprite?.add(
        ScaleEffect.to(
          Vector2.all(platformScale),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
      );
    }
  }

  void _handleCollision(ObstacleComponent obstacle) {
    if (_hitGraceTimer > 0) return;

    debugPrint('¡GOLPE! Perdiendo combustible...');

    gameState.takeHit();

    _hitGraceTimer = 1.0;

    _visualSprite?.add(
      ColorEffect(
        Colors.red,
        EffectController(duration: 0.2, alternate: true, repeatCount: 3),
        opacityTo: 0.7,
      ),
    );
  }
}
