// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

import '../constants.dart';

/// A qué parte de la regla se engancha un trazo.
enum RulerSnap { edgeTop, edgeBottom, arc, baseline }

/// Unidades de mundo por centímetro: la hoja A4 mide 1191 unidades de ancho
/// = 21 cm, así que la regla mide en centímetros "de la hoja" (lo que se lee
/// en la regla coincide con la página, a cualquier zoom).
const double kWorldUnitsPerCm = 1191 / 21;

/// Geometría pura de la regla/transportador (sin widgets, testeable).
///
/// La regla tiene **tamaño constante en pantalla** (como en Samsung Notes y
/// GoodNotes): su largo/ancho en unidades de mundo dependen del zoom. Su
/// posición ([center]) y [angle] viven en coordenadas de mundo para que se
/// quede "pegada" a la hoja al desplazar la vista.
class RulerGeometry {
  const RulerGeometry({
    required this.type,
    required this.center,
    required this.angle,
    required this.scale,
  });

  /// Tamaños en píxeles de pantalla.
  static const double lengthPx = 720;
  static const double widthPx = 76;
  static const double protractorRadiusPx = 230;

  /// Distancia (px de pantalla) a la que un trazo se engancha a un borde.
  static const double snapPx = 26;

  final RulerType type;
  final Offset center;
  final double angle;
  final double scale;

  Offset get dir => Offset(cos(angle), sin(angle));
  Offset get normal => Offset(-sin(angle), cos(angle));

  double get halfLength => lengthPx / 2 / scale;
  double get halfWidth => widthPx / 2 / scale;
  double get radius => protractorRadiusPx / scale;
  double get _snap => snapPx / scale;

  /// Coordenadas locales (a lo largo, a través) de un punto de mundo.
  Offset toLocal(Offset p) {
    final d = p - center;
    return Offset(d.dx * dir.dx + d.dy * dir.dy, d.dx * normal.dx + d.dy * normal.dy);
  }

  Offset fromLocal(Offset l) => center + dir * l.dx + normal * l.dy;

  /// true si [p] (mundo) cae sobre el cuerpo de la regla.
  bool hitTest(Offset p, {double slopPx = 10}) {
    final l = toLocal(p);
    final slop = slopPx / scale;
    switch (type) {
      case RulerType.straight:
        return l.dx.abs() <= halfLength + slop && l.dy.abs() <= halfWidth + slop;
      case RulerType.protractor:
        // Semicírculo "encima" de la base (lado negativo de la normal).
        return l.distance <= radius + slop && l.dy <= slop;
    }
  }

  /// Borde/arco al que debe engancharse un trazo que empieza en [p], o null
  /// si empieza lejos (entonces se dibuja libremente).
  RulerSnap? snapFor(Offset p) {
    final l = toLocal(p);
    switch (type) {
      case RulerType.straight:
        if (l.dx.abs() > halfLength + _snap) return null;
        final dTop = (l.dy + halfWidth).abs();
        final dBottom = (l.dy - halfWidth).abs();
        if (dTop <= _snap && dTop <= dBottom) return RulerSnap.edgeTop;
        if (dBottom <= _snap) return RulerSnap.edgeBottom;
        return null;
      case RulerType.protractor:
        final dArc = (l.distance - radius).abs();
        final dBase = l.dy.abs();
        if (dArc <= _snap && l.dy <= _snap && dArc <= dBase) return RulerSnap.arc;
        if (dBase <= _snap && l.dx.abs() <= radius + _snap) return RulerSnap.baseline;
        return null;
    }
  }

  /// Proyecta [p] sobre el borde/arco [snap].
  Offset project(RulerSnap snap, Offset p) {
    final l = toLocal(p);
    switch (snap) {
      case RulerSnap.edgeTop:
        return fromLocal(Offset(l.dx, -halfWidth));
      case RulerSnap.edgeBottom:
        return fromLocal(Offset(l.dx, halfWidth));
      case RulerSnap.baseline:
        return fromLocal(Offset(l.dx, 0));
      case RulerSnap.arc:
        final d = l.distance;
        if (d < 1e-6) return fromLocal(Offset(radius, 0));
        return fromLocal(l / d * radius);
    }
  }

  /// Ángulo en grados, normalizado a (-180, 180].
  static double degrees(double radians) {
    var d = radians * 180 / pi;
    d = d % 360;
    if (d > 180) d -= 360;
    return d;
  }

  /// Imán de ángulo: si está a menos de [toleranceDeg] de un múltiplo de
  /// 45°, lo ajusta (horizontal, vertical, diagonales).
  static double snapAngle(double radians, {double toleranceDeg = 2}) {
    const step = pi / 4;
    final nearest = (radians / step).round() * step;
    return (radians - nearest).abs() <= toleranceDeg * pi / 180 ? nearest : radians;
  }
}
