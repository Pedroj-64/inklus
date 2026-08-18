import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_test_');
    storage = StorageService(baseDir: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('StorageService', () {
    test('create guarda el documento y lo lista en el índice', () async {
      final doc = await storage.create(title: 'Matemáticas');

      final metas = await storage.loadIndex();
      expect(metas.length, 1);
      expect(metas.first.id, doc.id);
      expect(metas.first.title, 'Matemáticas');

      final loaded = await storage.load(doc.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, doc.id);
      expect(loaded.title, 'Matemáticas');
      expect(loaded.pages.length, 1);
    });

    test('load de un id inexistente devuelve null', () async {
      expect(await storage.load('doc_inexistente'), isNull);
    });

    test('save actualiza el título y el índice', () async {
      final doc = await storage.create(title: 'Original');
      doc.title = 'Renombrado';
      await storage.save(doc);

      final metas = await storage.loadIndex();
      expect(metas.length, 1);
      expect(metas.first.title, 'Renombrado');
      expect((await storage.load(doc.id))!.title, 'Renombrado');
    });

    test('rename actualiza documento e índice', () async {
      final doc = await storage.create(title: 'Antes');
      await storage.rename(doc.id, 'Después');

      expect((await storage.load(doc.id))!.title, 'Después');
      final metas = await storage.loadIndex();
      expect(metas.first.title, 'Después');
    });

    test('duplicate crea una copia profunda con id y título nuevos', () async {
      final doc = await storage.create(title: 'Apuntes');
      final page = doc.pages.first;
      page.strokes.add(
        Stroke(
          id: 'st_x',
          points: const [StrokePoint(0, 0, 0.5), StrokePoint(5, 5, 0.5)],
          tool: ToolType.pen,
          colorValue: 0xFF000000,
          size: 3,
        ),
      );
      await storage.save(doc);

      final copy = await storage.duplicate(doc.id);

      expect(copy.id, isNot(doc.id));
      expect(copy.title, 'Apuntes (copia)');
      expect(copy.pages.length, doc.pages.length);
      expect(copy.pages.first.strokes.length, 1);
      expect(copy.pages.first.strokes.first.id, 'st_x');

      final metas = await storage.loadIndex();
      expect(metas.length, 2);
    });

    test('delete elimina el archivo y la entrada del índice', () async {
      final doc = await storage.create(title: 'Temporal');
      await storage.delete(doc.id);

      expect(await storage.load(doc.id), isNull);
      expect((await storage.loadIndex()).length, 0);

      final docFile =
          File('${tempDir.path}/documents/${doc.id}.json');
      expect(docFile.existsSync(), isFalse);
    });

    test('el índice se ordena por updatedAt descendente', () async {
      final a = await storage.create(title: 'A');
      final b = await storage.create(title: 'B');

      // A se tocó después (en la app lo hace CanvasController._touch).
      await Future<void>.delayed(const Duration(milliseconds: 5));
      a.title = 'A (editado)';
      a.updatedAt = DateTime.now();
      await storage.save(a);

      final metas = await storage.loadIndex();
      expect(metas.length, 2);
      expect(metas.first.id, a.id);
      expect(metas.last.id, b.id);
    });

    test('migra el antiguo current_document.json al nuevo formato', () async {
      final legacy = File('${tempDir.path}/current_document.json');
      final doc = Document.newBlank(title: 'Legacy');
      legacy.writeAsStringSync(jsonEncode(doc.toJson()));

      final metas = await storage.loadIndex();

      expect(metas.length, 1);
      expect(metas.first.title, 'Legacy');
      // El legacy desaparece y el documento vive en documents/<id>.json.
      expect(legacy.existsSync(), isFalse);
      final loaded = await storage.load(doc.id);
      expect(loaded, isNotNull);
      expect(loaded!.pages.length, 1);
    });

    test('sin datos previos el índice está vacío y no migra nada', () async {
      final metas = await storage.loadIndex();
      expect(metas, isEmpty);
    });
  });
}
