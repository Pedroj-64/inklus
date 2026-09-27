// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/file_utils.dart';
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
      // El legacy desaparece tras la migración.
      expect(legacy.existsSync(), isFalse);
      // El contenido vive en notebooks/<id>.json + notes/note_<id>.json
      final nbFile = File('${tempDir.path}/notebooks/${doc.id}.json');
      expect(nbFile.existsSync(), isTrue);
      final noteFile = File('${tempDir.path}/notes/note_${doc.id}.json');
      expect(noteFile.existsSync(), isTrue);
    });

    test('sin datos previos el índice está vacío y no migra nada', () async {
      final metas = await storage.loadIndex();
      expect(metas, isEmpty);
    });
  });

  group('Respaldo local completo', () {
    test('exportFullBackup + importFullBackup restaura Notebook+Note e imágenes',
        () async {
      final imagesDir = Directory('${tempDir.path}/images')..createSync();
      final img = File('${imagesDir.path}/foto.png')..writeAsBytesSync([1, 2, 3]);

      final nb = await storage.createNotebook(title: 'Física');
      final note = nb.notes.first;
      note.pages.first.images.add(ImageItem(
        id: 'img_1',
        localPath: img.path,
        x: 0,
        y: 0,
        width: 10,
        height: 10,
      ));
      await storage.saveNote(nb.id, note);
      await storage.setSyncEnabled(nb.id, false);

      final zip = await storage.exportFullBackup();

      // Restaurar en "otro equipo" (otra carpeta base).
      final otherDir = Directory.systemTemp.createTempSync('inklus_restore_');
      try {
        final other = StorageService(baseDir: otherDir);
        final count = await other.importFullBackup(zip);
        expect(count, 1);

        final metas = await other.loadIndex();
        expect(metas.single.title, 'Física');
        expect(metas.single.isSyncEnabled, isFalse);

        final restored = await other.loadNotebook(nb.id);
        expect(restored, isNotNull);
        final restoredImg = restored!.notes.first.pages.first.images.single;
        // La ruta absoluta se re-mapea a la nueva carpeta base.
        expect(restoredImg.localPath, '${otherDir.path}/images/foto.png');
        expect(File(restoredImg.localPath).readAsBytesSync(), [1, 2, 3]);
      } finally {
        otherDir.deleteSync(recursive: true);
      }
    });

    test('importFullBackup fusiona: conserva cuadernos locales', () async {
      final a = await storage.createNotebook(title: 'A');
      final zip = await storage.exportFullBackup();

      final otherDir = Directory.systemTemp.createTempSync('inklus_merge_');
      try {
        final other = StorageService(baseDir: otherDir);
        final local = await other.createNotebook(title: 'Local');
        await other.importFullBackup(zip);
        final ids = (await other.loadIndex()).map((m) => m.id).toSet();
        expect(ids, {a.id, local.id});
      } finally {
        otherDir.deleteSync(recursive: true);
      }
    });

    test('importFullBackup ignora rutas con .. (zip-slip)', () async {
      final archive = Archive()
        ..addFile(ArchiveFile('images/../../evil.txt', 1, [65]))
        ..addFile(ArchiveFile('/abs.txt', 1, [65]));
      final zip = Uint8List.fromList(ZipEncoder().encode(archive));

      await storage.importFullBackup(zip);
      expect(File('${tempDir.parent.path}/evil.txt').existsSync(), isFalse);
      expect(File('/abs.txt').existsSync(), isFalse);
    });

    test('backup antiguo (solo documents/) se migra a Notebook+Note', () async {
      final doc = Document.newBlank(title: 'Viejo');
      final archive = Archive()
        ..addFile(ArchiveFile.string(
            'documents/${doc.id}.json', jsonEncode(doc.toJson())))
        ..addFile(ArchiveFile.string(
            'index.json',
            jsonEncode({
              'documents': [
                {'id': doc.id, 'title': 'Viejo', 'updatedAt': doc.updatedAt.toIso8601String()}
              ]
            })));
      final zip = Uint8List.fromList(ZipEncoder().encode(archive));

      final count = await storage.importFullBackup(zip);
      expect(count, 1);
      final metas = await storage.loadIndex();
      expect(metas.single.title, 'Viejo');
      expect(await storage.loadNotebook(doc.id), isNotNull);
    });
  });

  group('Robustez del índice', () {
    test('índice corrupto se reconstruye desde notebooks/', () async {
      final a = await storage.createNotebook(title: 'Uno');
      final b = await storage.createNotebook(title: 'Dos');
      File('${tempDir.path}/index.json').writeAsStringSync('{"formatVers');

      final metas = await storage.loadIndex();
      expect(metas.map((m) => m.id).toSet(), {a.id, b.id});
    });

    test('guardados concurrentes no pierden entradas del índice', () async {
      final nbs = await Future.wait(
        List.generate(8, (i) => storage.createNotebook(title: 'NB $i')),
      );
      final metas = await storage.loadIndex();
      expect(metas.length, nbs.length);
    });

    test('safeJoin rechaza rutas peligrosas', () {
      expect(safeJoin('/base', 'images/a.png'), '/base/images/a.png');
      expect(safeJoin('/base', '../x'), isNull);
      expect(safeJoin('/base', 'images/../../x'), isNull);
      expect(safeJoin('/base', '/etc/passwd'), isNull);
      expect(safeJoin('/base', 'C:/x'), isNull);
      expect(safeJoin('/base', 'images/'), isNull);
    });

    test('writeAtomic no deja temporales', () async {
      final f = File('${tempDir.path}/x.json');
      await writeAtomic(f, '{"a":1}');
      await writeAtomic(f, '{"a":2}');
      expect(f.readAsStringSync(), '{"a":2}');
      expect(tempDir.listSync().where((e) => e.path.contains('.tmp-')), isEmpty);
    });
  });

  group('Notas sin reescribir el cuaderno', () {
    File noteFile(String id) => File('${tempDir.path}/notes/$id.json');

    test('saveNote guarda en disco el updatedAt de ese guardado', () async {
      final nb = await storage.createNotebook(title: 'Fechas');
      final note = nb.notes.first;
      final before = note.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await storage.saveNote(nb.id, note);

      final onDisk = (await storage.loadNote(note.id))!.updatedAt;
      expect(onDisk.isAfter(before), isTrue);
      expect(onDisk, note.updatedAt);
    });

    test('createNote, renameNote y duplicateNote no tocan las otras notas',
        () async {
      final nb = await storage.createNotebook(title: 'Grande');
      final first = nb.notes.first;
      final stamp = DateTime(2001);
      noteFile(first.id).setLastModifiedSync(stamp);

      final created = await storage.createNote(nb.id, title: 'Nueva');
      await storage.renameNote(nb.id, created.id, 'Renombrada');
      final copy = await storage.duplicateNote(nb.id, created.id);

      expect(noteFile(first.id).lastModifiedSync(), stamp);
      final loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.notes.map((n) => n.id), [first.id, created.id, copy.id]);
      expect(loaded.notes[1].title, 'Renombrada');
    });

    test('deleteNote quita la nota pero nunca la última', () async {
      final nb = await storage.createNotebook(title: 'Borrar');
      final extra = await storage.createNote(nb.id);

      await storage.deleteNote(nb.id, extra.id);
      var loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.notes.map((n) => n.id), [nb.notes.first.id]);
      expect(noteFile(extra.id).existsSync(), isFalse);

      await storage.deleteNote(nb.id, nb.notes.first.id);
      loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.notes.length, 1);
    });

    test('renombrar, color y etiquetas actualizan cuaderno e índice', () async {
      final nb = await storage.createNotebook(title: 'Antes', colorValue: 0xFF112233);
      await storage.renameNotebook(nb.id, 'Después');
      await storage.setNotebookTags(nb.id, ['física']);
      await storage.setNotebookColor(nb.id, null);

      final meta = (await storage.loadIndex()).single;
      expect(meta.title, 'Después');
      expect(meta.tags, ['física']);
      expect(meta.colorValue, isNull);
      final loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.title, 'Después');
      expect(loaded.tags, ['física']);
      expect(loaded.colorValue, isNull);
      expect(loaded.notes.length, 1);
    });

    test('createNote en un cuaderno inexistente no deja la nota huérfana',
        () async {
      await expectLater(storage.createNote('nb_no_existe'), throwsStateError);
      final notesDir = Directory('${tempDir.path}/notes');
      final left = notesDir.existsSync() ? notesDir.listSync() : const [];
      expect(left, isEmpty);
    });

    test('writeJsonAtomic en segundo plano escribe el mismo JSON', () async {
      final f = File('${tempDir.path}/big.json');
      final json = {'a': List.generate(1000, (i) => {'x': i, 'y': i / 2})};
      await writeJsonAtomic(f, json, background: true);
      expect(jsonDecode(f.readAsStringSync()), json);
      expect(tempDir.listSync().where((e) => e.path.contains('.tmp-')), isEmpty);
    });
  });

  group('Papelera', () {
    Directory trash() => Directory('${tempDir.path}/trash');

    test('un cuaderno borrado es UNA entrada, con sus notas y su fecha', () async {
      final nb = await storage.createNotebook(title: 'Física');
      await storage.createNote(nb.id, title: 'Tema 2');
      await storage.deleteNotebook(nb.id);

      final entries = await storage.loadTrash();
      expect(entries.single.id, nb.id);
      expect(entries.single.kind, TrashKind.notebook);
      expect(entries.single.noteCount, 2);
      expect(DateTime.now().difference(entries.single.deletedAt).inMinutes, 0);
    });

    test('una nota borrada vuelve a su cuaderno', () async {
      final nb = await storage.createNotebook(title: 'Química');
      final extra = await storage.createNote(nb.id, title: 'Enlaces');
      await storage.deleteNote(nb.id, extra.id);

      final entry = (await storage.loadTrash()).single;
      expect(entry.kind, TrashKind.note);
      expect(entry.notebookTitle, 'Química');

      await storage.restoreFromTrash(extra.id);
      final loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.notes.map((n) => n.id), contains(extra.id));
      expect(await storage.loadTrash(), isEmpty);
      expect((await storage.loadIndex()).length, 1, reason: 'sin cuaderno nuevo');
    });

    test('si su cuaderno ya no existe, la nota vuelve en uno nuevo', () async {
      final nb = await storage.createNotebook(title: 'Historia');
      final extra = await storage.createNote(nb.id, title: 'Roma');
      await storage.deleteNote(nb.id, extra.id);
      await storage.deleteNotebook(nb.id);
      await storage.purgeFromTrash(nb.id);

      await storage.restoreFromTrash(extra.id);
      final metas = await storage.loadIndex();
      expect(metas.single.title, 'Historia');
      final restored = (await storage.loadNotebook(metas.single.id))!;
      expect(restored.notes.single.title, 'Roma');
    });

    test('borrar definitivamente un cuaderno borra también sus notas', () async {
      final nb = await storage.createNotebook(title: 'Temporal');
      await storage.deleteNotebook(nb.id);
      await storage.purgeFromTrash(nb.id);
      expect(trash().listSync(), isEmpty);
    });

    test('restaurar un cuaderno recupera todas sus notas', () async {
      final nb = await storage.createNotebook(title: 'Arte');
      final n2 = await storage.createNote(nb.id, title: 'Color');
      await storage.deleteNotebook(nb.id);
      await storage.restoreFromTrash(nb.id);

      final loaded = (await storage.loadNotebook(nb.id))!;
      expect(loaded.notes.map((n) => n.id), [nb.notes.first.id, n2.id]);
      expect(await storage.loadTrash(), isEmpty);
      final raw = File('${tempDir.path}/notebooks/${nb.id}.json').readAsStringSync();
      expect(raw.contains('_trash'), isFalse);
    });

    test('lo que lleva más de 30 días se borra solo', () async {
      final nb = await storage.createNotebook(title: 'Viejo');
      await storage.deleteNotebook(nb.id);
      final f = File('${trash().path}/${nb.id}.json');
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      json['_trash'] = {
        'deletedAt':
            DateTime.now().subtract(const Duration(days: 31)).toIso8601String(),
      };
      f.writeAsStringSync(jsonEncode(json));

      expect(await storage.loadTrash(), isEmpty);
      expect(trash().listSync(), isEmpty, reason: 'también sus notas');
    });
  });
}
