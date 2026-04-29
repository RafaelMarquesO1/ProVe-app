import 'package:flutter/material.dart';

/// Classe utilitária para cores adaptáveis ao tema claro/escuro
class ThemeColors {
  /// Cores semi-transparentes para backgrounds
  static Color getSurfaceOverlay(
    BuildContext context, {
    double opacity = 0.04,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.white.withValues(alpha: opacity);
    }
    return Colors.black.withValues(alpha: opacity);
  }

  /// Cor para divisores/borders
  static Color getDividerColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.white12;
    }
    return Colors.grey.shade200;
  }

  /// Cor para texto secundário
  static Color getSecondaryTextColor(
    BuildContext context, {
    double opacity = 0.7,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.white.withValues(alpha: opacity);
    }
    return Colors.black.withValues(alpha: opacity);
  }

  /// Cor para texto terciário (mais fraco)
  static Color getTertiaryTextColor(
    BuildContext context, {
    double opacity = 0.5,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.white.withValues(alpha: opacity);
    }
    return Colors.grey.shade500;
  }

  /// Cor para ícones secundários
  static Color getSecondaryIconColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.white70;
    }
    return Colors.grey.shade600;
  }

  /// Cor para cards/containers
  static Color getCardBackground(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return const Color(0xFF1C1C1E);
    }
    return Colors.white;
  }

  /// Cor para backgrounds leves
  static Color getLightBackground(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return const Color(0xFF2A2A2C);
    }
    return Colors.grey.shade50;
  }

  /// Cor para shimmer (loading)
  static List<Color> getShimmerColors(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return [
        const Color(0xFF2A2A2C),
        const Color(0xFF3A3A3C),
        const Color(0xFF2A2A2C),
      ];
    }
    return [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade200];
  }

  /// Cor para desabilitado/inativo
  static Color getDisabledColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (isDarkMode) {
      return Colors.grey.shade600;
    }
    return Colors.grey.shade400;
  }

  /// Sombras tema-adaptáveis para cards e containers
  static BoxShadow getCardShadow(
    BuildContext context, {
    double opacity = 0.04,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDarkMode
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 8),
    );
  }

  /// Sombra mais forte para elementos elevados
  static BoxShadow getElevatedShadow(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDarkMode
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }
}
