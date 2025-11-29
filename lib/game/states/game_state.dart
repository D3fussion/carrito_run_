import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  int _coins = 0;

  int get coins => _coins;

  void addCoin() {
    _coins++;
    notifyListeners();
  }

  void reset() {
    _coins = 0;
    notifyListeners();
  }
}
