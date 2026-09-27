// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/logic/undo_stack.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/text_item.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/template.dart';
import 'package:flutter/painting.dart' show Color, Rect, Size;
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/storage_service.dart';

/// Tests de regresión del controlador del lienzo (bugs de la auditoría).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late CanvasController c;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_ctrl_');
    c = CanvasController(StorageService(baseDir: tmp))
      ..setHapticEnabled(false)
      ..setShapeDetection(false);
  });

  tearDown(() {
    c.dispose();
    tmp.deleteSync(recursive: true);
  });

  /// Dibuja un trazo recto horizontal de (x0,y) a (x1,y).
  Stroke draw(double x0, double x1, double y, {ToolType tool = ToolType.pen}) {
    c.beginStroke(Offset(x0, y), 0.5, tool: tool);
    for (var x = x0 + 5; x <= x1; x += 5) {
      c.addStrokePoint(Offset(x, y), 0.5);
    }
    c.endStroke();
    return c.page.strokes.last;
  }

  List<String> ids() => c.page.strokes.map((s) => s.id).toList();

  group('Capas', () {
    setUp(() {
      c.addLayer(); // capa 1 activa
    });

    test('la detección de figuras conserva la capa', () {
      c.setShapeDetection(true);
      final s = draw(0, 300, 50);
      expect(s.shapeType, isNotNull, reason: 'una recta debería detectarse');
      expect(s.layerIndex, 1);
    });

    test('pegar conserva atributos y usa la capa activa', () {
      final s = draw(0, 100, 50);
      c.beginLasso(const Offset(-20, 20));
      for (final p in const [Offset(150, 20), Offset(150, 80), Offset(-20, 80)]) {
        c.addLassoPoint(p);
      }
      c.endLasso();
      expect(c.selectedStrokes, isNotEmpty);
      c.copySelectedStrokes();
      c.pasteStrokes();
      final pasted = c.page.strokes.last;
      expect(pasted.id, isNot(s.id));
      expect(pasted.layerIndex, 1);
      expect(pasted.colorValue, s.colorValue);
    });

    test('transformar conserva capa y figura', () {
      c.setShapeDetection(true);
      draw(0, 300, 50);
      c.beginLasso(const Offset(-20, 0));
      for (final p in const [Offset(350, 0), Offset(350, 100), Offset(-20, 100)]) {
        c.addLassoPoint(p);
      }
      c.endLasso();
      c.transformSelectedStrokes(
        scaleFactor: 2,
        rotationAngle: 0,
        pivotPoint: Offset.zero,
      );
      final t = c.page.strokes.single;
      expect(t.layerIndex, 1);
      expect(t.shapeType, 'line');
    });
  });

  group('Orden (z-order)', () {
    test('el borrador conserva el orden y deshacer lo restaura', () {
      final a = draw(0, 100, 0);
      final b = draw(0, 100, 100); // se partirá
      final d = draw(0, 100, 200);
      final original = ids();

      // Borra el centro del trazo b.
      c.beginStroke(const Offset(50, 100), 0.5, tool: ToolType.eraser);
      c.endStroke();

      expect(c.page.strokes.first.id, a.id);
      expect(c.page.strokes.last.id, d.id);
      expect(c.page.strokes.length, 4, reason: 'b se parte en 2 fragmentos');
      expect(ids(), isNot(contains(b.id)));

      c.undo();
      expect(ids(), original);
      c.redo();
      expect(c.page.strokes.length, 4);
      expect(c.page.strokes.first.id, a.id);
    });

    test('el borrador no toca capas bloqueadas ni cambia su orden', () {
      final a = draw(0, 100, 0); // capa 0
      c.addLayer();
      draw(0, 100, 0); // capa 1
      c.toggleLayerLocked(0);
      c.beginStroke(const Offset(50, 0), 0.5, tool: ToolType.eraser);
      c.endStroke();
      expect(c.page.strokes.first.id, a.id,
          reason: 'el trazo bloqueado sigue siendo el primero');
    });

    test('deshacer un movimiento devuelve el trazo a su posición', () {
      final a = draw(0, 100, 0);
      draw(0, 100, 100);
      final before = [a];
      c.selectStrokeAt(const Offset(50, 0));
      c.moveSelectedStrokes(const Offset(0, 500), before: before);
      c.commitMoveStrokes(before);
      expect(c.page.strokes.first.points.first.y, 500);
      c.undo();
      expect(c.page.strokes.first, same(a));
    });

    test('deshacer eliminar selección reinserta en su sitio', () {
      draw(0, 100, 0);
      final b = draw(0, 100, 100);
      draw(0, 100, 200);
      final original = ids();
      c.selectStrokeAt(const Offset(50, 100));
      expect(c.selectedStrokes.single, same(b));
      c.deleteSelectedStrokes();
      expect(c.page.strokes.length, 2);
      c.undo();
      expect(ids(), original);
    });
  });

  group('Ajustes de trazo', () {
    test('thinning/smoothing personalizados se guardan en el trazo', () {
      c.setThinning(0.9);
      final s = draw(0, 100, 0);
      expect(s.thinning, 0.9);
      expect(s.smoothing, isNull, reason: 'sin cambios = valor por defecto');
      final json = Stroke.fromJson(s.toJson());
      expect(json.thinning, 0.9);
    });

    test('el trazo confirmado es inmutable', () {
      final s = draw(0, 100, 0);
      expect(() => s.points.add(const StrokePoint(0, 0, 0.5)),
          throwsUnsupportedError);
    });
  });

  group('Páginas', () {
    test('clearPage también borra los textos', () {
      c.addTextItem(const Offset(10, 10));
      c.clearPage();
      expect(c.page.textItems, isEmpty);
    });

    test('cambiar de página reinicia la capa activa', () {
      c.addLayer();
      expect(c.activeLayerIndex, 1);
      c.addPage();
      expect(c.activeLayerIndex, 0);
    });

    test('duplicar página copia textos y clona capas', () {
      c.addTextItem(const Offset(10, 10));
      c.duplicatePage();
      final dup = c.page;
      final src = c.pages[c.pageIndex - 1];
      expect(dup.textItems.length, 1);
      dup.layers.first.locked = true;
      expect(src.layers.first.locked, isFalse);
    });
  });

  group('applyOrderedSwap', () {
    test('reemplaza en sitio por id', () {
      final list = ['a1', 'b1', 'c1'];
      applyOrderedSwap<String>(
        list,
        remove: [list[1]],
        add: ['b2'],
        idOf: (s) => s[0],
      );
      expect(list, ['a1', 'b2', 'c1']);
    });

    test('reinserta por índice', () {
      final list = ['a', 'c'];
      applyOrderedSwap<String>(
        list,
        remove: const [],
        add: ['b'],
        addAt: [1],
        idOf: (s) => s,
      );
      expect(list, ['a', 'b', 'c']);
    });
  });

  test('Page sin capas crea una por defecto', () {
    expect(Page.blank().layers.length, 1);
  });

  group('PDF y plantillas', () {
    test('insertPdfPages: una hoja fija por página, reutiliza la vacía', () {
      c.insertPdfPages([
        (path: '/tmp/p1.png', width: 1240, height: 1754),
        (path: '/tmp/p2.png', width: 1754, height: 1240),
      ]);
      expect(c.pageCount, 2);
      final t = c.pages.first.template;
      expect(t.isFinite, isTrue, reason: 'el PDF no se repite infinitamente');
      expect(t.sheetSize.width, 1191);
      expect(c.pages[1].template.sheetSize.height, lessThan(1191),
          reason: 'página apaisada conserva su proporción');
    });

    test('los presets de tamaño afectan a la hoja', () {
      c.setTemplate(const PageTemplate(
          type: TemplateType.sheet, customWidth: 1275, customHeight: 1650));
      expect(c.sheetSize, const Size(1275, 1650));
    });
  });

  group('Acciones destructivas', () {
    test('limpiar página se puede deshacer', () {
      draw(0, 100, 0);
      draw(0, 100, 50);
      final ids0 = ids();
      c.clearPage();
      expect(c.page.strokes, isEmpty);
      c.undo();
      expect(ids(), ids0);
    });

    test('borrar página ofrece deshacer y la restaura en su sitio', () {
      c.addPage();
      draw(0, 100, 0);
      final second = c.page;
      VoidCallback? undo;
      c.onUndoableNotice = (_, u) => undo = u;
      c.deleteCurrentPage();
      expect(c.pageCount, 1);
      undo!();
      expect(c.pageCount, 2);
      expect(c.pages[1], same(second));
    });

    test('duplicar selección no pisa el portapapeles', () {
      draw(0, 100, 0);
      c.selectStrokeAt(const Offset(50, 0));
      c.duplicateSelectedStrokes();
      expect(c.page.strokes.length, 2);
      expect(c.hasClipboard, isFalse);
    });
  });

  group('Borrador: modos', () {
    test('trazo completo borra el trazo entero', () {
      draw(0, 200, 0);
      c.setEraserMode(EraserMode.stroke);
      c.beginStroke(const Offset(100, 0), 0.5, tool: ToolType.eraser);
      c.endStroke();
      expect(c.page.strokes, isEmpty);
    });

    test('solo resaltador no toca la tinta', () {
      draw(0, 200, 0); // tinta
      draw(0, 200, 0, tool: ToolType.highlighter);
      c.setEraserMode(EraserMode.highlighterOnly);
      c.beginStroke(const Offset(100, 0), 0.5, tool: ToolType.eraser);
      c.endStroke();
      expect(c.page.strokes.where((s) => s.tool == ToolType.pen).length, 1);
      expect(c.page.strokes.any((s) =>
          s.tool == ToolType.highlighter && s.points.length > 30), isFalse);
    });
  });

  group('Acciones de selección', () {
    Stroke selectLine() {
      final s = draw(0, 100, 0);
      c.selectStrokeAt(const Offset(50, 0));
      return s;
    }

    test('recolorear en sitio y deshacer', () {
      final s = selectLine();
      draw(0, 100, 100);
      c.recolorSelection(const Color(0xFFFF0000));
      expect(c.page.strokes.first.colorValue, 0xFFFF0000);
      expect(c.page.strokes.first.id, s.id, reason: 'mismo sitio');
      c.undo();
      expect(c.page.strokes.first, same(s));
    });

    test('grosor escala la selección', () {
      final s = selectLine();
      c.scaleSelectionThickness(2);
      expect(c.page.strokes.single.size, s.size * 2);
    });

    test('convertir a texto sustituye los trazos por una caja de texto', () {
      selectLine();
      c.convertSelectionToText('Hola');
      expect(c.page.strokes, isEmpty);
      expect(c.page.textItems.single.text, 'Hola');
      c.undo();
      expect(c.page.strokes.length, 1);
      expect(c.page.textItems, isEmpty);
    });
  });

  group('Navegación de páginas', () {
    test('siguiente/anterior y marcadores persistentes', () {
      c.addPage();
      c.addPage();
      c.goToPage(0);
      c.nextPage();
      expect(c.pageIndex, 1);
      c.previousPage();
      c.previousPage(); // no pasa de la primera
      expect(c.pageIndex, 0);
      c.toggleBookmark();
      final json = c.page.toJson();
      expect(json['bookmarked'], isTrue);
      expect(Page.fromJson(json).bookmarked, isTrue);
    });
  });

  group('Lazo con imágenes y textos', () {
    void lassoAround(Rect r) {
      c.beginLasso(r.topLeft);
      for (final p in [r.topRight, r.bottomRight, r.bottomLeft]) {
        c.addLassoPoint(p);
      }
      c.endLasso();
    }

    setUp(() {
      draw(0, 100, 0);
      c.addImage(ImageItem(
          id: 'img', localPath: '/tmp/x.png', x: 50, y: 60, width: 40, height: 40));
      c.page.textItems.add(TextItem(id: 'txt', x: 50, y: 120, width: 80, text: 'Hola'));
      c.setTool(ToolType.lasso);
      lassoAround(const Rect.fromLTRB(-20, -20, 200, 160));
    });

    test('el lazo selecciona trazos, imágenes y textos', () {
      expect(c.selectionCount, 3);
      expect(c.selectedImages.single.id, 'img');
      expect(c.selectedTexts.single.id, 'txt');
    });

    test('mover y deshacer devuelve imagen y texto a su sitio', () {
      final strokes = List.of(c.selectedStrokes);
      c.moveSelectedStrokes(const Offset(100, 0), before: strokes);
      c.commitMoveStrokes(strokes);
      expect(c.page.images.single.x, 150);
      expect(c.page.textItems.single.x, 150);
      c.undo();
      expect(c.page.images.single.x, 50);
      expect(c.page.textItems.single.x, 50);
    });

    test('eliminar la selección y deshacer lo restaura todo', () {
      c.deleteSelectedStrokes();
      expect(c.page.strokes, isEmpty);
      expect(c.page.images, isEmpty);
      expect(c.page.textItems, isEmpty);
      c.undo();
      expect(c.page.strokes.length, 1);
      expect(c.page.images.single.id, 'img');
      expect(c.page.textItems.single.id, 'txt');
    });
  });
}
