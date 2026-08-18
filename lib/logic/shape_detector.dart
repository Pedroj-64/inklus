import 'dart:math';
import 'dart:ui';

import '../models/stroke.dart';

/// Resultado de la detección de una forma en un trazo.
class DetectedShape {
  final ShapeType type;
  final List<StrokePoint> normalizedPoints;

  const DetectedShape(this.type, this.normalizedPoints);
}

enum ShapeType { line, rectangle, circle, arrow }

/// Detecta si un trazo se aproxima a una forma geométrica simple.
///
/// Se llama al finalizar un trazo para post-procesarlo. Si el trazo se
/// parece a una forma, devuelve los puntos normalizados de esa forma;
/// si no, devuelve null (el trazo se queda como está).
class ShapeDetector {
  const ShapeDetector._();

  static const double _minPoints = 10;
  static const double _lineTolerance = 0.12; // 12% de la longitud
  static const double _circleTolerance = 0.15;
  static const double _rectAngleThreshold = pi / 8; // ~22.5°

  /// Analiza un trazo y devuelve la forma detectada o null.
  static DetectedShape? detect(List<StrokePoint> points) {
    if (points.length < _minPoints) return null;

    final first = points.first.offset;
    final last = points.last.offset;
    final totalLength = _pathLength(points);

    // ¿Es una línea recta o flecha?
    final lineResult = _detectLine(points, first, last, totalLength);
    if (lineResult != null) return lineResult;

    // ¿Es un rectángulo?
    final rectResult = _detectRectangle(points, totalLength);
    if (rectResult != null) return rectResult;

    // ¿Es un círculo/óvalo?
    final circleResult = _detectCircle(points);
    if (circleResult != null) return circleResult;

    return null;
  }

  /// Calcula la longitud total del camino del trazo.
  static double _pathLength(List<StrokePoint> points) {
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += (points[i].offset - points[i - 1].offset).distance;
    }
    return length;
  }

  /// Detecta si el trazo es una línea recta o una flecha.
  static DetectedShape? _detectLine(
    List<StrokePoint> points,
    Offset first,
    Offset last,
    double totalLength,
  ) {
    final lineLength = (last - first).distance;
    if (lineLength < 30) return null;

    // La distancia recorrida no debería ser mucho mayor que la distancia
    // en línea recta (indicaría curvas).
    if (totalLength > lineLength * (1 + _lineTolerance)) return null;

    // Todos los puntos deberían estar cerca de la línea recta.
    final dir = (last - first) / lineLength;
    final normal = Offset(-dir.dy, dir.dx);
    final maxDeviation = lineLength * _lineTolerance;
    for (final p in points) {
      final d = p.offset - first;
      final dev = (normal * (normal.dx * d.dx + normal.dy * d.dy)).distance;
      if (dev > maxDeviation) return null;
    }

    // Detecta si es una flecha: si los últimos puntos forman una punta.
    final isArrow = _detectArrowHead(points, first, last);
    final type = isArrow ? ShapeType.arrow : ShapeType.line;

    return DetectedShape(
      type,
      [StrokePoint.fromOffset(first, 0.5), StrokePoint.fromOffset(last, 0.5)],
    );
  }

  /// Detecta si hay una cabeza de flecha al final del trazo.
  static bool _detectArrowHead(
    List<StrokePoint> points,
    Offset first,
    Offset last,
  ) {
    if (points.length < 15) return false;

    // Toma los últimos 20% de los puntos y verifica si forman un ángulo
    // agudo con la dirección principal.
    final tailStart = (points.length * 0.8).round();
    final dir = (last - first);
    if (dir.distance < 30) return false;

    var deviatingPoints = 0;
    for (var i = tailStart; i < points.length; i++) {
      final d = points[i].offset - points[tailStart].offset;
      if (d.distance < 5) continue;
      final angle = d.direction - dir.direction;
      if (angle.abs() > pi / 4) deviatingPoints++;
    }

    return deviatingPoints >= 3;
  }

  /// Detecta si el trazo es un rectángulo.
  static DetectedShape? _detectRectangle(
    List<StrokePoint> points,
    double totalLength,
  ) {
    if (points.length < 20) return null;

    // Encuentra las 4 esquinas aproximadas (puntos de curvatura máxima).
    final corners = _findCorners(points);
    if (corners.length < 3 || corners.length > 5) return null;

    // Verifica que los lados sean rectos y los ángulos cercanos a 90°.
    final rect = _boundingRect(points);
    if (rect.width < 30 || rect.height < 30) return null;

    // ¿Los corners están cerca de las esquinas del rectángulo delimitador?
    final cornersExpected = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    var matched = 0;
    for (final c in corners) {
      for (final expected in cornersExpected) {
        if ((c - expected).distance < rect.shortestSide * 0.2) {
          matched++;
          break;
        }
      }
    }

    if (matched >= 3) {
      return DetectedShape(ShapeType.rectangle, [
        StrokePoint.fromOffset(rect.topLeft, 0.5),
        StrokePoint.fromOffset(rect.topRight, 0.5),
        StrokePoint.fromOffset(rect.bottomRight, 0.5),
        StrokePoint.fromOffset(rect.bottomLeft, 0.5),
      ]);
    }
    return null;
  }

  /// Detecta si el trazo es un círculo u óvalo.
  static DetectedShape? _detectCircle(List<StrokePoint> points) {
    if (points.length < 20) return null;

    final rect = _boundingRect(points);
    if (rect.shortestSide < 30) return null;

    final center = rect.center;
    final avgRadius = (rect.width + rect.height) / 4;

    // Verifica que los puntos estén a una distancia similar del centro.
    var deviation = 0.0;
    for (final p in points) {
      final d = (p.offset - center).distance;
      deviation += (d - avgRadius).abs();
    }
    deviation /= points.length;

    if (deviation < avgRadius * _circleTolerance) {
      // Genera puntos de círculo perfecto.
      final circlePoints = <StrokePoint>[];
      for (var i = 0; i <= 60; i++) {
        final angle = (i / 60) * 2 * pi;
        final p = center + Offset(cos(angle), sin(angle)) * avgRadius;
        circlePoints.add(StrokePoint.fromOffset(p, 0.5));
      }
      return DetectedShape(ShapeType.circle, circlePoints);
    }
    return null;
  }

  /// Encuentra las esquinas (puntos de curvatura máxima) en el trazo.
  static List<Offset> _findCorners(List<StrokePoint> points) {
    if (points.length < 10) return [];

    final corners = <Offset>[];
    final windowSize = max(3, points.length ~/ 10);

    for (var i = windowSize; i < points.length - windowSize; i++) {
      final prev = points[i - windowSize].offset;
      final curr = points[i].offset;
      final next = points[i + windowSize].offset;

      final d1 = (curr - prev).direction;
      final d2 = (next - curr).direction;
      final angleDiff = (d2 - d1).abs();
      final normalizedDiff = angleDiff > pi ? 2 * pi - angleDiff : angleDiff;

      if (normalizedDiff > _rectAngleThreshold) {
        // Evita esquinas muy cercanas entre sí.
        if (corners.isEmpty ||
            (curr - corners.last).distance > 20) {
          corners.add(curr);
        }
      }
    }

    return corners;
  }

  /// Rectángulo delimitador de los puntos.
  static Rect _boundingRect(List<StrokePoint> points) {
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    for (final p in points) {
      if (p.x < left) left = p.x;
      if (p.y < top) top = p.y;
      if (p.x > right) right = p.x;
      if (p.y > bottom) bottom = p.y;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
