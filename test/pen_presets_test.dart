// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/logic/pen_presets.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late CanvasController canvas;
  late PenPresetsController presets;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_presets_');
    canvas = CanvasController(StorageService(baseDir: tmp))..setHapticEnabled(false);
    presets = PenPresetsController(persist: false);
    canvas.bottomBarContextNotifier.addListener(() => presets.syncFrom(canvas));
  });

  tearDown(() {
    canvas.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('cada pluma recuerda su propio color', () {
    presets.activate(0, canvas);
    canvas.setColor(const Color(0xFF00AA00));
    presets.activate(1, canvas);
    expect(canvas.color, PenPresetsController.defaultPens[1].color,
        reason: 'activar otra pluma no arrastra el color anterior');
    presets.activate(0, canvas);
    expect(canvas.color, const Color(0xFF00AA00));
  });

  test('el resaltador tiene color y grosor propios', () {
    presets.activate(PenPresetsController.highlighterSlot, canvas);
    expect(canvas.tool, ToolType.highlighter);
    expect(canvas.color, PenPresetsController.defaultHighlighter.color);
    presets.activate(0, canvas);
    expect(canvas.tool, ToolType.pen);
  });

  test('cambiar el tipo de pluma se guarda en la ranura', () {
    presets.activate(2, canvas);
    canvas.setTool(ToolType.brush);
    expect(presets.presetAt(2).tool, ToolType.brush);
    expect(presets.isShowing(2, ToolType.brush), isTrue);
  });

  test('colores recientes sin duplicados y con límite', () {
    for (var i = 0; i < 12; i++) {
      presets.addRecentColor(Color(0xFF000000 + i));
    }
    presets.addRecentColor(const Color(0xFF000005));
    expect(presets.recentColors.length, PenPresetsController.maxRecent);
    expect(presets.recentColors.first, const Color(0xFF000005));
  });
}
