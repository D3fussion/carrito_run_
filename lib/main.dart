import 'dart:io';

import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/overlays/refuel_overlay.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/overlays/start_screen.dart';
import 'package:carrito_run/game/overlays/pause_menu.dart';
import 'package:carrito_run/game/overlays/pause_button.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración para ESCRITORIO (Windows/Mac/Linux)
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600), // Tamaño inicial sugerido
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Configuración para MÓVIL (Bloqueo de rotación inicial permisivo)
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await Flame.device.fullScreen();
  }

  runApp(ChangeNotifierProvider(create: (_) => GameState(), child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Run',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Cart Run'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CarritoGame game;

  @override
  void initState() {
    super.initState();

    final gameState = Provider.of<GameState>(context, listen: false);
    game = CarritoGame(gameState: gameState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: game,
            overlayBuilderMap: {
              'StartScreen': (context, game) =>
                  StartScreen(game: game as CarritoGame),
              'PauseMenu': (context, game) =>
                  PauseMenu(game: game as CarritoGame),
              'PauseButton': (context, game) =>
                  PauseButton(game: game as CarritoGame),
              'RefuelOverlay': (context, game) =>
                  RefuelOverlay(game: game as CarritoGame),
            },
            initialActiveOverlays: const ['StartScreen'],
          ),
          Positioned(top: 40, left: 0, right: 0, child: _buildGameUI()),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                MediaQuery.of(context).size.width >
                MediaQuery.of(context).size.height;

            if (isLandscape) {
              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildScoreDisplay(gameState.score),
                      SizedBox(height: 10),
                      _buildCoinCounter(gameState.coins),
                      SizedBox(height: 10),
                      _buildFuelMeter(gameState.fuel, gameState.maxFuel),
                      SizedBox(height: 10),
                      _buildSectionDisplay(
                        gameState.currentSection,
                        gameState.scoreUntilNextGasStation,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildScoreDisplay(gameState.score),
                        _buildCoinCounter(gameState.coins),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFuelMeter(gameState.fuel, gameState.maxFuel),
                        _buildSectionDisplay(
                          gameState.currentSection,
                          gameState.scoreUntilNextGasStation,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildScoreDisplay(int score) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, color: Colors.blue, size: 28),
          SizedBox(width: 8),
          Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinCounter(int coins) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: Colors.amber, size: 28),
          SizedBox(width: 8),
          Text(
            '$coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelMeter(double fuel, double maxFuel) {
    final percentage = fuel / maxFuel;
    Color fuelColor;

    if (percentage > 0.5) {
      fuelColor = Colors.green;
    } else if (percentage > 0.25) {
      fuelColor = Colors.orange;
    } else {
      fuelColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fuelColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_gas_station, color: fuelColor, size: 28),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(fuelColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDisplay(int section, int pointsRemaining) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, color: Colors.purple, size: 28),
              SizedBox(width: 8),
              Text(
                'Sección $section',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_gas_station, color: Colors.orange, size: 16),
              SizedBox(width: 4),
              Text(
                '-${pointsRemaining}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
