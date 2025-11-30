import 'package:carrito_run/game/game.dart';
import 'package:carrito_run/game/states/game_state.dart';
import 'package:carrito_run/game/overlays/start_screen.dart';
import 'package:carrito_run/game/overlays/pause_menu.dart';
import 'package:carrito_run/game/overlays/pause_button.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.fullScreen();

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
                    ],
                  ),
                ),
              );
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScoreDisplay(gameState.score),
                    _buildCoinCounter(gameState.coins),
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
}
