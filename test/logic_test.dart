// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/eraser.dart';
import 'package:inklus/logic/shape_detector.dart';
import 'package:inklus/logic/snap_guides.dart';
import 'package:inklus/logic/undo_stack.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/text_item.dart';

void main() {
  group('StrokeEraser', () {
    test('no borra trazos intactos', () {
      final strokes = [
        Stroke(
          id: 's1',
          points: const [
            StrokePoint(100, 100, 0.5),
            StrokePoint(200, 100, 0.5),
          ],
          tool: ToolType.pen,
          colorValue: 0xFF000000,
          size: 3,
        ),
      ];
      final survivors = StrokeEraser.erase(
        strokes,
        [const Offset(50, 50)],
        10,
      );
      expect(survivors.length, 1);
      expect(survivors.first.id, 's1');
    });

    test('borra puntos dentro del radio y genera fragmentos', () {
      final strokes = [
        Stroke(
          id: 's1',
          points: const [
            StrokePoint(0, 0, 0.5),
            StrokePoint(50, 0, 0.5),
            StrokePoint(100, 0, 0.5), // ← borrado
            StrokePoint(150, 0, 0.5),
            StrokePoint(200, 0, 0.5),
          ],
          tool: ToolType.pen,
          colorValue: 0xFF000000,
          size: 3,
        ),
      ];
      final survivors = StrokeEraser.erase(
        strokes,
        [const Offset(100, 0)],
        20,
      );
      // Debería generar 2 fragmentos (0-50 y 150-200)
      expect(survivors.length, 2);
    });
  });

  group('UndoStack', () {
    test('push y undo devuelven la acción', () {
      final stack = UndoStack();
      final s1 = Stroke(id: 's1', points: [], tool: ToolType.pen, colorValue: 0, size: 3);
      final action = CanvasAction(strokesAdded: [s1]);
      stack.push(action);
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);

      final undone = stack.undo();
      expect(undone, isNotNull);
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
    });

    test('redo restaura la acción', () {
      final stack = UndoStack();
      final s1 = Stroke(id: 's1', points: [], tool: ToolType.pen, colorValue: 0, size: 3);
      final action = CanvasAction(strokesAdded: [s1]);
      stack.push(action);
      stack.undo();
      final redone = stack.redo();
      expect(redone, isNotNull);
      expect(stack.canUndo, isTrue);
    });

    test('push después de undo limpia el redo', () {
      final stack = UndoStack();
      final s1 = Stroke(id: 's1', points: [], tool: ToolType.pen, colorValue: 0, size: 3);
      final s2 = Stroke(id: 's2', points: [], tool: ToolType.pen, colorValue: 0, size: 3);
      final a1 = CanvasAction(strokesAdded: [s1]);
      final a2 = CanvasAction(strokesAdded: [s2]);
      stack.push(a1);
      stack.undo();
      stack.push(a2);
      expect(stack.canRedo, isFalse);
    });
  });

  group('ShapeDetector', () {
    test('detecta una línea recta', () {
      final points = List.generate(
        30,
        (i) => StrokePoint(i * 10.0, 0, 0.5),
      );
      final result = ShapeDetector.detect(points);
      expect(result, isNotNull);
      expect(result!.type, ShapeType.line);
    });

    test('no detecta forma con pocos puntos', () {
      final points = [
        const StrokePoint(0, 0, 0.5),
        const StrokePoint(10, 0, 0.5),
        const StrokePoint(20, 0, 0.5),
      ];
      final result = ShapeDetector.detect(points);
      expect(result, isNull);
    });

    test('detecta un círculo', () {
      final points = <StrokePoint>[];
      const center = Offset(100, 100);
      const radius = 50.0;
      for (var i = 0; i <= 60; i++) {
        final angle = (i / 60) * 2 * pi;
        final p = center + Offset(cos(angle), sin(angle)) * radius;
        points.add(StrokePoint(p.dx, p.dy, 0.5));
      }
      final result = ShapeDetector.detect(points);
      expect(result, isNotNull);
      expect(result!.type, ShapeType.circle);
    });
  });

  group('SnapGuides', () {
    test('snap al centro de la hoja', () {
      const sheetSize = Size(1191, 1684);
      final result = SnapGuides.compute(
        candidateCenter: const Offset(5, 0),
        candidateBounds: const Rect.fromLTWH(0, 0, 100, 50),
        strokes: [],
        images: [],
        sheetSize: sheetSize,
      );
      expect(result.verticalGuides, contains(0.0));
    });

    test('sin snap si está lejos', () {
      const sheetSize = Size(1191, 1684);
      final result = SnapGuides.compute(
        candidateCenter: const Offset(200, 300),
        candidateBounds: const Rect.fromLTWH(150, 275, 100, 50),
        strokes: [],
        images: [],
        sheetSize: sheetSize,
      );
      expect(result.verticalGuides, isEmpty);
      expect(result.horizontalGuides, isEmpty);
    });
  });

  group('ImageItem', () {
    test('rotación se serializa y deserializa', () {
      final item = ImageItem(
        id: 'img1',
        localPath: '/tmp/test.png',
        x: 100,
        y: 200,
        width: 300,
        height: 150,
        rotation: 0.5,
      );
      final roundtrip = ImageItem.fromJson(item.toJson());
      expect(roundtrip.rotation, closeTo(0.5, 0.001));
    });

    test('rotación 0 no se serializa', () {
      final item = ImageItem(
        id: 'img1',
        localPath: '/tmp/test.png',
        x: 0,
        y: 0,
        width: 100,
        height: 100,
      );
      final json = item.toJson();
      expect(json.containsKey('rotation'), isFalse);
    });

    test('contains funciona con rotación', () {
      final item = ImageItem(
        id: 'img1',
        localPath: '/tmp/test.png',
        x: 100,
        y: 100,
        width: 200,
        height: 100,
        rotation: 0,
      );
      expect(item.contains(const Offset(100, 100)), isTrue);
      expect(item.contains(const Offset(500, 500)), isFalse);
    });
  });

  group('TextItem formato', () {
    test('serializa formato y permite quitar el enlace', () {
      final t = TextItem(
        id: 't', x: 0, y: 0, width: 200, text: 'Hola',
        bold: true, italic: true, align: 'center', fontFamily: 'serif',
        linkToPageId: 'p1',
      );
      final back = TextItem.fromJson(t.toJson());
      expect(back.bold, isTrue);
      expect(back.italic, isTrue);
      expect(back.align, 'center');
      expect(back.fontFamily, 'serif');
      expect(back.copyWith(clearLink: true).linkToPageId, isNull,
          reason: 'antes "Quitar enlace" no quitaba nada');
    });
  });
}
