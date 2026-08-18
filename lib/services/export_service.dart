import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/document.dart';
import '../models/page.dart';
import '../ui/canvas/world_painter.dart';

/// Exportación de la página a imagen PNG o PDF.
///
/// Renderiza fuera de pantalla con un [ui.PictureRecorder] reutilizando el
/// mismo pintor del lienzo, por lo que el resultado es independiente del
/// zoom/pan actual de la vista.
class ExportService {
  const ExportService._();

  /// Renderiza la página completa y devuelve los bytes PNG.
  ///
  /// [maxDimension] limita el lado más largo de la imagen resultante
  /// (manteniendo el aspect ratio): las exportaciones usan el tamaño 1:1 del
  /// mundo; las miniaturas de la biblioteca pasan un valor pequeño (p. ej.
  /// 480) para renderizar rápido y ligero.
  static Future<Uint8List> renderPagePng(
    Page page, {
    required Size sheetSize,
    required Map<String, ui.Image> imageCache,
    int maxDimension = 2048,
  }) async {
    final finite = page.template.isFinite;
    final bounds = finite
        ? Rect.fromCenter(
            center: Offset.zero,
            width: sheetSize.width,
            height: sheetSize.height,
          ).inflate(24) // margen de la sombra de la hoja
        : contentBounds(page);

    var w = bounds.width.ceil().clamp(64, 8192);
    var h = bounds.height.ceil().clamp(64, 8192);
    final longest = w > h ? w : h;
    final factor = longest > maxDimension ? maxDimension / longest : 1.0;
    if (factor < 1.0) {
      w = (w * factor).ceil().clamp(64, maxDimension);
      h = (h * factor).ceil().clamp(64, maxDimension);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (factor < 1.0) canvas.scale(factor);
    paintWorld(
      canvas,
      visibleWorldRect: bounds,
      page: page,
      sheetSize: sheetSize,
      imageCache: imageCache,
    );
    final picture = recorder.endRecording();

    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Genera un PDF con la página (una página por hoja).
  static Future<Uint8List> renderPagePdf(
    Page page, {
    required Size sheetSize,
    required Map<String, ui.Image> imageCache,
  }) async {
    final png = await renderPagePng(
      page,
      sheetSize: sheetSize,
      imageCache: imageCache,
    );

    final finite = page.template.isFinite;
    final aspect = finite
        ? sheetSize.width / sheetSize.height
        : (contentBounds(page).width / contentBounds(page).height).clamp(0.5, 2.0);

    final format = PdfPageFormat(
      PdfPageFormat.a4.width,
      PdfPageFormat.a4.width / aspect,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (ctx) => pw.Center(
          child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
        ),
      ),
    );
    return doc.save();
  }

  /// Genera un PDF con **todas las páginas** del cuaderno (una hoja PDF por
  /// página de nota). Cada página se renderiza con su propia plantilla/tamaño.
  static Future<Uint8List> renderNotebookPdf(
    Document document, {
    required Map<String, ui.Image> imageCache,
  }) async {
    final doc = pw.Document();
    for (final page in document.pages) {
      final sheetSize = page.template.sheetSize;
      final png = await renderPagePng(
        page,
        sheetSize: sheetSize,
        imageCache: imageCache,
      );

      final finite = page.template.isFinite;
      final aspect = finite
          ? sheetSize.width / sheetSize.height
          : (contentBounds(page).width / contentBounds(page).height)
              .clamp(0.5, 2.0);

      final format = PdfPageFormat(
        PdfPageFormat.a4.width,
        PdfPageFormat.a4.width / aspect,
      );
      doc.addPage(
        pw.Page(
          pageFormat: format,
          build: (ctx) => pw.Center(
            child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return doc.save();
  }
}
