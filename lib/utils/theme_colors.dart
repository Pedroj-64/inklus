import 'package:flutter/material.dart';

/// Helper para obtener colores adaptativos según el tema actual.
///
/// Uso:
/// ```dart
/// final colors = ThemeColors.of(context);
/// Text('Hello', style: TextStyle(color: colors.textSecondary))
/// ```
class ThemeColors {
  final Brightness brightness;

  const ThemeColors(this.brightness);

  bool get isDark => brightness == Brightness.dark;

  static ThemeColors of(BuildContext context) =>
      ThemeColors(Theme.of(context).brightness);

  // -- Texto --
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;
  Color get textTertiary => isDark ? Colors.white38 : Colors.black38;
  Color get textDisabled => isDark ? Colors.white24 : Colors.black26;
  Color get textHint => isDark ? Colors.white54 : Colors.black45;

  // -- Bordes --
  Color get border => isDark ? Colors.white24 : Colors.black26;
  Color get borderLight => isDark ? Colors.white12 : Colors.black12;

  // -- Fondos --
  Color get iconBg => isDark ? Colors.white12 : Colors.black.withAlpha(18);
  Color get shadow => isDark ? Colors.black26 : Colors.black12;
  Color get surfaceOverlay => isDark ? Colors.white12 : Colors.black.withAlpha(12);

  // -- Íconos --
  Color get iconSecondary => isDark ? Colors.white54 : Colors.black54;
  Color get iconTertiary => isDark ? Colors.white38 : Colors.black38;
}
