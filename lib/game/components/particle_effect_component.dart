import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// Tipos de partículas
enum ParticleEffectType {
  dust,   // Polvo del desierto
  rain,   // Lluvia
  snow,   // Nieve cayendo
  leaves, // Hojas del bosque
}

/// Sistema de partículas para efectos visuales
class ParticleEffectComponent extends Component with HasGameReference {
  final ParticleEffectType effectType;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  
  // Configuración según tipo
  late int _maxParticles;
  late double _spawnRate;
  double _spawnTimer = 0.0;

  ParticleEffectComponent({required this.effectType}) {
    _configureEffect();
  }

  void _configureEffect() {
    switch (effectType) {
      case ParticleEffectType.dust:
        _maxParticles = 20;
        _spawnRate = 0.2; // Cada 0.2 segundos
        break;
      case ParticleEffectType.rain:
        _maxParticles = 100;
        _spawnRate = 0.05; // Lluvia intensa
        break;
      case ParticleEffectType.snow:
        _maxParticles = 50;
        _spawnRate = 0.1;
        break;
      case ParticleEffectType.leaves:
        _maxParticles = 30;
        _spawnRate = 0.15;
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer += dt;
    
    // Spawn nuevas partículas
    if (_spawnTimer >= _spawnRate && _particles.length < _maxParticles) {
      _spawnTimer = 0.0;
      _spawnParticle();
    }

    // Actualizar partículas existentes
    _particles.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
  }

  void _spawnParticle() {
    final gameSize = game.size;
    
    switch (effectType) {
      case ParticleEffectType.dust:
        _particles.add(_Particle(
          position: Vector2(
            _random.nextDouble() * gameSize.x,
            gameSize.y * 0.8 + _random.nextDouble() * gameSize.y * 0.2,
          ),
          velocity: Vector2(
            -50 - _random.nextDouble() * 50,
            -20 + _random.nextDouble() * 40,
          ),
          color: Color.fromRGBO(210, 180, 140, 0.3 + _random.nextDouble() * 0.3),
          size: 2 + _random.nextDouble() * 3,
          lifetime: 1.0 + _random.nextDouble() * 1.0,
        ));
        break;
        
      case ParticleEffectType.rain:
        _particles.add(_Particle(
          position: Vector2(
            _random.nextDouble() * gameSize.x,
            -10,
          ),
          velocity: Vector2(
            -20 + _random.nextDouble() * 40,
            300 + _random.nextDouble() * 200,
          ),
          color: Color.fromRGBO(135, 206, 250, 0.6),
          size: 1 + _random.nextDouble() * 2,
          lifetime: 3.0,
        ));
        break;
        
      case ParticleEffectType.snow:
        _particles.add(_Particle(
          position: Vector2(
            _random.nextDouble() * gameSize.x,
            -10,
          ),
          velocity: Vector2(
            -10 + _random.nextDouble() * 20,
            30 + _random.nextDouble() * 50,
          ),
          color: Color.fromRGBO(255, 255, 255, 0.7 + _random.nextDouble() * 0.3),
          size: 2 + _random.nextDouble() * 4,
          lifetime: 5.0,
        ));
        break;
        
      case ParticleEffectType.leaves:
        _particles.add(_Particle(
          position: Vector2(
            gameSize.x + 10,
            _random.nextDouble() * gameSize.y,
          ),
          velocity: Vector2(
            -40 - _random.nextDouble() * 30,
            -10 + _random.nextDouble() * 20,
          ),
          color: Color.fromRGBO(34, 139, 34, 0.5 + _random.nextDouble() * 0.3),
          size: 3 + _random.nextDouble() * 4,
          lifetime: 3.0,
        ));
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }
}

/// Partícula individual
class _Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifetime;
  double age = 0.0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });

  bool get isDead => age >= lifetime;

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    
    // Fade out al final de la vida
    final fadeProgress = (age / lifetime).clamp(0.0, 1.0);
    color = color.withOpacity(color.opacity * (1.0 - fadeProgress));
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      size,
      paint,
    );
  }
}