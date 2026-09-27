// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/image_service.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/canvas/drawing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entrada real (eventos de puntero) sobre el lienzo: lápiz, palma y dedo.
void main() {
  late Directory tmp;
  late CanvasController c;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('inklus_input_');
    c = CanvasController(StorageService(baseDir: tmp))
      ..setHapticEnabled(false)
      ..setShapeDetection(false);
  });

  tearDown(() {
    c.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pumpCanvas(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DrawingCanvas(controller: c, imageService: ImageService()),
      ),
    ));
    await tester.pump();
  }

  /// Cancela el autoguardado pendiente (timer) guardando de verdad.
  Future<void> finish(WidgetTester tester) =>
      tester.runAsync(c.flush);

  Future<void> drag(WidgetTester tester, Offset from, PointerDeviceKind kind,
      {int pointer = 1}) async {
    final g = await tester.startGesture(from, kind: kind, pointer: pointer);
    for (var i = 1; i <= 10; i++) {
      await g.moveTo(from + Offset(i * 8.0, 0));
    }
    await g.up();
    await tester.pump();
  }

  testWidgets('el lápiz dibuja y activa el modo solo lápiz', (tester) async {
    await pumpCanvas(tester);
    await drag(tester, const Offset(100, 100), PointerDeviceKind.stylus);
    expect(c.page.strokes.length, 1);
    expect(c.fingerDrawingEnabled, isFalse,
        reason: 'tras detectar un lápiz el dedo ya no dibuja');
    await finish(tester);
  });

  testWidgets('la palma apoyada mientras se escribe no raya', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(true); // el usuario quiere dedo también
    final pen = await tester.startGesture(const Offset(100, 100),
        kind: PointerDeviceKind.stylus, pointer: 1);
    // Palma: toca y se mueve mientras el lápiz escribe.
    await drag(tester, const Offset(300, 300), PointerDeviceKind.touch, pointer: 2);
    for (var i = 1; i <= 5; i++) {
      await pen.moveTo(Offset(100 + i * 10.0, 100));
    }
    await pen.up();
    await tester.pump();
    expect(c.page.strokes.length, 1, reason: 'solo el trazo del lápiz');
    expect(c.page.strokes.single.points.first.x, lessThan(200));
    await finish(tester);
  });

  testWidgets('tras mover una selección con el lápiz, el dedo sigue funcionando',
      (tester) async {
    await pumpCanvas(tester);
    await drag(tester, const Offset(100, 100), PointerDeviceKind.stylus);
    c.setTool(ToolType.select);
    // Selecciona y mueve el trazo con el lápiz.
    await drag(tester, const Offset(120, 100), PointerDeviceKind.stylus, pointer: 3);
    // Pasa el periodo de gracia del lápiz.
    // El periodo de gracia usa el reloj real: esperar de verdad.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    c.setTool(ToolType.pen);
    c.setFingerDrawing(true);
    await drag(tester, const Offset(100, 300), PointerDeviceKind.touch, pointer: 4);
    expect(c.page.strokes.length, 2,
        reason: 'antes el estado "lápiz apoyado" se quedaba atascado');
    await finish(tester);
  });

  testWidgets('en modo solo lápiz, un dedo desplaza la página', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(false);
    final before = c.translate;
    await drag(tester, const Offset(200, 200), PointerDeviceKind.touch, pointer: 5);
    expect(c.page.strokes, isEmpty);
    expect(c.translate, isNot(before));
  });

  testWidgets('regla: un dedo la arrastra y el lápiz se pega a su borde',
      (tester) async {
    await pumpCanvas(tester);
    c.toggleRuler();
    await tester.pump();
    final center0 = c.rulerCenter;
    // Arrastrar la regla con un dedo (tocando su cuerpo).
    final screen0 = c.worldToViewport(center0, Size.zero);
    await drag(tester, screen0, PointerDeviceKind.touch, pointer: 7);
    expect(c.rulerCenter.dx, greaterThan(center0.dx + 40));
    expect(c.page.strokes, isEmpty, reason: 'mover la regla no dibuja');

    // Trazo con lápiz empezando justo encima del borde superior.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 450)));
    final g = c.rulerGeometry;
    final edgeStart = c.worldToViewport(
        g.fromLocal(Offset(-50, -g.halfWidth - 6 / c.scale)), Size.zero);
    final pen = await tester.startGesture(edgeStart,
        kind: PointerDeviceKind.stylus, pointer: 8);
    for (var i = 1; i <= 8; i++) {
      await pen.moveTo(edgeStart + Offset(i * 12.0, (i.isEven ? 9 : -7)));
    }
    await pen.up();
    await tester.pump();
    final stroke = c.page.strokes.single;
    final ys = stroke.points.map((p) => g.toLocal(p.offset).dy);
    for (final y in ys) {
      expect(y, closeTo(-g.halfWidth, 1e-6), reason: 'todo el trazo sobre el borde');
    }
    await finish(tester);
  });

  testWidgets('mantener el lápiz quieto al final endereza la figura',
      (tester) async {
    await pumpCanvas(tester);
    c.setShapeMode(ShapeMode.hold);
    final pen = await tester.startGesture(const Offset(100, 300),
        kind: PointerDeviceKind.stylus, pointer: 20);
    // Línea algo temblorosa.
    for (var i = 1; i <= 30; i++) {
      await pen.moveTo(Offset(100 + i * 10.0, 300 + (i.isEven ? 1 : -1)));
    }
    // Quieto más de medio segundo antes de soltar.
    await tester.pump(const Duration(milliseconds: 700));
    await pen.up();
    await tester.pump();
    expect(c.page.strokes.single.shapeType, 'line');
    await finish(tester);
  });

  testWidgets('sin mantener, el trazo NO se convierte en figura',
      (tester) async {
    await pumpCanvas(tester);
    c.setShapeMode(ShapeMode.hold);
    await drag(tester, const Offset(100, 300), PointerDeviceKind.stylus, pointer: 21);
    expect(c.page.strokes.single.shapeType, isNull);
    await finish(tester);
  });

  testWidgets('el puntero láser no deja trazos y su estela se desvanece',
      (tester) async {
    await pumpCanvas(tester);
    c.toggleLaser();
    await drag(tester, const Offset(100, 100), PointerDeviceKind.stylus, pointer: 22);
    expect(c.page.strokes, isEmpty);
    expect(c.laserTrail, isNotEmpty);
    // La estela usa el reloj real (DateTime): esperar de verdad.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.laserTrail, isEmpty);
    c.toggleLaser();
    await finish(tester);
  });
}
