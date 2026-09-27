// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

import '../models/stroke.dart';
import '../utils/geometry_utils.dart';

// Geometría pura de la selección con lazo (extraída de CanvasController).

/// Calcula los límites del polígono del lazo.
Rect polygonBounds(List<Offset> polygon) {
  if (polygon.isEmpty) return Rect.zero;
  var left = double.infinity, top = double.infinity;
  var right = double.negativeInfinity, bottom = double.negativeInfinity;
  for (final p in polygon) {
    if (p.dx < left) left = p.dx;
    if (p.dy < top) top = p.dy;
    if (p.dx > right) right = p.dx;
    if (p.dy > bottom) bottom = p.dy;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Determina si un trazo está "dentro" del lazo usando 3 estrategias.
bool isStrokeInLasso(
  Stroke stroke,
  List<Offset> lassoPolygon,
  Rect lassoBounds,
) {
  if (stroke.points.isEmpty) return false;

  // --- Estrategia 1: Bounding box rápido ---
  // Si el bounding box del trazo no interseca el del lazo, no puede estar dentro.
  final strokeBounds = stroke.pointBounds;
  if (!strokeBounds.overlaps(lassoBounds)) return false;

  // --- Estrategia 2: Punto dentro del polígono ---
  // El más preciso: algún punto del trazo está dentro del lazo.
  for (final p in stroke.points) {
    if (pointInPolygon(p.offset, lassoPolygon)) return true;
  }

  // --- Estrategia 3: Bounding box completamente dentro ---
  // Para trazos grandes cuyos puntos están fuera pero el área del trazo
  // (considerando su grosor) está dentro del lazo.
  final halfSize = stroke.size / 2;
  final inflatedStroke = strokeBounds.inflate(halfSize);
  if (_isRectInsidePolygon(inflatedStroke, lassoPolygon)) return true;

  // --- Estrategia 4: Intersección de bordes ---
  // Verificar si algún segmento del trazo cruza algún segmento del lazo.
  if (_strokeIntersectsLasso(stroke, lassoPolygon)) return true;

  return false;
}

/// Verifica si un rectángulo está completamente dentro de un polígono.
bool _isRectInsidePolygon(Rect rect, List<Offset> polygon) {
  // Verificar las 4 esquinas + centro + puntos medios de los lados.
  final testPoints = [
    rect.topLeft,
    rect.topRight,
    rect.bottomLeft,
    rect.bottomRight,
    rect.center,
    rect.centerLeft,
    rect.centerRight,
    rect.topCenter,
    rect.bottomCenter,
  ];
  for (final p in testPoints) {
    if (!pointInPolygon(p, polygon)) return false;
  }
  return true;
}

/// Verifica si algún segmento del trazo cruza algún segmento del lazo.
bool _strokeIntersectsLasso(
  Stroke stroke,
  List<Offset> lassoPolygon,
) {
  // Muestrear el trazo para no hacer O(n*m) con todos los puntos.
  final step = max(1, stroke.points.length ~/ 20);
  final strokeSegments = <(Offset, Offset)>[];
  for (var i = 0; i < stroke.points.length - 1; i += step) {
    final next = min(i + step, stroke.points.length - 1);
    strokeSegments.add((
      stroke.points[i].offset,
      stroke.points[next].offset,
    ));
  }

  // Verificar intersección entre cada segmento del trazo y cada segmento del lazo.
  for (final (a, b) in strokeSegments) {
    for (var i = 0; i < lassoPolygon.length; i++) {
      final j = (i + 1) % lassoPolygon.length;
      if (segmentsIntersect(
        a, b,
        lassoPolygon[i], lassoPolygon[j],
      )) {
        return true;
      }
    }
  }
  return false;
}

/// Verifica si dos segmentos de línea se cruzan (intersección proper).
bool segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  final d1 = _direction(b1, b2, a1);
  final d2 = _direction(b1, b2, a2);
  final d3 = _direction(a1, a2, b1);
  final d4 = _direction(a1, a2, b2);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }

  // Casos especiales: puntos colineales.
  if (d1 == 0 && _onSegment(b1, b2, a1)) return true;
  if (d2 == 0 && _onSegment(b1, b2, a2)) return true;
  if (d3 == 0 && _onSegment(a1, a2, b1)) return true;
  if (d4 == 0 && _onSegment(a1, a2, b2)) return true;

  return false;
}

/// Producto cruz para determinar orientación.
double _direction(Offset a, Offset b, Offset c) {
  return (c.dx - a.dx) * (b.dy - a.dy) - (c.dy - a.dy) * (b.dx - a.dx);
}

/// Verifica si el punto [p] está en el segmento [a]-[b].
bool _onSegment(Offset a, Offset b, Offset p) {
  return p.dx >= min(a.dx, b.dx) &&
      p.dx <= max(a.dx, b.dx) &&
      p.dy >= min(a.dy, b.dy) &&
      p.dy <= max(a.dy, b.dy);
}
