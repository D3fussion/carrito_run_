import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';

class PauseButton extends StatelessWidget {
  final CarritoGame game;

  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          onPressed: () {
            game.pauseEngine();
            game.overlays.remove('PauseButton');
            game.overlays.add('PauseMenu');
          },
          icon: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.pause, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
