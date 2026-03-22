import 'package:flutter/material.dart';

// Enum para representar a seleção de voz
enum VoiceType { masculina, feminina }

class ReadingSettingsProvider with ChangeNotifier {
  // Construtor privado
  ReadingSettingsProvider._privateConstructor();

  // Instância estática (Singleton)
  static final ReadingSettingsProvider instance = ReadingSettingsProvider._privateConstructor();

  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFFFFF9F0);
  double _speechRate = 1.0; // Velocidade normal
  VoiceType _voiceType = VoiceType.feminina; // Padrão para voz feminina

  double get fontSize => _fontSize;
  Color get backgroundColor => _backgroundColor;
  double get speechRate => _speechRate;
  VoiceType get voiceType => _voiceType;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    notifyListeners();
  }

  void setVoiceType(VoiceType type) {
    _voiceType = type;
    notifyListeners();
  }
}
