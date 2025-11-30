import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Título o Logo
            Text(
              'CARGANDO MOTOR...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4.0,
              ),
            ),
            SizedBox(height: 40),
            // Indicador de progreso circular
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.amber,
                strokeWidth: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
