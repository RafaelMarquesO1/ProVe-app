import 'package:flutter/material.dart';

class ReadingSettingsProvider with ChangeNotifier {
  // Etapa 1: Construtor privado
  ReadingSettingsProvider._privateConstructor();

  // Etapa 2: Instância estática (Singleton)
  static final ReadingSettingsProvider instance = ReadingSettingsProvider._privateConstructor();

  double _fontSize = 16.0;
  Color _backgroundColor = const Color(0xFFF5F5DC); // Bege claro
  double _speechRate = 0.8; // um valor padrão razoável

  double get fontSize => _fontSize;
  Color get backgroundColor => _backgroundColor;
  double get speechRate => _speechRate;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    // Garante que a velocidade permaneça dentro de um intervalo seguro
    _speechRate = rate.clamp(0.5, 1.0);
    notifyListeners();
  }
}
