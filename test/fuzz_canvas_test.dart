// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas aleatorias (semillas fijas, reproducibles) del lienzo:
/// invariantes tras miles de operaciones mezcladas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const drawTools = [
    ToolType.pen, ToolType.pencil, ToolType.highlighter, ToolType.brush,
    ToolType.marker, ToolType.calligraphy,
  ];

  /// Firma comparable del contenido (orden y atributos).
  List<String> sig(CanvasController c) => [
        for (final s in c.page.strokes)
          '${s.id}|${s.tool.name}|${s.colorValue}|${s.layerIndex}|'
              '${s.points.length}|${s.points.first.x.toStringAsFixed(2)}|'
              '${s.points.first.y.toStringAsFixed(2)}'
      ];

  void expectHealthy(CanvasController c, String ctx) {
    final ids = c.page.strokes.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'ids duplicados: $ctx');
    for (final s in c.page.strokes) {
      expect(s.points, isNotEmpty, reason: 'trazo vacío: $ctx');
      for (final p in s.points) {
        expect(p.x.isFinite && p.y.isFinite && p.pressure.isFinite, isTrue,
            reason: 'punto no finito: $ctx');
      }
    }
  }

  void draw(CanvasController c, Random r, ToolType tool) {
    var p = Offset(r.nextDouble() * 600 - 300, r.nextDouble() * 400 - 200);
    c.beginStroke(p, r.nextDouble(), tool: tool);
    final n = r.nextInt(30);
    for (var i = 0; i < n; i++) {
      p += Offset(r.nextDouble() * 20 - 10, r.nextDouble() * 20 - 10);
      c.addStrokePoint(p, r.nextDouble());
    }
    c.endStroke();
  }

  for (final seed in [1, 7, 42, 2026]) {
    test('semilla $seed: operaciones mezcladas mantienen invariantes', () {
      final tmp = Directory.systemTemp.createTempSync('inklus_fuzz_');
      final c = CanvasController(StorageService(baseDir: tmp))
        ..setHapticEnabled(false)
        ..setShapeDetection(false);
      final r = Random(seed);
      try {
        for (var i = 0; i < 600; i++) {
          final op = r.nextInt(12);
          switch (op) {
            case 0 || 1 || 2 || 3:
              c.setTool(drawTools[r.nextInt(drawTools.length)]);
              draw(c, r, c.tool);
            case 4:
              c.setTool(ToolType.eraser);
              draw(c, r, ToolType.eraser);
              c.setTool(ToolType.pen);
            case 5:
              c.undo();
            case 6:
              c.redo();
            case 7:
              c.selectAll();
              c.duplicateSelectedStrokes();
            case 8:
              c.selectAll();
              c.copySelectedStrokes();
              c.pasteStrokes();
            case 9:
              c.selectAll();
              c.cutSelectedStrokes();
            case 10:
              c.selectAll();
              c.deleteSelectedStrokes();
            case 11:
              c.undo();
              c.undo();
              c.redo();
          }
          expectHealthy(c, 'semilla $seed paso $i op $op');
        }
      } finally {
        c.dispose();
        tmp.deleteSync(recursive: true);
      }
    });

    test('semilla $seed: deshacer todo vacía y rehacer todo restaura', () {
      final tmp = Directory.systemTemp.createTempSync('inklus_fuzz_');
      final c = CanvasController(StorageService(baseDir: tmp))
        ..setHapticEnabled(false)
        ..setShapeDetection(false);
      final r = Random(seed);
      try {
        for (var i = 0; i < 55; i++) { // < maxDepth (60)
          switch (r.nextInt(6)) {
            case 0 || 1 || 2:
              c.setTool(drawTools[r.nextInt(drawTools.length)]);
              draw(c, r, c.tool);
            case 3:
              c.setTool(ToolType.eraser);
              draw(c, r, ToolType.eraser);
              c.setTool(ToolType.pen);
            case 4:
              c.selectAll();
              c.duplicateSelectedStrokes();
            case 5:
              c.selectAll();
              c.deleteSelectedStrokes();
          }
        }
        final finalSig = sig(c);
        var guard = 0;
        while (c.canUndo && guard++ < 10000) {
          c.undo();
          expectHealthy(c, 'deshaciendo');
        }
        expect(c.page.strokes, isEmpty, reason: 'deshacer todo debe vaciar');
        guard = 0;
        while (c.canRedo && guard++ < 10000) {
          c.redo();
          expectHealthy(c, 'rehaciendo');
        }
        expect(sig(c), finalSig, reason: 'rehacer todo debe restaurar');
      } finally {
        c.dispose();
        tmp.deleteSync(recursive: true);
      }
    });
  }
}
