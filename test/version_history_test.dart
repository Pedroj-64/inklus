// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/services/version_history_service.dart';

void main() {
  late Directory tmp;
  late VersionHistoryService versions;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_versions_');
    versions = VersionHistoryService(
      storage: StorageService(baseDir: tmp),
      maxVersions: 3,
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Note noteWith(int strokes) {
    final note = Note.newBlank(title: 'Historial');
    for (var i = 0; i < strokes; i++) {
      note.pages.first.strokes.add(Stroke(
        id: 's$i',
        points: const [StrokePoint(0, 0, 0.5), StrokePoint(10, 10, 0.5)],
        tool: ToolType.pen,
        colorValue: 0xFF000000,
        size: 3,
      ));
    }
    return note;
  }

  test('snapshot + load devuelve el mismo contenido', () async {
    final note = noteWith(2);
    expect(await versions.snapshot(note), isTrue);
    final list = await versions.list(note.id);
    expect(list.length, 1);
    final loaded = await versions.load(list.single);
    expect(loaded.id, note.id);
    expect(loaded.pages.first.strokes.length, 2);
  });

  test('respeta el intervalo mínimo salvo con force', () async {
    final note = noteWith(1);
    expect(await versions.snapshot(note), isTrue);
    expect(await versions.snapshot(note), isFalse);
    expect(await versions.snapshot(note, force: true), isTrue);
    expect((await versions.list(note.id)).length, 2);
  });

  test('conserva solo las maxVersions más recientes', () async {
    final note = noteWith(0);
    for (var i = 0; i < 5; i++) {
      await versions.snapshot(noteWithId(note.id, i), force: true);
    }
    final list = await versions.list(note.id);
    expect(list.length, 3);
    // La más reciente primero.
    final newest = await versions.load(list.first);
    expect(newest.pages.first.strokes.length, 4);
  });
}

Note noteWithId(String id, int strokes) {
  final note = Note(
    id: id,
    title: 'Historial',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    pages: Note.newBlank().pages,
  );
  for (var i = 0; i < strokes; i++) {
    note.pages.first.strokes.add(Stroke(
      id: 's$i',
      points: const [StrokePoint(0, 0, 0.5), StrokePoint(10, 10, 0.5)],
      tool: ToolType.pen,
      colorValue: 0xFF000000,
      size: 3,
    ));
  }
  return note;
}
