import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  int _coins = 0;
  int _score = 0;
  double _timeElapsed = 0.0;
  final double _scoreMultiplier = 10.0; // Puntos por segundo

  int get coins => _coins;
  int get score => _score;
  double get timeElapsed => _timeElapsed;

  void addCoin() {
    _coins++;
    notifyListeners();
  }

  void updateTime(double dt) {
    _timeElapsed += dt;
    _score = (_timeElapsed * _scoreMultiplier).toInt();
    notifyListeners();
  }

  void reset() {
    _coins = 0;
    _score = 0;
    _timeElapsed = 0.0;
    notifyListeners();
  }
}
