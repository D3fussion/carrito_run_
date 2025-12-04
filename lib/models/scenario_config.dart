import 'package:flutter/material.dart';

/// Tipos de terreno especial
enum TerrainType {
  normal,       // Sin efecto
  sand,         // Arena - consume x3 gasolina
  slowMud,      // Lodo - reduce velocidad
  ice,          // Hielo - derrape
  puddle,       // Charco - pérdida de control
}

/// Tipos de obstáculos dinámicos
enum DynamicObstacleType {
  deer,         // Venado que cruza
  snowball,     // Bola de nieve rodante
  drone,        // Drone que pasa
}

/// Configuración completa de un escenario
class ScenarioConfig {
  final int id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  
  // Mecánicas del escenario
  final double fuelMultiplierOnSides;  // Multiplicador en carriles laterales
  final List<int> affectedLanes;       // Carriles afectados por terreno
  final TerrainType sideTerrainType;   // Tipo de terreno en lados
  
  // Obstáculos especiales
  final List<String> jumpableObstacles;     // Rutas de sprites saltables
  final List<String> nonJumpableObstacles;  // Rutas de sprites no saltables
  final List<DynamicObstacleType> dynamicObstacles;
  
  // Power-ups especiales
  final String? specialPowerUpSprite;
  final String? specialPowerUpName;
  
  // Efectos visuales
  final bool hasParticles;
  final String? particleType;
  
  // Dificultad
  final double speedMultiplier;        // 1.0 = normal, 1.1 = 10% más rápido

  const ScenarioConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.fuelMultiplierOnSides = 1.0,
    this.affectedLanes = const [0, 4], // Por defecto, carriles externos
    this.sideTerrainType = TerrainType.normal,
    this.jumpableObstacles = const [],
    this.nonJumpableObstacles = const [],
    this.dynamicObstacles = const [],
    this.specialPowerUpSprite,
    this.specialPowerUpName,
    this.hasParticles = false,
    this.particleType,
    this.speedMultiplier = 1.0,
  });

  /// Verifica si un carril está afectado por el terreno especial
  bool isLaneAffected(int lane) => affectedLanes.contains(lane);
}

/// Base de datos de configuraciones de escenarios
class ScenariosDatabase {
  static const List<ScenarioConfig> allScenarios = [
    // ========== ESCENARIO 0: DESIERTO ==========
    ScenarioConfig(
      id: 0,
      name: 'Desierto',
      description: 'Calor extremo. La arena consume más gasolina.',
      primaryColor: Color(0xFFD2691E), // Marrón arena
      secondaryColor: Color(0xFFF4A460), // Arena clara
      fuelMultiplierOnSides: 3.0, // ⚠️ x3 consumo en arena
      affectedLanes: [0, 1, 3, 4], // Solo carril central (2) es seguro
      sideTerrainType: TerrainType.sand,
      jumpableObstacles: [
        'escenarios/desierto/obstaculo_cactus.png',
      ],
      nonJumpableObstacles: [
        'escenarios/desierto/obstaculo_roca.png',
      ],
      specialPowerUpSprite: 'escenarios/desierto/item_botella_agua.png',
      specialPowerUpName: 'Botella de Agua',
      hasParticles: true,
      particleType: 'dust', // Polvo
      speedMultiplier: 1.0,
    ),

    // ========== ESCENARIO 1: CIUDAD FUTURISTA ==========
    ScenarioConfig(
      id: 1,
      name: 'Ciudad Futurista',
      description: 'Luces neón y tráfico rápido.',
      primaryColor: Color(0xFF00FFFF), // Cyan neón
      secondaryColor: Color(0xFFFF1493), // Rosa neón
      fuelMultiplierOnSides: 1.0, // Sin penalización
      affectedLanes: [],
      sideTerrainType: TerrainType.normal,
      jumpableObstacles: [
        'escenarios/ciudad/obstaculo_drone.png',
      ],
      nonJumpableObstacles: [
        'escenarios/ciudad/obstaculo_auto.png',
      ],
      dynamicObstacles: [DynamicObstacleType.drone],
      specialPowerUpSprite: 'escenarios/ciudad/item_chip_magnetico.png',
      specialPowerUpName: 'Chip Magnético',
      hasParticles: true,
      particleType: 'neon', // Luces neón
      speedMultiplier: 1.1, // 10% más rápido
    ),

    // ========== ESCENARIO 2: BOSQUE ==========
    ScenarioConfig(
      id: 2,
      name: 'Bosque',
      description: 'Caminos irregulares. Cuidado con los animales.',
      primaryColor: Color(0xFF228B22), // Verde bosque
      secondaryColor: Color(0xFF8B4513), // Marrón madera
      fuelMultiplierOnSides: 1.2, // Lodo consume un poco más
      affectedLanes: [0, 4], // Solo carriles extremos con lodo
      sideTerrainType: TerrainType.slowMud,
      jumpableObstacles: [
        'escenarios/bosque/obstaculo_tronco.png',
      ],
      nonJumpableObstacles: [
        'escenarios/bosque/obstaculo_arbol.png',
      ],
      dynamicObstacles: [DynamicObstacleType.deer],
      specialPowerUpSprite: 'escenarios/bosque/item_miel.png',
      specialPowerUpName: 'Miel Energética',
      hasParticles: true,
      particleType: 'leaves', // Hojas cayendo
      speedMultiplier: 0.95, // 5% más lento (terreno irregular)
    ),

    // ========== ESCENARIO 3: NIEVE/GLACIAR ==========
    ScenarioConfig(
      id: 3,
      name: 'Glaciar',
      description: 'Hielo resbaladizo. Controla el derrape.',
      primaryColor: Color(0xFFE0FFFF), // Azul hielo claro
      secondaryColor: Color(0xFF4682B4), // Azul acero
      fuelMultiplierOnSides: 1.0,
      affectedLanes: [0, 1, 2, 3, 4], // ¡TODO es hielo!
      sideTerrainType: TerrainType.ice,
      jumpableObstacles: [
        'escenarios/nieve/obstaculo_nieve.png',
      ],
      nonJumpableObstacles: [
        'escenarios/nieve/obstaculo_hielo.png',
      ],
      dynamicObstacles: [DynamicObstacleType.snowball],
      specialPowerUpSprite: 'escenarios/nieve/item_llanta_antideslizante.png',
      specialPowerUpName: 'Llanta Antideslizante',
      hasParticles: true,
      particleType: 'snow', // Nieve cayendo
      speedMultiplier: 1.0,
    ),

    // ========== ESCENARIO 4: LLUVIA NOCTURNA ==========
    ScenarioConfig(
      id: 4,
      name: 'Lluvia Nocturna',
      description: 'Tormenta y relámpagos. Evita los charcos.',
      primaryColor: Color(0xFF191970), // Azul medianoche
      secondaryColor: Color(0xFF4169E1), // Azul real
      fuelMultiplierOnSides: 1.0,
      affectedLanes: [], // Los charcos aparecen aleatoriamente
      sideTerrainType: TerrainType.puddle,
      jumpableObstacles: [
        'escenarios/lluvia_nocturna/obstaculo_charco.png',
      ],
      nonJumpableObstacles: [
        'escenarios/lluvia_nocturna/obstaculo_poste.png',
      ],
      specialPowerUpSprite: 'escenarios/lluvia_nocturna/item_limpiaparabrisas.png',
      specialPowerUpName: 'Limpiaparabrisas Turbo',
      hasParticles: true,
      particleType: 'rain', // Lluvia
      speedMultiplier: 1.0,
    ),
  ];

  /// Obtiene un escenario por su ID
  static ScenarioConfig getScenarioById(int id) {
    if (id < 0 || id >= allScenarios.length) {
      return allScenarios[0]; // Default: Desierto
    }
    return allScenarios[id];
  }

  /// Obtiene el escenario para una sección del juego
  static ScenarioConfig getScenarioForSection(int section) {
    // Secciones 1-2 = Desierto (0)
    // Secciones 3-4 = Ciudad (1)
    // Secciones 5-6 = Bosque (2)
    // Secciones 7-8 = Nieve (3)
    // Secciones 9+ = Lluvia (4)
    
    if (section <= 2) return allScenarios[0];
    if (section <= 4) return allScenarios[1];
    if (section <= 6) return allScenarios[2];
    if (section <= 8) return allScenarios[3];
    return allScenarios[4];
  }

  /// Nombre del escenario por ID
  static String getScenarioName(int id) {
    return getScenarioById(id).name;
  }
}