import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/components/obstacle_component.dart';
import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/fuel_canister_component.dart';

class CarritoComponent extends PositionComponent
    with KeyboardHandler, HasGameReference<CarritoGame>, CollisionCallbacks {
  final bool isLandscape;
  final GameState gameState;

  // -- Configuración de Carriles --
  int currentLane = 2;
  final int totalLanes = 5;

  // -- Variables Visuales --
  SpriteComponent? _visualSprite;
  Sprite? _cachedExplosionSprite;
  Effect? _jumpEffect;

  // Control de efectos de color (Para evitar conflictos)
  ColorEffect? _fuelPenaltyEffect; // Rojo (Desierto)
  ColorEffect? _slowEffectVisual; // Azul (Charco)

  // -- Variables de Lógica --
  bool _isMoving = false;
  bool _isJumping = false;
  bool _isOnObstacle = false;
  bool _hasExploded = false;

  // -- Timers --
  double _jumpGraceTimer = 0.0; // Inmunidad al despegar
  double _hitGraceTimer = 0.0; // Inmunidad tras recibir golpe
  double _slowDebuffTimer = 0.0; // Tiempo del efecto lento

  // -- Referencias --
  ObstacleComponent? _platformToIgnore; // Plataforma de la que saltamos
  final Set<ObstacleComponent> _platformsInContact = {};

  // -- Constantes de Animación --
  final double jumpDuration = 0.5;
  final double jumpScale = 1.3;
  final double platformScale = 1.15;
  final double dragThreshold = 10.0;
  Vector2 _basePosition = Vector2.zero();

  double _iceCampingTimer = 0.0;
  double _currentIceTintIntensity = 0.0;
  final double _maxIceTime = 2.0;

  double _lavaDamageTimer = 0.0;

  double get laneChangeDuration {
    double baseDuration = 0.15 / game.gameState.speedMultiplier;

    if (_slowDebuffTimer > 0) {
      return baseDuration * 2.0;
    }
    return baseDuration;
  }

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

    try {
      _cachedExplosionSprite = await game.loadSprite('explosion.png');
    } catch (e) {
      debugPrint("Error cargando explosion.png: $e");
    }

    _updateSize();
    add(RectangleHitbox());

    if (_visualSprite != null) {
      add(_visualSprite!);
    }

    _updatePosition();
    _basePosition = position.clone();

    _checkLanePenalty();
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

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState.isGameOver && !_hasExploded) {
      _triggerExplosionVisuals();
    }

    if (_jumpGraceTimer > 0) {
      _jumpGraceTimer -= dt;
      if (_jumpGraceTimer <= 0) _platformToIgnore = null;
    }
    if (_hitGraceTimer > 0) _hitGraceTimer -= dt;

    if (_slowDebuffTimer > 0) {
      _slowDebuffTimer -= dt;
      if (_slowDebuffTimer <= 0) {
        _slowDebuffTimer = 0;
        _removeSlowVisuals();
      }
    }

    bool isPenaltyActive = gameState.isOffRoad;
    bool isVolcano = (gameState.currentSection - 1) % 5 == 4;

    if (isVolcano && isPenaltyActive && !_hasExploded) {
      _lavaDamageTimer += dt;
      if (_lavaDamageTimer >= 0.1) {
        _lavaDamageTimer = 0.0;
      }
    } else {
      _lavaDamageTimer = 0.0;
    }

    _updateIceVisuals(dt);
  }

  void _triggerExplosionVisuals() {
    if (_cachedExplosionSprite == null) return;

    _hasExploded = true;
    _isMoving = false;
    _isJumping = false;
    _isOnObstacle = false;

    children.whereType<Effect>().forEach((e) => e.removeFromParent());

    if (_visualSprite != null) {
      _visualSprite!.sprite = _cachedExplosionSprite;

      final gameSize = game.size;
      final bigSquareSize = isLandscape ? gameSize.y * 0.8 : gameSize.x * 0.8;

      size = Vector2.all(bigSquareSize);
      _visualSprite!.size = size;
      _visualSprite!.position = size / 2;

      _visualSprite!.add(
        SequenceEffect([
          ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.1)),
          ScaleEffect.by(Vector2.all(1.0), EffectController(duration: 0.1)),
        ]),
      );
    }
    anchor = Anchor.center;
  }

  void handleDrag(Vector2 delta) {
    if (_hasExploded) return;
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
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_hasExploded) return true;

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
      _checkLanePenalty();
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

  void jump() {
    if (_hasExploded) return;
    if (_isJumping) return;

    _isJumping = true;
    _jumpGraceTimer = 0.2;

    if (_isOnObstacle && _platformsInContact.isNotEmpty) {
      _platformToIgnore = _platformsInContact.first;
    } else {
      _platformToIgnore = null;
    }

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

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (_hasExploded) return;
    super.onCollisionStart(intersectionPoints, other);

    if (other is CoinComponent) {
      gameState.addCoin();
      other.removeFromParent();
      return;
    }
    if (other is FuelCanisterComponent) {
      gameState.collectFuelCanister();
      other.removeFromParent();
      _visualSprite?.add(
        ColorEffect(
          Colors.green,
          EffectController(duration: 0.2, alternate: true, repeatCount: 2),
          opacityTo: 0.7,
        ),
      );
      return;
    }

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.puddle) {
        _applySlowDebuff();
        return;
      }

      if (other.type == ObstacleType.geyser) {
        if (other.isGeyserActive) {
          _handleCollision(other);
        }
        return;
      }

      bool isMountable =
          other.type == ObstacleType.jumpable ||
          other.type == ObstacleType.snowball;

      if (isMountable) {
        if (_jumpGraceTimer > 0 && other == _platformToIgnore) return;

        if (_isJumping) {
          _platformsInContact.add(other);
          _isOnObstacle = true;
          _stopJumpEffect();
          return;
        } else if (_isOnObstacle && _platformsInContact.isNotEmpty) {
          _platformsInContact.add(other);
          return;
        } else {
          _handleCollision(other);
          return;
        }
      }

      _handleCollision(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    bool isMountable = false;
    if (other is ObstacleComponent) {
      isMountable =
          other.type == ObstacleType.jumpable ||
          other.type == ObstacleType.snowball;
    }

    if (isMountable) {
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

  void _handleCollision(ObstacleComponent obstacle) {
    if (_hitGraceTimer > 0) return;
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

  void _checkLanePenalty() {
    int sectionTheme = (gameState.currentSection - 1) % 5;

    bool isOffRoad = currentLane == 0 || currentLane == 4;

    bool isDesert = sectionTheme == 0; // Tema 0
    bool isVolcano = sectionTheme == 4; // Tema 4

    if ((isDesert || isVolcano) && isOffRoad) {
      gameState.setOffRoad(true);

      Color penaltyColor = isVolcano ? Colors.deepOrange : Colors.red;

      if (_fuelPenaltyEffect == null && _visualSprite != null) {
        _fuelPenaltyEffect = ColorEffect(
          penaltyColor,
          EffectController(duration: 0.2, alternate: true, infinite: true),
          opacityTo: 0.8,
        );
        _visualSprite!.add(_fuelPenaltyEffect!);
      }
    } else {
      gameState.setOffRoad(false);

      if (_fuelPenaltyEffect != null) {
        _fuelPenaltyEffect!.removeFromParent();
        _fuelPenaltyEffect = null;

        if (_slowEffectVisual == null && _currentIceTintIntensity < 0.01) {
          _visualSprite?.paint.colorFilter = null;
        }
      }
    }
  }

  void _applySlowDebuff() {
    _slowDebuffTimer = 2.0;

    if (_slowEffectVisual == null && _visualSprite != null) {
      _slowEffectVisual = ColorEffect(
        Colors.blue,
        EffectController(duration: 0.5, alternate: true, infinite: true),
        opacityTo: 0.6,
      );
      _visualSprite!.add(_slowEffectVisual!);
    }
  }

  void _removeSlowVisuals() {
    if (_slowEffectVisual != null) {
      _slowEffectVisual!.removeFromParent();
      _slowEffectVisual = null;

      if (_fuelPenaltyEffect == null) {
        _visualSprite?.paint.colorFilter = null;
      }
    }
  }

  void _updateIceVisuals(double dt) {
    double targetIntensity = (_iceCampingTimer / _maxIceTime) * 0.8;

    double speed = (targetIntensity > _currentIceTintIntensity) ? 1.0 : 10.0;

    double diff = targetIntensity - _currentIceTintIntensity;
    _currentIceTintIntensity += diff * speed * dt;

    if (_fuelPenaltyEffect == null &&
        _slowEffectVisual == null &&
        _visualSprite != null) {
      if (_currentIceTintIntensity > 0.01) {
        _visualSprite!.paint.colorFilter = ColorFilter.mode(
          Colors.cyan.withOpacity(_currentIceTintIntensity),
          BlendMode.srcATop,
        );
      } else {
        _visualSprite!.paint.colorFilter = null;
      }
    }
  }
}
