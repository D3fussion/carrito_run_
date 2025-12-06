import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:window_manager/window_manager.dart';
import 'package:carrito_run/services/supabase_service.dart';
import 'package:provider/provider.dart';

class GameOverOverlay extends StatelessWidget {
  final CarritoGame game;

  const GameOverOverlay({super.key, required this.game});

  void _showSaveScoreDialog(BuildContext context, int score) {
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D44),
          title: const Text(
            "Guardar Puntuación",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.cyanAccent,
              fontSize: 14,
            ),
          ),
          content: TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'PressStart2P',
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              hintText: "Tu Nombre",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'PressStart2P',
                fontSize: 10,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancelar",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  final supabase = Provider.of<SupabaseService>(
                    context,
                    listen: false,
                  );
                  await supabase.checkAndUpsertPlayer(
                    playerName: name,
                    score: score,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "¡Score Guardado!",
                        style: TextStyle(fontFamily: 'PressStart2P'),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.greenAccent,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
            border: Border.all(color: Colors.redAccent, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titulo
              const Text(
                '¡SIN GASOLINA!',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              _buildResultRow(
                'assets/images/ui/icon_star.png',
                'Score:',
                '${gameState.score}',
                Colors.blueAccent,
              ),
              const SizedBox(height: 15),
              _buildResultRow(
                'assets/images/ui/icon_coin.png',
                'Dinero:',
                '${gameState.coins}',
                const Color(0xFFfacb03),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu para ir al inicio
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.windows ||
                                defaultTargetPlatform == TargetPlatform.macOS ||
                                defaultTargetPlatform ==
                                    TargetPlatform.linux)) {
                          await windowManager.setResizable(true);
                        }
                        game.overlays.remove('GameOverOverlay');
                        game.resetGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/ui/icon_home.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Menú',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Botón para volver a jugar
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('GameOverOverlay');
                        game.restartInstant();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/ui/icon_replay.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reintentar',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Boton Guardar Score Supabase
              ElevatedButton.icon(
                onPressed: () {
                  _showSaveScoreDialog(context, gameState.score);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "Guardar Score",
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String iconPath,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
