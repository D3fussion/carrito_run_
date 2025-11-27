import 'package:carrito_run/game/components/carrito_component.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';


class CarritoGame extends FlameGame with HasKeyboardHandlerComponents, PanDetector {
  ParallaxComponent? _parallaxComponent;
  CarritoComponent? _carrito;
  bool _isLandscape = false;


  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }


  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    final isCurrentlyLandscape = size.x > size.y;
    
    if (_isLandscape != isCurrentlyLandscape) {
      _isLandscape = isCurrentlyLandscape;
      _updateParallax();
      _updateCarrito();
    } else if (_parallaxComponent == null) {
      _updateParallax();
      _updateCarrito();
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_carrito != null) {
      _carrito!.handleDrag(info.delta.global);
    }
  }


  Future<void> _updateCarrito() async {
    if (_carrito != null) {
      remove(_carrito!);
    }


    _carrito = CarritoComponent(isLandscape: _isLandscape);
    await add(_carrito!);
  }


  Future<void> _updateParallax() async {
    if (_parallaxComponent != null) {
      remove(_parallaxComponent!);
    }


    final layers = await Future.wait([
      loadParallaxLayer(
        ParallaxImageData(
          _isLandscape ? 'road_landscape.png' : 'road_portrait.png'
        ),
        velocityMultiplier: Vector2(1.3, 1.3),
        alignment: Alignment.center,
        fill: _isLandscape ? LayerFill.height : LayerFill.width,
        repeat: _isLandscape ? ImageRepeat.repeatX : ImageRepeat.repeatY,
      ),
      loadParallaxLayer(
        ParallaxImageData(
          _isLandscape ? 'borders_landscape.png' : 'borders_portrait.png'
        ),
        velocityMultiplier: Vector2(1.0, 1.0),
        alignment: Alignment.center,
        fill: _isLandscape ? LayerFill.height : LayerFill.width,
        repeat: _isLandscape ? ImageRepeat.repeatX : ImageRepeat.repeatY,
      ),
    ]);


    final parallax = ParallaxComponent(
      parallax: Parallax(
        layers,
        baseVelocity: _isLandscape 
          ? Vector2(-80, 0)
          : Vector2(0, 80),
      ),
      priority: -1,
    );


    _parallaxComponent = parallax;
    add(_parallaxComponent!);
  }


}
