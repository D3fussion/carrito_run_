import 'package:flutter/material.dart';
import 'package:carrito_run/game/game.dart';

class PauseButton extends StatelessWidget {
  final CarritoGame game;

  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: GestureDetector(
        onTap: () {
          game.musicManager.setVolume(0.2);
          game.sfxManager.play('ui_pause.wav');
          game.pauseEngine();
          game.overlays.remove('PauseButton');
          game.overlays.add('PauseMenu');
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            shape: BoxShape.rectangle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/ui/icon_pause.png',
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),
    );
  }
}
