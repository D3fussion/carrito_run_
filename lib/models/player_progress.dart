/// Modelo que representa el progreso completo del jugador
class PlayerProgress {
  final int currentCarId;              // Carrito actualmente seleccionado
  final Set<int> unlockedCarIds;       // IDs de carritos desbloqueados
  final int totalCoins;                // Monedas totales acumuladas
  final int highestSection;            // Sección más alta alcanzada
  final int highScore;                 // Puntuación más alta
  
  // Stats adicionales (opcionales)
  final int totalGamesPlayed;
  final int totalCoinsCollected;
  final int totalObstaclesAvoided;

  const PlayerProgress({
    this.currentCarId = 0,
    this.unlockedCarIds = const {0}, // Default car siempre desbloqueado
    this.totalCoins = 0,
    this.highestSection = 1,
    this.highScore = 0,
    this.totalGamesPlayed = 0,
    this.totalCoinsCollected = 0,
    this.totalObstaclesAvoided = 0,
  });

  /// Crea una copia con valores modificados
  PlayerProgress copyWith({
    int? currentCarId,
    Set<int>? unlockedCarIds,
    int? totalCoins,
    int? highestSection,
    int? highScore,
    int? totalGamesPlayed,
    int? totalCoinsCollected,
    int? totalObstaclesAvoided,
  }) {
    return PlayerProgress(
      currentCarId: currentCarId ?? this.currentCarId,
      unlockedCarIds: unlockedCarIds ?? this.unlockedCarIds,
      totalCoins: totalCoins ?? this.totalCoins,
      highestSection: highestSection ?? this.highestSection,
      highScore: highScore ?? this.highScore,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalCoinsCollected: totalCoinsCollected ?? this.totalCoinsCollected,
      totalObstaclesAvoided: totalObstaclesAvoided ?? this.totalObstaclesAvoided,
    );
  }

  /// Desbloquea un carrito y resta las monedas
  PlayerProgress unlockCar(int carId, int price) {
    final newUnlocked = Set<int>.from(unlockedCarIds)..add(carId);
    return copyWith(
      unlockedCarIds: newUnlocked,
      totalCoins: totalCoins - price,
    );
  }

  /// Selecciona un carrito (debe estar desbloqueado)
  PlayerProgress selectCar(int carId) {
    if (!unlockedCarIds.contains(carId)) {
      throw Exception('Cannot select locked car');
    }
    return copyWith(currentCarId: carId);
  }

  /// Actualiza después de terminar un juego
  PlayerProgress updateAfterGame({
    required int coinsEarned,
    required int sectionReached,
    required int finalScore,
  }) {
    return copyWith(
      totalCoins: totalCoins + coinsEarned,
      totalCoinsCollected: totalCoinsCollected + coinsEarned,
      highestSection: sectionReached > highestSection ? sectionReached : highestSection,
      highScore: finalScore > highScore ? finalScore : highScore,
      totalGamesPlayed: totalGamesPlayed + 1,
    );
  }

  /// Verifica si un carrito está desbloqueado
  bool isCarUnlocked(int carId) => unlockedCarIds.contains(carId);

  /// Progreso del jugador (0.0 - 1.0)
  double get overallProgress {
    return unlockedCarIds.length / 16.0; // 16 carritos totales
  }

  /// Serialización para guardado
  Map<String, dynamic> toJson() => {
    'currentCarId': currentCarId,
    'unlockedCarIds': unlockedCarIds.toList(),
    'totalCoins': totalCoins,
    'highestSection': highestSection,
    'highScore': highScore,
    'totalGamesPlayed': totalGamesPlayed,
    'totalCoinsCollected': totalCoinsCollected,
    'totalObstaclesAvoided': totalObstaclesAvoided,
  };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      currentCarId: json['currentCarId'] as int? ?? 0,
      unlockedCarIds: (json['unlockedCarIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toSet() ?? const {0},
      totalCoins: json['totalCoins'] as int? ?? 0,
      highestSection: json['highestSection'] as int? ?? 1,
      highScore: json['highScore'] as int? ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalCoinsCollected: json['totalCoinsCollected'] as int? ?? 0,
      totalObstaclesAvoided: json['totalObstaclesAvoided'] as int? ?? 0,
    );
  }

  /// Estado inicial (nuevo jugador)
  static const PlayerProgress initial = PlayerProgress();
}