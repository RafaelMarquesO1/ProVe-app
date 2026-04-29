import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

    _authSubscription = _auth.userChanges().listen((user) {
      _loadThemeForUser(user);
    });

    await _loadThemeForUser(_auth.currentUser);
  }

  Future<void> _loadThemeForUser(User? user) async {
    if (user == null) {
      _updateThemeMode(ThemeMode.light);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final rawTheme = doc.data()?['themeMode'] as String?;
      final mode = _modeFromString(rawTheme) ?? ThemeMode.light;
      _updateThemeMode(mode);
    } catch (e) {
      debugPrint('Erro ao carregar tema do usuário: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _updateThemeMode(mode);

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'themeMode': _modeToString(mode),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar tema do usuário: $e');
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
