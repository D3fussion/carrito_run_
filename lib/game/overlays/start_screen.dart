import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/managers/car_manager.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class StartScreen extends StatelessWidget {
  final CarritoGame game;

  const StartScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.purple.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título del juego
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Text(
                    'CART RUN',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.blue,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // ⭐ NUEVO: Stats del jugador
              Consumer<CarManager>(
                builder: (context, carManager, child) {
                  if (!carManager.isInitialized) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              carManager.currentCar.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${carManager.totalCoins}',
                              style: const TextStyle(color: Colors.amber, fontSize: 16),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.emoji_events, color: Colors.yellow, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${carManager.highScore}',
                              style: const TextStyle(color: Colors.yellow, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // Botón JUGAR
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _startGame(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'JUGAR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // ⭐ NUEVO: Botón de Selección de Carritos
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('StartScreen');
                    game.overlays.add('CarSelectionMenu');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'CARRITOS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGame(BuildContext context) async {
    // LÓGICA PARA MÓVIL
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final orientation = MediaQuery.of(context).orientation;
      if (orientation == Orientation.landscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    }

    // LÓGICA PARA ESCRITORIO
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      await windowManager.setResizable(false);
    }

    // INICIAR EL JUEGO
    game.overlays.remove('StartScreen');
    game.overlays.add('PauseButton');

    Future.delayed(const Duration(milliseconds: 100), () {
      game.onGameResize(game.size);
      game.startGame();
    });
  }
}