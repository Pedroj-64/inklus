// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/models/flashcard.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/services/backup_crypto.dart';
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

    // --- A12: Tests de Note ---

    test('exportNoteBytes/importNoteBytes roundtrip preserva contenido', () async {
      final page = Page.blank(name: 'Nota P1');
      page.strokes.add(Stroke(
        id: 'st_note',
        points: const [StrokePoint(0, 0, 0.5), StrokePoint(20, 30, 0.7)],
        tool: ToolType.calligraphy,
        colorValue: 0xFF8B5CF6,
        size: 5,
      ));
      page.images.add(ImageItem(
        id: 'img_note',
        localPath: imageFile.path,
        x: 50,
        y: 50,
        width: 100,
        height: 80,
      ));

      final note = Note(
        id: 'note_fmt',
        title: 'Nota de prueba',
        createdAt: DateTime(2026, 8, 19),
        updatedAt: DateTime(2026, 8, 19, 15),
        pages: [page],
      );

      final bytes = await InklusFormat.exportNoteBytes(note);
      expect(bytes, isNotEmpty);

      final restored = await InklusFormat.importNoteBytes(
        bytes,
        extractTo: extractDir,
      );

      expect(restored.id, 'note_fmt');
      expect(restored.title, 'Nota de prueba');
      expect(restored.pages.length, 1);
      expect(restored.pages.first.name, 'Nota P1');
      expect(restored.pages.first.strokes.length, 1);
      expect(restored.pages.first.strokes.first.tool, ToolType.calligraphy);

      // Imagen se restaura a archivo local
      final img = restored.pages.first.images.first;
      expect(img.localPath, isNot(contains('inklus://')));
      expect(File(img.localPath).existsSync(), isTrue);
    });

    test('exportNoteBytes genera un .inklus válido para importBytes (compat)', () async {
      // Un Note exportado debe poder importarse también con importBytes (Document)
      final note = Note(
        id: 'note_compat',
        title: 'Compat',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        pages: [Page.blank()],
      );

      final bytes = await InklusFormat.exportNoteBytes(note);
      final doc = await InklusFormat.importBytes(bytes, extractTo: extractDir);

      // El Document importado tiene el mismo id y contenido
      expect(doc.id, 'note_compat');
      expect(doc.title, 'Compat');
      expect(doc.pages.length, 1);
    });
  });

  test('una copia cifrada no se abre como .inklus: FormatException', () async {
    final bytes = await InklusFormat.exportNoteBytes(Note.newBlank(title: 'x'));
    final encrypted = await BackupCrypto.encrypt(bytes, 'secreta');
    await expectLater(
      InklusFormat.importNoteBytes(encrypted, extractTo: extractDir),
      throwsA(isA<FormatException>()),
    );
  });

  test('audio, marcadores y enlaces viajan en .inklus (nota y cuaderno)', () async {
    final audio = File('${tempDir.path}/rec_1.m4a')..writeAsBytesSync(List.filled(16, 3));
    final page = Page.blank()..bookmarked = true;
    page.links.add(const PageLink(Rect.fromLTWH(1, 2, 3, 4), 'p2'));
    final note = Note.newBlank()..pages[0] = page;
    note.recordings.add(AudioRecording(id: 'rec_1', path: audio.path, startedAt: 10, durationMs: 500));
    note.flashcards.add(Flashcard(id: 'card', pageId: page.id, front: const Rect.fromLTWH(0, 0, 5, 5)));

    final one = await InklusFormat.importNoteBytes(
        await InklusFormat.exportNoteBytes(note), extractTo: Directory('${tempDir.path}/a'));
    expect(one.recordings.single.durationMs, 500);
    expect(one.flashcards.single.id, 'card');
    expect(File(one.recordings.single.path).readAsBytesSync(), audio.readAsBytesSync());

    final nb = await InklusFormat.importNotebookBytes(
        await InklusFormat.exportNotebookBytes(Notebook(id: 'nb', title: 't', notes: [note])),
        extractTo: Directory('${tempDir.path}/b'));
    final back = nb.notes.single;
    expect(back.pages.single.bookmarked, isTrue);
    expect(back.pages.single.links.single.toPageId, 'p2');
    expect(File(back.recordings.single.path).existsSync(), isTrue);
    expect(back.flashcards.single.pageId, page.id);
  });
}
