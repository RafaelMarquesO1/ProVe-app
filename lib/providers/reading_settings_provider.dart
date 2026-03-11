import 'package:flutter/material.dart';

class ReadingSettingsProvider with ChangeNotifier {
  // Etapa 1: Construtor privado
  ReadingSettingsProvider._privateConstructor();

  // Etapa 2: Instância estática (Singleton)
  static final ReadingSettingsProvider instance = ReadingSettingsProvider._privateConstructor();

  double _fontSize = 16.0;
  Color _backgroundColor = const Color(0xFFF5F5DC); // Bege claro

  double get fontSize => _fontSize;
  Color get backgroundColor => _backgroundColor;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }
}
