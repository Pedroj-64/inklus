// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/bucket_fill.dart';
import 'package:inklus/models/stroke.dart';

Stroke _s(String id, double x, double y) => Stroke(
      id: id,
      points: [StrokePoint(x, y, 1), StrokePoint(x + 1, y, 1)],
      tool: ToolType.pen,
      colorValue: 0xFF000000,
      size: 2,
    );

void main() {
  test('agrupa trazos conectados aunque el puente tenga índice menor', () {
    // 0 está cerca de 2, y 2 cerca de 1; 0 y 1 lejos entre sí.
    final strokes = [_s('a', 0, 0), _s('b', 20, 0), _s('c', 10, 0)];
    final groups = groupStrokesIntoComponents(strokes, 10);
    expect(groups.length, 1);
  });

  test('trazos lejanos quedan en grupos distintos', () {
    final groups = groupStrokesIntoComponents([_s('a', 0, 0), _s('b', 500, 0)], 10);
    expect(groups.length, 2);
  });

  test('convexHull de un cuadrado con un punto interior', () {
    final hull = convexHull(const [
      Offset(0, 0), Offset(4, 0), Offset(4, 4), Offset(0, 4), Offset(2, 2),
    ]);
    expect(hull.length, 4);
    expect(hull, isNot(contains(const Offset(2, 2))));
  });
}
