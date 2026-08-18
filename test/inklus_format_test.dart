import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/services/inklus_format.dart';

void main() {
  late Directory tempDir;
  late Directory extractDir;
  late File imageFile;
  late File templateFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_fmt_');
    extractDir = Directory('${tempDir.path}/restored');
    imageFile = File('${tempDir.path}/foto.png')
      ..writeAsBytesSync(Uint8List.fromList(List.filled(64, 7)));
    templateFile = File('${tempDir.path}/plantilla.png')
      ..writeAsBytesSync(Uint8List.fromList(List.filled(32, 9)));
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Document buildNotebook({bool missingImage = false}) {
    final page = Page.blank(name: 'Página 1');
    page.strokes.add(
      Stroke(
        id: 'st_1',
        points: const [StrokePoint(0, 0, 0.5), StrokePoint(4, 4, 0.5)],
        tool: ToolType.pen,
        colorValue: 0xFF000000,
        size: 3,
      ),
    );
    page.images.add(
      ImageItem(
        id: 'img_1',
        localPath: missingImage ? '/no/existe.png' : imageFile.path,
        x: 100,
        y: 100,
        width: 200,
        height: 150,
      ),
    );
    page.template = const PageTemplate(
      type: TemplateType.custom,
      infiniteFill: true,
    ).copyWith(imagePath: templateFile.path);
    return Document(
      id: 'doc_test',
      title: 'Cuaderno de prueba',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2, 10),
      pages: [page],
    );
  }

  group('InklusFormat', () {
    test('roundtrip: exporta e importa el cuaderno con sus imágenes', () async {
      final bytes = await InklusFormat.exportBytes(buildNotebook());
      expect(bytes, isNotEmpty);

      final doc = await InklusFormat.importBytes(bytes, extractTo: extractDir);

      expect(doc.id, 'doc_test');
      expect(doc.title, 'Cuaderno de prueba');
      expect(doc.pages.length, 1);
      expect(doc.pages.first.strokes.length, 1);

      // La imagen se extrae a un archivo local real y conserva el contenido.
      final img = doc.pages.first.images.first;
      expect(img.localPath, isNot(contains('inklus://')));
      final extracted = File(img.localPath);
      expect(extracted.existsSync(), isTrue);
      expect(extracted.readAsBytesSync(), imageFile.readAsBytesSync());

      // La plantilla propia también se restaura.
      final tplPath = doc.pages.first.template.imagePath;
      expect(tplPath, isNotNull);
      expect(File(tplPath!).existsSync(), isTrue);
      expect(File(tplPath).readAsBytesSync(), templateFile.readAsBytesSync());
    });

    test('los archivos inexistentes se dejan con su ruta original', () async {
      final bytes = await InklusFormat.exportBytes(buildNotebook(missingImage: true));
      final doc = await InklusFormat.importBytes(bytes, extractTo: extractDir);

      final img = doc.pages.first.images.first;
      expect(img.localPath, '/no/existe.png');
    });

    test('bytes inválidos lanzan FormatException', () async {
      expect(
        () => InklusFormat.importBytes(
          Uint8List.fromList([1, 2, 3, 4]),
          extractTo: extractDir,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
