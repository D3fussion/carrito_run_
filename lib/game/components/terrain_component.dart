import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart'; // ⭐ AGREGADO para Canvas, Color, Paint
import 'package:carrito_run/models/scenario_config.dart';
import 'package:carrito_run/game/managers/scenario_manager.dart';

/// Componente que representa un área de terreno especial
/// (arena, lodo, hielo, charco)
class TerrainComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  final bool isLandscape;
  final int lane;
  final TerrainType terrainType;
  final double gameSpeed;
  final ScenarioManager scenarioManager;

  TerrainComponent({
    required this.isLandscape,
    required this.lane,
    required this.terrainType,
    required this.scenarioManager,
    this.gameSpeed = 200.0,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    priority = 1; // Debajo de todo (fondo)

    _updateSize();
    anchor = Anchor.center;
    _updatePosition();

    // Hitbox para detectar cuando el carrito entra
    add(RectangleHitbox());
  }

  void _updateSize() {
    final gameSize = game.size;

    if (isLandscape) {
      final laneHeight = gameSize.y / 5;
      // Terreno ocupa todo el ancho visible y la altura del carril
      size = Vector2(gameSize.x * 2, laneHeight);
    } else {
      final laneWidth = gameSize.x / 5;
      size = Vector2(laneWidth, gameSize.y * 2);
    }
  }

  void _updatePosition() {
    final gameSize = game.size;

    if (isLandscape) {
      position.x = gameSize.x + size.x / 2;
      position.y = _getLanePositionY(gameSize.y);
    } else {
      position.x = _getLanePositionX(gameSize.x);
      position.y = -size.y / 2;
    }
  }

  double _getLanePositionX(double screenWidth) {
    final laneWidth = screenWidth / 5;
    return (lane + 0.5) * laneWidth;
  }

  double _getLanePositionY(double screenHeight) {
    final laneHeight = screenHeight / 5;
    return (lane + 0.5) * laneHeight;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Mover el terreno
    if (isLandscape) {
      position.x -= gameSpeed * dt;

      if (position.x < -size.x) {
        removeFromParent();
      }
    } else {
      position.y += gameSpeed * dt;

      if (position.y > game.size.y + size.y) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 🖼️ AQUÍ SE DIBUJARÍAN LAS TEXTURAS DEL TERRENO
    // Por ahora, un color semitransparente según el tipo
    
    Color terrainColor;
    switch (terrainType) {
      case TerrainType.sand:
        terrainColor = const Color(0x40F4A460); // Arena amarillenta
        break;
      case TerrainType.slowMud:
        terrainColor = const Color(0x408B4513); // Marrón lodo
        break;
      case TerrainType.ice:
        terrainColor = const Color(0x40ADD8E6); // Azul hielo
        break;
      case TerrainType.puddle:
        terrainColor = const Color(0x404682B4); // Azul charco
        break;
      default:
        return; // No dibujar nada para normal
    }

    final paint = Paint()
      ..color = terrainColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), paint);
  }
}