// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/services/export_service.dart';

/// Regresión: la exportación debe incluir contenido en coordenadas negativas
/// (la hoja está centrada en el origen del mundo).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<int> opaquePixels(Page page) async {
    final png = await ExportService.renderPagePng(
      page,
      sheetSize: const Size(600, 800),
      imageCache: const {},
      options: const ExportOptions(transparentBackground: true),
    );
    final codec = await ui.instantiateImageCodec(png);
    final img = (await codec.getNextFrame()).image;
    final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var count = 0;
    for (var i = 3; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i) > 0) count++;
    }
    return count;
  }

  /// Píxeles que no son papel blanco, con la plantilla incluida.
  Future<int> inkPixels(Page page) async {
    final png = await ExportService.renderPagePng(
      page,
      sheetSize: const Size(600, 800),
      imageCache: const {},
      options: const ExportOptions(),
    );
    final img = (await (await ui.instantiateImageCodec(png)).getNextFrame()).image;
    final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var count = 0;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i) < 240 || data.getUint8(i + 1) < 240 || data.getUint8(i + 2) < 240) {
        count++;
      }
    }
    return count;
  }

  Stroke line(double y) => Stroke(
        id: 'l$y',
        points: [StrokePoint(-250, y, 0.5), StrokePoint(-150, y, 0.5)],
        tool: ToolType.pen,
        colorValue: 0xFF000000,
        size: 6,
      );

  testWidgets('hoja finita: un trazo arriba a la izquierda se exporta', (tester) async {
    final page = Page.blank(template: const PageTemplate(type: TemplateType.sheet))
      ..strokes.add(line(-300));
    final n = await tester.runAsync(() => opaquePixels(page));
    expect(n, greaterThan(100));
  });

  testWidgets('lienzo infinito: contenido en negativo se exporta', (tester) async {
    final page = Page.blank(template: const PageTemplate(type: TemplateType.blank))
      ..strokes.add(line(-300));
    final n = await tester.runAsync(() => opaquePixels(page));
    expect(n, greaterThan(100));
  });

  testWidgets('hojas con estructura: son finitas y se exportan con su rayado', (tester) async {
    for (final type in [...kStructuredTemplates, TemplateType.millimeter]) {
      final page = Page.blank(
          template: PageTemplate(type: type, infiniteFill: type == TemplateType.millimeter));
      expect(page.template.isFinite, type != TemplateType.millimeter,
          reason: '$type: estructuradas finitas, milimetrado infinito por defecto');
      final n = await tester.runAsync(() => inkPixels(page));
      expect(n, greaterThan(500), reason: '$type debe pintar su estructura');
    }
  });
}
