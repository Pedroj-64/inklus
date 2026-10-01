// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/text_item.dart';
import 'package:inklus/services/image_service.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/canvas/drawing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('tramos de formato', () {
    test('aplicar formato a un rango parte, no solapa y fusiona', () {
      var runs = applyRunStyle(const [], 2, 6, (r) => r.copyStyle(bold: true));
      expect(runs.length, 1);
      runs = applyRunStyle(runs, 4, 8, (r) => r.copyStyle(bold: true));
      expect(runs.single.start, 2);
      expect(runs.single.end, 8, reason: 'tramos contiguos iguales se fusionan');
      runs = applyRunStyle(runs, 3, 5, (r) => r.copyStyle(color: 0xFFFF0000));
      expect([for (final r in runs) (r.start, r.end)], [(2, 3), (3, 5), (5, 8)]);
      expect(runs[1].bold, isTrue);
      expect(runs[1].color, 0xFFFF0000);
      expect(runs[0].color, isNull);
    });

    test('quitar el formato deja los tramos vacíos fuera', () {
      var runs = applyRunStyle(const [], 0, 4, (r) => r.copyStyle(highlight: 1));
      runs = applyRunStyle(runs, 0, 4, (r) => r.copyStyle(clearHighlight: true));
      expect(runs, isEmpty);
    });

    test('teclear al final de un tramo hereda su formato', () {
      final runs = [const TextRun(0, 3, bold: true)];
      final out = adjustRunsForEdit(runs, 'abc', 'abcd');
      expect(out.single.end, 4);
    });

    test('teclear antes desplaza los tramos; borrar dentro los encoge', () {
      final runs = [const TextRun(4, 8, underline: true)];
      expect(adjustRunsForEdit(runs, 'abcdefghij', 'XXabcdefghij').single.start, 6);
      final shrunk = adjustRunsForEdit(
          [const TextRun(2, 8, underline: true)], 'abcdefghij', 'abcdij');
      expect([shrunk.single.start, shrunk.single.end], [2, 4]);
    });

    test('borrar todo el tramo lo elimina', () {
      final runs = [const TextRun(2, 4, bold: true)];
      expect(adjustRunsForEdit(runs, 'abcdef', 'abef'), isEmpty);
    });

    test('JSON de ida y vuelta conserva tramos, tachado e interlineado', () {
      final t = TextItem(
        id: 't', x: 0, y: 0, width: 100, text: 'Hola mundo',
        strike: true, lineHeight: 1.5, fontFamily: 'caveat',
        runs: [const TextRun(0, 4, bold: true, color: 0xFF112233, font: 'lora')],
      );
      final back = TextItem.fromJson(t.toJson());
      expect(back.strike, isTrue);
      expect(back.lineHeight, 1.5);
      expect(back.runs.single.color, 0xFF112233);
      expect(back.runs.single.font, 'lora');
    });

    test('la altura medida crece con las líneas', () {
      final one = TextItem(id: 'a', x: 0, y: 0, width: 200, text: 'Hola');
      final many = one.copyWith(text: 'Hola\nHola\nHola');
      expect(many.height, greaterThan(one.height * 2.5));
    });
  });

  group('editor de texto en el lienzo', () {
    late Directory tmp;
    late CanvasController c;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tmp = Directory.systemTemp.createTempSync('inklus_text_');
      c = CanvasController(StorageService(baseDir: tmp))
        ..setHapticEnabled(false)
        ..setShapeDetection(false);
    });

    tearDown(() {
      c.dispose();
      tmp.deleteSync(recursive: true);
    });

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: DrawingCanvas(controller: c, imageService: ImageService()),
        ),
      ));
      await tester.pump();
    }

    testWidgets('tocar la barra de formato NO crea cajas ni mueve la vista',
        (tester) async {
      await pump(tester);
      c.setTool(ToolType.text);
      c.setFingerDrawing(true);
      await tester.tapAt(const Offset(500, 400));
      await tester.pump();
      expect(c.editingTextId, isNotNull);
      await tester.enterText(find.byType(TextField), 'Hola mundo');
      await tester.pump();

      final translate = c.translate;
      final boxes = c.page.textItems.length;
      // Varias pulsaciones sobre la barra (incluida la zona de arrastre).
      await tester.tap(find.byTooltip('Negrita'));
      await tester.pump();
      await tester.tap(find.byTooltip('Cursiva'));
      await tester.pump();
      await tester.drag(find.byTooltip('Negrita'), const Offset(60, 40));
      await tester.pump();

      expect(c.page.textItems.length, boxes, reason: 'no se crean cajas nuevas');
      expect(c.translate, translate, reason: 'la página no se desplaza');
      expect(c.editingTextId, isNotNull, reason: 'la edición sigue abierta');
      expect(c.page.textItems.single.bold, isTrue);
      await tester.runAsync(c.flush);
    });

    testWidgets('subrayar y colorear solo una parte del texto', (tester) async {
      await pump(tester);
      c.setTool(ToolType.text);
      c.setFingerDrawing(true);
      await tester.tapAt(const Offset(500, 400));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Hola mundo');
      await tester.pump();
      // Selecciona "mundo".
      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.selection = const TextSelection(baseOffset: 5, extentOffset: 10);
      await tester.pump();

      await tester.tap(find.byTooltip('Subrayado'));
      await tester.pump();
      final item = c.page.textItems.single;
      expect(item.underline, isFalse, reason: 'la caja entera no cambia');
      expect([for (final r in item.runs) (r.start, r.end, r.underline)],
          [(5, 10, true)]);

      c.commitEditingText();
      await tester.pump();
      c.undo();
      expect(c.page.textItems, isEmpty, reason: 'deshacer quita la caja entera');
      c.redo();
      expect(c.page.textItems.single.runs.single.underline, isTrue);
      await tester.runAsync(c.flush);
    });

    testWidgets('con la herramienta de texto, tocar una caja existente la edita',
        (tester) async {
      await pump(tester);
      c.page.textItems.add(TextItem(
          id: 'x', x: 0, y: 0, width: 200, text: 'Existente'));
      c.setTool(ToolType.text);
      c.setFingerDrawing(true);
      final world = c.worldToViewport(Offset.zero, c.viewportSize);
      final g = await tester.startGesture(world, kind: PointerDeviceKind.touch);
      await g.up();
      await tester.pump();
      expect(c.editingTextId, 'x');
      expect(c.page.textItems.length, 1, reason: 'no crea otra caja encima');
      await tester.runAsync(c.flush);
    });
  });
}
