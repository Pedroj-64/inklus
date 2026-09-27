// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

import '../models/stroke.dart';

// Geometría pura del bote de pintura (extraída de CanvasController).

/// Agrupa trazos en componentes conectados usando distancia umbral.
List<List<Stroke>> groupStrokesIntoComponents(
  List<Stroke> strokes,
  double maxDistance,
) {
  final visited = List<bool>.filled(strokes.length, false);
  final components = <List<Stroke>>[];

  for (var i = 0; i < strokes.length; i++) {
    if (visited[i]) continue;
    final component = <Stroke>[];
    final queue = [i];
    while (queue.isNotEmpty) {
      final idx = queue.removeLast();
      if (visited[idx]) continue;
      visited[idx] = true;
      component.add(strokes[idx]);
      // Buscar trazos cercanos no visitados.
      for (var j = idx + 1; j < strokes.length; j++) {
        if (visited[j]) continue;
        if (_strokesClose(strokes[idx], strokes[j], maxDistance)) {
          queue.add(j);
        }
      }
    }
    components.add(component);
  }
  return components;
}

/// Determina si dos trazos están cerca (algún punto de uno está a
/// distancia < [maxDistance] de algún punto del otro).
bool _strokesClose(Stroke a, Stroke b, double maxDistance) {
  // Muestreo rápido: comparar puntos cada N para no hacer O(n²).
  final stepA = max(1, a.points.length ~/ 10);
  final stepB = max(1, b.points.length ~/ 10);
  for (var i = 0; i < a.points.length; i += stepA) {
    for (var j = 0; j < b.points.length; j += stepB) {
      final dx = a.points[i].x - b.points[j].x;
      final dy = a.points[i].y - b.points[j].y;
      if (dx * dx + dy * dy < maxDistance * maxDistance) return true;
    }
  }
  return false;
}

/// Convex hull de Andrew (O(n log n)).
List<Offset> convexHull(List<Offset> points) {
  if (points.length < 3) return points;
  final sorted = List<Offset>.from(points)
    ..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  final hull = <Offset>[];
  // Lower hull
  for (final p in sorted) {
    while (hull.length >= 2 &&
        _cross(hull[hull.length - 2], hull[hull.length - 1], p) <= 0) {
      hull.removeLast();
    }
    hull.add(p);
  }
  // Upper hull
  final lowerLen = hull.length + 1;
  for (var i = sorted.length - 2; i >= 0; i--) {
    while (hull.length >= lowerLen &&
        _cross(hull[hull.length - 2], hull[hull.length - 1], sorted[i]) <= 0) {
      hull.removeLast();
    }
    hull.add(sorted[i]);
  }
  hull.removeLast(); // duplicado del primer punto
  return hull;
}

double _cross(Offset o, Offset a, Offset b) =>
    (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
