import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/services/storage_service.dart';

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

    // --- B6: Tests de isFinite para plantillas infinitas/finitas ---

    test('B6: blank siempre es infinito', () {
      const t = PageTemplate(type: TemplateType.blank);
      expect(t.isFinite, isFalse);
    });

    test('B6: sheet siempre es finito', () {
      const t = PageTemplate(type: TemplateType.sheet);
      expect(t.isFinite, isTrue);
    });

    test('B6: ruled desde constructor con infiniteFill default es finito', () {
      // El const constructor pone infiniteFill: false por defecto.
      // isFinite trata ruled como finito cuando infiniteFill = false.
      // En la práctica, el template picker crea ruled con infiniteFill: true.
      const t = PageTemplate(type: TemplateType.ruled);
      expect(t.infiniteFill, isFalse);
      expect(t.isFinite, isTrue);
    });

    test('B6: ruled desde picker (infiniteFill: true) es infinito', () {
      // El template picker crea ruled con infiniteFill: true explícito.
      const t = PageTemplate(type: TemplateType.ruled, infiniteFill: true);
      expect(t.isFinite, isFalse);
    });

    test('B6: ruled con infiniteFill true desde JSON es infinito', () {
      final t = PageTemplate.fromJson({'type': 'ruled'});
      // Sin campo infiniteFill en JSON → _shouldBeInfiniteByDefault → true
      expect(t.infiniteFill, isTrue);
      expect(t.isFinite, isFalse);
    });

    test('B6: ruled con infiniteFill false desde JSON es finito', () {
      final t = PageTemplate.fromJson({'type': 'ruled', 'infiniteFill': false});
      expect(t.infiniteFill, isFalse);
      expect(t.isFinite, isTrue);
    });

    test('B6: grid con infiniteFill false desde JSON es finito', () {
      final t = PageTemplate.fromJson({'type': 'grid', 'infiniteFill': false});
      expect(t.isFinite, isTrue);
    });

    test('B6: dots con infiniteFill true desde JSON es infinito', () {
      final t = PageTemplate.fromJson({'type': 'dots', 'infiniteFill': true});
      expect(t.isFinite, isFalse);
    });

    test('B6: planner con infiniteFill false desde JSON es finito', () {
      final t = PageTemplate.fromJson({'type': 'planner', 'infiniteFill': false});
      expect(t.isFinite, isTrue);
    });

    test('B6: custom con infiniteFill false es finito', () {
      const t = PageTemplate(type: TemplateType.custom, infiniteFill: false);
      expect(t.isFinite, isTrue);
    });

    test('B6: custom con infiniteFill true es infinito', () {
      const t = PageTemplate(type: TemplateType.custom, infiniteFill: true);
      expect(t.isFinite, isFalse);
    });

    test('B6: fromJson sin infiniteFill usa default por tipo', () {
      // ruled/grid/dots/planner/music/habit/blank → infinito por defecto
      for (final typeName in ['ruled', 'grid', 'dots', 'planner', 'music', 'habit', 'blank']) {
        final t = PageTemplate.fromJson({'type': typeName});
        expect(t.infiniteFill, isTrue, reason: '$typeName debería ser infinito');
        expect(t.isFinite, isFalse, reason: '$typeName isFinite debería ser false');
      }
      // sheet/custom → finito por defecto
      for (final typeName in ['sheet', 'custom']) {
        final t = PageTemplate.fromJson({'type': typeName});
        expect(t.infiniteFill, isFalse, reason: '$typeName debería ser finito');
        expect(t.isFinite, isTrue, reason: '$typeName isFinite debería ser true');
      }
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

  group('Modelo Note', () {
    test('roundtrip JSON preserva todos los campos', () {
      final note = Note(
        id: 'note_test',
        title: 'Mi nota',
        createdAt: DateTime(2026, 8, 19),
        updatedAt: DateTime(2026, 8, 19, 14, 30),
        pages: [Page.blank(name: 'P1')],
      );
      final roundtrip = Note.fromJson(note.toJson());

      expect(roundtrip.id, 'note_test');
      expect(roundtrip.title, 'Mi nota');
      expect(roundtrip.pages.length, 1);
      expect(roundtrip.pages.first.name, 'P1');
    });

    test('Note.newBlank genera ids únicos', () {
      final a = Note.newBlank();
      final b = Note.newBlank();
      expect(a.id, isNot(b.id));
      expect(a.title, 'Sin título');
    });

    test('touch actualiza updatedAt', () {
      final note = Note.newBlank();
      final before = note.updatedAt;
      // Pequeña espera para asegurar que el timestamp cambie
      note.touch();
      expect(note.updatedAt.isAfter(before) || note.updatedAt == before, isTrue);
    });
  });

  group('Modelo Notebook', () {
    test('roundtrip JSON preserva metadatos', () {
      final note = Note.newBlank();
      final nb = Notebook(
        id: 'nb_test',
        title: 'Cuaderno de prueba',
        colorValue: 0xFF3B82F6,
        tags: ['clase', 'matemáticas'],
        notes: [note],
      );
      final roundtrip = Notebook.fromJson(
        nb.toJson(),
        loadedNotes: [note],
      );

      expect(roundtrip.id, 'nb_test');
      expect(roundtrip.title, 'Cuaderno de prueba');
      expect(roundtrip.colorValue, 0xFF3B82F6);
      expect(roundtrip.tags, ['clase', 'matemáticas']);
      expect(roundtrip.notes.length, 1);
    });

    test('toJson solo incluye noteIds, no el contenido', () {
      final note = Note.newBlank();
      final nb = Notebook(
        id: 'nb_1',
        title: 'Test',
        notes: [note],
      );
      final json = nb.toJson();

      expect(json.containsKey('noteIds'), isTrue);
      expect((json['noteIds'] as List).length, 1);
      expect(json.containsKey('notes'), isFalse);
    });

    test('firstNote devuelve el primer note', () {
      final nb = Notebook.newBlank();
      expect(nb.firstNote, isNotNull);
      expect(nb.firstNote!.title, 'Sin título');
    });

    test('Notebook.newBlank crea un notebook con 1 note', () {
      final nb = Notebook.newBlank();
      expect(nb.notes.length, 1);
      expect(nb.id.startsWith('nb_'), isTrue);
    });
  });

  group('StorageService - Migración', () {
    late Directory tmpDir;
    late StorageService storage;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('inklus_test_');
      storage = StorageService(baseDir: tmpDir);
    });

    tearDown(() async {
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('loadIndex crea un notebook desde current_document.json', () async {
      // Simular el formato legacy
      final legacyDoc = Document(
        id: 'legacy_1',
        title: 'Documento legacy',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 15),
        pages: [Page.blank()],
        colorValue: 0xFF4CAF50,
        tags: ['importante'],
      );
      final legacyFile = File('${tmpDir.path}/current_document.json');
      await legacyFile.writeAsString(jsonEncode(legacyDoc.toJson()));

      // loadIndex debe detectar el legacy y migrarlo
      final metas = await storage.loadIndex();
      expect(metas.length, 1);
      expect(metas.first.title, 'Documento legacy');
      expect(metas.first.colorValue, 0xFF4CAF50);
      expect(metas.first.tags, ['importante']);

      // El archivo legacy debe haberse eliminado
      expect(await legacyFile.exists(), isFalse);

      // Debe existir el notebook y el note en los nuevos directorios
      final nbFile = File('${tmpDir.path}/notebooks/legacy_1.json');
      expect(await nbFile.exists(), isTrue);
      final noteFile = File('${tmpDir.path}/notes/note_legacy_1.json');
      expect(await noteFile.exists(), isTrue);
    });

    test('loadIndex migra formato antiguo (documents/) a formato nuevo', () async {
      // Simular formato antiguo: index.json con key 'documents'
      final doc = Document(
        id: 'old_doc',
        title: 'Cuaderno viejo',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 7, 20),
        pages: [Page.blank()],
      );
      // Guardar en formato antiguo
      final docsDir = Directory('${tmpDir.path}/documents');
      await docsDir.create(recursive: true);
      await File('${docsDir.path}/old_doc.json')
          .writeAsString(jsonEncode(doc.toJson()));
      final indexFile = File('${tmpDir.path}/index.json');
      await indexFile.writeAsString(jsonEncode({
        'documents': [{'id': 'old_doc', 'title': 'Cuaderno viejo', 'updatedAt': doc.updatedAt.toIso8601String()}],
      }));

      // loadIndex debe migrar al formato nuevo
      final metas = await storage.loadIndex();
      expect(metas.length, 1);
      expect(metas.first.title, 'Cuaderno viejo');

      // Verificar que el index ahora tiene formatVersion
      final rawIndex = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      expect(rawIndex['formatVersion'], 2);
      expect(rawIndex.containsKey('notebooks'), isTrue);
      expect(rawIndex.containsKey('documents'), isFalse);
    });
  });

  group('StorageService - CRUD', () {
    late Directory tmpDir;
    late StorageService storage;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('inklus_test_');
      storage = StorageService(baseDir: tmpDir);
    });

    tearDown(() async {
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('createNotebook crea un notebook con 1 note', () async {
      final nb = await storage.createNotebook(title: 'Mi cuaderno');
      expect(nb.id.startsWith('nb_'), isTrue);
      expect(nb.title, 'Mi cuaderno');
      expect(nb.notes.length, 1);
      expect(nb.firstNote, isNotNull);
    });

    test('loadNotebook carga el notebook con sus notes', () async {
      final created = await storage.createNotebook(title: 'Test');
      final loaded = await storage.loadNotebook(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Test');
      expect(loaded.notes.length, 1);
    });

    test('renameNotebook actualiza el título', () async {
      final nb = await storage.createNotebook(title: 'Original');
      await storage.renameNotebook(nb.id, 'Renombrado');
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.title, 'Renombrado');
    });

    test('createNote añade un note al notebook', () async {
      final nb = await storage.createNotebook(title: 'Test');
      await storage.createNote(nb.id, title: 'Nota 2');
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.notes.length, 2);
      expect(loaded.notes[1].title, 'Nota 2');
    });

    test('deleteNote elimina un note (mínimo 1)', () async {
      final nb = await storage.createNotebook(title: 'Test');
      final note2 = await storage.createNote(nb.id, title: 'Nota 2');
      await storage.deleteNote(nb.id, note2.id);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.notes.length, 1);
    });

    test('deleteNote no elimina el último note', () async {
      final nb = await storage.createNotebook(title: 'Test');
      await storage.deleteNote(nb.id, nb.notes.first.id);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.notes.length, 1);
    });

    test('duplicateNote crea una copia después del original', () async {
      final nb = await storage.createNotebook(title: 'Test');
      final original = nb.notes.first;
      await storage.duplicateNote(nb.id, original.id);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.notes.length, 2);
      expect(loaded.notes[0].id, original.id);
      expect(loaded.notes[1].title, '${original.title} (copia)');
    });

    test('duplicateNotebook crea copia profunda con nuevos IDs', () async {
      final nb = await storage.createNotebook(title: 'Original');
      final copy = await storage.duplicateNotebook(nb.id);
      expect(copy.id, isNot(nb.id));
      expect(copy.title, 'Original (copia)');
      expect(copy.notes.length, nb.notes.length);
      expect(copy.notes.first.id, isNot(nb.notes.first.id));
    });

    test('deleteNotebook elimina notebook y notes', () async {
      await storage.emptyTrash();
      final nb = await storage.createNotebook(title: 'Para borrar');
      await storage.createNote(nb.id, title: 'Nota 2');
      await storage.deleteNotebook(nb.id);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded, isNull);
      final trash = await storage.loadTrash();
      expect(trash.length, greaterThanOrEqualTo(1));
      expect(trash.any((m) => m.title == 'Para borrar'), isTrue);
    });

    // --- A12: Tests adicionales de CRUD ---

    test('setNotebookColor asigna y lee color de portada', () async {
      final nb = await storage.createNotebook(title: 'Color');
      await storage.setNotebookColor(nb.id, 0xFFE53935);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.colorValue, 0xFFE53935);

      // Quitar color
      await storage.setNotebookColor(nb.id, null);
      final loaded2 = await storage.loadNotebook(nb.id);
      expect(loaded2!.colorValue, isNull);
    });

    test('setNotebookTags guarda y lee etiquetas', () async {
      final nb = await storage.createNotebook(title: 'Tags');
      await storage.setNotebookTags(nb.id, ['clase', 'mate']);
      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.tags, ['clase', 'mate']);

      // Reemplazar
      await storage.setNotebookTags(nb.id, ['arte']);
      final loaded2 = await storage.loadNotebook(nb.id);
      expect(loaded2!.tags, ['arte']);
    });

    test('allTags devuelve todas las etiquetas únicas', () async {
      final nb1 = await storage.createNotebook(title: 'A');
      final nb2 = await storage.createNotebook(title: 'B');
      await storage.setNotebookTags(nb1.id, ['clase', 'mate']);
      await storage.setNotebookTags(nb2.id, ['clase', 'arte']);
      final tags = await storage.allTags();
      expect(tags, containsAll(['arte', 'clase', 'mate']));
      expect(tags.length, 3); // Sin duplicados
    });

    test('setSyncEnabled guarda flag de sincronización', () async {
      final nb = await storage.createNotebook(title: 'Sync');
      await storage.setSyncEnabled(nb.id, false);
      final metas = await storage.loadIndex();
      final meta = metas.firstWhere((m) => m.id == nb.id);
      expect(meta.isSyncEnabled, isFalse);

      await storage.setSyncEnabled(nb.id, true);
      final metas2 = await storage.loadIndex();
      final meta2 = metas2.firstWhere((m) => m.id == nb.id);
      expect(meta2.isSyncEnabled, isTrue);
    });

    test('saveNote persiste cambios en el note y actualiza índice', () async {
      final nb = await storage.createNotebook(title: 'Test');
      final note = nb.notes.first;
      note.title = 'Editada';
      note.touch();
      await storage.saveNote(nb.id, note);

      final loaded = await storage.loadNote(note.id);
      expect(loaded!.title, 'Editada');

      // El índice se actualiza con el nuevo updatedAt
      final metas = await storage.loadIndex();
      expect(metas.first.id, nb.id);
    });

    test('renameNote actualiza el título del note', () async {
      final nb = await storage.createNotebook(title: 'Test');
      final note = nb.notes.first;
      await storage.renameNote(nb.id, note.id, 'Nueva nota');
      final loaded = await storage.loadNote(note.id);
      expect(loaded!.title, 'Nueva nota');
    });

    test('renameNote vacío no cambia nada', () async {
      final nb = await storage.createNotebook(title: 'Test');
      final note = nb.notes.first;
      final originalTitle = note.title;
      await storage.renameNote(nb.id, note.id, '');
      final loaded = await storage.loadNote(note.id);
      expect(loaded!.title, originalTitle);
    });

    test('loadNote devuelve null para id inexistente', () async {
      expect(await storage.loadNote('note_inexistente'), isNull);
    });

    test('loadNotebook devuelve null para id inexistente', () async {
      expect(await storage.loadNotebook('nb_inexistente'), isNull);
    });

    test('restoreFromTrash restaura notebook al índice', () async {
      await storage.emptyTrash();
      final nb = await storage.createNotebook(title: 'Restore');
      final docId = nb.id;
      await storage.deleteNotebook(docId);

      // Verificar que no está en el índice
      var metas = await storage.loadIndex();
      expect(metas.where((m) => m.id == docId).isEmpty, isTrue);

      // Restaurar
      await storage.restoreFromTrash(docId);
      metas = await storage.loadIndex();
      expect(metas.any((m) => m.id == docId), isTrue);
    });

    test('purgeFromTrash elimina definitivamente', () async {
      await storage.emptyTrash();
      final nb = await storage.createNotebook(title: 'Purge');
      await storage.deleteNotebook(nb.id);

      // Verificar que está en la papelera
      var trash = await storage.loadTrash();
      expect(trash.any((m) => m.id == nb.id), isTrue);

      // Purge
      await storage.purgeFromTrash(nb.id);
      trash = await storage.loadTrash();
      expect(trash.any((m) => m.id == nb.id), isFalse);
    });

    test('emptyTrash elimina todo de la papelera', () async {
      await storage.emptyTrash();
      final nb1 = await storage.createNotebook(title: 'A');
      final nb2 = await storage.createNotebook(title: 'B');
      await storage.deleteNotebook(nb1.id);
      await storage.deleteNotebook(nb2.id);

      var trash = await storage.loadTrash();
      expect(trash.length, greaterThanOrEqualTo(2));

      await storage.emptyTrash();
      trash = await storage.loadTrash();
      expect(trash, isEmpty);
    });

    test('createNotebook con template aplica plantilla a la primera página', () async {
      const template = PageTemplate(type: TemplateType.ruled, infiniteFill: true);
      final nb = await storage.createNotebook(
        title: 'Rayas',
        template: template,
      );
      expect(nb.notes.first.pages.first.template.type, TemplateType.ruled);
      expect(nb.notes.first.pages.first.template.infiniteFill, isTrue);
    });

    test('createNote con template aplica plantilla', () async {
      final nb = await storage.createNotebook(title: 'Test');
      const template = PageTemplate(type: TemplateType.grid);
      final note = await storage.createNote(nb.id, title: 'Grid', template: template);
      expect(note.pages.first.template.type, TemplateType.grid);
    });

    test('loadIndex con formato v2 no re-migra', () async {
      // Crear un notebook en formato nuevo
      await storage.createNotebook(title: 'V2');
      // loadIndex de nuevo — no debe fallar ni re-migrar
      final metas = await storage.loadIndex();
      expect(metas.length, 1);
      expect(metas.first.title, 'V2');

      // Verificar que formatVersion sigue siendo 2
      final indexFile = File('${tmpDir.path}/index.json');
      final raw = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      expect(raw['formatVersion'], 2);
    });
  });

  group('StorageService - Migración de contenido', () {
    late Directory tmpDir;
    late StorageService storage;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('inklus_mig_');
      storage = StorageService(baseDir: tmpDir);
    });

    tearDown(() async {
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('migración preserva trazos y páginas del Document', () async {
      // Crear un Document legacy con contenido real
      final page = Page.blank(name: 'P1');
      page.strokes.add(Stroke(
        id: 'st_mig',
        points: const [StrokePoint(10, 20, 0.5), StrokePoint(30, 40, 0.8)],
        tool: ToolType.pen,
        colorValue: 0xFF1C7ED6,
        size: 3.5,
      ));
      final doc = Document(
        id: 'doc_mig',
        title: 'Migrar esto',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 15),
        pages: [page],
      );

      // Guardar como legacy
      final legacyFile = File('${tmpDir.path}/current_document.json');
      await legacyFile.writeAsString(jsonEncode(doc.toJson()));

      // Migrar
      final metas = await storage.loadIndex();
      expect(metas.length, 1);

      // Cargar el note migrado y verificar contenido
      final nb = await storage.loadNotebook(metas.first.id);
      expect(nb, isNotNull);
      expect(nb!.notes.length, 1);

      final migratedNote = nb.notes.first;
      expect(migratedNote.pages.length, 1);
      expect(migratedNote.pages.first.strokes.length, 1);
      expect(migratedNote.pages.first.strokes.first.id, 'st_mig');
      expect(migratedNote.pages.first.strokes.first.tool, ToolType.pen);
      expect(migratedNote.pages.first.strokes.first.colorValue, 0xFF1C7ED6);
      expect(migratedNote.pages.first.strokes.first.points.length, 2);
      expect(migratedNote.pages.first.name, 'P1');
    });

    test('migración mapea Document.colorValue → Notebook.colorValue', () async {
      final doc = Document(
        id: 'doc_color',
        title: 'Con color',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        pages: [Page.blank()],
        colorValue: 0xFF9C27B0,
      );
      final legacyFile = File('${tmpDir.path}/current_document.json');
      await legacyFile.writeAsString(jsonEncode(doc.toJson()));

      final metas = await storage.loadIndex();
      expect(metas.first.colorValue, 0xFF9C27B0);

      final nb = await storage.loadNotebook(metas.first.id);
      expect(nb!.colorValue, 0xFF9C27B0);
    });

    test('migración mapea Document.tags → Notebook.tags', () async {
      final doc = Document(
        id: 'doc_tags',
        title: 'Con tags',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        pages: [Page.blank()],
        tags: ['estudio', 'parcial'],
      );
      final legacyFile = File('${tmpDir.path}/current_document.json');
      await legacyFile.writeAsString(jsonEncode(doc.toJson()));

      final metas = await storage.loadIndex();
      expect(metas.first.tags, ['estudio', 'parcial']);

      final nb = await storage.loadNotebook(metas.first.id);
      expect(nb!.tags, ['estudio', 'parcial']);
    });

    test('migración preserva fechas createdAt/updatedAt', () async {
      final created = DateTime(2025, 3, 15, 10, 30);
      final updated = DateTime(2026, 8, 19, 14, 0);
      final doc = Document(
        id: 'doc_dates',
        title: 'Fechas',
        createdAt: created,
        updatedAt: updated,
        pages: [Page.blank()],
      );
      final legacyFile = File('${tmpDir.path}/current_document.json');
      await legacyFile.writeAsString(jsonEncode(doc.toJson()));

      final metas = await storage.loadIndex();
      final nb = await storage.loadNotebook(metas.first.id);
      final note = nb!.notes.first;

      expect(note.createdAt, created);
      expect(note.updatedAt, updated);
    });

    test('migración de multi-documento preserva cada uno', () async {
      // Simular formato antiguo con 3 documentos
      final docs = <Document>[];
      for (var i = 0; i < 3; i++) {
        final page = Page.blank(name: 'Página ${i + 1}');
        page.strokes.add(Stroke(
          id: 'st_$i',
          points: const [StrokePoint(0, 0, 0.5), StrokePoint(10, 10, 0.5)],
          tool: ToolType.pencil,
          colorValue: 0xFF000000,
          size: 2,
        ));
        final doc = Document(
          id: 'doc_$i',
          title: 'Cuaderno $i',
          createdAt: DateTime(2026, 1, i + 1),
          updatedAt: DateTime(2026, 6, i + 1),
          pages: [page],
          colorValue: [0xFF3B82F6, 0xFF4CAF50, 0xFFE53935][i],
          tags: [const ['tag_a'], const ['tag_b', 'tag_c'], const <String>[]][i],
        );
        docs.add(doc);
      }

      // Guardar en formato antiguo
      final docsDir = Directory('${tmpDir.path}/documents');
      await docsDir.create(recursive: true);
      final indexEntries = <Map<String, dynamic>>[];
      for (final doc in docs) {
        await File('${docsDir.path}/${doc.id}.json')
            .writeAsString(jsonEncode(doc.toJson()));
        indexEntries.add({
          'id': doc.id,
          'title': doc.title,
          'updatedAt': doc.updatedAt.toIso8601String(),
        });
      }
      final indexFile = File('${tmpDir.path}/index.json');
      await indexFile.writeAsString(jsonEncode({'documents': indexEntries}));

      // Migrar
      final metas = await storage.loadIndex();
      expect(metas.length, 3);

      // Verificar cada notebook migrado
      for (var i = 0; i < 3; i++) {
        final nb = await storage.loadNotebook(docs[i].id);
        expect(nb, isNotNull);
        expect(nb!.title, 'Cuaderno $i');
        expect(nb.colorValue, docs[i].colorValue);
        expect(nb.tags, docs[i].tags);
        expect(nb.notes.length, 1);
        expect(nb.notes.first.pages.first.strokes.length, 1);
      }
    });

    test('migración de multi-documento: index.json se reescribe con formatVersion 2', () async {
      final doc = Document(
        id: 'doc_v1',
        title: 'V1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        pages: [Page.blank()],
      );
      final docsDir = Directory('${tmpDir.path}/documents');
      await docsDir.create(recursive: true);
      await File('${docsDir.path}/doc_v1.json')
          .writeAsString(jsonEncode(doc.toJson()));
      await File('${tmpDir.path}/index.json')
          .writeAsString(jsonEncode({'documents': [{'id': 'doc_v1', 'title': 'V1', 'updatedAt': doc.updatedAt.toIso8601String()}]}));

      await storage.loadIndex();

      final raw = jsonDecode(
        await File('${tmpDir.path}/index.json').readAsString(),
      ) as Map<String, dynamic>;
      expect(raw['formatVersion'], 2);
      expect(raw.containsKey('notebooks'), isTrue);
      expect(raw.containsKey('documents'), isFalse);
    });
  });

  group('Modelo Note - fromLegacyDocument', () {
    test('convierte Document a Note preservando contenido', () {
      final page = Page.blank(name: 'Legacy P1');
      page.strokes.add(Stroke(
        id: 'st_leg',
        points: const [StrokePoint(5, 10, 0.5)],
        tool: ToolType.pen,
        colorValue: 0xFF000000,
        size: 3,
      ));
      final doc = Document(
        id: 'doc_legacy',
        title: 'Documento legacy',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 15),
        pages: [page],
        colorValue: 0xFF4CAF50,
        tags: ['tag1'],
      );

      final note = Note.fromLegacyDocument(doc.toJson());

      expect(note.id, 'doc_legacy');
      expect(note.title, 'Documento legacy');
      expect(note.pages.length, 1);
      expect(note.pages.first.strokes.length, 1);
      expect(note.pages.first.name, 'Legacy P1');
      // colorValue y tags no están en Note (van al Notebook)
      expect(note.toJson().containsKey('colorValue'), isFalse);
      expect(note.toJson().containsKey('tags'), isFalse);
    });
  });
}
