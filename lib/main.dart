import 'package:flutter/foundation.dart';
import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/overlays/loading_screen.dart';
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

  // ============ CONFIGURACIÓN PARA ESCRITORIO CON LÍMITES ============
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 700),           // Tamaño inicial más grande
      minimumSize: Size(800, 600),     // ⭐ TAMAÑO MÍNIMO - No se puede achicar más
      maximumSize: Size(1920, 1080),   // Tamaño máximo opcional
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Carrito Run',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // CONFIGURACIÓN PARA MÓVIL
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
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
      title: 'Carrito Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Carrito Run'),
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
            loadingBuilder: (context) => const LoadingScreen(),
            overlayBuilderMap: {
              'StartScreen': (context, game) =>
                  StartScreen(game: game as CarritoGame),
              'PauseMenu': (context, game) =>
                  PauseMenu(game: game as CarritoGame),
              'PauseButton': (context, game) =>
                  PauseButton(game: game as CarritoGame),
              'RefuelOverlay': (context, game) =>
                  RefuelOverlay(game: game as CarritoGame),
              // ⭐ NUEVO: Overlay para Game Over
              'GameOver': (context, game) =>
                  _buildGameOverScreen(game as CarritoGame),
            },
            initialActiveOverlays: const ['StartScreen'],
          ),
          Positioned(top: 20, left: 0, right: 0, child: _buildGameUI()),
        ],
      ),
    );
  }

  // ============ HUD MEJORADO ============
  Widget _buildGameUI() {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (!gameState.isPlaying) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = MediaQuery.of(context).size.width >
                MediaQuery.of(context).size.height;

            if (isLandscape) {
              return _buildLandscapeHUD(gameState);
            } else {
              return _buildPortraitHUD(gameState);
            }
          },
        );
      },
    );
  }

  Widget _buildLandscapeHUD(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lado izquierdo: Vidas
          _buildLivesDisplay(gameState.lives, gameState.maxLives),
          const Spacer(),
          // Lado derecho: Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildScoreDisplay(gameState.score),
                  const SizedBox(width: 10),
                  _buildCoinCounter(gameState.coins),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFuelMeter(gameState.fuel, gameState.maxFuel),
                  const SizedBox(width: 10),
                  _buildSectionDisplay(
                    gameState.currentSection,
                    gameState.scoreUntilNextGasStation,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitHUD(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          // Primera fila: Vidas centradas
          Center(child: _buildLivesDisplay(gameState.lives, gameState.maxLives)),
          const SizedBox(height: 10),
          // Segunda fila: Score y Monedas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreDisplay(gameState.score),
              _buildCoinCounter(gameState.coins),
            ],
          ),
          const SizedBox(height: 10),
          // Tercera fila: Gasolina y Sección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildFuelMeter(gameState.fuel, gameState.maxFuel)),
              const SizedBox(width: 10),
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

  // ============ WIDGET DE VIDAS ============
  // 🖼️ IMAGEN FUTURA: assets/ui/heart_full.png (corazón rojo pixel art 32x32)
  // 🖼️ IMAGEN FUTURA: assets/ui/heart_empty.png (corazón gris pixel art 32x32)
  // Por ahora usa Icons de Flutter
  Widget _buildLivesDisplay(int currentLives, int maxLives) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLives, (index) {
          final isFilled = index < currentLives;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              isFilled ? Icons.favorite : Icons.favorite_border,
              color: isFilled ? Colors.red : Colors.grey,
              size: 28,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScoreDisplay(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.blue, size: 24),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🖼️ IMAGEN: assets/ui/coin.png (moneda dorada pixel art 64x64)
  Widget _buildCoinCounter(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fuelColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: fuelColor.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_gas_station, color: fuelColor, size: 24),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(fuelColor),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDisplay(int section, int pointsRemaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag, color: Colors.purple, size: 22),
              const SizedBox(width: 6),
              Text(
                'Sección $section',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_gas_station, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text(
                '-$pointsRemaining',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ PANTALLA DE GAME OVER ============
  Widget _buildGameOverScreen(CarritoGame game) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_very_dissatisfied,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                '¡GAME OVER!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Te quedaste sin vidas',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 30),
              Consumer<GameState>(
                builder: (context, gameState, child) {
                  return Column(
                    children: [
                      Text(
                        'Puntuación: ${gameState.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Monedas: ${gameState.coins}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sección alcanzada: ${gameState.currentSection}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  game.overlays.remove('GameOver');
                  game.resetGame();
                  game.overlays.add('StartScreen');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}