// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/text_item.dart';
import 'package:inklus/services/search_service.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tmp;
  late SearchService search;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_search_');
    search = SearchService(storage: StorageService(baseDir: tmp));
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Note noteWithText(String title, String text) {
    final n = Note.newBlank(title: title);
    n.pages.first.textItems.add(TextItem(id: 't', x: 0, y: 0, width: 100, text: text));
    return n;
  }

  test('ignora mayúsculas y acentos', () async {
    await search.indexNote('nb', noteWithText('Álgebra', 'Ecuación de segundo grado'));
    expect(search.search('ECUACION').single.matches.single.pageIndex, 0);
    expect(search.search('algebra').single.matches.first.source, SearchSource.title);
  });

  test('la escritura reconocida se conserva al reindexar', () async {
    final note = noteWithText('Física', 'hola');
    await search.indexNote('nb', note);
    await search.setHandwriting(note.id, note.pages.first.id, 'velocidad angular');
    await search.indexNote('nb', note); // p. ej. al volver a abrir la nota
    final m = search.search('angular').single.matches.single;
    expect(m.source, SearchSource.handwriting);
  });

  test('persiste en disco', () async {
    final note = noteWithText('Química', 'enlace covalente');
    await search.indexNote('nb', note);
    final reopened = SearchService(storage: StorageService(baseDir: tmp));
    await reopened.load();
    expect(reopened.search('covalente'), isNotEmpty);
  });

  test('solo en una nota', () async {
    final a = noteWithText('A', 'manzana');
    final b = noteWithText('B', 'manzana');
    await search.indexNote('nb', a);
    await search.indexNote('nb', b);
    expect(search.search('manzana').length, 2);
    expect(search.search('manzana', onlyNoteId: a.id).single.noteId, a.id);
  });
}
