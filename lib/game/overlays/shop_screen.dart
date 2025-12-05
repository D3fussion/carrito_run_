import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';

class ShopScreen extends StatelessWidget {
  final CarritoGame game;

  const ShopScreen({super.key, required this.game});

  @override
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
                  GestureDetector(
                    onTap: () {
                      game.overlays.remove('ShopScreen');
                      game.overlays.add('StartScreen');
                      game.musicManager.playUiMusic('music_menu.ogg');
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/ui/icon_back.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Título
                  const Text(
                    'GARAJE',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.cyanAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 0,
                          color: Colors.blue,
                          offset: Offset(3, 3),
                        ),
                      ],
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
                          border: Border.all(
                            color: const Color(0xFFfacb03),
                            width: 3,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/ui/icon_coin.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${state.totalWalletCoins}',
                              style: const TextStyle(
                                fontFamily: 'PressStart2P',
                                color: Color(0xFFfacb03),
                                fontSize: 16,
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

            // Lista de carros
            Expanded(
              child: Consumer<GameState>(
                builder: (context, state, _) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: state.allCars.length,
                    itemBuilder: (context, index) {
                      final car = state.allCars[index];

                      final isOwned = state.isCarOwned(car.id);
                      final isSelected = state.selectedCarId == car.id;
                      final isUnlockable = state.isCarUnlocked(car.id);

                      Color cardColor = Colors.grey[900]!;
                      Color borderColor = Colors.white10;
                      double opacity = 1.0;

                      if (isSelected) {
                        cardColor = Colors.green[900]!.withOpacity(0.5);
                        borderColor = Colors.greenAccent;
                      } else if (!isOwned && !isUnlockable) {
                        opacity = 0.5;
                      }

                      return Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.greenAccent
                                  : borderColor,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 0,
                                  offset: const Offset(4, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 10),

                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/images/carts/${car.assetPath}_landscape.png',
                                    fit: BoxFit.contain,
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

                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Text(
                                      car.name,
                                      style: const TextStyle(
                                        fontFamily: 'PressStart2P',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
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
            border: Border.all(color: Colors.greenAccent, width: 2),
          ),
          child: const Text(
            "EQUIPADO",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.greenAccent,
              fontSize: 8,
            ),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: () => state.equipCar(car.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Colors.white, width: 2),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            "EQUIPAR",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.white,
              fontSize: 8,
            ),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[800],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 2),
          ),
          padding: EdgeInsets.zero,
        ),
        child: FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "COMPRAR ",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              Image.asset(
                'assets/images/ui/icon_coin.png',
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 4),
              Text(
                "${car.price}",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ui/icon_lock.png',
              width: 16,
              height: 16,
              color: Colors.red,
            ),
            const SizedBox(height: 4),
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
