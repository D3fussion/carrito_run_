import 'package:carrito_run/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';

class StartScreen extends StatefulWidget {
  final CarritoGame game;

  const StartScreen({super.key, required this.game});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  List<Map<String, dynamic>> _highscores = [];

  @override
  void initState() {
    super.initState();
    _loadHighscores();
  }

  Future<void> _loadHighscores() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final scores = await supabase.getTopHighscores(limit: 3);
    if (mounted) {
      setState(() {
        _highscores = scores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_gato.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titulo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.cyanAccent, width: 4),
                    ),
                    child: Text(
                      'LAST DROP',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        shadows: [
                          Shadow(
                            blurRadius: 0,
                            color: Colors.blue,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Boton para jugar
                  SizedBox(
                    width: 220,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.android ||
                                defaultTargetPlatform == TargetPlatform.iOS)) {
                          final orientation = MediaQuery.of(
                            context,
                          ).orientation;
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

                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.windows ||
                                defaultTargetPlatform == TargetPlatform.macOS ||
                                defaultTargetPlatform ==
                                    TargetPlatform.linux)) {
                          await windowManager.setResizable(false);
                        }

                        widget.game.overlays.remove('StartScreen');
                        widget.game.overlays.add('PauseButton');

                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.game.onGameResize(widget.game.size);
                          widget.game.startGame();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.white, width: 3),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'JUGAR',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ir al Garaje
                  _buildMenuButton(
                    context,
                    label: "GARAJE",
                    iconPath: 'assets/images/ui/icon_garage.png',
                    onPressed: () {
                      widget.game.musicManager.playUiMusic('music_garage.ogg');
                      widget.game.overlays.remove('StartScreen');
                      widget.game.overlays.add('ShopScreen');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ir a Mejoras
                  _buildMenuButton(
                    context,
                    label: "MEJORAS",
                    iconPath: 'assets/images/ui/icon_upgrades.png',
                    onPressed: () {
                      widget.game.musicManager.playUiMusic('music_garage.ogg');
                      widget.game.overlays.remove('StartScreen');
                      widget.game.overlays.add('UpgradesScreen');
                    },
                  ),

                  // Display Highscores
                  if (_highscores.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "TOP 3 HIGHSCORES",
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._highscores.map((score) {
                            final name = score['player_name'] ?? 'Anon';
                            final points = score['points'] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                "$name: $points",
                                style: const TextStyle(
                                  fontFamily: 'PressStart2P',
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Monedas
          Positioned(
            top: 40,
            right: 20,
            child: Consumer<GameState>(
              builder: (context, gameState, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
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
                      const SizedBox(width: 12),
                      Text(
                        '${gameState.totalWalletCoins}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 220,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 3),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
