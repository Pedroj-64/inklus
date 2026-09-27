// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'file_utils.dart';

/// Servicio de importación de PDF.
///
/// Renderiza páginas de un archivo PDF como imágenes PNG para usar como
/// plantilla de fondo en el editor. Usa el paquete `printing` que delega
/// el renderizado a la plataforma nativa (Android/iOS).
///
/// En Linux desktop (dev), PDF rendering no está soportado por `printing`.
/// La app funciona correctamente sin esta feature en escritorio.
class PdfImportService {
  const PdfImportService._();

  /// Si la plataforma soporta renderizado de PDF.
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Renderiza la primera página de un PDF como imagen PNG.
  ///
  /// Devuelve los bytes PNG de la imagen renderizada, o null si falla.
  /// [maxWidth] controla la resolución máxima de renderizado (píxeles).
  static Future<Uint8List?> renderFirstPage(
    String pdfPath, {
    int maxWidth = 1200,
  }) async {
    if (!isSupported) return null;
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();

      final images = await Printing.raster(
        bytes,
        pages: [0], // Solo la primera página
        dpi: 150, // Resolución de renderizado
      ).toList();

      if (images.isEmpty) return null;

      final image = images.first;
      final pngBytes = await image.toPng();
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      debugPrint('PdfImportService.renderFirstPage: $e');
      return null;
    }
  }

  /// Renderiza todas las páginas de un PDF como imágenes PNG.
  ///
  /// Devuelve una lista de bytes PNG (una por página), o lista vacía si falla.
  static Future<List<Uint8List>> renderAllPages(
    String pdfPath, {
    int maxWidth = 1200,
  }) async {
    if (!isSupported) return [];
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return [];
      final bytes = await file.readAsBytes();

      final images = await Printing.raster(
        bytes,
        dpi: 150,
      ).toList();

      final results = <Uint8List>[];
      for (final image in images) {
        final pngBytes = await image.toPng();
        results.add(Uint8List.fromList(pngBytes));
      }
      return results;
    } catch (e) {
      debugPrint('PdfImportService.renderAllPages: $e');
      return [];
    }
  }

  /// Importa **todas** las páginas de un PDF para anotarlas: renderiza cada
  /// página y la guarda en `inklus/pdf_imports/` de una en una (sin tener
  /// todo el PDF rasterizado en memoria). Emite (ruta, ancho px, alto px).
  ///
  /// [onPage] informa del progreso (páginas procesadas).
  static Stream<PdfPageImage> importPages(
    String pdfPath, {
    double dpi = 150,
    void Function(int done)? onPage,
  }) async* {
    if (!isSupported) return;
    final bytes = await File(pdfPath).readAsBytes();
    final dir = await getApplicationSupportDirectory();
    final out = Directory('${dir.path}/inklus/pdf_imports');
    await out.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    var i = 0;
    await for (final raster in Printing.raster(bytes, dpi: dpi)) {
      final png = await raster.toPng();
      final file = File('${out.path}/pdf_${stamp}_p${i + 1}.png');
      await writeAtomic(file, png);
      i++;
      onPage?.call(i);
      yield PdfPageImage(file.path, raster.width, raster.height);
    }
  }

  /// Guarda una imagen PNG renderizada del PDF en la carpeta de la app
  /// y devuelve la ruta local.
  static Future<String?> saveRenderedPage(
    Uint8List pngBytes, {
    String? name,
  }) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final imagesDir = Directory('${dir.path}/inklus/pdf_imports');
      await imagesDir.create(recursive: true);
      final fileName = name ?? 'pdf_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${imagesDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      debugPrint('PdfImportService.saveRenderedPage: $e');
      return null;
    }
  }
}

/// Una página de PDF ya rasterizada y guardada en disco.
class PdfPageImage {
  const PdfPageImage(this.path, this.widthPx, this.heightPx);
  final String path;
  final int widthPx;
  final int heightPx;
}
