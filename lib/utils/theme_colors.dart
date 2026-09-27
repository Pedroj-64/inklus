// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Colores adaptativos derivados del [ColorScheme] del tema actual.
///
/// Se mantiene por compatibilidad con pantallas existentes. **Para código
/// nuevo** usar directamente `context.colors` / `context.inklus`
/// (`ui/theme/inklus_colors.dart`).
class ThemeColors {
  const ThemeColors(this.scheme);

  final ColorScheme scheme;

  static ThemeColors of(BuildContext context) =>
      ThemeColors(Theme.of(context).colorScheme);

  bool get isDark => scheme.brightness == Brightness.dark;

  // -- Texto --
  Color get textPrimary => scheme.onSurface;
  Color get textSecondary => scheme.onSurfaceVariant;
  Color get textTertiary => scheme.onSurfaceVariant.withValues(alpha: 0.72);
  Color get textDisabled => scheme.onSurface.withValues(alpha: 0.38);
  Color get textHint => scheme.onSurfaceVariant;

  // -- Bordes --
  Color get border => scheme.outline;
  Color get borderLight => scheme.outlineVariant;

  // -- Fondos --
  Color get iconBg => scheme.surfaceContainerHighest;
  Color get shadow => scheme.shadow.withValues(alpha: isDark ? 0.4 : 0.12);
  Color get surfaceOverlay => scheme.surfaceContainerHigh;

  // -- Íconos --
  Color get iconSecondary => scheme.onSurfaceVariant;
  Color get iconTertiary => scheme.onSurfaceVariant.withValues(alpha: 0.72);
}
