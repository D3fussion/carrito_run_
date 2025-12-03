import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';

class ShopScreen extends StatelessWidget {
  final CarritoGame game;

  const ShopScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Regresar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        game.overlays.remove('ShopScreen');
                        game.overlays.add('StartScreen');
                      },
                    ),
                  ),

                  // Título
                  const Text(
                    'GARAJE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),

                  // Monedas
                  Consumer<GameState>(
                    builder: (context, state, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.savings,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.totalWalletCoins}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- LISTA DE CARROS (GRID) ---
            Expanded(
              child: Consumer<GameState>(
                builder: (context, state, _) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 Columnas
                          childAspectRatio:
                              0.8, // Relación de aspecto (Más alto que ancho)
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: state.allCars.length,
                    itemBuilder: (context, index) {
                      // 1. DEFINICIÓN DE LA VARIABLE 'car'
                      final car = state.allCars[index];

                      final isOwned = state.isCarOwned(car.id);
                      final isSelected = state.selectedCarId == car.id;
                      final isUnlockable = state.isCarUnlocked(car.id);

                      // Lógica de colores según estado
                      Color cardColor = Colors.grey[900]!;
                      Color borderColor = Colors.white10;
                      double opacity = 1.0;

                      if (isSelected) {
                        cardColor = Colors.green[900]!.withOpacity(0.5);
                        borderColor = Colors.greenAccent;
                      } else if (!isOwned && !isUnlockable) {
                        opacity = 0.5; // Oscurecer si está bloqueado por nivel
                      }

                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 10),

                              // 2. IMAGEN DEL CARRO
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    // Usamos la versión landscape para que se vea de lado en la tienda
                                    'assets/images/carts/${car.assetPath}_landscape.png',
                                    fit: BoxFit.contain,

                                    // Si no encuentra la imagen, muestra un ícono
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.directions_car_filled,
                                        size: 60,
                                        color: isOwned
                                            ? Colors.amber
                                            : Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // 3. INFORMACIÓN
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Text(
                                      car.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Text(
                                        car.description,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 4. BOTÓN DE ACCIÓN
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  0,
                                  10,
                                  10,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: _buildActionButton(
                                    context,
                                    state,
                                    car,
                                    isOwned,
                                    isSelected,
                                    isUnlockable,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método helper para decidir qué botón mostrar
  Widget _buildActionButton(
    BuildContext context,
    GameState state,
    dynamic car,
    bool isOwned,
    bool isSelected,
    bool isUnlockable,
  ) {
    if (isOwned) {
      if (isSelected) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: const Text(
            "EQUIPADO",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: () => state.equipCar(car.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "EQUIPAR",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
    } else if (isUnlockable) {
      return ElevatedButton(
        onPressed: () {
          if (state.totalWalletCoins >= car.price) {
            state.buyCar(car.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "¡No tienes suficiente dinero!",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          child: Row(
            children: [
              const Text(
                "COMPRAR ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.monetization_on, size: 14, color: Colors.white),
              Text(
                "${car.price}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // ESTADO BLOQUEADO
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.red, size: 16),
            Text(
              car.requiredSection > 0
                  ? "Llega a Sec. ${car.requiredSection}"
                  : "Compra previos",
              style: const TextStyle(color: Colors.redAccent, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
