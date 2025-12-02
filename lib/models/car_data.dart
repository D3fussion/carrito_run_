/// Modelo de datos para un carrito individual
class CarData {
  final int id;                    // ID único (0-15)
  final String name;               // Nombre del carrito
  final String description;        // Descripción corta
  final int sectionGroup;          // Grupo de sección (0-5)
  final int price;                 // Precio en monedas (0 = gratis)
  final int requiredSection;       // Sección mínima requerida
  final List<int> requiredCarIds;  // IDs de carritos previos requeridos
  
  // Características del carrito (para balance futuro)
  final double speedMultiplier;    // Multiplicador de velocidad (1.0 = normal)
  final double fuelEfficiency;     // Eficiencia de gasolina (1.0 = normal, 0.8 = mejor)
  
  const CarData({
    required this.id,
    required this.name,
    required this.description,
    required this.sectionGroup,
    this.price = 0,
    this.requiredSection = 1,
    this.requiredCarIds = const [],
    this.speedMultiplier = 1.0,
    this.fuelEfficiency = 1.0,
  });

  /// Ruta del sprite landscape para este carrito
  String get spritePathLandscape => 'cars/car_${id}_landscape.png';
  
  /// Ruta del sprite portrait para este carrito
  String get spritePathPortrait => 'cars/car_${id}_portrait.png';
  
  /// Si es el carrito por defecto (gratuito)
  bool get isDefault => id == 0;

  /// Verifica si el jugador cumple los requisitos para desbloquear este carrito
  bool canUnlock({
    required int currentSection,
    required Set<int> unlockedCarIds,
    required int currentCoins,
  }) {
    // El default siempre está desbloqueado
    if (isDefault) return true;
    
    // Verificar sección mínima
    if (currentSection < requiredSection) return false;
    
    // Verificar carritos previos requeridos
    for (final requiredId in requiredCarIds) {
      if (!unlockedCarIds.contains(requiredId)) return false;
    }
    
    // Verificar monedas
    if (currentCoins < price) return false;
    
    return true;
  }

  /// Mensaje de requisito no cumplido
  String getRequirementMessage({
    required int currentSection,
    required Set<int> unlockedCarIds,
    required int currentCoins,
  }) {
    if (currentSection < requiredSection) {
      return 'Alcanza la sección $requiredSection';
    }
    
    for (final requiredId in requiredCarIds) {
      if (!unlockedCarIds.contains(requiredId)) {
        return 'Desbloquea todos los carritos anteriores';
      }
    }
    
    if (currentCoins < price) {
      final needed = price - currentCoins;
      return 'Te faltan $needed monedas';
    }
    
    return 'Cumple todos los requisitos';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'sectionGroup': sectionGroup,
    'price': price,
    'requiredSection': requiredSection,
    'requiredCarIds': requiredCarIds,
    'speedMultiplier': speedMultiplier,
    'fuelEfficiency': fuelEfficiency,
  };

  factory CarData.fromJson(Map<String, dynamic> json) => CarData(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String,
    sectionGroup: json['sectionGroup'] as int,
    price: json['price'] as int? ?? 0,
    requiredSection: json['requiredSection'] as int? ?? 1,
    requiredCarIds: (json['requiredCarIds'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList() ?? const [],
    speedMultiplier: json['speedMultiplier'] as double? ?? 1.0,
    fuelEfficiency: json['fuelEfficiency'] as double? ?? 1.0,
  );
}

/// Base de datos de todos los carritos disponibles
class CarsDatabase {
  static const List<CarData> allCars = [
    // ========== SECCIÓN 0: DEFAULT (1 carrito) ==========
    CarData(
      id: 0,
      name: 'Carrito Clásico',
      description: 'Tu primer vehículo. Confiable y equilibrado.',
      sectionGroup: 0,
      price: 0,
      requiredSection: 1,
      speedMultiplier: 1.0,
      fuelEfficiency: 1.0,
    ),

    // ========== SECCIÓN 1: DESIERTO (3 carritos) ==========
    CarData(
      id: 1,
      name: 'Todoterreno Arena',
      description: 'Perfecto para el desierto. Eficiente en arena.',
      sectionGroup: 1,
      price: 100,
      requiredSection: 2,
      requiredCarIds: [],
      speedMultiplier: 1.0,
      fuelEfficiency: 0.95, // 5% mejor consumo
    ),
    CarData(
      id: 2,
      name: 'Buggy Rápido',
      description: 'Más veloz pero consume más gasolina.',
      sectionGroup: 1,
      price: 150,
      requiredSection: 2,
      requiredCarIds: [],
      speedMultiplier: 1.1, // 10% más rápido
      fuelEfficiency: 1.05, // 5% peor consumo
    ),
    CarData(
      id: 3,
      name: 'Camioneta Resistente',
      description: 'Lento pero muy eficiente con el combustible.',
      sectionGroup: 1,
      price: 200,
      requiredSection: 2,
      requiredCarIds: [],
      speedMultiplier: 0.95, // 5% más lento
      fuelEfficiency: 0.85, // 15% mejor consumo
    ),

    // ========== SECCIÓN 2: CIUDAD (3 carritos) ==========
    CarData(
      id: 4,
      name: 'Deportivo Urbano',
      description: 'Ágil en la ciudad. Gran aceleración.',
      sectionGroup: 2,
      price: 250,
      requiredSection: 4,
      requiredCarIds: [1, 2, 3], // Todos los de sección 1
      speedMultiplier: 1.15,
      fuelEfficiency: 1.0,
    ),
    CarData(
      id: 5,
      name: 'Taxi Eléctrico',
      description: 'Eficiente y ecológico. Ahorra combustible.',
      sectionGroup: 2,
      price: 300,
      requiredSection: 4,
      requiredCarIds: [1, 2, 3],
      speedMultiplier: 1.0,
      fuelEfficiency: 0.80, // 20% mejor consumo
    ),
    CarData(
      id: 6,
      name: 'Muscle Car',
      description: 'Potencia bruta. El más rápido hasta ahora.',
      sectionGroup: 2,
      price: 350,
      requiredSection: 4,
      requiredCarIds: [1, 2, 3],
      speedMultiplier: 1.2, // 20% más rápido
      fuelEfficiency: 1.1, // 10% peor consumo
    ),

    // ========== SECCIÓN 3: BOSQUE (3 carritos) ==========
    CarData(
      id: 7,
      name: 'Jeep Explorador',
      description: 'Ideal para terrenos irregulares del bosque.',
      sectionGroup: 3,
      price: 400,
      requiredSection: 6,
      requiredCarIds: [4, 5, 6],
      speedMultiplier: 1.0,
      fuelEfficiency: 0.90,
    ),
    CarData(
      id: 8,
      name: 'Rally Cross',
      description: 'Balance perfecto entre velocidad y eficiencia.',
      sectionGroup: 3,
      price: 450,
      requiredSection: 6,
      requiredCarIds: [4, 5, 6],
      speedMultiplier: 1.1,
      fuelEfficiency: 0.95,
    ),
    CarData(
      id: 9,
      name: 'Monster Truck',
      description: 'Imparable. Consume más pero vale la pena.',
      sectionGroup: 3,
      price: 500,
      requiredSection: 6,
      requiredCarIds: [4, 5, 6],
      speedMultiplier: 1.05,
      fuelEfficiency: 1.15,
    ),

    // ========== SECCIÓN 4: NIEVE (3 carritos) ==========
    CarData(
      id: 10,
      name: 'Snowmobile',
      description: 'Diseñado para la nieve. Muy eficiente.',
      sectionGroup: 4,
      price: 550,
      requiredSection: 8,
      requiredCarIds: [7, 8, 9],
      speedMultiplier: 1.0,
      fuelEfficiency: 0.85,
    ),
    CarData(
      id: 11,
      name: 'Vehículo Polar',
      description: 'Equilibrado para condiciones extremas.',
      sectionGroup: 4,
      price: 600,
      requiredSection: 8,
      requiredCarIds: [7, 8, 9],
      speedMultiplier: 1.08,
      fuelEfficiency: 0.90,
    ),
    CarData(
      id: 12,
      name: 'Tanque de Hielo',
      description: 'Lento pero increíblemente eficiente.',
      sectionGroup: 4,
      price: 650,
      requiredSection: 8,
      requiredCarIds: [7, 8, 9],
      speedMultiplier: 0.90,
      fuelEfficiency: 0.75, // 25% mejor consumo
    ),

    // ========== SECCIÓN 5: LLUVIA NOCTURNA (3 carritos) ==========
    CarData(
      id: 13,
      name: 'Coche de Carreras',
      description: 'Velocidad máxima. Para expertos.',
      sectionGroup: 5,
      price: 700,
      requiredSection: 10,
      requiredCarIds: [10, 11, 12],
      speedMultiplier: 1.25, // 25% más rápido
      fuelEfficiency: 1.05,
    ),
    CarData(
      id: 14,
      name: 'Hypercar Futurista',
      description: 'Tecnología de punta. Rápido y eficiente.',
      sectionGroup: 5,
      price: 800,
      requiredSection: 10,
      requiredCarIds: [10, 11, 12],
      speedMultiplier: 1.15,
      fuelEfficiency: 0.85,
    ),
    CarData(
      id: 15,
      name: 'Vehículo Legendario',
      description: 'El mejor de todos. Perfección absoluta.',
      sectionGroup: 5,
      price: 1000,
      requiredSection: 10,
      requiredCarIds: [10, 11, 12],
      speedMultiplier: 1.2,
      fuelEfficiency: 0.80,
    ),
  ];

  /// Obtiene un carrito por su ID
  static CarData? getCarById(int id) {
    try {
      return allCars.firstWhere((car) => car.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todos los carritos de una sección
  static List<CarData> getCarsBySection(int section) {
    return allCars.where((car) => car.sectionGroup == section).toList();
  }

  /// Obtiene el carrito por defecto
  static CarData get defaultCar => allCars[0];
}