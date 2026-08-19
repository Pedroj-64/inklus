import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/stroke_engine.dart';
import '../models/document.dart';
import '../models/page.dart';
import '../models/stroke.dart';
import '../ui/canvas/world_painter.dart';
import 'pptx_builder.dart';

/// Opciones de exportación configurables por el usuario.
class ExportOptions {
  /// Dimensiones máximas del lado más largo de la imagen (px).
  final int maxDimension;

  /// Rect de región a exportar (en coordenadas de mundo). null = contenido
  /// completo de la página.
  final Rect? region;

  /// Si es true, no dibuja la plantilla (fondo) — solo imágenes + trazos.
  final bool transparentBackground;

  /// Si es true, solo dibuja los trazos (sin plantilla ni imágenes).
  final bool strokesOnly;

  const ExportOptions({
    this.maxDimension = 2048,
    this.region,
    this.transparentBackground = false,
    this.strokesOnly = false,
  });

  /// Opción por defecto (1:1, contenido completo, todo visible).
  static const defaults = ExportOptions();

  /// Para miniaturas de la biblioteca.
  static const thumbnail = ExportOptions(maxDimension: 480);

  ExportOptions copyWith({
    int? maxDimension,
    Rect? region,
    bool? transparentBackground,
    bool? strokesOnly,
  }) =>
      ExportOptions(
        maxDimension: maxDimension ?? this.maxDimension,
        region: region ?? this.region,
        transparentBackground:
            transparentBackground ?? this.transparentBackground,
        strokesOnly: strokesOnly ?? this.strokesOnly,
      );
}

/// Exportación de la página a imagen PNG o PDF.
///
/// Renderiza fuera de pantalla con un [ui.PictureRecorder] reutilizando el
/// mismo pintor del lienzo, por lo que el resultado es independiente del
/// zoom/pan actual de la vista.
class ExportService {
  const ExportService._();

  /// Renderiza la página completa y devuelve los bytes PNG.
  ///
  /// [options] permite configurar DPI, región, fondo transparente y solo
  /// trazos. Por defecto usa [ExportOptions.defaults].
  static Future<Uint8List> renderPagePng(
    Page page, {
    required Size sheetSize,
    required Map<String, ui.Image> imageCache,
    ExportOptions options = ExportOptions.defaults,
  }) async {
    final finite = page.template.isFinite;
    final bounds = options.region ??
        (finite
            ? Rect.fromCenter(
                center: Offset.zero,
                width: sheetSize.width,
                height: sheetSize.height,
              ).inflate(24)
            : contentBounds(page));

    var w = bounds.width.ceil().clamp(64, 8192);
    var h = bounds.height.ceil().clamp(64, 8192);
    final longest = w > h ? w : h;
    final factor =
        longest > options.maxDimension ? options.maxDimension / longest : 1.0;
    if (factor < 1.0) {
      w = (w * factor).ceil().clamp(64, options.maxDimension);
      h = (h * factor).ceil().clamp(64, options.maxDimension);
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
      omitTemplate: options.transparentBackground || options.strokesOnly,
      omitImages: options.strokesOnly,
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
    ExportOptions options = ExportOptions.defaults,
  }) async {
    final png = await renderPagePng(
      page,
      sheetSize: sheetSize,
      imageCache: imageCache,
      options: options,
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
    ExportOptions options = ExportOptions.defaults,
  }) async {
    final doc = pw.Document();
    for (final page in document.pages) {
      final sheetSize = page.template.sheetSize;
      final png = await renderPagePng(
        page,
        sheetSize: sheetSize,
        imageCache: imageCache,
        options: options,
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

  // -------------------------------------------------------------------------
  // SVG
  // -------------------------------------------------------------------------

  /// Genera un archivo SVG con los trazos de la página.
  ///
  /// Cada trazo se convierte en un `<path>` SVG usando el polígono de
  /// `StrokeEngine.outlineFor`. El SVG resultante es un documento válido
  /// que se puede abrir en Inkscape, Illustrator o cualquier visor SVG.
  ///
  /// [strokesOnly] si es true, solo incluye trazos (sin plantilla).
  static String renderPageSvg(
    Page page, {
    bool strokesOnly = false,
  }) {
    // Calcular bounds del contenido.
    final bounds = contentBounds(page, padding: 20);

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="${bounds.left} ${bounds.top} ${bounds.width} ${bounds.height}" '
      'width="${bounds.width.ceil()}" height="${bounds.height.ceil()}">',
    );

    // Fondo (opcional).
    if (!strokesOnly) {
      buffer.writeln(
        '  <rect x="${bounds.left}" y="${bounds.top}" '
        'width="${bounds.width}" height="${bounds.height}" '
        'fill="#FEFDF9" />',
      );
    }

    // Trazos.
    for (final stroke in page.strokes) {
      final outline = StrokeEngine.outlineFor(stroke);
      if (outline.length < 3) continue;

      final color = StrokeEngine.paintColor(stroke);
      final hexColor = _colorToHex(color);
      final opacity = stroke.tool == ToolType.highlighter ? 0.38 : 1.0;

      // Construir el path SVG del polígono.
      final pathData = StringBuffer('M');
      for (var i = 0; i < outline.length; i++) {
        final p = outline[i];
        if (i > 0) pathData.write(' L');
        pathData.write(' ${p.dx.toStringAsFixed(2)} ${p.dy.toStringAsFixed(2)}');
      }
      pathData.write(' Z');

      buffer.writeln(
        '  <path d="$pathData" fill="$hexColor" '
        'opacity="${opacity.toStringAsFixed(2)}" />',
      );
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Convierte un Color a string hex (#RRGGBB).
  static String _colorToHex(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  // -------------------------------------------------------------------------
  // PowerPoint (.pptx)
  // -------------------------------------------------------------------------

  /// Exporta el cuaderno completo como un archivo .pptx.
  ///
  /// Cada página se renderiza como imagen PNG y se inserta como una
  /// diapositiva. El resultado es un archivo PPTX válido que se puede
  /// abrir en PowerPoint, Google Slides o Keynote.
  static Future<Uint8List> renderNotebookPptx(
    Document document, {
    required Map<String, ui.Image> imageCache,
    ExportOptions options = ExportOptions.defaults,
  }) async {
    // Renderizar cada página como PNG.
    final slideImages = <Uint8List>[];
    for (final page in document.pages) {
      final png = await renderPagePng(
        page,
        sheetSize: page.template.sheetSize,
        imageCache: imageCache,
        options: options,
      );
      slideImages.add(png);
    }

    // Delega al builder externo (pptx_builder.dart).
    return buildPptx(slideImages, document.title);
  }
}
