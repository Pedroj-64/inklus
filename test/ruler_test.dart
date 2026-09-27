// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/logic/ruler.dart';

void main() {
  const r = RulerGeometry(
    type: RulerType.straight,
    center: Offset(100, 100),
    angle: 0,
    scale: 1,
  );

  test('un trazo que empieza junto al borde superior se engancha a él', () {
    final start = const Offset(150, 100 - 38 - 10); // 10 px por encima del borde
    expect(r.snapFor(start), RulerSnap.edgeTop);
    final p = r.project(RulerSnap.edgeTop, const Offset(250, 20));
    expect(p.dy, closeTo(100 - 38, 1e-9), reason: 'queda sobre el borde, no el centro');
    expect(p.dx, 250);
  });

  test('lejos de la regla no hay imán', () {
    expect(r.snapFor(const Offset(150, 300)), isNull);
    expect(r.snapFor(const Offset(900, 62)), isNull, reason: 'fuera de su largo');
  });

  test('el tamaño es constante en pantalla', () {
    const zoomed = RulerGeometry(
      type: RulerType.straight, center: Offset.zero, angle: 0, scale: 2);
    expect(zoomed.halfWidth, RulerGeometry.widthPx / 4);
  });

  test('regla rotada: proyección sobre el borde inferior', () {
    const rot = RulerGeometry(
      type: RulerType.straight, center: Offset.zero, angle: pi / 2, scale: 1);
    // Con 90°, el borde "inferior" (normal +) queda en x = -38.
    final p = rot.project(RulerSnap.edgeBottom, const Offset(-30, 50));
    expect(p.dx, closeTo(-38, 1e-9));
    expect(p.dy, closeTo(50, 1e-9));
  });

  test('transportador: imán al arco (compás)', () {
    const p = RulerGeometry(
      type: RulerType.protractor, center: Offset.zero, angle: 0, scale: 1);
    final start = const Offset(0, -225); // cerca del arco superior
    expect(p.snapFor(start), RulerSnap.arc);
    final proj = p.project(RulerSnap.arc, const Offset(10, -100));
    expect(proj.distance, closeTo(RulerGeometry.protractorRadiusPx, 1e-9));
  });

  test('imán de ángulo a 45°', () {
    expect(RulerGeometry.snapAngle(pi / 4 + 0.01), pi / 4);
    expect(RulerGeometry.snapAngle(0.3), 0.3);
    expect(RulerGeometry.degrees(-pi / 2), -90);
  });

  test('hitTest', () {
    expect(r.hitTest(const Offset(100, 100)), isTrue);
    expect(r.hitTest(const Offset(100, 200)), isFalse);
  });
}
