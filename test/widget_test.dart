import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';

void main() {
  group('Modelos Inklus', () {
    test('Stroke se serializa y deserializa con presión', () {
      final stroke = Stroke(
        id: 'st_1',
        points: const [
          StrokePoint(10, 20, 0.3),
          StrokePoint(30, 40, 0.9),
        ],
        tool: ToolType.pencil,
        colorValue: 0xFF1C7ED6,
        size: 4.5,
      );

      final roundtrip = Stroke.fromJson(stroke.toJson());

      expect(roundtrip.id, stroke.id);
      expect(roundtrip.points.length, 2);
      expect(roundtrip.points[1].x, 30);
      expect(roundtrip.points[1].pressure, 0.9);
      expect(roundtrip.tool, ToolType.pencil);
      expect(roundtrip.colorValue, 0xFF1C7ED6);
      expect(roundtrip.size, 4.5);
    });

    test('PageTemplate guarda el modo de plantilla personalizada', () {
      const template = PageTemplate(
        type: TemplateType.custom,
        imagePath: '/tmp/plantilla.png',
        infiniteFill: true,
        customWidth: 800,
        customHeight: 600,
      );

      final roundtrip = PageTemplate.fromJson(template.toJson());

      expect(roundtrip.type, TemplateType.custom);
      expect(roundtrip.imagePath, '/tmp/plantilla.png');
      expect(roundtrip.infiniteFill, isTrue);
      expect(roundtrip.customWidth, 800);
    });

    test('Document completo sobrevive al roundtrip JSON', () {
      final page = Page.blank(name: 'Página 1');
      page.strokes.add(
        Stroke(
          id: 'st_a',
          points: const [StrokePoint(0, 0, 0.5), StrokePoint(1, 1, 0.5)],
          tool: ToolType.pen,
          colorValue: 0xFF000000,
          size: 3,
        ),
      );

      final doc = Document(
        id: 'doc_x',
        title: 'Mi cuaderno',
        createdAt: DateTime(2026, 8, 17),
        updatedAt: DateTime(2026, 8, 17, 12),
        pages: [page],
      );

      final roundtrip = Document.fromJson(doc.toJson());

      expect(roundtrip.title, 'Mi cuaderno');
      expect(roundtrip.pages.length, 1);
      expect(roundtrip.pages.first.strokes.length, 1);
      expect(roundtrip.pages.first.strokes.first.tool, ToolType.pen);
    });
  });
}
