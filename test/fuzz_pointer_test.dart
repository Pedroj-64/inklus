// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/image_service.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/canvas/drawing_canvas.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tormenta de punteros: lápiz, dedos y ratón mezclados al azar (con
/// cancelaciones, levantados fuera de orden, zoom y herramientas distintas).
/// No debe lanzar excepciones ni dejar la vista/estado inválidos.
void main() {
  for (final seed in [3, 11, 99]) {
    testWidgets('semilla $seed: eventos de puntero aleatorios', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final tmp = Directory.systemTemp.createTempSync('inklus_ptr_');
      final c = CanvasController(StorageService(baseDir: tmp))
        ..setHapticEnabled(false)
        ..setShapeDetection(false);
      addTearDown(() {
        c.dispose();
        tmp.deleteSync(recursive: true);
      });
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrawingCanvas(controller: c, imageService: ImageService()),
        ),
      ));
      await tester.pump();

      final r = Random(seed);
      const kinds = [
        PointerDeviceKind.stylus,
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.invertedStylus,
      ];
      const tools = [
        ToolType.pen, ToolType.eraser, ToolType.highlighter, ToolType.pencil,
        ToolType.lasso,
      ];
      final active = <int, TestGesture>{};
      var nextId = 1;
      Offset rp() => Offset(r.nextDouble() * 1000, r.nextDouble() * 700);

      for (var i = 0; i < 700; i++) {
        switch (r.nextInt(10)) {
          case 0 || 1 || 2:
            if (active.length < 4) {
              final id = nextId++;
              active[id] = await tester.startGesture(rp(),
                  kind: kinds[r.nextInt(kinds.length)], pointer: id);
            }
          case 3 || 4 || 5 || 6:
            if (active.isNotEmpty) {
              final g = active.values.elementAt(r.nextInt(active.length));
              await g.moveTo(rp());
            }
          case 7:
            if (active.isNotEmpty) {
              final k = active.keys.elementAt(r.nextInt(active.length));
              await active.remove(k)!.up();
            }
          case 8:
            if (active.isNotEmpty) {
              final k = active.keys.elementAt(r.nextInt(active.length));
              await active.remove(k)!.cancel();
            }
          case 9:
            c.setTool(tools[r.nextInt(tools.length)]);
            if (r.nextBool()) c.undo();
        }
        await tester.pump(const Duration(milliseconds: 8));
        expect(tester.takeException(), isNull, reason: 'semilla $seed paso $i');
        final v = c.scale;
        expect(v.isFinite && v > 0, isTrue, reason: 'zoom inválido $v');
        expect(c.translate.dx.isFinite && c.translate.dy.isFinite, isTrue);
      }
      for (final g in active.values) {
        await g.up();
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
      final ids = c.page.strokes.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      await tester.runAsync(c.flush);
    });
  }
}
