import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class GameState extends ChangeNotifier {
  // --- VARIABLES ---
  int _coins = 0;
  int _displayScore = 0;
  int _internalScore = 0;
  double _timeElapsed = 0.0;
  final double _displayScoreMultiplier = 10.0;

  // Estado del Juego
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isOffRoad = false; // Para el desierto

  // Sistema de Gasolina
  double _fuel = 100.0;
  final double _maxFuel = 100.0;
  // Consumo ajustado para que dure la sección + margen
  final double _fuelConsumptionRate = 1.15;
  final double _collisionDamage = 30.0;
  final double _smallFuelRecovery = 15.0;

  // Sistema de Secciones
  int _currentSection = 1;
  int _nextGasStationScore = 50;
  final int _firstGasStation = 50;
  final int _gasStationInterval = 60;

  // Costo de Gasolina
  int _refuelCost = 10;
  final int _baseCost = 10;
  final double _costMultiplier = 1.5;

  // Velocidad
  final double _baseSpeed = 400.0;
  final double _maxSpeed = 1000.0;
  final int _maxSpeedSection = 11;

  // --- GETTERS ---
  int get coins => _coins;
  int get score => _displayScore;
  int get internalScore => _internalScore;
  double get timeElapsed => _timeElapsed;
  double get fuel => _fuel;
  double get maxFuel => _maxFuel;
  int get currentSection => _currentSection;
  int get refuelCost => _refuelCost;
  bool get isOutOfFuel => _fuel <= 0;
  bool get isPlaying => _isPlaying;
  bool get isGameOver => _isGameOver;
  int get nextGasStationScore => _nextGasStationScore;
  int get scoreUntilNextGasStation => _nextGasStationScore - _internalScore;

  double get currentSpeed {
    if (_currentSection >= _maxSpeedSection) return _maxSpeed;
    double progress = (_currentSection - 1) / (_maxSpeedSection - 1);
    return _baseSpeed + ((_maxSpeed - _baseSpeed) * progress);
  }

  double get speedMultiplier => currentSpeed / _baseSpeed;

  // --- MÉTODOS ---

  void setPlaying(bool playing) {
    _isPlaying = playing;
    _safeNotifyListeners();
  }

  void setOffRoad(bool isOffRoad) {
    _isOffRoad = isOffRoad;
  }

  bool shouldSpawnGasStation() {
    return _internalScore >= _nextGasStationScore;
  }

  void markGasStationSpawned() {
    _nextGasStationScore =
        _firstGasStation + (_currentSection) * _gasStationInterval;
  }

  void advanceToNextLevel() {
    _currentSection++;
    _refuelCost = (_baseCost * (_costMultiplier * (_currentSection - 1)))
        .toInt();
    if (_refuelCost < _baseCost) _refuelCost = _baseCost;
    _safeNotifyListeners();
  }

  void addCoin() {
    _coins++;
    _safeNotifyListeners();
  }

  void collectFuelCanister() {
    if (_fuel < _maxFuel) {
      _fuel += _smallFuelRecovery;
      if (_fuel > _maxFuel) _fuel = _maxFuel;
      _safeNotifyListeners();
    }
  }

  void takeHit() {
    if (_fuel > 0 && !_isGameOver) {
      _fuel -= _collisionDamage;

      if (_fuel <= 0) {
        _fuel = 0;
        _triggerGameOver();
      }

      _safeNotifyListeners();
    }
  }

  void updateTime(double dt) {
    // Si ya es Game Over, no hacemos nada más
    if (_isGameOver) return;

    _timeElapsed += dt;
    _internalScore = _timeElapsed.floor();
    _displayScore = (_timeElapsed * _displayScoreMultiplier).toInt();

    if (_fuel > 0) {
      double currentConsumption = _fuelConsumptionRate;

      // Lógica Desierto (Sección 1, 6, 11...)
      bool isDesertSection = (_currentSection - 1) % 5 == 0;
      if (isDesertSection && _isOffRoad) {
        currentConsumption *= 3.0;
      }

      _fuel -= currentConsumption * dt;

      if (_fuel <= 0) {
        _fuel = 0;
        _triggerGameOver();
      }
    }

    _safeNotifyListeners();
  }

  void _triggerGameOver() {
    _isGameOver = true;
    // OJO: NO hacemos setPlaying(false) aquí todavía.
    // Dejamos que el Game Loop detecte el game over, haga la explosión
    // y luego él mismo detenga el juego.
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
    _coins = 0;
    _displayScore = 0;
    _internalScore = 0;
    _timeElapsed = 0.0;
    _fuel = _maxFuel;
    _currentSection = 1;
    _nextGasStationScore = _firstGasStation;
    _refuelCost = _baseCost;
    _isGameOver = false; // Reseteamos bandera de muerte
    _isOffRoad = false;
    _isPlaying = false;
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
}
