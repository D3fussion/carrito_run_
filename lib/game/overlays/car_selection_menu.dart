import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/managers/car_manager.dart';
import 'package:carrito_run/models/car_data.dart';

class CarSelectionMenu extends StatefulWidget {
  final CarritoGame game;

  const CarSelectionMenu({super.key, required this.game});

  @override
  State<CarSelectionMenu> createState() => _CarSelectionMenuState();
}

class _CarSelectionMenuState extends State<CarSelectionMenu> {
  int _selectedSection = 0; // Sección actual visible (0-5)

  @override
  Widget build(BuildContext context) {
    return Consumer<CarManager>(
      builder: (context, carManager, child) {
        if (!carManager.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Material(
          color: Colors.black.withOpacity(0.9),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(carManager),
                _buildSectionTabs(),
                Expanded(
                  child: _buildCarGrid(carManager),
                ),
                _buildFooter(carManager),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ HEADER CON STATS ============
  Widget _buildHeader(CarManager carManager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón cerrar
              IconButton(
                onPressed: () {
                  widget.game.overlays.remove('CarSelectionMenu');
                  widget.game.overlays.add('StartScreen'); // ⭐ AGREGADO
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
              
              // Título
              const Text(
                'SELECCIONAR CARRITO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Monedas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${carManager.totalCoins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Progreso
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: carManager.overallProgress,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${carManager.unlockedCars.length}/16',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ TABS DE SECCIONES ============
  Widget _buildSectionTabs() {
    const sectionNames = [
      'DEFAULT',
      'DESIERTO',
      'CIUDAD',
      'BOSQUE',
      'NIEVE',
      'LLUVIA',
    ];

    return Container(
      height: 60,
      color: Colors.grey.shade900,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedSection;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSection = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  sectionNames[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ GRID DE CARRITOS ============
  Widget _buildCarGrid(CarManager carManager) {
    final cars = carManager.getCarsBySection(_selectedSection);

    if (cars.isEmpty) {
      return const Center(
        child: Text(
          'No hay carritos en esta sección',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas en desktop/tablet, ajustar para móvil
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(cars[index], carManager);
      },
    );
  }

  // ============ CARD DE CARRITO INDIVIDUAL ============
  Widget _buildCarCard(CarData car, CarManager carManager) {
    final isUnlocked = carManager.isCarUnlocked(car.id);
    final isSelected = carManager.currentCar.id == car.id;
    final canUnlock = !isUnlocked && carManager.canUnlockCar(car.id);

    return GestureDetector(
      onTap: () => _handleCarTap(car, carManager, isUnlocked, canUnlock),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade700 
              : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : (isUnlocked ? Colors.green : Colors.red),
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen del carrito o candado
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Center(
                    child: isUnlocked
                        ? _buildCarImage(car)
                        : Icon(
                            Icons.lock,
                            size: 60,
                            color: Colors.grey.shade600,
                          ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, thickness: 1),
            
            // Info del carrito
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      car.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isUnlocked) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: canUnlock ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${car.price}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isSelected) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EN USO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ IMAGEN DEL CARRITO ============
  // 🖼️ AQUÍ SE CARGAN LAS IMÁGENES: assets/cars/car_X_landscape.png
  Widget _buildCarImage(CarData car) {
    return Image.asset(
      'assets/${car.spritePathLandscape}',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Si no existe la imagen, mostrar placeholder
        return Container(
          color: Colors.grey.shade700,
          child: const Icon(
            Icons.directions_car,
            size: 50,
            color: Colors.white54,
          ),
        );
      },
    );
  }

  // ============ MANEJO DE TAP EN CARRITO ============
  void _handleCarTap(CarData car, CarManager carManager, bool isUnlocked, bool canUnlock) {
    if (isUnlocked) {
      // Seleccionar carrito desbloqueado
      carManager.selectCar(car.id);
      _showSnackBar('${car.name} seleccionado', Colors.blue);
    } else if (canUnlock) {
      // Mostrar diálogo de compra
      _showUnlockDialog(car, carManager);
    } else {
      // Mostrar requisitos
      final message = carManager.getRequirementMessage(car.id);
      _showSnackBar(message, Colors.red);
    }
  }

  // ============ DIÁLOGO DE DESBLOQUEO ============
  void _showUnlockDialog(CarData car, CarManager carManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          '¿Desbloquear ${car.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              car.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${car.price}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Te quedarán: ${carManager.totalCoins - car.price} monedas',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await carManager.unlockCar(car.id);
              if (success) {
                _showSnackBar('¡${car.name} desbloqueado!', Colors.green);
                // Auto-seleccionar el carrito recién comprado
                await carManager.selectCar(car.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }

  // ============ FOOTER CON STATS DEL CARRITO SELECCIONADO ============
  Widget _buildFooter(CarManager carManager) {
    final car = carManager.currentCar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: const Border(
          top: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            car.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            car.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                'Velocidad',
                car.speedMultiplier,
                car.speedMultiplier > 1.0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                'Eficiencia',
                car.fuelEfficiency,
                car.fuelEfficiency < 1.0 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, double value, Color color) {
    String displayValue;
    if (value == 1.0) {
      displayValue = 'Normal';
    } else if (value > 1.0) {
      displayValue = '+${((value - 1.0) * 100).toInt()}%';
    } else {
      displayValue = '-${((1.0 - value) * 100).toInt()}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============ SNACKBAR ============
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}