import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrito_run/models/player_progress.dart';

/// Servicio para guardar y cargar el progreso del jugador localmente
class StorageService {
  static const String _progressKey = 'player_progress_v1';
  
  SharedPreferences? _prefs;

  /// Inicializa el servicio (llamar al inicio de la app)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Guarda el progreso del jugador
  Future<bool> saveProgress(PlayerProgress progress) async {
    try {
      if (_prefs == null) await initialize();
      
      final jsonString = jsonEncode(progress.toJson());
      final success = await _prefs!.setString(_progressKey, jsonString);
      
      if (success) {
        print('✅ Progreso guardado: ${progress.totalCoins} monedas, ${progress.unlockedCarIds.length} carritos');
      }
      
      return success;
    } catch (e) {
      print('❌ Error al guardar progreso: $e');
      return false;
    }
  }

  /// Carga el progreso del jugador
  Future<PlayerProgress> loadProgress() async {
    try {
      if (_prefs == null) await initialize();
      
      final jsonString = _prefs!.getString(_progressKey);
      
      if (jsonString == null) {
        print('📋 No hay progreso guardado, usando inicial');
        return PlayerProgress.initial;
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final progress = PlayerProgress.fromJson(json);
      
      print('✅ Progreso cargado: ${progress.totalCoins} monedas, ${progress.unlockedCarIds.length} carritos');
      return progress;
      
    } catch (e) {
      print('❌ Error al cargar progreso: $e');
      return PlayerProgress.initial;
    }
  }

  /// Borra todo el progreso (resetear juego)
  Future<bool> clearProgress() async {
    try {
      if (_prefs == null) await initialize();
      
      final success = await _prefs!.remove(_progressKey);
      
      if (success) {
        print('🗑️ Progreso eliminado');
      }
      
      return success;
    } catch (e) {
      print('❌ Error al borrar progreso: $e');
      return false;
    }
  }

  /// Verifica si hay progreso guardado
  Future<bool> hasProgress() async {
    if (_prefs == null) await initialize();
    return _prefs!.containsKey(_progressKey);
  }

  /// Exporta el progreso como JSON (para debug o respaldo)
  Future<String?> exportProgress() async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getString(_progressKey);
    } catch (e) {
      print('❌ Error al exportar progreso: $e');
      return null;
    }
  }

  /// Importa progreso desde JSON (para restaurar respaldo)
  Future<bool> importProgress(String jsonString) async {
    try {
      // Validar que sea JSON válido
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      PlayerProgress.fromJson(json); // Validar estructura
      
      if (_prefs == null) await initialize();
      final success = await _prefs!.setString(_progressKey, jsonString);
      
      if (success) {
        print('✅ Progreso importado exitosamente');
      }
      
      return success;
    } catch (e) {
      print('❌ Error al importar progreso: $e');
      return false;
    }
  }
}