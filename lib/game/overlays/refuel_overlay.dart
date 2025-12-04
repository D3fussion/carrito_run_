import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';
import 'package:provider/provider.dart';
import 'package:carrito_run/game/states/game_state.dart';

class RefuelOverlay extends StatefulWidget {
  final CarritoGame game;

  const RefuelOverlay({super.key, required this.game});

  @override
  State<RefuelOverlay> createState() => _RefuelOverlayState();
}

class _RefuelOverlayState extends State<RefuelOverlay> {
  int _remainingSeconds = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _closeOverlay();
      }
    });
  }

  void _closeOverlay() {
    _timer?.cancel();
    FlameAudio.play('car_start.wav', volume: 0.8);
    widget.game.overlays.remove('RefuelOverlay');
    widget.game.overlays.add('PauseButton');
    widget.game.resumeAfterGasStation();
    widget.game.resumeEngine();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return GestureDetector(
          onTap: () {
            if (gameState.canRefuel()) {
              gameState.refuel();
              _closeOverlay();
            }
          },
          child: Material(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                width: 350,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      color: Colors.yellow,
                      size: 60,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '¡GASOLINERA!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Toca para recargar gasolina',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 24,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${gameState.refuelCost}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: gameState.canRefuel()
                                ? Colors.amber
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!gameState.canRefuel()) ...[
                      SizedBox(height: 10),
                      Text(
                        '¡No tienes suficientes monedas!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    Text(
                      'Cerrando en $_remainingSeconds segundos',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
