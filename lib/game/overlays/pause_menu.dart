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
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titulo
              const Text(
                'PAUSA',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 32,
                  color: Colors.cyanAccent,
                  shadows: [
                    Shadow(
                      color: Colors.blue,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Boton para seguir
              _buildPixelButton(
                label: 'REANUDAR',
                iconPath: 'assets/images/ui/icon_play.png',
                color: Colors.green,
                onPressed: () {
                  game.musicManager.setVolume(0.5);
                  game.sfxManager.play('ui_resume.wav');
                  game.overlays.remove('PauseMenu');
                  game.overlays.add('PauseButton');
                  game.resumeEngine();
                },
              ),

              const SizedBox(height: 20),

              // Boton para salir
              _buildPixelButton(
                label: 'SALIR',
                iconPath: 'assets/images/ui/icon_home.png',
                color: Colors.redAccent,
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

                  if (!kIsWeb &&
                      (defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.macOS ||
                          defaultTargetPlatform == TargetPlatform.linux)) {
                    await windowManager.setResizable(true);
                  }

                  game.musicManager.setVolume(0.5);

                  game.overlays.remove('PauseMenu');
                  game.overlays.remove('PauseButton');
                  game.resetGame();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPixelButton({
    required String label,
    required String iconPath,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 3),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'REANUDAR' ? Icons.play_arrow : Icons.home,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 18,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
