import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum para representar a seleção de voz
enum VoiceType { masculina, feminina }

class ReadingSettingsProvider with ChangeNotifier {
  static const String _fontSizeKey = 'reading_font_size';
  static const String _backgroundColorKey = 'reading_background_color';
  static const String _speechRateKey = 'reading_speech_rate';
  static const String _voiceTypeKey = 'reading_voice_type';

  // Construtor privado
  ReadingSettingsProvider._privateConstructor() {
    _loadSettings();
  }

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
    _saveSettings();
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    _saveSettings();
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    _saveSettings();
    notifyListeners();
  }

  void setVoiceType(VoiceType type) {
    _voiceType = type;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? _fontSize;
    _backgroundColor =
        Color(prefs.getInt(_backgroundColorKey) ?? _backgroundColor.value);
    _speechRate = prefs.getDouble(_speechRateKey) ?? _speechRate;
    final String? savedVoice = prefs.getString(_voiceTypeKey);
    if (savedVoice != null) {
      _voiceType = savedVoice == 'masculina'
          ? VoiceType.masculina
          : VoiceType.feminina;
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setInt(_backgroundColorKey, _backgroundColor.value);
    await prefs.setDouble(_speechRateKey, _speechRate);
    await prefs.setString(_voiceTypeKey, _voiceType.name);
  }
}
