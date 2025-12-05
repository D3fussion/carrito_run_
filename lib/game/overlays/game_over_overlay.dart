import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:window_manager/window_manager.dart';

class GameOverOverlay extends StatelessWidget {
  final CarritoGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final gameState = game.gameState;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              const Text(
                '¡SIN GASOLINA!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 30),

              _buildResultRow(
                Icons.sports_score,
                'Score:',
                '${gameState.score}',
              ),
              const SizedBox(height: 15),
              _buildResultRow(
                Icons.monetization_on,
                'Dinero:',
                '${gameState.coins}',
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!kIsWeb &&
                          (defaultTargetPlatform == TargetPlatform.windows ||
                              defaultTargetPlatform == TargetPlatform.macOS ||
                              defaultTargetPlatform == TargetPlatform.linux)) {
                        await windowManager.setResizable(true);
                      }
                      game.resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text('Menú'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      game.overlays.remove('GameOverOverlay');
                      game.restartInstant();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    icon: const Icon(Icons.replay),
                    label: const Text('Otra Partida'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.amber, size: 30),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 24, color: Colors.white70),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
