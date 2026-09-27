// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/services/import_service.dart';
import 'package:inklus/services/inklus_format.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  group('ImportService.kindFor', () {
    test('respaldo completo', () {
      expect(ImportService.kindFor({'backup.json', 'index.json', 'notes/a.json'}),
          ImportKind.fullBackup);
      expect(ImportService.kindFor({'index.json'}), ImportKind.fullBackup);
    });

    test('cuaderno .inklus v2 (aunque venga renombrado a .zip)', () {
      expect(ImportService.kindFor({'format.json', 'notebook.json', 'notes/n1.json'}),
          ImportKind.notebook);
    });

    test('.inklus v1 legacy', () {
      expect(ImportService.kindFor({'document.json', 'images/a.png'}),
          ImportKind.legacyDocument);
    });

    test('nota suelta (copia de Drive): format.json + document.json es v1', () {
      expect(ImportService.kindFor({'format.json', 'document.json'}),
          ImportKind.legacyDocument);
    });

    test('otro ZIP → FormatException', () {
      expect(() => ImportService.kindFor({'foo.txt'}), throwsFormatException);
      expect(() => ImportService.kindFor(<String>{}), throwsFormatException);
    });
  });

  test('un .inklus v1 importado queda dentro de su cuaderno', () async {
    final tempDir = Directory.systemTemp.createTempSync('inklus_import_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final storage = StorageService(baseDir: Directory('${tempDir.path}/lib'));
    final doc = Document.newBlank(title: 'Viejo');
    final bytes = await InklusFormat.exportBytes(doc);

    final result = await ImportService.importBytes(
      bytes,
      storage: storage,
      extractTo: Directory('${tempDir.path}/restored'),
    );

    expect(result.kind, ImportKind.legacyDocument);
    final nb = (await storage.loadNotebook(result.notebookId!))!;
    expect(nb.title, 'Viejo');
    expect(nb.notes.single.title, 'Viejo');
    expect(nb.notes.single.id, isNot(doc.id));
  });
}
