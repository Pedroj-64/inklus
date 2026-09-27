// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/import_service.dart';

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

    test('otro ZIP → FormatException', () {
      expect(() => ImportService.kindFor({'foo.txt'}), throwsFormatException);
      expect(() => ImportService.kindFor(<String>{}), throwsFormatException);
    });
  });
}
