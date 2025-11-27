import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class CarritoComponent extends SpriteComponent 
    with KeyboardHandler, HasGameReference {
  final bool isLandscape;
  int currentLane = 2;
  final int totalLanes = 5;
  
  final double laneChangeDuration = 0.15;
  
  bool _isMoving = false;
  
  final double dragThreshold = 10.0;
  
  CarritoComponent({required this.isLandscape});


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite(
      isLandscape ? 'carrito_landscape.png' : 'carrito_portrait.png'
    );
    
    _updateSize();
    anchor = Anchor.center;
    _updatePosition();
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
  }


  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (sprite != null) {
      _updateSize();
      _updatePosition();
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


  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;
    
    if (!isKeyDown) {
      return true;
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
      targetPosition = Vector2(
        position.x,
        _getLanePositionY(gameSize.y),
      );
    } else {
      targetPosition = Vector2(
        _getLanePositionX(gameSize.x),
        position.y,
      );
    }
    
    _isMoving = true;
    
    children.whereType<MoveToEffect>().forEach((effect) {
      effect.removeFromParent();
    });
    
    add(
      MoveToEffect(
        targetPosition,
        EffectController(
          duration: laneChangeDuration,
          curve: Curves.easeInOut,
        ),
        onComplete: () {
          _isMoving = false;
        },
      ),
    );
  }
}
