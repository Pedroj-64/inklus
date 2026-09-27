// SPDX-License-Identifier: GPL-3.0-or-later
// Genera un cuaderno de estrés para medir el rendimiento en un dispositivo
// real (Fase 1.5 del roadmap): 3 páginas A4, ~5.000 trazos y 10 fotos
// grandes (4000×3000).
//
//   flutter test tool/stress/stress_note_test.dart
//
// Salida: build/inklus_stress.inklus (o $INKLUS_STRESS_OUT). Se importa en
// la app desde la biblioteca → "Importar .inklus o respaldo". Fuera de test/
// a propósito: no forma parte de la suite ni de la CI.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/image_item.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/models/page.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/models/template.dart';
import 'package:inklus/services/inklus_format.dart';

const _strokesPerPage = 1700;
const _photos = 10;

void main() {
  testWidgets('genera build/inklus_stress.inklus', (tester) async {
    await tester.runAsync(() async {
      final tmp = Directory.systemTemp.createTempSync('inklus_stress_');
      final rnd = Random(42);
      final pages = <Page>[];
      for (var p = 0; p < 3; p++) {
        final page = Page.blank(
          name: 'Página ${p + 1}',
          template: const PageTemplate(type: TemplateType.sheet),
        );
        _fillWithHandwriting(page, rnd, p);
        pages.add(page);
      }
      // Fotos grandes en la primera página (las que antes se decodificaban
      // a resolución completa: ~48 MB cada una).
      for (var i = 0; i < _photos; i++) {
        final file = File('${tmp.path}/foto_$i.png')
          ..writeAsBytesSync(await _photo(4000, 3000, i));
        pages[i.isEven ? 0 : 1].images.add(ImageItem(
              id: 'img_$i',
              localPath: file.path,
              x: -300.0 + (i % 3) * 300,
              y: -600.0 + (i ~/ 3) * 320,
              width: 280,
              height: 210,
            ));
      }

      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb_stress_${now.millisecondsSinceEpoch}',
        title: 'Prueba de rendimiento',
        notes: [
          Note(
            id: 'note_stress_${now.millisecondsSinceEpoch}',
            title: 'Estrés: ${_strokesPerPage * 3} trazos + $_photos fotos',
            createdAt: now,
            updatedAt: now,
            pages: pages,
          ),
        ],
      );
      final out = File(Platform.environment['INKLUS_STRESS_OUT'] ??
          'build/inklus_stress.inklus');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(await InklusFormat.exportNotebookBytes(nb));
      tmp.deleteSync(recursive: true);
      // ignore: avoid_print
      print('→ ${out.path} (${(out.lengthSync() / 1e6).toStringAsFixed(1)} MB)');
    });
  });
}

/// Renglones de "letras" (bucles cortos con presión variable) sobre la hoja.
void _fillWithHandwriting(Page page, Random rnd, int pageIndex) {
  const left = -540.0, top = -780.0, lineH = 38.0, width = 1080.0;
  var x = left, y = top;
  const colors = [0xFF1A1A1A, 0xFF1565C0, 0xFFC62828];
  for (var s = 0; s < _strokesPerPage; s++) {
    final pts = <StrokePoint>[];
    final w = 12 + rnd.nextDouble() * 18;
    final n = 14 + rnd.nextInt(20);
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      pts.add(StrokePoint(
        x + t * w,
        y + sin(t * pi * (2 + rnd.nextInt(3))) * 9 + rnd.nextDouble() * 2,
        0.35 + 0.4 * sin(t * pi),
      ));
    }
    page.strokes.add(Stroke(
      id: 'st_${pageIndex}_$s',
      points: pts,
      tool: s % 40 == 0 ? ToolType.highlighter : ToolType.pen,
      colorValue: colors[(s ~/ 200) % colors.length],
      size: s % 40 == 0 ? 14 : 3,
    ));
    x += w + 6;
    if (x > left + width) {
      x = left;
      y += lineH;
      if (y > -top) y = top;
    }
  }
}

/// PNG "foto" de [w]×[h] con degradado y formas (se comprime poco, como una
/// foto real).
Future<List<int>> _photo(int w, int h, int seed) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [Color(0xFF000000 | (seed * 0x3A5F17) & 0xFFFFFF), const Color(0xFFFFE0B2)],
      ),
  );
  final rnd = Random(seed);
  for (var i = 0; i < 400; i++) {
    canvas.drawCircle(
      Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
      10 + rnd.nextDouble() * 120,
      Paint()..color = Color(0x80000000 | rnd.nextInt(0xFFFFFF)),
    );
  }
  final img = await recorder.endRecording().toImage(w, h);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}
