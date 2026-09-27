// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema de la app (claro/oscuro/sistema), compartido por todas las
/// pantallas y **recordado** entre sesiones.
class ThemeModeController {
  ThemeModeController._();

  static const _pref = 'theme_mode';

  /// Modo actual. `InklusApp` lo escucha para reconstruir el MaterialApp.
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_pref);
      mode.value = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {}
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pref, value.name);
    } catch (_) {}
  }

  /// Alterna claro ↔ oscuro partiendo de lo que se ve ahora (si el modo era
  /// "sistema", el opuesto del brillo actual).
  static Future<void> toggle(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return set(dark ? ThemeMode.light : ThemeMode.dark);
  }
}
