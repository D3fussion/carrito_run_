import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class PauseMenu extends StatelessWidget {
  final CarritoGame game;

  const PauseMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSA',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // --- BOTÓN REANUDAR (CORREGIDO) ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. Restaurar volumen de música
                    game.musicManager.setVolume(0.5);

                    // 2. Sonido de UI
                    FlameAudio.play('ui_resume.wav');

                    // 3. Reanudar Juego
                    game.overlays.remove('PauseMenu');
                    game.overlays.add('PauseButton');
                    game.resumeEngine();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'REANUDAR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Botón de salir
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // DESBLOQUEAR MÓVIL
                    if (!kIsWeb &&
                        (defaultTargetPlatform == TargetPlatform.android ||
                            defaultTargetPlatform == TargetPlatform.iOS)) {
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                    }

                    // DESBLOQUEAR ESCRITORIO
                    if (!kIsWeb &&
                        (defaultTargetPlatform == TargetPlatform.windows ||
                            defaultTargetPlatform == TargetPlatform.macOS ||
                            defaultTargetPlatform == TargetPlatform.linux)) {
                      await windowManager.setResizable(true);
                    }

                    // Restaurar volumen por si acaso
                    game.musicManager.setVolume(0.5);
                    // FlameAudio.play('ui_resume.wav'); // Opcional, ya te vas

                    // SALIR
                    game.overlays.remove('PauseMenu');
                    game.overlays.remove('PauseButton');
                    // game.overlays.add('StartScreen'); // ResetGame ya hace esto en tu código actual
                    game.resetGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
