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

  // NUEVAS VARIABLES PARA MANEJAR EL CAMBIO DE GIRO
  int _currentThemeIndex = 0;
  bool _lastWasLandscape = false;

  BackgroundManager() {
    priority = -10;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    // Guardamos la orientación inicial
    _lastWasLandscape = game.size.x > game.size.y;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;

    // Detectamos si la orientación cambió realmente
    bool isNowLandscape = size.x > size.y;

    if (_lastWasLandscape != isNowLandscape) {
      // SI CAMBIÓ LA ORIENTACIÓN: Recargamos las imágenes
      _lastWasLandscape = isNowLandscape;
      _reloadCurrentBackground();
    } else {
      // SI SOLO CAMBIÓ EL TAMAÑO (pero no la orientación): Solo ajustamos
      _currentParallax?.size = size;
      _currentParallax?.parallax?.resize(size);

      _nextParallax?.size = size;
      _nextParallax?.parallax?.resize(size);
    }
  }

  // MÉTODO NUEVO: Cambia la imagen (Landscape <-> Portrait) en caliente
  Future<void> _reloadCurrentBackground() async {
    // 1. Cargamos el nuevo parallax con la orientación correcta
    // Usamos _currentThemeIndex para saber qué carretera poner (tierra, asfalto, etc.)
    final newParallax = await _createParallaxForTheme(_currentThemeIndex);

    // 2. Reemplazamos el actual
    _currentParallax = newParallax;

    // 3. Si justo estábamos en medio de una transición (raro en el menú, pero posible)
    if (_isTransitioning && _nextParallax != null) {
      // Calculamos cuál era el siguiente tema y lo recargamos también
      int nextTheme = (_currentThemeIndex + 1) % 5;
      _nextParallax = await _createParallaxForTheme(nextTheme);
    }
  }

  Future<void> loadInitialTheme(int themeIndex) async {
    _currentThemeIndex = themeIndex; // Guardamos qué tema es
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
      baseVelocity: isLandscape ? Vector2(80, 0) : Vector2(0, -80),
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

    // IMPORTANTE: Actualizamos el índice del tema actual al terminar la transición
    // Para que si giramos la pantalla después, sepamos en qué tema estamos.
    _currentThemeIndex = (_currentThemeIndex + 1) % 5;
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
