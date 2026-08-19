import 'dart:ui';

import '../models/stroke.dart';

// ============================================================================
// Utilidades geométricas compartidas
//
// Extraídas de duplicados en drawing_canvas.dart, shape_detector.dart,
// snap_guides.dart y world_painter.dart.
// ============================================================================

/// Calcula el bounding box de una lista de puntos.
///
/// Devuelve `Rect.zero` si la lista está vacía.
Rect boundingBoxFromPoints(List<StrokePoint> points) {
  if (points.isEmpty) return Rect.zero;
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final p in points) {
    if (p.x < left) left = p.x;
    if (p.y < top) top = p.y;
    if (p.x > right) right = p.x;
    if (p.y > bottom) bottom = p.y;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Calcula el bounding box de una lista de trazos (todos sus puntos).
///
/// Incluye el grosor del trazo en el cálculo.
Rect boundingBoxFromStrokes(List<Stroke> strokes) {
  if (strokes.isEmpty) return Rect.zero;
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final s in strokes) {
    for (final p in s.points) {
      if (p.x < left) left = p.x;
      if (p.y < top) top = p.y;
      if (p.x > right) right = p.x;
      if (p.y > bottom) bottom = p.y;
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Algoritmo ray-casting para determinar si un punto está dentro de un polígono.
///
/// Método estándar O(n) con un solo recorrido. Usado por el lazo, bucket fill
/// y hit-test de imágenes.
bool pointInPolygon(Offset point, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].dx;
    final yi = polygon[i].dy;
    final xj = polygon[j].dx;
    final yj = polygon[j].dy;
    if (((yi > point.dy) != (yj > point.dy)) &&
        (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  return inside;
}

/// Centro (promedio) de un polígono.
Offset polygonCenter(List<Offset> polygon) {
  if (polygon.isEmpty) return Offset.zero;
  var x = 0.0;
  var y = 0.0;
  for (final p in polygon) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / polygon.length, y / polygon.length);
}

/// Longitud total del camino recorrido por una lista de puntos.
double pathLength(List<StrokePoint> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i].offset - points[i - 1].offset).distance;
  }
  return length;
}
