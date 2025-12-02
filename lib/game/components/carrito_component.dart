import 'package:carrito_run/game/components/coin_component.dart';
import 'package:carrito_run/game/components/powerup_component.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/collisions.dart';
import 'obstacle_component.dart';

class CarritoComponent extends PositionComponent
    with KeyboardHandler, HasGameReference, CollisionCallbacks {
  final bool isLandscape;
  final GameState gameState;

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

  final Set<ObstacleComponent> _platformsInContact = {};

  // ============ SISTEMA DE INVULNERABILIDAD VISUAL ============
  double _blinkTimer = 0.0;
  final double _blinkInterval = 0.15; // Parpadeo cada 0.15 segundos
  bool _isVisible = true;

  CarritoComponent({required this.isLandscape, required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    priority = 10;
    anchor = Anchor.center;

    // 🖼️ IMAGEN REQUERIDA: assets/cars/car_0_landscape.png
    // 🖼️ IMAGEN REQUERIDA: assets/cars/car_0_portrait.png
    // Relación 2:1 según especificaciones
    // Landscape: 128x64 px (o 256x128, 512x256)
    // Portrait: 64x128 px (o 128x256, 256x512)
    
    // Por ahora carga desde la ubicación temporal
    // Después cambiar a: 'cars/car_0_landscape.png'
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

  @override
  void update(double dt) {
    super.update(dt);

    // ⭐ Efecto de parpadeo durante invulnerabilidad
    if (gameState.isInvulnerable) {
      _blinkTimer += dt;
      if (_blinkTimer >= _blinkInterval) {
        _blinkTimer = 0.0;
        _isVisible = !_isVisible;
        _visualSprite.opacity = _isVisible ? 1.0 : 0.3;
      }
    } else {
      // Asegurar que el sprite sea visible cuando no hay invulnerabilidad
      if (_visualSprite.opacity != 1.0) {
        _visualSprite.opacity = 1.0;
        _isVisible = true;
      }
    }
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

    _jumpEffect = FunctionEffect<CarritoComponent>(
      (target, progress) {
        final jumpCurve = 4 * progress * (1 - progress);
        final scaleValue = startScale + (jumpScale - startScale) * jumpCurve;
        _visualSprite.scale = Vector2.all(scaleValue);
      },
      EffectController(duration: jumpDuration),
    )..onComplete = () {
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
      _platformsInContact.clear();
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
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // ⭐ Colisión con moneda
    if (other is CoinComponent) {
      gameState.addCoin();
      other.removeFromParent();
      // 🔊 SONIDO: Aquí agregar efecto de sonido al recolectar moneda
      print('🪙 Moneda recolectada!');
      return;
    }

    // ⭐ NUEVO: Colisión con power-up
    if (other is PowerUpComponent) {
      other.applyEffect(); // Aplica el efecto (vida o gasolina)
      other.removeFromParent();
      // 🔊 SONIDO: Aquí agregar efecto de sonido de power-up
      print('✨ Power-up recolectado: ${other.type}');
      return;
    }

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.jumpable) {
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

    if (other is ObstacleComponent) {
      if (other.type == ObstacleType.jumpable) {
        _platformsInContact.remove(other);

        if (_platformsInContact.isEmpty && _isOnObstacle) {
          _isOnObstacle = false;

          if (!_isJumping) {
            _visualSprite.add(
              ScaleEffect.to(
                Vector2.all(1.0),
                EffectController(duration: 0.3, curve: Curves.easeInOut),
              ),
            );
          }
        }
      }
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
        _visualSprite.add(
          ScaleEffect.to(
            Vector2.all(platformScale),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  // ============ MANEJO DE COLISIONES CON PÉRDIDA DE VIDA ============
  void _handleCollision(ObstacleComponent obstacle) {
    // ⭐ No hacer nada si está invulnerable
    if (gameState.isInvulnerable) {
      print('🛡️ Invulnerable - Colisión ignorada');
      return;
    }

    print('💥 ¡Colisión con obstáculo ${obstacle.type}!');
    
    // ⭐ Perder una vida
    gameState.loseLife();
    
    // 🔊 SONIDO: Aquí agregar efecto de sonido de daño/colisión
    
    // ⭐ Efecto visual de sacudida
    _addShakeEffect();
    
    // Si se acabaron las vidas, el Game Over se maneja automáticamente en game.dart
  }

  // ⭐ Efecto visual de sacudida al recibir daño
  void _addShakeEffect() {
    final originalPosition = position.clone();
    const shakeAmount = 5.0;
    const shakeCount = 3;
    const shakeDuration = 0.05;

    var shakes = 0;
    
    void shake() {
      if (shakes >= shakeCount * 2) {
        position = originalPosition;
        return;
      }

      final offset = shakes % 2 == 0
          ? Vector2(shakeAmount, 0)
          : Vector2(-shakeAmount, 0);

      position = originalPosition + offset;
      shakes++;

      Future.delayed(
        Duration(milliseconds: (shakeDuration * 1000).toInt()),
        shake,
      );
    }

    shake();
  }
}