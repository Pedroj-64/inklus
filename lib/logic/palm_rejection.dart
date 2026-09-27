// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/gestures.dart';

/// Política de entrada del lienzo: decide qué punteros pueden dibujar.
///
/// Reglas (en orden):
/// 1. Stylus / goma del stylus / mouse siempre dibujan.
/// 2. Un toque se descarta si hay un lápiz **apoyado**, **flotando cerca**
///    (hover, S-Pen/Apple Pencil lo reportan a ~1 cm) o levantado hace muy
///    poco: la palma suele tocar justo antes/después del trazo.
/// 3. Un toque con área de contacto grande es una palma (si el dispositivo
///    reporta `radiusMajor`; muchos reportan 0 y entonces no se usa).
///
/// Es una clase pura (sin widgets) para poder probarla con tests.
class PalmRejection {
  PalmRejection({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

  /// Tras levantar el lápiz, los toques se ignoran durante este tiempo.
  static const stylusGrace = Duration(milliseconds: 400);

  /// Un hover mantiene "lápiz cerca" durante este tiempo desde el último evento.
  static const hoverGrace = Duration(milliseconds: 350);

  /// Radio (px lógicos) a partir del cual un contacto se considera palma.
  static const palmRadius = 28.0;

  final Set<int> _stylusPointers = {};
  DateTime? _lastStylusActivity;

  static bool isStylusKind(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus || kind == PointerDeviceKind.invertedStylus;

  /// Hay un lápiz apoyado ahora mismo.
  bool get stylusDown => _stylusPointers.isNotEmpty;

  /// Hay un lápiz apoyado, flotando cerca o recién levantado.
  bool get stylusNearby {
    if (stylusDown) return true;
    final last = _lastStylusActivity;
    return last != null && _now().difference(last) < stylusGrace;
  }

  void stylusDownEvent(int pointer) {
    _stylusPointers.add(pointer);
    _lastStylusActivity = _now();
  }

  void stylusUpEvent(int pointer) {
    _stylusPointers.remove(pointer);
    _lastStylusActivity = _now();
  }

  /// Hover del lápiz (sin tocar). Extiende la ventana de "lápiz cerca".
  void stylusHoverEvent() {
    // Se guarda como actividad "futura" para que la ventana dure hoverGrace.
    _lastStylusActivity = _now().subtract(stylusGrace - hoverGrace);
  }

  /// true si un toque de dedo debe ignorarse por completo.
  bool rejectTouch({double radiusMajor = 0}) {
    if (stylusNearby) return true;
    if (radiusMajor > palmRadius) return true;
    return false;
  }

  /// Limpia el estado (p. ej. al perder el foco la ventana).
  void reset() {
    _stylusPointers.clear();
    _lastStylusActivity = null;
  }
}
