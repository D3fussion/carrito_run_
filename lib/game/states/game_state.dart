import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class GameState extends ChangeNotifier {
  int _coins = 0;
  int _displayScore = 0; // Puntaje que ve el jugador
  int _internalScore = 0; // Puntaje secreto para gasolineras/powerups
  double _timeElapsed = 0.0;
  final double _displayScoreMultiplier =
      10.0; // Multiplicador del puntaje visible

  // Saber si esta jugando o no
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Sistema de gasolina
  double _fuel = 100.0;
  final double _maxFuel = 100.0;
  final double _fuelConsumptionRate = 5.0;

  // Sistema de secciones basado en puntaje interno
  int _currentSection = 1;
  int _nextGasStationScore = 50; // Primera gasolinera a los 50 puntos
  final int _firstGasStation = 50;
  final int _gasStationInterval =
      60; // Cada 60 puntos adicionales después de la primera

  // Costo de gasolina
  int _refuelCost = 10;
  final int _baseCost = 10;
  final double _costMultiplier = 1.5;

  int get coins => _coins;
  int get score => _displayScore; // El jugador ve este puntaje
  int get internalScore => _internalScore; // Puntaje secreto
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

  void updateTime(double dt) {
    _timeElapsed += dt;

    _internalScore = _timeElapsed.floor();

    _displayScore = (_timeElapsed * _displayScoreMultiplier).toInt();

    if (_fuel > 0) {
      _fuel -= _fuelConsumptionRate * dt;
      if (_fuel < 0) _fuel = 0;
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
