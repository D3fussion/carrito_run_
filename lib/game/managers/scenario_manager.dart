import 'package:carrito_run/models/scenario_config.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/components/particle_effect_component.dart';
import 'package:flame/components.dart';

/// Gestor que coordina las mecánicas específicas de cada escenario
class ScenarioManager extends Component with HasGameReference {
  final GameState gameState;
  
  ScenarioConfig _currentScenario;
  int _currentScenarioId = 0;
  
  // Efectos temporales activos
  bool _hasAntiSlipEffect = false;
  double _antiSlipTimer = 0.0;
  
  bool _hasMudRemovalEffect = false;
  double _mudRemovalTimer = 0.0;
  
  // ⭐ NUEVO: Sistema de partículas
  ParticleEffectComponent? _particleEffect;

  ScenarioManager({
    required this.gameState,
    int initialScenarioId = 0,
  }) : _currentScenario = ScenariosDatabase.getScenarioById(initialScenarioId) {
    _currentScenarioId = initialScenarioId;
  }

  ScenarioConfig get currentScenario => _currentScenario;
  int get currentScenarioId => _currentScenarioId;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Actualizar timers de efectos temporales
    if (_hasAntiSlipEffect) {
      _antiSlipTimer -= dt;
      if (_antiSlipTimer <= 0) {
        _hasAntiSlipEffect = false;
        print('❄️ Efecto antideslizante terminado');
      }
    }
    
    if (_hasMudRemovalEffect) {
      _mudRemovalTimer -= dt;
      if (_mudRemovalTimer <= 0) {
        _hasMudRemovalEffect = false;
        print('🌲 Efecto de limpieza de lodo terminado');
      }
    }
  }

  /// Cambia al escenario de una sección específica
  void changeToSection(int section) {
    final newScenario = ScenariosDatabase.getScenarioForSection(section);
    
    if (newScenario.id != _currentScenarioId) {
      _currentScenario = newScenario;
      _currentScenarioId = newScenario.id;
      
      print('🎬 Cambio de escenario: ${_currentScenario.name}');
      _applyScenarioEffects();
    }
  }

  /// Aplica los efectos del escenario actual
  void _applyScenarioEffects() {
    // Resetear multiplicador de gasolina
    gameState.resetFuelMultiplier();
    
    // ⭐ NUEVO: Remover partículas anteriores
    _particleEffect?.removeFromParent();
    _particleEffect = null;
    
    // Aplicar efectos según el escenario
    switch (_currentScenario.id) {
      case 0: // Desierto
        print('🏜️ Desierto: Arena en carriles laterales (x3 gasolina)');
        _addParticleEffect(ParticleEffectType.dust);
        break;
      case 1: // Ciudad
        print('🌆 Ciudad: Velocidad aumentada (+10%)');
        // Partículas de neón o luces (opcional)
        break;
      case 2: // Bosque
        print('🌲 Bosque: Lodo en carriles extremos');
        _addParticleEffect(ParticleEffectType.leaves);
        break;
      case 3: // Nieve
        print('❄️ Nieve: Hielo resbaladizo en todos los carriles');
        _addParticleEffect(ParticleEffectType.snow);
        break;
      case 4: // Lluvia
        print('🌧️ Lluvia: Charcos aleatorios y poca visibilidad');
        _addParticleEffect(ParticleEffectType.rain);
        break;
    }
  }
  
  /// ⭐ NUEVO: Agregar sistema de partículas
  void _addParticleEffect(ParticleEffectType effectType) {
    _particleEffect = ParticleEffectComponent(effectType: effectType);
    game.add(_particleEffect!);
    print('✨ Partículas activadas: $effectType');
  }

  /// Verifica si un carril tiene terreno especial
  bool isLaneAffected(int lane) {
    return _currentScenario.isLaneAffected(lane);
  }

  /// Obtiene el multiplicador de gasolina para un carril
  double getFuelMultiplierForLane(int lane) {
    // Si tiene efecto especial activo, ignorar terreno
    if (_currentScenario.id == 0 && _hasMudRemovalEffect) {
      return 1.0; // Botella de agua en desierto
    }
    
    if (_currentScenario.isLaneAffected(lane)) {
      return _currentScenario.fuelMultiplierOnSides;
    }
    return 1.0;
  }

  /// Activa el efecto antideslizante (Nieve)
  void activateAntiSlipEffect(double duration) {
    _hasAntiSlipEffect = true;
    _antiSlipTimer = duration;
    print('❄️ Llanta antideslizante activada ($duration seg)');
  }

  /// Activa el efecto de limpieza de lodo/arena (Desierto/Bosque)
  void activateMudRemovalEffect(double duration) {
    _hasMudRemovalEffect = true;
    _mudRemovalTimer = duration;
    
    // Restaurar multiplicador normal mientras dure
    gameState.resetFuelMultiplier();
    
    print('💧 Efecto de limpieza activado ($duration seg)');
  }

  /// Verifica si el carrito tiene control antideslizante activo
  bool get hasAntiSlipControl => _hasAntiSlipEffect;

  /// Verifica si tiene protección contra terreno
  bool get hasTerrainProtection => _hasMudRemovalEffect;

  /// Obtiene el tipo de terreno en los lados
  TerrainType get sideTerrainType => _currentScenario.sideTerrainType;

  /// Aplica el efecto de un power-up especial del escenario
  void applySpecialPowerUp() {
    switch (_currentScenario.id) {
      case 0: // Desierto - Botella de agua
        activateMudRemovalEffect(10.0); // 10 segundos
        break;
      case 1: // Ciudad - Chip magnético
        print('🧲 Chip magnético: Atrae monedas (no implementado aún)');
        // TODO: Implementar atracción de monedas
        break;
      case 2: // Bosque - Miel energética
        print('🍯 Miel energética: Acelera y quita lodo');
        activateMudRemovalEffect(5.0);
        // TODO: Aumentar velocidad temporalmente
        break;
      case 3: // Nieve - Llanta antideslizante
        activateAntiSlipEffect(8.0); // 8 segundos
        break;
      case 4: // Lluvia - Limpiaparabrisas
        print('🌧️ Limpiaparabrisas: Elimina efectos de lluvia');
        // TODO: Mejorar visibilidad temporalmente
        break;
    }
  }

  /// Obtiene la ruta del sprite de obstáculo saltable aleatorio
  String getRandomJumpableObstacle() {
    if (_currentScenario.jumpableObstacles.isEmpty) {
      return 'obstacle_jumpable.png'; // Fallback
    }
    final index = (DateTime.now().millisecondsSinceEpoch % 
        _currentScenario.jumpableObstacles.length);
    return _currentScenario.jumpableObstacles[index];
  }

  /// Obtiene la ruta del sprite de obstáculo no saltable aleatorio
  String getRandomNonJumpableObstacle() {
    if (_currentScenario.nonJumpableObstacles.isEmpty) {
      return 'obstacle_nonjumpable.png'; // Fallback
    }
    final index = (DateTime.now().millisecondsSinceEpoch % 
        _currentScenario.nonJumpableObstacles.length);
    return _currentScenario.nonJumpableObstacles[index];
  }

  /// Resetea el manager al escenario inicial
  void reset() {
    _currentScenarioId = 0;
    _currentScenario = ScenariosDatabase.getScenarioById(0);
    _hasAntiSlipEffect = false;
    _antiSlipTimer = 0.0;
    _hasMudRemovalEffect = false;
    _mudRemovalTimer = 0.0;
    gameState.resetFuelMultiplier();
    
    // ⭐ NUEVO: Limpiar partículas
    _particleEffect?.removeFromParent();
    _particleEffect = null;
  }
}