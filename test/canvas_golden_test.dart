// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/ui/canvas/world_painter.dart';
import 'package:material_ui/material_ui.dart' hide Page;

/// Goldens del pintado compartido (lienzo y exportación). Sin texto: las
/// fuentes cambian entre máquinas; solo trazos y plantilla.
/// Regenerar tras un cambio visual intencionado:
///   flutter test test/canvas_golden_test.dart --update-goldens
void main() {
  Stroke wave(String id, ToolType tool, double y, {int color = 0xFF1E3A8A, double size = 6, int? ts, String? shape}) =>
      Stroke(
        id: id,
        tool: tool,
        colorValue: color,
        size: size,
        ts: ts,
        shapeType: shape,
        points: [
          for (var i = 0; i <= 40; i++)
            StrokePoint(-150 + i * 7.5, y + sin(i / 4) * 12, 0.3 + 0.7 * (i % 10) / 10),
        ],
      );

  Page samplePage() => Page.blank(template: const PageTemplate(type: TemplateType.grid))
    ..strokes.addAll([
      wave('a', ToolType.pen, -120),
      wave('b', ToolType.pencil, -80),
      wave('c', ToolType.calligraphy, -40),
      wave('d', ToolType.brush, 0),
      wave('e', ToolType.marker, 40, color: 0xFFE53935, size: 14),
      wave('f', ToolType.highlighter, 80, color: 0xFFFDD835, size: 24),
      Stroke(id: 'g', tool: ToolType.tape, colorValue: 0xFF7E57C2, size: 30,
          points: const [StrokePoint(-150, 130, .5), StrokePoint(150, 130, .5)]),
      Stroke(id: 'h', tool: ToolType.tape, colorValue: 0xFF7E57C2, size: 30, shapeType: 'tapeOpen',
          points: const [StrokePoint(-150, 175, .5), StrokePoint(150, 175, .5)]),
    ]);

  Future<void> golden(WidgetTester tester, Page page, String name, {int? replayUntil}) async {
    tester.view.physicalSize = const Size(400, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Center(
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(400, 440),
          painter: _WorldPainter(page, replayUntil),
        ),
      ),
    ));
    await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('herramientas, resaltador y cinta', (tester) => golden(tester, samplePage(), 'tools'));

  testWidgets('reproducción de audio: lo posterior se ve tenue', (tester) {
    final page = Page.blank()
      ..strokes.addAll([
        wave('a', ToolType.pen, -40, ts: 1000),
        wave('b', ToolType.pen, 40, ts: 5000),
      ]);
    return golden(tester, page, 'replay', replayUntil: 2000);
  });
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.page, this.replayUntil);
  final Page page;
  final int? replayUntil;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    paintWorld(
      canvas,
      visibleWorldRect: Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
      page: page,
      sheetSize: const Size(400, 440),
      imageCache: const {},
      replayUntil: replayUntil,
    );
  }

  @override
  bool shouldRepaint(_WorldPainter old) => false;
}
