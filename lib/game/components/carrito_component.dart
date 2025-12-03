import 'package:carrito_run/game/components/cannon_ball_component.dart';
import 'package:carrito_run/game/components/missile_component.dart';
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

  // Configuración de Carriles
  int currentLane = 2;
  final int totalLanes = 5;

  // Variables Visuales
  SpriteComponent? _visualSprite;
  Sprite? _cachedExplosionSprite;
  Effect? _jumpEffect;
  RoundedShieldComponent? _shieldVisual;

  // Variables para gestos
  bool _swipeHandled = false;
  Vector2 _dragAccumulator = Vector2.zero();

  // Control de efectos de color
  ColorEffect? _fuelPenaltyEffect;
  ColorEffect? _slowEffectVisual;

  // Variables de Lógica
  bool _isMoving = false;
  bool _isJumping = false;
  bool _isOnObstacle = false;
  bool _hasExploded = false;

  // Timers
  double _jumpGraceTimer = 0.0;
  double _hitGraceTimer = 0.0;
  double _slowDebuffTimer = 0.0;

  // Referencias
  ObstacleComponent? _platformToIgnore;
  final Set<ObstacleComponent> _platformsInContact = {};

  // Constantes de Animación
  final double jumpDuration = 0.5;
  final double jumpScale = 1.3;
  final double platformScale = 1.15;
  final double dragThreshold = 10.0;
  Vector2 _basePosition = Vector2.zero();

  // Variables Hielo/Lava
  double _iceCampingTimer = 0.0;
  double _currentIceTintIntensity = 0.0;
  final double _maxIceTime = 2.0;
  double _abilityDurationTimer = 0.0;
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

    final selectedCarId = gameState.selectedCarId;
    final carItem = gameState.allCars.firstWhere(
      (c) => c.id == selectedCarId,
      orElse: () => gameState.allCars[0],
    );

    final orientation = isLandscape ? 'landscape' : 'portrait';
    final spritePath = 'carts/${carItem.assetPath}_$orientation.png';

    try {
      _visualSprite = SpriteComponent(
        sprite: await game.loadSprite(spritePath),
        anchor: Anchor.center,
      );
    } catch (e) {
      debugPrint("Error cargando carro: $e");
      _visualSprite = SpriteComponent(
        sprite: await game.loadSprite('carts/classic_$orientation.png'),
        anchor: Anchor.center,
      );
    }

    try {
      _cachedExplosionSprite = await game.loadSprite('explosion.png');
    } catch (e) {
      debugPrint("Error explosión: $e");
    }

    _updateSize();

    _shieldVisual = RoundedShieldComponent(
      color: Colors.cyan.withOpacity(0.4),
      priority: -1,
    );
    _shieldVisual!.anchor = Anchor.center;

    if (_visualSprite != null) {
      _shieldVisual!.size = size * 1.2;
      _shieldVisual!.position = _visualSprite!.size / 2;
    }

    add(RectangleHitbox());

    if (_visualSprite != null) {
      add(_visualSprite!);

      if (gameState.hasShield) {
        _visualSprite!.add(_shieldVisual!);
      }
    }

    _updatePosition();
    _basePosition = position.clone();

    _applyCarPassives(carItem.id);
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

      if (_shieldVisual != null) {
        _shieldVisual!.size = size * 1.2;
        _shieldVisual!.position = _visualSprite!.size / 2;
      }
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

  void _spawnGoldParticle() {
    final particle = RectangleComponent(
      position: position.clone(),
      size: Vector2.all(10),
      paint: Paint()..color = Colors.amberAccent.withOpacity(0.6),
      priority: 9,
      anchor: Anchor.center,
    );

    particle.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.5),
        onComplete: () => particle.removeFromParent(),
      ),
    );

    game.add(particle);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState.isAbilityActive) {
      _abilityDurationTimer -= dt;
      if (_visualSprite != null && _abilityDurationTimer % 0.2 < 0.1) {
        _visualSprite!.paint.colorFilter = const ColorFilter.mode(
          Colors.white54,
          BlendMode.srcATop,
        );
      } else {
        _visualSprite?.paint.colorFilter = null;
      }

      if (_abilityDurationTimer <= 0) {
        gameState.deactivateAbility();
        _visualSprite?.paint.colorFilter = null;

        if (gameState.selectedCarId == 12) {
          _visualSprite?.paint.color = _visualSprite!.paint.color.withOpacity(
            1.0,
          );
        }
      }
    }

    if (gameState.hasShield && !_hasExploded) {
      if (_shieldVisual?.parent == null && _visualSprite != null) {
        _visualSprite!.add(_shieldVisual!);
      }
    } else {
      if (_shieldVisual?.parent != null) {
        _shieldVisual!.removeFromParent();
      }
    }

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

    if (gameState.selectedCarId == 1 && !_hasExploded) {
      _applyMagnetEffect(dt);
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

    bool isIceSection = (gameState.currentSection - 1) % 5 == 3;

    if (isIceSection &&
        !_hasExploded &&
        gameState.selectedCarId != 11 &&
        gameState.selectedCarId != 16) {
      if (!_isMoving) {
        _iceCampingTimer += dt;
      } else {
        _iceCampingTimer = 0.0;
      }

      if (_iceCampingTimer >= _maxIceTime) {
        debugPrint("¡CONGELADO! Daño recibido.");
        gameState.takeHit();
        _iceCampingTimer = 0.0;

        _visualSprite?.add(
          ColorEffect(
            Colors.red,
            EffectController(duration: 0.2, alternate: true, repeatCount: 2),
            opacityTo: 0.8,
          ),
        );
      }
    } else {
      _iceCampingTimer = 0.0;
    }

    if (gameState.selectedCarId == 16 && !_hasExploded) {
      if (_visualSprite != null) {
        if ((dt * 1000).toInt() % 5 == 0) {
          _spawnGoldParticle();
        }
      }
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

    if (_shieldVisual?.parent != null) {
      _shieldVisual!.removeFromParent();
    }

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
    if (_hasExploded || _isMoving) return;
    if (_swipeHandled) return;
    _dragAccumulator += delta;
    const double activationThreshold = 20.0;
    if (isLandscape) {
      if (_dragAccumulator.y > activationThreshold) {
        _changeLane(1);
        _swipeHandled = true;
      } else if (_dragAccumulator.y < -activationThreshold) {
        _changeLane(-1);
        _swipeHandled = true;
      }
      if (_dragAccumulator.x < -activationThreshold) {
        _tryActivateAbility();
        _swipeHandled = true;
      }
    } else {
      if (_dragAccumulator.x > activationThreshold) {
        _changeLane(1);
        _swipeHandled = true;
      } else if (_dragAccumulator.x < -activationThreshold) {
        _changeLane(-1);
        _swipeHandled = true;
      }
      if (_dragAccumulator.y > activationThreshold) {
        _tryActivateAbility();
        _swipeHandled = true;
      }
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
    if (keysPressed.contains(LogicalKeyboardKey.keyX)) {
      _tryActivateAbility();
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
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        _tryActivateAbility();
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
      if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        _tryActivateAbility();
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

    if (gameState.selectedCarId == 12) {
      _isMoving = false;
      position = targetPosition;
      _basePosition = position.clone();

      _visualSprite?.add(
        ColorEffect(
          Colors.cyanAccent,
          EffectController(duration: 0.1),
          opacityTo: 0.8,
        ),
      );
      return;
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
    if (_hasExploded || _isJumping) return;
    _isJumping = true;
    _jumpGraceTimer = 0.2;
    if (_isOnObstacle && _platformsInContact.isNotEmpty)
      _platformToIgnore = _platformsInContact.first;
    else
      _platformToIgnore = null;
    final startScale = _isOnObstacle ? platformScale : 1.0;
    if (_isOnObstacle) _isOnObstacle = false;
    _jumpEffect =
        FunctionEffect<CarritoComponent>((target, progress) {
            final currentBaseScale = startScale + (1.0 - startScale) * progress;
            final jumpCurve = 4 * progress * (1 - progress);
            final jumpImpulse = (jumpScale - 1.0) * jumpCurve;
            _visualSprite?.scale = Vector2.all(currentBaseScale + jumpImpulse);
          }, EffectController(duration: jumpDuration))
          ..onComplete = () {
            _isJumping = false;
            _jumpEffect = null;
            if (_isOnObstacle)
              _visualSprite?.scale = Vector2.all(platformScale);
            else
              _visualSprite?.scale = Vector2.all(1.0);
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

    if (gameState.selectedCarId == 12 && gameState.isAbilityActive) {
      if (other is CoinComponent || other is FuelCanisterComponent) {
      } else if (other is ObstacleComponent) {
        return;
      }
    }

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
      if (gameState.selectedCarId == 6 && gameState.isAbilityActive) {
        bool isDestructible =
            other.type == ObstacleType.jumpable ||
            other.type == ObstacleType.nonJumpable ||
            other.type == ObstacleType.barrier ||
            other.type == ObstacleType.snowball;
        if (isDestructible) {
          other.removeFromParent();
          _visualSprite?.add(
            MoveEffect.by(
              Vector2(2, 0),
              EffectController(duration: 0.1, alternate: true),
            ),
          );
          return;
        }
      }
      if (other.type == ObstacleType.puddle) {
        if (gameState.selectedCarId == 4 ||
            gameState.selectedCarId == 11 ||
            gameState.selectedCarId == 16) {
          return;
        }
        _applySlowDebuff();
        return;
      }
      if (other.type == ObstacleType.geyser) {
        if (other.isGeyserActive) _handleCollision(other);
        return;
      }
      if (gameState.selectedCarId == 13) {
        bool isLowObstacle =
            other.type == ObstacleType.barrier ||
            other.type == ObstacleType.snowball ||
            other.type == ObstacleType.jumpable ||
            other.type == ObstacleType.puddle;

        if (isLowObstacle) {
          return;
        }
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
    if (other is ObstacleComponent)
      isMountable =
          other.type == ObstacleType.jumpable ||
          other.type == ObstacleType.snowball;

    if (isMountable) {
      _platformsInContact.remove(other);
      if (_platformsInContact.isEmpty && _isOnObstacle) {
        _isOnObstacle = false;
        if (!_isJumping)
          _visualSprite?.add(
            ScaleEffect.to(
              Vector2.all(1.0),
              EffectController(duration: 0.3, curve: Curves.easeInOut),
            ),
          );
      }
    }
  }

  void _handleCollision(ObstacleComponent obstacle) {
    if (_hitGraceTimer > 0) return;
    bool hadShield = gameState.hasShield;
    gameState.takeHit();
    _hitGraceTimer = 1.0;
    if (hadShield) {
      _visualSprite?.add(
        ColorEffect(
          Colors.cyan,
          EffectController(duration: 0.5, curve: Curves.easeOut),
          opacityTo: 0.0,
        ),
      );
    } else {
      _visualSprite?.add(
        ColorEffect(
          Colors.red,
          EffectController(duration: 0.2, alternate: true, repeatCount: 3),
          opacityTo: 0.7,
        ),
      );
    }
  }

  void _checkLanePenalty() {
    if (gameState.selectedCarId == 11 || gameState.selectedCarId == 16) {
      return;
    }

    int sectionTheme = (gameState.currentSection - 1) % 5;
    bool isOffRoad = currentLane == 0 || currentLane == 4;
    bool isDesert = sectionTheme == 0;
    bool isVolcano = sectionTheme == 4;
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
        if (_slowEffectVisual == null && _currentIceTintIntensity < 0.01)
          _visualSprite?.paint.colorFilter = null;
      }
    }
  }

  void _applySlowDebuff() {
    _slowDebuffTimer = 2.0;
    if (_slowEffectVisual != null) return;
    if (_fuelPenaltyEffect != null) {
      _fuelPenaltyEffect!.removeFromParent();
      _fuelPenaltyEffect = null;
    }
    _visualSprite?.paint.colorFilter = null;
    _slowEffectVisual = ColorEffect(
      Colors.blue,
      EffectController(duration: 0.5, alternate: true, infinite: true),
      opacityTo: 0.6,
    );
    if (_visualSprite != null) _visualSprite!.add(_slowEffectVisual!);
  }

  void _removeSlowVisuals() {
    if (_slowEffectVisual != null) {
      _slowEffectVisual!.removeFromParent();
      _slowEffectVisual = null;
      _visualSprite?.paint.colorFilter = null;
      _checkLanePenalty();
    }
  }

  void _activateMidasTouch() {
    final obstacles = game.children.whereType<ObstacleComponent>().toList();

    for (final obs in obstacles) {
      if (obs.type != ObstacleType.geyser) {
        final pos = obs.position.clone();
        final isLandscapeObs = obs.isLandscape;
        final laneObs = obs.lane;

        obs.removeFromParent();

        final giantCoin = CoinComponent(
          isLandscape: isLandscapeObs,
          lane: laneObs,
          isOnObstacle: false,
        );

        game.add(giantCoin);

        Future.delayed(Duration.zero, () {
          giantCoin.scale = Vector2.all(2.0);
          giantCoin.position = pos;
        });
      }
    }
  }

  void _updateIceVisuals(double dt) {
    if (gameState.selectedCarId == 11) {
      if (_fuelPenaltyEffect == null &&
          _slowEffectVisual == null &&
          _visualSprite != null) {
        _visualSprite!.paint.colorFilter = null;
      }
      return;
    }

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

  void _applyCarPassives(int carId) {
    if (carId == 9) gameState.grantShield();
  }

  void _applyMagnetEffect(double dt) {
    const double magnetRange = 200.0;
    double attractionSpeed = game.gameState.currentSpeed + 400.0;
    final coins = game.children.whereType<CoinComponent>();
    for (final coin in coins) {
      double distance = position.distanceTo(coin.position);
      if (distance < magnetRange) {
        Vector2 direction = (position - coin.position).normalized();
        coin.position += direction * attractionSpeed * dt;
      }
    }
  }

  void _activateTractorBeam() {
    final targets = [
      ...game.children.whereType<CoinComponent>(),
      ...game.children.whereType<FuelCanisterComponent>(),
    ];

    for (final target in targets) {
      target.add(
        MoveToEffect(
          position,
          EffectController(duration: 0.3, curve: Curves.easeIn),
          onComplete: () {},
        ),
      );
    }
  }

  void _tryActivateAbility() {
    if (gameState.abilityCharge >= 100.0 && !gameState.isAbilityActive) {
      debugPrint(
        "Activando habilidad para Carro ID: ${gameState.selectedCarId}",
      );

      if (gameState.selectedCarId == 6) {
        _abilityDurationTimer = 5.0;
        gameState.activateAbility();
        _visualSprite?.add(
          ColorEffect(
            Colors.white,
            EffectController(duration: 0.3),
            opacityTo: 0.8,
          ),
        );
      } else if (gameState.selectedCarId == 9) {
        if (!gameState.hasShield) {
          gameState.grantShield();
          gameState.activateAbility();
          Future.delayed(
            const Duration(milliseconds: 500),
            () => gameState.deactivateAbility(),
          );
          _visualSprite?.add(
            ColorEffect(
              Colors.greenAccent,
              EffectController(duration: 0.5),
              opacityTo: 0.8,
            ),
          );
        } else {
          debugPrint("¡Escudo lleno, no se gasta la habilidad!");
        }
      } else if (gameState.selectedCarId == 10) {
        gameState.activateAbility();

        final missile = MissileComponent(
          isLandscape: isLandscape,
          position: position.clone(),
          size: size * 0.6,
        );

        game.add(missile);
        debugPrint("¡MISIL DISPARADO!");

        Future.delayed(const Duration(seconds: 1), () {
          gameState.deactivateAbility();
        });
      } else if (gameState.selectedCarId == 12) {
        _abilityDurationTimer = 4.0;
        gameState.activateAbility();

        if (_visualSprite != null) {
          _visualSprite!.paint.color = _visualSprite!.paint.color.withOpacity(
            0.5,
          );
        }

        debugPrint("¡MODO FANTASMA!");
      } else if (gameState.selectedCarId == 13) {
        gameState.activateAbility();

        _visualSprite?.add(
          ColorEffect(
            Colors.purpleAccent,
            EffectController(duration: 0.5, alternate: true, repeatCount: 2),
            opacityTo: 0.6,
          ),
        );

        _activateTractorBeam();

        Future.delayed(
          const Duration(seconds: 1),
          () => gameState.deactivateAbility(),
        );
      } else if (gameState.selectedCarId == 14) {
        gameState.activateAbility();

        double cannonWidth = isLandscape ? size.y * 3.0 : size.x * 3.0;

        final cannonBall = CannonBallComponent(
          isLandscape: isLandscape,
          position: position.clone(),
          size: Vector2.all(cannonWidth),
        );
        game.add(cannonBall);

        debugPrint("¡CAÑONAZO!");

        Future.delayed(
          const Duration(seconds: 1),
          () => gameState.deactivateAbility(),
        );
      } else if (gameState.selectedCarId == 15) {
        gameState.activateAbility();

        gameState.rewindTime();

        _visualSprite?.add(
          ColorEffect(
            Colors.cyan,
            EffectController(duration: 0.1, alternate: true, repeatCount: 5),
            opacityTo: 0.9,
          ),
        );

        _hitGraceTimer = 3.0;

        debugPrint("¡GRAN SCOTT! TIEMPO REBOBINADO");

        Future.delayed(
          const Duration(seconds: 3),
          () => gameState.deactivateAbility(),
        );
      } else if (gameState.selectedCarId == 16) {
        _abilityDurationTimer = 10.0;
        gameState.activateAbility();

        _visualSprite?.add(
          ColorEffect(
            Colors.yellow,
            EffectController(duration: 0.5, alternate: true, infinite: true),
            opacityTo: 0.5,
          ),
        );

        _activateMidasTouch();

        debugPrint("¡TOQUE DE MIDAS!");
      }
    }
  }

  void onPanStart() {
    _swipeHandled = false;
    _dragAccumulator = Vector2.zero();
  }
}

class RoundedShieldComponent extends PositionComponent {
  final Color color;
  final double cornerRadius;

  late final Paint _paint;

  RoundedShieldComponent({
    required this.color,
    this.cornerRadius = 15.0,
    super.priority,
  }) {
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rrect, _paint);
  }
}
