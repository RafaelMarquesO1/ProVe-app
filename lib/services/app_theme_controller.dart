import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._internal();
  static final AppThemeController instance = AppThemeController._internal();

  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localTheme = prefs.getString('themeMode');
      _updateThemeMode(_modeFromString(localTheme) ?? ThemeMode.light);
    } catch (e) {
      debugPrint('Erro ao carregar tema local: $e');
      _updateThemeMode(ThemeMode.light);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _updateThemeMode(mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', _modeToString(mode));
    } catch (e) {
      debugPrint('Erro ao salvar tema localmente: $e');
    }
  }

  void _updateThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  ThemeMode? _modeFromString(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      default:
        return null;
    }
  }
}
