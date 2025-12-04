import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:carrito_run/models/scenario_config.dart';
import 'dart:math';

/// Componente de obstáculo que se mueve dinámicamente
/// (venado que cruza, bola de nieve rodante, drone)
class DynamicObstacleComponent extends SpriteComponent
    with CollisionCallbacks, HasGameReference {
  final bool isLandscape;
  final DynamicObstacleType dynamicType;
  final double gameSpeed;
  
  int currentLane;
  int targetLane;
  bool isMovingBetweenLanes = false;
  double laneChangeTimer = 0.0;
  final double laneChangeDuration = 1.0; // 1 segundo para cambiar de carril
  
  final Random _random = Random();

  DynamicObstacleComponent({
    required this.isLandscape,
    required this.dynamicType,
    required int initialLane,
    this.gameSpeed = 200.0,
  })  : currentLane = initialLane,
        targetLane = initialLane;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await _loadSpriteForType();

    priority = 6; // Mayor que obstáculos normales

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();

    add(RectangleHitbox());
    
    // Programar cambio de carril aleatorio
    _scheduleNextLaneChange();
  }

  Future<Sprite> _loadSpriteForType() async {
    // 🖼️ IMÁGENES REQUERIDAS:
    // - assets/escenarios/bosque/dynamic_venado.png
    // - assets/escenarios/nieve/dynamic_bola_nieve.png
    // - assets/escenarios/ciudad/dynamic_drone.png
    
    try {
      switch (dynamicType) {
        case DynamicObstacleType.deer:
          return await game.loadSprite('escenarios/bosque/venado.png');
        case DynamicObstacleType.snowball:
          return await game.loadSprite('escenarios/nieve/bola_nieve.png');
        case DynamicObstacleType.drone:
          return await game.loadSprite('escenarios/ciudad/drone.png');
      }
    } catch (e) {
      print('⚠️ Sprite dinámico no encontrado, usando placeholder');
      // Fallback a obstacle_jumpable
      return await game.loadSprite('obstacle_jumpable.png');
    }
  }

  void _updateSize() {
    final gameSize = game.size;

    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      final size = laneHeight * 0.9;
      this.size = Vector2.all(size);
    } else {
      final laneWidth = gameSize.x / 5;
      final size = laneWidth * 0.9;
      this.size = Vector2.all(size);
    }
  }

  void _updatePosition() {
    final gameSize = game.size;

    if (isLandscape) {
      position.x = gameSize.x + size.x;
      position.y = _getLanePositionY(gameSize.y, currentLane);
    } else {
      position.x = _getLanePositionX(gameSize.x, currentLane);
      position.y = -size.y;
    }
  }

  double _getLanePositionX(double screenWidth, int lane) {
    final laneWidth = screenWidth / 5;
    return (lane + 0.5) * laneWidth;
  }

  double _getLanePositionY(double screenHeight, int lane) {
    final laneHeight = screenHeight / 5;
    return (lane + 0.5) * laneHeight;
  }

  void _scheduleNextLaneChange() {
    // Cambiar de carril en 2-4 segundos
    final delay = 2.0 + _random.nextDouble() * 2.0;
    
    Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
      if (parent != null && isMounted) {
        _startLaneChange();
      }
    });
  }

  void _startLaneChange() {
    // Elegir un carril aleatorio diferente al actual
    final possibleLanes = [0, 1, 2, 3, 4];
    possibleLanes.remove(currentLane);
    
    targetLane = possibleLanes[_random.nextInt(possibleLanes.length)];
    isMovingBetweenLanes = true;
    laneChangeTimer = 0.0;
    
    print('🦌 Obstáculo dinámico cambiando de carril $currentLane → $targetLane');
  }

  @override
  void update(double dt) {
    super.update(dt);

    final gameSize = game.size;

    // Movimiento de cambio de carril
    if (isMovingBetweenLanes) {
      laneChangeTimer += dt;
      final progress = (laneChangeTimer / laneChangeDuration).clamp(0.0, 1.0);
      
      if (isLandscape) {
        final startY = _getLanePositionY(gameSize.y, currentLane);
        final endY = _getLanePositionY(gameSize.y, targetLane);
        position.y = startY + (endY - startY) * progress;
      } else {
        final startX = _getLanePositionX(gameSize.x, currentLane);
        final endX = _getLanePositionX(gameSize.x, targetLane);
        position.x = startX + (endX - startX) * progress;
      }
      
      if (progress >= 1.0) {
        currentLane = targetLane;
        isMovingBetweenLanes = false;
        _scheduleNextLaneChange();
      }
    }

    // Movimiento principal (como obstáculos normales)
    if (isLandscape) {
      position.x -= gameSpeed * dt;

      if (position.x < -size.x) {
        removeFromParent();
      }
    } else {
      position.y += gameSpeed * dt;

      if (position.y > gameSize.y + size.y) {
        removeFromParent();
      }
    }
    
    // Rotación para bola de nieve
    if (dynamicType == DynamicObstacleType.snowball) {
      angle += dt * 3.0; // Gira mientras rueda
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // La colisión se maneja en carrito_component.dart
  }
}