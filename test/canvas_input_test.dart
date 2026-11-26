// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/logic/stroke_engine.dart';
import 'package:inklus/models/flashcard.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/page.dart';
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

  Future<void> hoverPen(WidgetTester tester) async {
    final pen = await tester.createGesture(kind: PointerDeviceKind.stylus, pointer: 9);
    await pen.addPointer(location: const Offset(50, 50));
    await pen.moveTo(const Offset(60, 60)); // sin apoyar = hover
    await tester.pump();
  }

  testWidgets('solo lápiz: con el lápiz flotando, el dedo sigue desplazando (#11)',
      (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(false);
    await hoverPen(tester);
    final before = c.translate;
    await drag(tester, const Offset(200, 200), PointerDeviceKind.touch, pointer: 5);
    expect(c.translate, isNot(before));
  });

  testWidgets('modo estricto: con el lápiz flotando, el dedo no desplaza', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(false);
    c.setStrictPalmRejection(true);
    await hoverPen(tester);
    final before = c.translate;
    await drag(tester, const Offset(200, 200), PointerDeviceKind.touch, pointer: 5);
    expect(c.translate, before);
  });

  testWidgets('dibujo con dedo: el lápiz flotando sigue bloqueando la palma', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(true);
    await hoverPen(tester);
    await drag(tester, const Offset(200, 200), PointerDeviceKind.touch, pointer: 5);
    expect(c.page.strokes, isEmpty);
    await finish(tester);
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
    // Quieto casi un segundo antes de soltar.
    await tester.pump(const Duration(milliseconds: 1000));
    await pen.up();
    await tester.pump();
    expect(c.page.strokes.single.shapeType, 'line');
    await finish(tester);
  });

  testWidgets('una pausa en escritura corta NO la convierte en figura',
      (tester) async {
    await pumpCanvas(tester);
    c.setShapeMode(ShapeMode.hold);
    final pen = await tester.startGesture(const Offset(100, 300),
        kind: PointerDeviceKind.stylus, pointer: 23);
    // Trazo de ~20 px (una letra) con muchos puntos.
    for (var i = 1; i <= 20; i++) {
      await pen.moveTo(Offset(100 + i * 1.0, 300));
    }
    await tester.pump(const Duration(milliseconds: 1000));
    await pen.up();
    await tester.pump();
    expect(c.page.strokes.single.shapeType, isNull);
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

  testWidgets('pan con instantánea: pinta durante el gesto y vuelve a nítido',
      (tester) async {
    await pumpCanvas(tester);
    // Contenido para que la instantánea tenga algo que pintar (por código:
    // un dedo justo después del lápiz se descartaría como palma).
    c.beginStroke(const Offset(10, 10), 0.5, tool: ToolType.pen);
    c.addStrokePoint(const Offset(80, 40), 0.5);
    c.endStroke();
    c.setFingerDrawing(false); // un dedo desplaza
    await tester.pump();
    final before = c.translate;
    final painter = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is CanvasPainter);
    CanvasPainter current() =>
        tester.widget<CustomPaint>(painter.first).painter! as CanvasPainter;

    final finger = await tester.startGesture(const Offset(400, 400),
        kind: PointerDeviceKind.touch, pointer: 5);
    for (var i = 1; i <= 6; i++) {
      await finger.moveTo(Offset(400 - i * 20.0, 400 - i * 10.0));
      await tester.pump();
    }
    expect(current().viewGesture, isTrue);
    expect(current().snapshot!.image, isNotNull,
        reason: 'durante el gesto se dibuja la instantánea');
    expect(tester.takeException(), isNull);

    await finger.up();
    await tester.pump();
    expect(c.translate, isNot(before));
    expect(current().viewGesture, isFalse);
    expect(current().snapshot!.image, isNull,
        reason: 'al soltar se libera y se repinta en vivo');
    await finish(tester);
  });

  group('CanvasPainter.uncoveredStrips', () {
    const view = Rect.fromLTWH(0, 0, 100, 100);

    test('cubierto entero → nada que pintar en vivo', () {
      expect(CanvasPainter.uncoveredStrips(view, view.inflate(10)), isEmpty);
    });

    test('desplazado → franjas que suman el área destapada', () {
      final strips = CanvasPainter.uncoveredStrips(
          view, const Rect.fromLTWH(20, -10, 100, 100));
      final area = strips.fold<double>(0, (a, r) => a + r.width * r.height);
      expect(area, 100 * 100 - 80 * 90);
      for (final r in strips) {
        expect(r.overlaps(const Rect.fromLTWH(20, 0, 80, 90)), isFalse);
      }
    });

    test('sin intersección → toda la vista', () {
      expect(CanvasPainter.uncoveredStrips(
          view, const Rect.fromLTWH(500, 500, 10, 10)), [view]);
    });
  });

  group('escritorio', () {
    testWidgets('la rueda desplaza y Ctrl+rueda hace zoom bajo el cursor', (tester) async {
      await pumpCanvas(tester);
      final t0 = c.translate;
      final mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.hover(const Offset(300, 300)));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 100)));
      await tester.pump();
      expect(c.translate.dy, lessThan(t0.dy), reason: 'rueda abajo = el contenido sube');

      final s0 = c.scale;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -150)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(c.scale, greaterThan(s0));
      await finish(tester);
    });

    testWidgets('clic derecho del ratón borra', (tester) async {
      await pumpCanvas(tester);
      c.setEraserMode(EraserMode.stroke);
      await drag(tester, const Offset(100, 100), PointerDeviceKind.stylus);
      expect(c.page.strokes.length, 1);
      final g = await tester.startGesture(const Offset(100, 100),
          kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton, pointer: 5);
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset(100 + i * 8.0, 100));
      }
      await g.up();
      await tester.pump();
      expect(c.page.strokes, isEmpty);
      await finish(tester);
    });

    testWidgets('botón central arrastrado desplaza sin dibujar', (tester) async {
      await pumpCanvas(tester);
      final t0 = c.translate;
      final g = await tester.startGesture(const Offset(200, 200),
          kind: PointerDeviceKind.mouse, buttons: kMiddleMouseButton);
      await g.moveBy(const Offset(40, 30));
      await g.up();
      await tester.pump();
      expect(c.page.strokes, isEmpty);
      expect(c.translate - t0, const Offset(40, 30));
      await finish(tester);
    });

    testWidgets('Ctrl+A selecciona todo y Ctrl+X lo corta (deshacible)', (tester) async {
      await pumpCanvas(tester);
      await drag(tester, const Offset(100, 100), PointerDeviceKind.stylus);
      await drag(tester, const Offset(100, 200), PointerDeviceKind.stylus, pointer: 2);
      expect(c.page.strokes.length, 2);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(c.selectionCount, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(c.page.strokes.length, 2, reason: 'cortar y deshacer restaura');
      await finish(tester);
    });
  });

  testWidgets('el lápiz flotando muestra el cursor y desaparece al apoyar', (tester) async {
    await pumpCanvas(tester);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<HoverCursorPainter>()
        .single;
    expect(painter.hover.value, isNull);
    final pen = await tester.createGesture(kind: PointerDeviceKind.stylus, pointer: 9);
    await pen.addPointer(location: const Offset(50, 50));
    await pen.moveTo(const Offset(80, 80));
    expect(painter.hover.value?.pos, const Offset(80, 80));
    await pen.down(const Offset(80, 80));
    expect(painter.hover.value, isNull);
    await pen.up();
    await finish(tester);
  });

  test('curva de presión: lineal no cambia; suave sube; firme baja; se guarda por herramienta', () {
    expect(c.curvePressure(0.5), 0.5);
    c.setPressureCurve(1);
    expect(c.curvePressure(0.25), closeTo(0.5, 1e-9));
    c.setPressureCurve(-1);
    expect(c.curvePressure(0.5), closeTo(0.25, 1e-9));
    c.setTool(ToolType.pencil);
    expect(c.pressureCurve, 0);
    c.setTool(ToolType.pen);
    expect(c.pressureCurve, -1);
    c.resetStrokeSettings();
    expect(c.pressureCurve, 0);
  });

  testWidgets('cinta: se dibuja recta, un toque del dedo la destapa y otro la tapa', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(true);
    c.setTool(ToolType.tape);
    await drag(tester, const Offset(100, 100), PointerDeviceKind.touch);
    expect(c.page.strokes.single.tool, ToolType.tape);
    expect(c.page.strokes.single.points.length, greaterThan(2), reason: 'recta remuestreada');
    c.setFingerDrawing(false);
    c.setTool(ToolType.pen);
    Future<void> tap() async {
      await tester.tapAt(const Offset(140, 100));
      await tester.pump();
    }
    await tap();
    expect(StrokeEngine.isTapeOpen(c.page.strokes.single), isTrue);
    await tap();
    expect(StrokeEngine.isTapeOpen(c.page.strokes.single), isFalse);
    c.undo();
    expect(StrokeEngine.isTapeOpen(c.page.strokes.single), isTrue);
    c.undo();
    c.undo();
    expect(c.page.strokes, isEmpty);
    await finish(tester);
  });

  test('índice: título de página y nombres por defecto', () {
    expect(c.page.hasCustomName, isFalse);
    c.renamePage(0, '  Tema 1: derivadas ');
    expect(c.page.name, 'Tema 1: derivadas');
    expect(c.page.hasCustomName, isTrue);
    c.renamePage(0, '   ');
    expect(c.page.name, 'Tema 1: derivadas', reason: 'vacío no borra el título');
    c.addPage();
    expect(c.page.hasCustomName, isFalse);
  });

  testWidgets('enlace: la selección lleva a otra página con un toque del dedo y se guarda', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(true);
    await drag(tester, const Offset(100, 100), PointerDeviceKind.touch);
    c.addPage();
    c.goToPage(0);
    c.selectAll();
    c.linkSelectionTo(1);
    expect(c.page.links, hasLength(1));
    expect(Page.fromJson(c.page.toJson()).links.single.toPageId, c.pages[1].id);
    c.setFingerDrawing(false);
    await tester.tapAt(const Offset(140, 100));
    await tester.pump();
    expect(c.pageIndex, 1);
    c.goToPage(0);
    c.selectAll();
    c.linkSelectionTo(null);
    expect(c.page.links, isEmpty);
    await finish(tester);
  });

  testWidgets('tarjeta: pregunta + respuesta en dos selecciones, repaso y guardado', (tester) async {
    await pumpCanvas(tester);
    c.setFingerDrawing(true);
    await drag(tester, const Offset(100, 100), PointerDeviceKind.touch);
    c.selectAll();
    expect(c.flashcardFromSelection(), isFalse, reason: 'primero queda pendiente la pregunta');
    expect(c.hasPendingFlashcard, isTrue);
    c.selectAll();
    expect(c.flashcardFromSelection(), isTrue);
    final card = c.note.flashcards.single;
    expect(card.back, isNotNull);
    expect(c.dueFlashcards(DateTime.now()), 1);
    c.reviewFlashcard(card.id, ReviewGrade.good);
    expect(c.dueFlashcards(DateTime.now()), 0);
    expect(Note.fromJson(c.note.toJson()).flashcards.single.intervalDays, 1);
    c.selectAll();
    c.flashcardFromSelection();
    c.finishFlashcardWithoutBack();
    expect(c.note.flashcards.last.back, isNull);
    await finish(tester);
  });

  test('pestañas: abrir otra nota no cambia su fecha ni la marca como modificada', () {
    final other = Note.newBlank(title: 'Otra');
    final stamp = DateTime(2020, 1, 1);
    other.updatedAt = stamp;
    final before = c.contentVersion;
    c.openNote(other);
    expect(c.note, same(other));
    expect(other.updatedAt, stamp);
    expect(c.contentVersion, greaterThan(before), reason: 'repinta');
    expect(c.pageIndex, 0);
  });
}
