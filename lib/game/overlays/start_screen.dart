import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:flutter/services.dart';
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
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_gato.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen del título del juego
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 130, 130, 130).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color.fromARGB(255, 129, 129, 129), width: 3),
                ),
                child: Center(
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
              SizedBox(height: 50),
              // Botón para iniciar el juego
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    // LÓGICA PARA MÓVIL (Solo si no es Web)
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

                    // LÓGICA PARA ESCRITORIO (Solo si no es Web)
                    if (!kIsWeb &&
                        (defaultTargetPlatform == TargetPlatform.windows ||
                            defaultTargetPlatform == TargetPlatform.macOS ||
                            defaultTargetPlatform == TargetPlatform.linux)) {
                      await windowManager.setResizable(false);
                    }

                    // INICIAR EL JUEGO
                    game.overlays.remove('StartScreen');
                    game.overlays.add('PauseButton');

                    Future.delayed(Duration(milliseconds: 100), () {
                      game.onGameResize(game.size);
                      game.startGame(); // <--- Recuerda usar startGame() que creamos antes
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'JUGAR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
