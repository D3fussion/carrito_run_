import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final int requiredSection;
  final List<int> requiredPreviousCars;
  final String assetPath;

  CarItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.requiredSection,
    required this.requiredPreviousCars,
    required this.assetPath,
  });
}

class GameState extends ChangeNotifier {
  // --- VARIABLES ---
  int _coins = 0;
  int _displayScore = 0;
  int _internalScore = 0;
  double _timeElapsed = 0.0;
  final double _displayScoreMultiplier = 10.0;

  // --- VARIABLES DE HABILIDAD ESPECIAL ---
  double _abilityCharge = 100.0; // De 0.0 a 100.0
  bool _isAbilityActive = false;

  // Estado del Juego
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isOffRoad = false; // Para el desierto y el volcan

  bool get isOffRoad => _isOffRoad;

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
  int _refuelCost = 15;

  // Velocidad
  final double _baseSpeed = 400.0;
  final double _maxSpeed = 1000.0;
  final int _maxSpeedSection = 11;

  bool _hasShield = false;
  bool get hasShield => _hasShield;

  // --- VARIABLES DE LA TIENDA ---
  int _totalWalletCoins = 0;
  int _maxSectionReached = 1; // Récord histórico del jugador
  int _selectedCarId = 0; // ID del carro equipado (0 es el default)
  List<int> _ownedCarIds = [0];

  final List<double> _fuelHistory = [];
  double _historyTimer = 0.0;

  bool get currentCarHasActiveAbility {
    // Lista de IDs que tienen habilidad activa (Según tu diseño anterior)
    // 6: Bulldozer
    // 10: 007
    // 12: Teleport
    // 13: OVNI
    // 14: Tanque
    // 15: DeLorean
    // 16: El Dorado
    const activeAbilityCarIds = [6, 9, 10, 12, 13, 14, 15, 16];

    return activeAbilityCarIds.contains(_selectedCarId);
  }

  final List<CarItem> allCars = [
    // TIER 0
    CarItem(
      id: 0,
      name: 'El Clásico',
      description: 'Equilibrado y confiable.',
      price: 0,
      requiredSection: 0,
      requiredPreviousCars: [],
      assetPath: 'classic',
    ), // Nombre del archivo base (classic_landscape.png)
    // TIER 1
    CarItem(
      id: 1,
      name: 'Taxi',
      description: 'Imán de monedas corto alcance.',
      price: 500,
      requiredSection: 3,
      requiredPreviousCars: [],
      assetPath: 'taxi',
    ),
    CarItem(
      id: 2,
      name: 'Pickup',
      description: '+30% Gasolina inicial.',
      price: 1200,
      requiredSection: 3,
      requiredPreviousCars: [],
      assetPath: 'pickup',
    ),
    CarItem(
      id: 3,
      name: 'Mini',
      description: 'Cambio de carril +20% rápido.',
      price: 2000,
      requiredSection: 3,
      requiredPreviousCars: [],
      assetPath: 'mini',
    ),

    // TIER 2
    CarItem(
      id: 4,
      name: '4x4 Jeep',
      description: 'Ignora penalización en Desierto.',
      price: 5000,
      requiredSection: 6,
      requiredPreviousCars: [1, 2, 3],
      assetPath: 'jeep',
    ),
    CarItem(
      id: 5,
      name: 'Ambulancia',
      description: 'Bidones curan el doble.',
      price: 8500,
      requiredSection: 6,
      requiredPreviousCars: [1, 2, 3],
      assetPath: 'ambulance',
    ),
    CarItem(
      id: 6,
      name: 'Bulldozer',
      description: 'Habilidad: Destruir obstáculos.',
      price: 12000,
      requiredSection: 6,
      requiredPreviousCars: [1, 2, 3],
      assetPath: 'bulldozer',
    ),

    // TIER 3
    CarItem(
      id: 7,
      name: 'Fórmula 1',
      description: 'Consume 10% menos gasolina.',
      price: 20000,
      requiredSection: 9,
      requiredPreviousCars: [4, 5, 6],
      assetPath: 'f1',
    ),
    CarItem(
      id: 8,
      name: 'Eléctrico',
      description: 'No gasta gasolina por tiempo.',
      price: 28000,
      requiredSection: 9,
      requiredPreviousCars: [4, 5, 6],
      assetPath: 'electric',
    ),
    CarItem(
      id: 9,
      name: 'Bumper Car',
      description: 'Empieza con 1 escudo gratis.',
      price: 35000,
      requiredSection: 9,
      requiredPreviousCars: [4, 5, 6],
      assetPath: 'bumper',
    ),

    // TIER 4
    CarItem(
      id: 10,
      name: 'Agente 007',
      description: 'Habilidad: Misil destructor.',
      price: 50000,
      requiredSection: 12,
      requiredPreviousCars: [7, 8, 9],
      assetPath: 'spycar',
    ),
    CarItem(
      id: 11,
      name: 'Hovercraft',
      description: 'Inmune a terrenos.',
      price: 65000,
      requiredSection: 12,
      requiredPreviousCars: [7, 8, 9],
      assetPath: 'hover',
    ),
    CarItem(
      id: 12,
      name: 'Teleport',
      description: 'Cambio de carril instantáneo.',
      price: 80000,
      requiredSection: 12,
      requiredPreviousCars: [7, 8, 9],
      assetPath: 'teleport',
    ),

    // TIER 5
    CarItem(
      id: 13,
      name: 'OVNI',
      description: 'Vuela sobre obstáculos bajos.',
      price: 120000,
      requiredSection: 15,
      requiredPreviousCars: [10, 11, 12],
      assetPath: 'ufo',
    ),
    CarItem(
      id: 14,
      name: 'Tanque',
      description: 'Resiste 6 golpes.',
      price: 150000,
      requiredSection: 15,
      requiredPreviousCars: [10, 11, 12],
      assetPath: 'tank',
    ),
    CarItem(
      id: 15,
      name: 'DeLorean',
      description: 'Habilidad: Rebobinar tiempo.',
      price: 200000,
      requiredSection: 15,
      requiredPreviousCars: [10, 11, 12],
      assetPath: 'delorean',
    ),

    // FINAL
    CarItem(
      id: 16,
      name: 'EL DORADO',
      description: 'DIOS: Ventajas máximas.',
      price: 0,
      requiredSection: 0,
      requiredPreviousCars: [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
      ],
      assetPath: 'golden',
    ),
  ];

  // --- GETTERS ---
  int get coins => _coins;
  int get score => _displayScore;
  int get internalScore => _internalScore;
  double get abilityCharge => _abilityCharge;
  bool get isAbilityActive => _isAbilityActive;
  double get timeElapsed => _timeElapsed;
  double get fuel => _fuel;
  double get maxFuel {
    if (_selectedCarId == 2) return 130.0;

    if (_selectedCarId == 16) return 200.0;

    return 100.0;
  }

  int get currentSection => _currentSection;
  int get refuelCost => _refuelCost;
  bool get isOutOfFuel => _fuel <= 0;
  bool get isPlaying => _isPlaying;
  bool get isGameOver => _isGameOver;
  int get nextGasStationScore => _nextGasStationScore;
  int get scoreUntilNextGasStation => _nextGasStationScore - _internalScore;
  int get totalWalletCoins => _totalWalletCoins;
  int get selectedCarId => _selectedCarId;
  int get maxSectionReached => _maxSectionReached;

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
    checkMaxSectionProgress();
    _safeNotifyListeners();
  }

  void addCoin() {
    int value = 1;

    if (_selectedCarId == 16) value = 2;

    _coins += value;
    _safeNotifyListeners();
  }

  void collectFuelCanister() {
    if (_fuel < maxFuel) {
      double recovery = _smallFuelRecovery;

      if (_selectedCarId == 5) {
        recovery *= 2.0;
      }

      _fuel += recovery;
      if (_fuel > maxFuel) _fuel = maxFuel;

      addAbilityCharge(20.0);

      _safeNotifyListeners();
    }
  }

  void takeHit() {
    if (_fuel > 0 && !_isGameOver) {
      // 1. LÓGICA ESCUDO (Bumper Car)
      if (_hasShield) {
        consumeShield(); // Se rompe el escudo
        return; // ¡NO RECIBES DAÑO!
      }

      double damage = _collisionDamage; // Base 30.0

      // 2. LÓGICA ELÉCTRICO (ID 8): Daño Doble (60%)
      if (_selectedCarId == 8) {
        damage = 60.0;
      }

      if (_selectedCarId == 14) {
        damage = 15.0;
      }

      _fuel -= damage;
      if (_fuel <= 0) {
        _fuel = 0;
        _triggerGameOver();
      }
      _safeNotifyListeners();
    }
  }

  void updateTime(double dt) {
    if (_isGameOver) return;

    addAbilityCharge(2.0 * dt);

    _timeElapsed += dt;
    _internalScore = _timeElapsed.floor();
    _displayScore = (_timeElapsed * _displayScoreMultiplier).toInt();

    if (_selectedCarId == 15) {
      _historyTimer += dt;
      if (_historyTimer >= 0.5) {
        _historyTimer = 0.0;
        _fuelHistory.add(_fuel);
        if (_fuelHistory.length > 6) {
          _fuelHistory.removeAt(0);
        }
      }
    }

    if (_fuel > 0) {
      double currentConsumption = _fuelConsumptionRate;

      bool isDesertSection = (_currentSection - 1) % 5 == 0;

      if (isDesertSection && _isOffRoad) {
        if (_selectedCarId != 4) {
          currentConsumption *= 3.0;
        }
      }

      if (_selectedCarId == 7) {
        currentConsumption *= 0.90;
      }

      if (_selectedCarId == 8) {
        currentConsumption = 0.0;
      }

      // Volcán sigue haciendo daño a todos por ahora
      bool isVolcanoSection = (_currentSection - 1) % 5 == 4;
      if (isVolcanoSection && _isOffRoad) {
        currentConsumption *= 10.0;
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
    if (_coins > 0) {
      _totalWalletCoins += _coins;
      _saveData(); // Guardamos en disco inmediatamente
      debugPrint(
        "💰 Se agregaron $_coins a la cartera. Total: $_totalWalletCoins",
      );
    }
  }

  bool canRefuel() {
    return _coins >= _refuelCost && _fuel < maxFuel;
  }

  void refuel() {
    if (canRefuel()) {
      _coins -= _refuelCost;
      _fuel = maxFuel;
      _safeNotifyListeners();
    }
  }

  void reset() {
    _abilityCharge = 100.0;
    _isAbilityActive = false;
    _hasShield = false;
    _coins = 0;
    _displayScore = 0;
    _internalScore = 0;
    _timeElapsed = 0.0;
    _fuel = maxFuel;
    _currentSection = 1;
    _nextGasStationScore = _firstGasStation;
    _refuelCost = 15;
    _isGameOver = false;
    _isOffRoad = false;
    _isPlaying = false;
    _fuelHistory.clear();
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

  // Recupera la gasolina al 100%
  void debugFillFuel() {
    _fuel = _maxFuel;
    _safeNotifyListeners();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _totalWalletCoins = prefs.getInt('wallet_coins') ?? 0;
    _maxSectionReached = prefs.getInt('max_section') ?? 1;
    _selectedCarId = prefs.getInt('selected_car') ?? 0;

    String? ownedString = prefs.getString('owned_cars');
    if (ownedString != null) {
      _ownedCarIds = ownedString.split(',').map((e) => int.parse(e)).toList();
    } else {
      _ownedCarIds = [0];
    }

    _safeNotifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wallet_coins', _totalWalletCoins);
    await prefs.setInt('max_section', _maxSectionReached);
    await prefs.setInt('selected_car', _selectedCarId);
    await prefs.setString('owned_cars', _ownedCarIds.join(','));
  }

  bool isCarUnlocked(int carId) {
    if (_ownedCarIds.contains(carId)) return true;

    final car = allCars.firstWhere((c) => c.id == carId);

    if (_maxSectionReached < car.requiredSection) return false;

    for (int reqId in car.requiredPreviousCars) {
      if (!_ownedCarIds.contains(reqId)) return false;
    }

    return true;
  }

  bool isCarOwned(int carId) => _ownedCarIds.contains(carId);

  void buyCar(int carId) {
    final car = allCars.firstWhere((c) => c.id == carId);

    if (_totalWalletCoins >= car.price && isCarUnlocked(carId)) {
      _totalWalletCoins -= car.price;
      _ownedCarIds.add(carId);
      _selectedCarId = carId;
      _saveData();
      notifyListeners();
    }
  }

  void equipCar(int carId) {
    if (_ownedCarIds.contains(carId)) {
      _selectedCarId = carId;
      _saveData();
      notifyListeners();
    }
  }

  void checkMaxSectionProgress() {
    if (_currentSection > _maxSectionReached) {
      _maxSectionReached = _currentSection;
      _saveData();
    }
  }

  void debugUnlockAllCars() {
    _ownedCarIds = allCars.map((car) => car.id).toList();

    if (_maxSectionReached < 20) {
      _maxSectionReached = 20;
    }

    _saveData();
    notifyListeners();
  }

  void addAbilityCharge(double amount) {
    if (_isAbilityActive) return;
    _abilityCharge += amount;
    if (_abilityCharge > 100.0) _abilityCharge = 100.0;
    _safeNotifyListeners();
  }

  void activateAbility() {
    if (_abilityCharge >= 100.0) {
      _isAbilityActive = true;
      _abilityCharge = 0.0;
      _safeNotifyListeners();
    }
  }

  void deactivateAbility() {
    _isAbilityActive = false;
    _safeNotifyListeners();
  }

  void grantShield() {
    _hasShield = true;
    _safeNotifyListeners();
  }

  void consumeShield() {
    _hasShield = false;
    _safeNotifyListeners();
  }

  void rewindTime() {
    if (_fuelHistory.isNotEmpty) {
      double oldFuel = _fuelHistory.first;

      if (oldFuel > _fuel) {
        _fuel = oldFuel;
      }
      _fuelHistory.clear();
      _safeNotifyListeners();
    }
  }
}
