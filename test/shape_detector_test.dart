// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/shape_detector.dart';
import 'package:inklus/models/stroke.dart';

/// Recorre un polígono a mano alzada (con un pequeño temblor).
List<StrokePoint> polygon(List<Offset> vertices, {int perSide = 20}) {
  final rnd = Random(7);
  final pts = <StrokePoint>[];
  for (var i = 0; i < vertices.length; i++) {
    final a = vertices[i], b = vertices[(i + 1) % vertices.length];
    for (var k = 0; k < perSide; k++) {
      final p = Offset.lerp(a, b, k / perSide)!;
      pts.add(StrokePoint(p.dx + rnd.nextDouble() * 2, p.dy + rnd.nextDouble() * 2, 0.5));
    }
  }
  pts.add(StrokePoint(vertices.first.dx, vertices.first.dy, 0.5));
  return pts;
}

void main() {
  test('rectángulo: la figura queda CERRADA (4 lados)', () {
    final shape = ShapeDetector.detect(polygon(const [
      Offset(0, 0), Offset(300, 0), Offset(300, 200), Offset(0, 200),
    ]));
    expect(shape?.type, ShapeType.rectangle);
    final pts = shape!.normalizedPoints;
    expect(pts.first.offset, pts.last.offset, reason: 'antes faltaba el 4º lado');
    expect(pts.length, greaterThan(20), reason: 'lados densificados');
  });

  test('óvalo alargado se mantiene como elipse (no círculo)', () {
    final pts = [
      for (var i = 0; i <= 60; i++)
        StrokePoint(200 + cos(i / 60 * 2 * pi) * 200, 100 + sin(i / 60 * 2 * pi) * 80, 0.5),
    ];
    final shape = ShapeDetector.detect(pts);
    expect(shape?.type, ShapeType.circle);
    final xs = shape!.normalizedPoints.map((p) => p.x);
    final ys = shape.normalizedPoints.map((p) => p.y);
    final w = xs.reduce(max) - xs.reduce(min);
    final h = ys.reduce(max) - ys.reduce(min);
    expect(w / h, greaterThan(2), reason: 'conserva la proporción dibujada');
  });

  test('triángulo', () {
    final shape = ShapeDetector.detect(polygon(const [
      Offset(150, 0), Offset(300, 260), Offset(0, 260),
    ], perSide: 25));
    expect(shape?.type, ShapeType.triangle);
    expect(shape!.normalizedPoints.first.offset, shape.normalizedPoints.last.offset);
  });
}
