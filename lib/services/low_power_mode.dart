// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «Modo ahorro» para tablets y móviles modestos: imágenes más pequeñas en
/// memoria y caché reducida. Se recuerda entre sesiones; surte efecto al
/// abrir la siguiente nota.
abstract final class LowPowerMode {
  static const _pref = 'low_power_mode';
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  /// Lado mayor (px) con que se decodifican las imágenes del lienzo.
  static int get canvasImageMaxSide => enabled.value ? 1280 : 2560;

  /// Presupuesto de la caché de imágenes decodificadas.
  static int get imageCacheBytes => (enabled.value ? 64 : 192) * 1024 * 1024;

  static Future<void> load() async {
    try {
      enabled.value = (await SharedPreferences.getInstance()).getBool(_pref) ?? false;
    } catch (_) {}
  }

  static Future<void> set(bool value) async {
    enabled.value = value;
    try {
      await (await SharedPreferences.getInstance()).setBool(_pref, value);
    } catch (_) {}
  }
}
