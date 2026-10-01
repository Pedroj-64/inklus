// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

import '../models/stroke.dart';
import '../utils/geometry_utils.dart';

/// Resultado de la detección de una forma en un trazo.
class DetectedShape {
  final ShapeType type;
  final List<StrokePoint> normalizedPoints;

  const DetectedShape(this.type, this.normalizedPoints);
}

enum ShapeType { line, rectangle, circle, arrow, triangle }

/// Detecta si un trazo se aproxima a una forma geométrica simple.
///
/// Se llama al finalizar un trazo para post-procesarlo. Si el trazo se
/// parece a una forma, devuelve los puntos normalizados de esa forma;
/// si no, devuelve null (el trazo se queda como está).
class ShapeDetector {
  const ShapeDetector._();

  static const double _minPoints = 10;
  static const double _lineTolerance = 0.12; // 12% de la longitud
  static const double _highlighterLineTolerance = 0.2;
  static const double _axisSnap = 4 * pi / 180; // ±4° a horizontal/vertical
  static const double _highlighterAxisSnap = 8 * pi / 180;
  static const double _circleTolerance = 0.09;
  static const double _rectAngleThreshold = pi / 8; // ~22.5°

  /// Analiza un trazo y devuelve la forma detectada o null.
  ///
  /// Con [lineOnly] (resaltador) solo se reconocen rectas: el marcador se
  /// usa para subrayar/resaltar renglones, no para dibujar figuras, y sale
  /// más tembloroso (trazo ancho), así que la tolerancia es mayor.
  static DetectedShape? detect(List<StrokePoint> points, {bool lineOnly = false}) {
    if (points.length < _minPoints) return null;

    final first = points.first.offset;
    final last = points.last.offset;
    final totalLength = pathLength(points);

    // ¿Es una línea recta o flecha?
    final lineResult = _detectLine(points, first, last, totalLength, lineOnly: lineOnly);
    if (lineResult != null || lineOnly) return lineResult;

    // ¿Es un rectángulo?
    final rectResult = _detectRectangle(points, totalLength);
    if (rectResult != null) return rectResult;

    // ¿Es un triángulo?
    final triangleResult = _detectTriangle(points, totalLength);
    if (triangleResult != null) return triangleResult;

    // ¿Es un círculo/óvalo?
    final circleResult = _detectCircle(points);
    if (circleResult != null) return circleResult;

    return null;
  }

  /// Polígono cerrado con lados densificados: [perfect_freehand] necesita
  /// varios puntos por lado para que las esquinas salgan nítidas y el
  /// grosor sea uniforme (con solo los vértices, redondea y deforma).
  static List<StrokePoint> _closedPolygon(List<Offset> vertices, {int perSide = 12}) {
    final out = <StrokePoint>[];
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      for (var k = 0; k < perSide; k++) {
        out.add(StrokePoint.fromOffset(Offset.lerp(a, b, k / perSide)!, 0.5));
      }
    }
    out.add(StrokePoint.fromOffset(vertices.first, 0.5)); // cierra la figura
    return out;
  }

  /// true si el trazo termina cerca de donde empezó (figura cerrada).
  static bool _isClosed(List<StrokePoint> points, double totalLength) =>
      (points.first.offset - points.last.offset).distance < totalLength * 0.15;

  /// Detecta un triángulo: trazo cerrado con exactamente 3 esquinas.
  static DetectedShape? _detectTriangle(List<StrokePoint> points, double totalLength) {
    if (points.length < 15 || !_isClosed(points, totalLength)) return null;
    final rect = boundingBoxFromPoints(points);
    if (rect.shortestSide < 30) return null;
    // El inicio/fin del trazo suele ser un vértice que _findCorners no ve
    // (queda en el borde de la ventana): se añade y se fusionan cercanos.
    final candidates = [points.first.offset, ..._findCorners(points)];
    final merged = <Offset>[];
    final minGap = rect.shortestSide * 0.25;
    for (final c in candidates) {
      if (merged.every((m) => (m - c).distance > minGap)) merged.add(c);
    }
    if (merged.length != 3) return null;
    // Los lados deben ser rectos: la longitud dibujada ≈ perímetro.
    final perimeter = (merged[0] - merged[1]).distance +
        (merged[1] - merged[2]).distance +
        (merged[2] - merged[0]).distance;
    if (totalLength > perimeter * 1.25) return null;
    return DetectedShape(ShapeType.triangle, _closedPolygon(merged));
  }

  /// Detecta si el trazo es una línea recta o una flecha.
  static DetectedShape? _detectLine(
    List<StrokePoint> points,
    Offset first,
    Offset last,
    double totalLength, {
    bool lineOnly = false,
  }) {
    final lineLength = (last - first).distance;
    if (lineLength < 30) return null;

    final tolerance = lineOnly ? _highlighterLineTolerance : _lineTolerance;

    // La distancia recorrida no debería ser mucho mayor que la distancia
    // en línea recta (indicaría curvas).
    if (totalLength > lineLength * (1 + tolerance)) return null;

    // Todos los puntos deberían estar cerca de la línea recta.
    final dir = (last - first) / lineLength;
    final normal = Offset(-dir.dy, dir.dx);
    final maxDeviation = lineLength * tolerance;
    for (final p in points) {
      final d = p.offset - first;
      final dev = (normal * (normal.dx * d.dx + normal.dy * d.dy)).distance;
      if (dev > maxDeviation) return null;
    }

    // Detecta si es una flecha: si los últimos puntos forman una punta.
    final isArrow = !lineOnly && _detectArrowHead(points, first, last);
    final type = isArrow ? ShapeType.arrow : ShapeType.line;

    // Casi horizontal/vertical → exactamente horizontal/vertical (subrayar
    // un renglón sin que quede torcido). La flecha se deja como está.
    var end = last;
    if (!isArrow) {
      final snap = lineOnly ? _highlighterAxisSnap : _axisSnap;
      final angle = dir.direction; // -π..π
      final toHorizontal = min((angle).abs(), (pi - angle.abs()).abs());
      final toVertical = (angle.abs() - pi / 2).abs();
      if (toHorizontal < snap) {
        end = Offset(last.dx, first.dy);
      } else if (toVertical < snap) {
        end = Offset(first.dx, last.dy);
      }
    }

    return DetectedShape(
      type,
      [StrokePoint.fromOffset(first, 0.5), StrokePoint.fromOffset(end, 0.5)],
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
    final rect = boundingBoxFromPoints(points);
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
      // Cerrado y con lados densificados (antes faltaba el cuarto lado).
      return DetectedShape(
        ShapeType.rectangle,
        _closedPolygon([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]),
      );
    }
    return null;
  }

  /// Detecta si el trazo es un círculo u óvalo.
  static DetectedShape? _detectCircle(List<StrokePoint> points) {
    if (points.length < 20) return null;

    final rect = boundingBoxFromPoints(points);
    if (rect.shortestSide < 30) return null;

    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;

    // Elipse (no se fuerza a círculo): cada punto debería cumplir
    // (dx/rx)² + (dy/ry)² ≈ 1. Se mide la desviación media de esa "distancia
    // normalizada" respecto a 1.
    var deviation = 0.0;
    for (final p in points) {
      final d = p.offset - center;
      final n = sqrt((d.dx / rx) * (d.dx / rx) + (d.dy / ry) * (d.dy / ry));
      deviation += (n - 1).abs();
    }
    deviation /= points.length;

    if (deviation < _circleTolerance) {
      // Casi redonda → círculo perfecto; si no, elipse del tamaño dibujado.
      final round = (rx - ry).abs() < max(rx, ry) * 0.12;
      final r = (rx + ry) / 2;
      final ellipsePoints = <StrokePoint>[];
      for (var i = 0; i <= 72; i++) {
        final angle = (i / 72) * 2 * pi;
        final p = center +
            Offset(cos(angle) * (round ? r : rx), sin(angle) * (round ? r : ry));
        ellipsePoints.add(StrokePoint.fromOffset(p, 0.5));
      }
      return DetectedShape(ShapeType.circle, ellipsePoints);
    }
    return null;
  }

  /// Encuentra las esquinas (puntos de curvatura máxima) en el trazo.
  ///
  /// Alrededor de una esquina real hay varios puntos seguidos con giro
  /// grande: se agrupan y se toma el de **mayor** giro de cada grupo (antes
  /// cada punto contaba como esquina y un rectángulo daba 8-12 esquinas).
  static List<Offset> _findCorners(List<StrokePoint> points) {
    if (points.length < 10) return [];

    final corners = <Offset>[];
    final windowSize = max(3, points.length ~/ 12);
    Offset? best;
    var bestTurn = 0.0;

    void flush() {
      final b = best;
      if (b != null && (corners.isEmpty || (b - corners.last).distance > 20)) {
        corners.add(b);
      }
      best = null;
      bestTurn = 0;
    }

    for (var i = windowSize; i < points.length - windowSize; i++) {
      final prev = points[i - windowSize].offset;
      final curr = points[i].offset;
      final next = points[i + windowSize].offset;

      final d1 = (curr - prev).direction;
      final d2 = (next - curr).direction;
      final angleDiff = (d2 - d1).abs();
      final turn = angleDiff > pi ? 2 * pi - angleDiff : angleDiff;

      if (turn > _rectAngleThreshold) {
        if (turn > bestTurn) {
          bestTurn = turn;
          best = curr;
        }
      } else {
        flush();
      }
    }
    flush();
    return corners;
  }
}
