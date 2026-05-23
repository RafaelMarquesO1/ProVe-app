import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._internal();
  static final AppThemeController instance = AppThemeController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Carrega do SharedPreferences local primeiro para evitar piscadas
    try {
      final prefs = await SharedPreferences.getInstance();
      final localTheme = prefs.getString('themeMode');
      if (localTheme != null) {
        final mode = _modeFromString(localTheme);
        if (mode != null) {
          _updateThemeMode(mode);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar tema local inicial: $e');
    }

    _authSubscription = _auth.userChanges().listen((user) {
      _loadThemeForUser(user);
    });

    await _loadThemeForUser(_auth.currentUser);
  }

  Future<void> _loadThemeForUser(User? user) async {
    if (user == null) {
      // Se não houver usuário logado, mantém o tema do SharedPreferences local
      try {
        final prefs = await SharedPreferences.getInstance();
        final localTheme = prefs.getString('themeMode');
        final mode = _modeFromString(localTheme) ?? ThemeMode.light;
        _updateThemeMode(mode);
      } catch (e) {
        _updateThemeMode(ThemeMode.light);
      }
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final rawTheme = doc.data()?['themeMode'] as String?;
        final mode = _modeFromString(rawTheme);
        if (mode != null) {
          _updateThemeMode(mode);
          // Sincroniza com o SharedPreferences local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('themeMode', _modeToString(mode));
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar tema do usuário do Firestore: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _updateThemeMode(mode);

    // Salva localmente no SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', _modeToString(mode));
    } catch (e) {
      debugPrint('Erro ao salvar tema localmente: $e');
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'themeMode': _modeToString(mode),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar tema do usuário no Firestore: $e');
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
