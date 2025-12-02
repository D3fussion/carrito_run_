import 'package:flutter/foundation.dart';
import 'package:carrito_run/models/car_data.dart';
import 'package:carrito_run/models/player_progress.dart';
import 'package:carrito_run/services/storage_service.dart';

/// Gestor centralizado de carritos y progreso del jugador
class CarManager extends ChangeNotifier {
  final StorageService _storageService;
  
  PlayerProgress _progress = PlayerProgress.initial;
  bool _isInitialized = false;

  CarManager(this._storageService);

  // ============ GETTERS ============
  
  PlayerProgress get progress => _progress;
  bool get isInitialized => _isInitialized;
  
  /// Carrito actualmente seleccionado
  CarData get currentCar {
    return CarsDatabase.getCarById(_progress.currentCarId) ?? CarsDatabase.defaultCar;
  }
  
  /// Lista de todos los carritos
  List<CarData> get allCars => CarsDatabase.allCars;
  
  /// Carritos desbloqueados
  List<CarData> get unlockedCars {
    return allCars.where((car) => _progress.isCarUnlocked(car.id)).toList();
  }
  
  /// Carritos bloqueados
  List<CarData> get lockedCars {
    return allCars.where((car) => !_progress.isCarUnlocked(car.id)).toList();
  }
  
  /// Monedas totales
  int get totalCoins => _progress.totalCoins;
  
  /// Sección más alta alcanzada
  int get highestSection => _progress.highestSection;
  
  /// Puntuación más alta
  int get highScore => _progress.highScore;
  
  /// Progreso total (0.0 - 1.0)
  double get overallProgress => _progress.overallProgress;

  // ============ INICIALIZACIÓN ============
  
  /// Inicializa el manager y carga el progreso guardado
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _storageService.initialize();
      _progress = await _storageService.loadProgress();
      _isInitialized = true;
      
      print('🚗 CarManager inicializado: ${_progress.unlockedCarIds.length} carritos desbloqueados');
      notifyListeners();
    } catch (e) {
      print('❌ Error inicializando CarManager: $e');
      _progress = PlayerProgress.initial;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============ GESTIÓN DE CARRITOS ============
  
  /// Verifica si un carrito está desbloqueado
  bool isCarUnlocked(int carId) {
    return _progress.isCarUnlocked(carId);
  }
  
  /// Verifica si un carrito puede ser desbloqueado
  bool canUnlockCar(int carId) {
    final car = CarsDatabase.getCarById(carId);
    if (car == null) return false;
    
    return car.canUnlock(
      currentSection: _progress.highestSection,
      unlockedCarIds: _progress.unlockedCarIds,
      currentCoins: _progress.totalCoins,
    );
  }
  
  /// Desbloquea un carrito (si se cumplen los requisitos)
  Future<bool> unlockCar(int carId) async {
    final car = CarsDatabase.getCarById(carId);
    if (car == null) {
      print('❌ Carrito $carId no encontrado');
      return false;
    }
    
    // Verificar si ya está desbloqueado
    if (_progress.isCarUnlocked(carId)) {
      print('⚠️ Carrito $carId ya está desbloqueado');
      return false;
    }
    
    // Verificar requisitos
    if (!canUnlockCar(carId)) {
      print('❌ No se cumplen los requisitos para desbloquear ${car.name}');
      return false;
    }
    
    // Desbloquear y restar monedas
    _progress = _progress.unlockCar(carId, car.price);
    await _save();
    
    print('✅ Carrito ${car.name} desbloqueado! (${car.price} monedas)');
    notifyListeners();
    return true;
  }
  
  /// Selecciona un carrito (debe estar desbloqueado)
  Future<bool> selectCar(int carId) async {
    if (!_progress.isCarUnlocked(carId)) {
      print('❌ No puedes seleccionar un carrito bloqueado');
      return false;
    }
    
    _progress = _progress.selectCar(carId);
    await _save();
    
    final car = CarsDatabase.getCarById(carId);
    print('🚗 Carrito seleccionado: ${car?.name}');
    notifyListeners();
    return true;
  }
  
  /// Obtiene el mensaje de requisitos para un carrito
  String getRequirementMessage(int carId) {
    final car = CarsDatabase.getCarById(carId);
    if (car == null) return 'Carrito no encontrado';
    
    return car.getRequirementMessage(
      currentSection: _progress.highestSection,
      unlockedCarIds: _progress.unlockedCarIds,
      currentCoins: _progress.totalCoins,
    );
  }
  
  /// Obtiene todos los carritos de una sección específica
  List<CarData> getCarsBySection(int section) {
    return CarsDatabase.getCarsBySection(section);
  }

  // ============ ACTUALIZACIÓN DE PROGRESO ============
  
  /// Actualiza el progreso después de un juego
  Future<void> updateAfterGame({
    required int coinsEarned,
    required int sectionReached,
    required int finalScore,
  }) async {
    _progress = _progress.updateAfterGame(
      coinsEarned: coinsEarned,
      sectionReached: sectionReached,
      finalScore: finalScore,
    );
    
    await _save();
    
    print('📊 Progreso actualizado:');
    print('  • Monedas ganadas: $coinsEarned (Total: ${_progress.totalCoins})');
    print('  • Sección alcanzada: $sectionReached');
    print('  • Puntuación: $finalScore (Récord: ${_progress.highScore})');
    
    notifyListeners();
  }
  
  /// Añade monedas (para testing o recompensas)
  Future<void> addCoins(int amount) async {
    _progress = _progress.copyWith(
      totalCoins: _progress.totalCoins + amount,
    );
    await _save();
    notifyListeners();
  }
  
  /// Actualiza la sección más alta
  Future<void> updateHighestSection(int section) async {
    if (section > _progress.highestSection) {
      _progress = _progress.copyWith(highestSection: section);
      await _save();
      notifyListeners();
    }
  }

  // ============ GUARDADO ============
  
  /// Guarda el progreso actual
  Future<void> _save() async {
    try {
      await _storageService.saveProgress(_progress);
    } catch (e) {
      print('❌ Error al guardar progreso: $e');
    }
  }
  
  /// Fuerza un guardado manual (útil para testing)
  Future<void> forceSave() async {
    await _save();
    print('💾 Progreso guardado manualmente');
  }

  // ============ RESET ============
  
  /// Resetea todo el progreso (¡CUIDADO!)
  Future<void> resetProgress() async {
    try {
      await _storageService.clearProgress();
      _progress = PlayerProgress.initial;
      notifyListeners();
      print('🗑️ Progreso reseteado completamente');
    } catch (e) {
      print('❌ Error al resetear progreso: $e');
    }
  }

  // ============ DEBUGGING / TESTING ============
  
  /// Desbloquea todos los carritos (para testing)
  Future<void> unlockAllCars() async {
    final allIds = allCars.map((car) => car.id).toSet();
    _progress = _progress.copyWith(unlockedCarIds: allIds);
    await _save();
    print('🔓 Todos los carritos desbloqueados (modo testing)');
    notifyListeners();
  }
  
  /// Da monedas ilimitadas (para testing)
  Future<void> giveUnlimitedCoins() async {
    _progress = _progress.copyWith(totalCoins: 999999);
    await _save();
    print('💰 Monedas ilimitadas activadas (modo testing)');
    notifyListeners();
  }
  
  /// Exporta el progreso como JSON
  Future<String?> exportProgress() async {
    return await _storageService.exportProgress();
  }
  
  /// Importa progreso desde JSON
  Future<bool> importProgress(String json) async {
    final success = await _storageService.importProgress(json);
    if (success) {
      _progress = await _storageService.loadProgress();
      notifyListeners();
    }
    return success;
  }
}