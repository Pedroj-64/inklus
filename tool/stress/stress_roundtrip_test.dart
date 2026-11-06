// SPDX-License-Identifier: GPL-3.0-or-later
// Prueba de carga: importa build/inklus_stress.inklus (genéralo antes con
// stress_note_test.dart), lo guarda/recarga y lo exporta a PNG/PDF/PPTX/SVG
// midiendo tiempos. Fuera de la suite normal.
//
//   flutter test tool/stress/stress_roundtrip_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/services/export_service.dart';
import 'package:inklus/services/inklus_format.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  testWidgets('importar → guardar → cargar → exportar la nota de estrés',
      (tester) async {
    await tester.runAsync(() async {
      final src = File('build/inklus_stress.inklus');
      expect(src.existsSync(), isTrue, reason: 'genera antes la nota de estrés');
      final tmp = Directory.systemTemp.createTempSync('inklus_load_');
      final sw = Stopwatch();
      Future<T> t<T>(String name, Future<T> Function() f) async {
        sw
          ..reset()
          ..start();
        final r = await f();
        // ignore: avoid_print
        print('  ${name.padRight(22)} ${sw.elapsedMilliseconds} ms');
        return r;
      }

      try {
        final imported = await t(
            'importar .inklus',
            () async => await InklusFormat.importAuto(src.readAsBytesSync(),
                extractTo: Directory('${tmp.path}/img')) as Notebook);
        final note = imported.notes.first;
        final strokes = note.pages.fold<int>(0, (n, p) => n + p.strokes.length);
        final images = note.pages.fold<int>(0, (n, p) => n + p.images.length);
        expect(strokes, greaterThan(5000));
        expect(images, 10);

        final storage = StorageService(baseDir: tmp);
        await t('guardar en disco', () => storage.saveNotebook(imported));
        final loaded = await t('cargar de disco', () => storage.loadNote(note.id));
        expect(loaded, isNotNull);
        expect(loaded!.pages.length, note.pages.length);
        expect(loaded.pages.fold<int>(0, (n, p) => n + p.strokes.length), strokes);
        for (var i = 0; i < note.pages.length; i++) {
          for (var j = 0; j < note.pages[i].strokes.length; j++) {
            expect(loaded.pages[i].strokes[j].id, note.pages[i].strokes[j].id);
            expect(loaded.pages[i].strokes[j].points.length,
                note.pages[i].strokes[j].points.length);
          }
        }

        final cache = <String, ui.Image>{};
        final png = await t(
            'PNG página 1',
            () => ExportService.renderPagePng(loaded.pages.first,
                sheetSize: const Size(595, 842), imageCache: cache));
        expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

        final pdf = await t('PDF cuaderno',
            () => ExportService.renderNotebookPdf(loaded, imageCache: cache));
        expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');

        final pptx = await t('PPTX cuaderno',
            () => ExportService.renderNotebookPptx(loaded, imageCache: cache));
        expect(pptx.sublist(0, 2), [0x50, 0x4B]);

        final svg = await t('SVG página 1',
            () async => ExportService.renderPageSvg(loaded.pages.first));
        expect(svg, contains('</svg>'));

        final backup = await t('respaldo completo', () => storage.exportFullBackup());
        final t2 = Directory.systemTemp.createTempSync('inklus_load2_');
        try {
          final restored = StorageService(baseDir: t2);
          final n = await t('restaurar respaldo',
              () => restored.importFullBackup(Uint8List.fromList(backup)));
          expect(n, greaterThan(0));
          expect(await restored.loadNote(note.id), isNotNull);
        } finally {
          t2.deleteSync(recursive: true);
        }
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });
  }, timeout: const Timeout(Duration(minutes: 8)));
}
