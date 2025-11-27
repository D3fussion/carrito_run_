import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

class CarritoComponent extends SpriteComponent 
    with DragCallbacks, KeyboardHandler, HasGameReference {
  final bool isLandscape;
  int currentLane = 2;
  final int totalLanes = 5;
  
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

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isLandscape) {
      if (event.localDelta.y > 10) {
        _changeLane(1);
      } else if (event.localDelta.y < -10) {
        _changeLane(-1);
      }
    } else {
      if (event.localDelta.x > 10) {
        _changeLane(1);
      } else if (event.localDelta.x < -10) {
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
      _updatePosition();
    }
  }
}
