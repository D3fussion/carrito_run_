import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';

class UpgradesScreen extends StatelessWidget {
  final CarritoGame game;

  const UpgradesScreen({super.key, required this.game});

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
                      game.overlays.remove('UpgradesScreen');
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
                    'MEJORAS',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 0,
                          color: Colors.green,
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

            // Lista de mejoras
            Expanded(
              child: Consumer<GameState>(
                builder: (context, state, _) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildUpgradeCard(
                        context,
                        state,
                        PowerupType.magnet,
                        'IMÁN',
                        'Atrae monedas cercanas.',
                        'assets/images/ui/icon_magnet.png',
                        state.getPowerupLevel(PowerupType.magnet),
                        state.getPowerupDuration(PowerupType.magnet),
                        state.magnetUpgradeCost,
                      ),
                      const SizedBox(height: 20),
                      _buildUpgradeCard(
                        context,
                        state,
                        PowerupType.shield,
                        'ESCUDO',
                        'Protege de un golpe.',
                        'assets/images/ui/icon_shield.png',
                        state.getPowerupLevel(PowerupType.shield),
                        state.getPowerupDuration(PowerupType.shield),
                        state.shieldUpgradeCost,
                      ),
                      const SizedBox(height: 20),
                      _buildUpgradeCard(
                        context,
                        state,
                        PowerupType.multiplier,
                        'DOBLE SCORE',
                        'Multiplica puntos x2.',
                        'assets/images/ui/icon_2x.png',
                        state.getPowerupLevel(PowerupType.multiplier),
                        state.getPowerupDuration(PowerupType.multiplier),
                        state.multiplierUpgradeCost,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context,
    GameState state,
    PowerupType type,
    String name,
    String description,
    String iconPath,
    int level,
    double duration,
    int cost,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.white24, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIVEL: ${level + 1}',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.cyanAccent,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DUR: ${duration.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.orangeAccent,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón Mejorar
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  if (state.totalWalletCoins >= cost) {
                    state.upgradePowerup(type);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "¡Sin fondos!",
                          style: TextStyle(fontFamily: 'PressStart2P'),
                        ),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.red,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'MÁS',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/ui/icon_coin.png',
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: const TextStyle(
                            fontFamily: 'PressStart2P',
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
