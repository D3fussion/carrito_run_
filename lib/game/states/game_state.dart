import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class GameState extends ChangeNotifier {
  int _coins = 0;
  int _displayScore = 0;
  int _internalScore = 0;
  double _timeElapsed = 0.0;
  final double _displayScoreMultiplier = 10.0;

  // ============ SISTEMA DE VIDAS ============
  int _lives = 3;
  final int _maxLives = 3;
  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0.0;
  final double _invulnerabilityDuration = 2.0;
  
  int get lives => _lives;
  int get maxLives => _maxLives;
  bool get isInvulnerable => _isInvulnerable;
  bool get isGameOver => _lives <= 0;
  // =========================================

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // ============ SISTEMA DE GASOLINA BALANCEADO ============
  double _fuel = 100.0;
  final double _maxFuel = 100.0;
  
  // ⭐ BALANCEADO: Consumo reducido de 5.0 a 2.5 (dura el doble)
  double _fuelConsumptionRate = 2.5; // Era 5.0, ahora más lento
  final double _baseFuelConsumptionRate = 2.5;
  
  // Multiplicador de consumo de gasolina (para terrenos especiales)
  double _fuelMultiplier = 1.0;
  
  double get fuelConsumptionRate => _fuelConsumptionRate;
  double get fuelMultiplier => _fuelMultiplier;
  // ======================================================

  // Sistema de secciones
  int _currentSection = 1;
  int _nextGasStationScore = 50;
  final int _firstGasStation = 50;
  final int _gasStationInterval = 60;

  // Costo de gasolina
  int _refuelCost = 10;
  final int _baseCost = 10;
  final double _costMultiplier = 1.5;

  // Getters existentes
  int get coins => _coins;
  int get score => _displayScore;
  int get internalScore => _internalScore;
  double get timeElapsed => _timeElapsed;
  double get fuel => _fuel;
  double get maxFuel => _maxFuel;
  int get currentSection => _currentSection;
  int get refuelCost => _refuelCost;
  bool get isOutOfFuel => _fuel <= 0;
  int get nextGasStationScore => _nextGasStationScore;
  int get scoreUntilNextGasStation => _nextGasStationScore - _internalScore;

  bool shouldSpawnGasStation() {
    return _internalScore >= _nextGasStationScore;
  }

  void markGasStationSpawned() {
    _currentSection++;
    _nextGasStationScore =
        _firstGasStation + (_currentSection - 1) * _gasStationInterval;

    _refuelCost = (_baseCost * (_costMultiplier * (_currentSection - 1)))
        .toInt();
    if (_refuelCost < _baseCost) _refuelCost = _baseCost;

    _safeNotifyListeners();
  }

  void addCoin() {
    _coins++;
    _safeNotifyListeners();
  }

  void addScore(int points) {
    _displayScore += points;
    _safeNotifyListeners();
  }

  // ============ MÉTODOS PARA VIDAS ============
  
  void loseLife() {
    if (_isInvulnerable || _lives <= 0) return;
    
    _lives--;
    _activateInvulnerability();
    
    print('❤️ Vida perdida! Vidas restantes: $_lives');
    
    if (_lives <= 0) {
      _handleGameOver();
    }
    
    _safeNotifyListeners();
  }
  
  void _activateInvulnerability() {
    _isInvulnerable = true;
    _invulnerabilityTimer = _invulnerabilityDuration;
  }
  
  void _handleGameOver() {
    print('💀 GAME OVER - Sin vidas');
  }
  
  // ⭐ NUEVO: Ganar vida (power-up)
  void gainLife() {
    if (_lives < _maxLives) {
      _lives++;
      print('💚 ¡Vida extra! Vidas: $_lives');
      _safeNotifyListeners();
    }
  }
  
  void resetLives() {
    _lives = _maxLives;
    _isInvulnerable = false;
    _invulnerabilityTimer = 0.0;
    _safeNotifyListeners();
  }
  
  // ============ MÉTODOS PARA GASOLINA ============
  
  /// ⭐ NUEVO: Recargar gasolina parcialmente (power-up)
  void addFuel(double amount) {
    _fuel += amount;
    if (_fuel > _maxFuel) _fuel = _maxFuel;
    print('⛽ Gasolina recargada: +$amount (Total: ${_fuel.toStringAsFixed(1)})');
    _safeNotifyListeners();
  }
  
  /// Establece el multiplicador de consumo de gasolina (terrenos especiales)
  void setFuelMultiplier(double multiplier) {
    _fuelMultiplier = multiplier;
    _fuelConsumptionRate = _baseFuelConsumptionRate * _fuelMultiplier;
    _safeNotifyListeners();
  }
  
  /// Resetea el multiplicador de gasolina a normal
  void resetFuelMultiplier() {
    _fuelMultiplier = 1.0;
    _fuelConsumptionRate = _baseFuelConsumptionRate;
    _safeNotifyListeners();
  }
  
  // ============================================

  void updateTime(double dt) {
    _timeElapsed += dt;
    _internalScore = _timeElapsed.floor();
    _displayScore = (_timeElapsed * _displayScoreMultiplier).toInt();

    // Consumo de gasolina
    if (_fuel > 0) {
      _fuel -= _fuelConsumptionRate * dt;
      if (_fuel < 0) _fuel = 0;
    }
    
    // Actualizar invulnerabilidad
    if (_isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        _isInvulnerable = false;
        _invulnerabilityTimer = 0.0;
      }
    }

    _safeNotifyListeners();
  }

  bool canRefuel() {
    return _coins >= _refuelCost && _fuel < _maxFuel;
  }

  void refuel() {
    if (canRefuel()) {
      _coins -= _refuelCost;
      _fuel = _maxFuel;
      _safeNotifyListeners();
    }
  }

  void reset() {
    _isPlaying = false;
    _coins = 0;
    _displayScore = 0;
    _internalScore = 0;
    _timeElapsed = 0.0;
    _fuel = 100.0;
    _currentSection = 1;
    _nextGasStationScore = _firstGasStation;
    _refuelCost = _baseCost;
    
    // Reset vidas
    _lives = _maxLives;
    _isInvulnerable = false;
    _invulnerabilityTimer = 0.0;
    
    // Reset gasolina
    _fuelMultiplier = 1.0;
    _fuelConsumptionRate = _baseFuelConsumptionRate;
    
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    _safeNotifyListeners();
  }
}