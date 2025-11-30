import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/components/gas_station_component.dart';
import 'package:flutter/material.dart';

class BackgroundManager extends PositionComponent
    with HasGameReference<CarritoGame> {
  ParallaxComponent? _currentParallax;
  ParallaxComponent? _nextParallax;
  GasStationComponent? _gasStationDelimiter;

  bool _isTransitioning = false;

  BackgroundManager() {
    priority = -10;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;

    _currentParallax?.size = size;
    _currentParallax?.parallax?.resize(size);

    _nextParallax?.size = size;
    _nextParallax?.parallax?.resize(size);
    // -----------------------
  }

  Future<void> loadInitialTheme(int themeIndex) async {
    _currentParallax = await _createParallaxForTheme(themeIndex);
  }

  Future<void> startTransition(
    int newThemeIndex,
    GasStationComponent gasStation,
  ) async {
    if (_isTransitioning) return;

    _isTransitioning = true;
    _gasStationDelimiter = gasStation;

    _nextParallax = await _createParallaxForTheme(newThemeIndex);
  }

  Future<ParallaxComponent> _createParallaxForTheme(int themeIndex) async {
    final isLandscape = game.size.x > game.size.y;

    final roadImage = isLandscape
        ? 'road_landscape_$themeIndex.png'
        : 'road_portrait_$themeIndex.png';

    final bordersImage = isLandscape
        ? 'borders_landscape_$themeIndex.png'
        : 'borders_portrait_$themeIndex.png';

    final component = await ParallaxComponent.load(
      [ParallaxImageData(roadImage), ParallaxImageData(bordersImage)],
      baseVelocity: isLandscape ? Vector2(-80, 0) : Vector2(0, 80),
      images: game.images,
      repeat: isLandscape ? ImageRepeat.repeatX : ImageRepeat.repeatY,
      alignment: Alignment.center,
      fill: isLandscape ? LayerFill.height : LayerFill.width,
    );

    component.parallax?.layers[0].velocityMultiplier = Vector2(1.3, 1.3);
    component.parallax?.layers[1].velocityMultiplier = Vector2(1.0, 1.0);

    component.size = game.size;
    component.parallax?.resize(game.size);

    return component;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _currentParallax?.update(dt);
    _nextParallax?.update(dt);

    if (_isTransitioning && _gasStationDelimiter != null) {
      final station = _gasStationDelimiter!;
      bool transitionFinished = false;

      if (game.size.x > game.size.y) {
        // Landscape
        if (station.position.x < -station.size.x) {
          transitionFinished = true;
        }
      } else {
        // Portrait
        if (station.position.y > game.size.y + station.size.y) {
          transitionFinished = true;
        }
      }

      if (transitionFinished || station.parent == null) {
        _finishTransition();
      }
    }
  }

  void _finishTransition() {
    _isTransitioning = false;
    _gasStationDelimiter = null;

    _currentParallax = _nextParallax;
    _nextParallax = null;
  }

  @override
  void render(Canvas canvas) {
    if (!_isTransitioning ||
        _nextParallax == null ||
        _gasStationDelimiter == null) {
      _currentParallax?.render(canvas);
      return;
    }

    final station = _gasStationDelimiter!;
    final isLandscape = game.size.x > game.size.y;

    double splitX = station.position.x;
    double splitY = station.position.y;

    canvas.save();
    if (isLandscape) {
      canvas.clipRect(Rect.fromLTWH(0, 0, splitX, size.y));
    } else {
      canvas.clipRect(Rect.fromLTWH(0, splitY, size.x, size.y - splitY));
    }
    _currentParallax?.render(canvas);
    canvas.restore();

    canvas.save();
    if (isLandscape) {
      canvas.clipRect(Rect.fromLTWH(splitX, 0, size.x - splitX, size.y));
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.x, splitY));
    }
    _nextParallax?.render(canvas);
    canvas.restore();
  }
}
