import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/overlays/start_screen.dart';
import 'package:carrito_run/game/overlays/pause_menu.dart';
import 'package:carrito_run/game/overlays/pause_button.dart';
import 'package:carrito_run/game/overlays/refuel_overlay.dart';
import 'package:carrito_run/game/overlays/loading_screen.dart';
import 'package:carrito_run/game/overlays/game_over_overlay.dart';
import 'package:carrito_run/game/overlays/shop_screen.dart';
import 'package:carrito_run/game/overlays/upgrades_screen.dart';
import 'package:carrito_run/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar .env
  await dotenv.load(fileName: ".env");

  // Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 1. CONFIGURACIÓN ESCRITORIO (Windows/Mac/Linux)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();

    await AudioPlayer.clearAssetCache();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 800),
      minimumSize: Size(350, 600),
      center: true,
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: "Last Drop",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 2. CONFIGURACIÓN MÓVIL (Android/iOS)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  await AudioPlayer.clearAssetCache();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        Provider<SupabaseService>(create: (_) => SupabaseService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Drop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CarritoGame game;

  @override
  void initState() {
    super.initState();

    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.loadData();

    game = CarritoGame(gameState: gameState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        game.musicManager.playUiMusic('music_menu.ogg');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ClipRect(
          child: Stack(
            children: [
              GameWidget(
                game: game,
                loadingBuilder: (context) => const LoadingScreen(),
                overlayBuilderMap: {
                  'StartScreen': (context, game) =>
                      StartScreen(game: game as CarritoGame),
                  'ShopScreen': (context, game) =>
                      ShopScreen(game: game as CarritoGame),
                  'PauseMenu': (context, game) =>
                      PauseMenu(game: game as CarritoGame),
                  'PauseButton': (context, game) =>
                      PauseButton(game: game as CarritoGame),
                  'RefuelOverlay': (context, game) =>
                      RefuelOverlay(game: game as CarritoGame),
                  'GameOverOverlay': (context, game) =>
                      GameOverOverlay(game: game as CarritoGame),
                  'UpgradesScreen': (context, game) =>
                      UpgradesScreen(game: game as CarritoGame),
                },
                initialActiveOverlays: const ['StartScreen'],
              ),

              Positioned.fill(child: _buildGameUI()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        if (!gameState.isPlaying || gameState.isGameOver) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return Stack(
              children: [
                if (isLandscape)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, right: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildScoreDisplay(gameState.score),
                          const SizedBox(height: 10),
                          _buildCoinCounter(gameState.coins),
                          const SizedBox(height: 10),
                          _buildFuelMeter(gameState.fuel, gameState.maxFuel),
                          const SizedBox(height: 10),
                          _buildSectionDisplay(
                            gameState.currentSection,
                            gameState.scoreUntilNextGasStation,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: _buildScoreDisplay(gameState.score),
                            ),
                            _buildCoinCounter(gameState.coins),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                  ),

                // Indicaciones powerups
                Positioned(
                  top: isLandscape ? 120 : 190,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gameState.isMagnetActive)
                        _buildPowerupIndicator(
                          'assets/images/ui/icon_magnet.png',
                          gameState.magnetTimer,
                        ),
                      if (gameState.hasShield || gameState.shieldTimer > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildPowerupIndicator(
                            'assets/images/ui/icon_shield.png',
                            gameState.shieldTimer > 0
                                ? gameState.shieldTimer
                                : 99,
                          ),
                        ),
                      if (gameState.isMultiplierActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildPowerupIndicator(
                            'assets/images/ui/icon_2x.png',
                            gameState.multiplierTimer,
                          ),
                        ),
                    ],
                  ),
                ),

                if (gameState.currentCarHasActiveAbility)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildAbilityBar(gameState)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreDisplay(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFF0204f9), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ui/icon_star.png', width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              color: Color(0xFF0204f9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinCounter(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFFfacb03), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ui/icon_coin.png', width: 24, height: 24),
          const SizedBox(width: 12),
          Text(
            '$coins',
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
  }

  Widget _buildFuelMeter(double fuel, double maxFuel) {
    final percentage = (fuel / maxFuel).clamp(0.0, 1.0);
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
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFF52a555), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ui/icon_fuel.png', width: 24, height: 24),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 16,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade900,
              valueColor: AlwaysStoppedAnimation<Color>(fuelColor),
              minHeight: 16,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDisplay(int section, int pointsRemaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFFad6ef3), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ui/icon_flag.png', width: 24, height: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NIVEL $section',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Color(0xFFad6ef3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '-$pointsRemaining m',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Color(0xFFad6ef3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityBar(GameState state) {
    final double percentage = (state.abilityCharge / 100.0).clamp(0.0, 1.0);
    final bool isReady = percentage >= 1.0;
    final bool isActive = state.isAbilityActive;

    Color barColor = Colors.cyan;
    Color glowColor = Colors.transparent;
    String label = "CARGANDO";

    if (isActive) {
      barColor = Colors.orangeAccent;
      label = "¡ACTIVA!";
    } else if (isReady) {
      barColor = Colors.yellowAccent;
      glowColor = Colors.yellow;
      label = "LISTO (X)";
    } else {
      label = "${(percentage * 100).toInt()}%";
    }

    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(
          color: isReady ? Colors.white : Colors.grey,
          width: 3,
        ),
        boxShadow: [
          if (isReady || isActive)
            BoxShadow(
              color: glowColor.withOpacity(0.6),
              blurRadius: 0,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * percentage,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.zero,
                  shape: BoxShape.rectangle,
                ),
              );
            },
          ),

          Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),

          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Image.asset(
                'assets/images/ui/icon_lightning.png',
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerupIndicator(String iconPath, double timer) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            timer > 90 ? "ON" : "${timer.toStringAsFixed(1)}s",
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
