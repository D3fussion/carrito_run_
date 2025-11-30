import 'dart:io';

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
              // Imagen del título del juego
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
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
                    // LÓGICA PARA MÓVIL (Bloqueo de rotación)
                    if (Platform.isAndroid || Platform.isIOS) {
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

                    // LÓGICA PARA ESCRITORIO (Bloqueo de ventana)
                    if (Platform.isWindows ||
                        Platform.isMacOS ||
                        Platform.isLinux) {
                      await windowManager.setResizable(false);
                    }

                    game.overlays.remove('StartScreen');
                    game.overlays.add('PauseButton');

                    Future.delayed(Duration(milliseconds: 100), () {
                      game.onGameResize(game.size);
                      game.startGame();
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
