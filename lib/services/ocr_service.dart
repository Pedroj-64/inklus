import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/page.dart';
import '../models/stroke.dart';
import 'export_service.dart';
import 'image_service.dart';

/// Resultado del reconocimiento de texto de una página.
class OcrResult {
  /// Texto completo reconocido (todas las líneas concatenadas con saltos).
  final String text;

  /// Bloques de texto reconocidos, cada uno con su texto y bounding box
  /// en coordenadas de imagen (px, no mundo).
  final List<OcrBlock> blocks;

  const OcrResult({required this.text, required this.blocks});

  bool get isEmpty => text.isEmpty;
}

/// Un bloque de texto reconocido con su posición aproximada.
class OcrBlock {
  final String text;
  final double x; // izquierda (px)
  final double y; // arriba (px)
  final double width;
  final double height;

  const OcrBlock({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Servicio de OCR on-device (solo Android/iOS).
///
/// Renderiza la página a un PNG temporal, lo pasa al reconocedor de texto
/// de ML Kit y devuelve el texto reconocido con las posiciones de cada bloque.
///
/// En plataformas no soportadas (Linux desktop), lanza
/// [UnsupportedError].
class OcrService {
  const OcrService._();

  /// Plataformas soportadas por ML Kit text recognition.
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Reconoce el texto de una página.
  ///
  /// [page] es la página a reconocer; [sheetSize] y [imageCache] se pasan
  /// a `renderPagePng` para generar la imagen temporal.
  ///
  /// Devuelve el texto completo o un string vacío si no hay nada reconocible.
  static Future<OcrResult> recognizeText(
    Page page, {
    required ui.Size sheetSize,
    required Map<String, ui.Image> imageCache,
    ImageService? imageService,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'OCR solo está disponible en Android e iOS.',
      );
    }

    // 1) Renderizar la página a PNG temporal.
    final pngBytes = await ExportService.renderPagePng(
      page,
      sheetSize: sheetSize,
      imageCache: imageCache,
      options: const ExportOptions(maxDimension: 4096),
    );

    // 2) Guardar en archivo temporal.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inklus_ocr_temp.png');
    await file.writeAsBytes(pngBytes);

    // 3) Ejecutar ML Kit text recognition.
    final inputImage = InputImage.fromFilePath(file.path);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final recognized = await textRecognizer.processImage(inputImage);

      // 4) Convertir bloques a nuestro modelo.
      final blocks = <OcrBlock>[];
      for (final block in recognized.blocks) {
        blocks.add(OcrBlock(
          text: block.text,
          x: block.boundingBox.left.toDouble(),
          y: block.boundingBox.top.toDouble(),
          width: block.boundingBox.width.toDouble(),
          height: block.boundingBox.height.toDouble(),
        ));
      }

      return OcrResult(
        text: recognized.text,
        blocks: blocks,
      );
    } finally {
      await textRecognizer.close();
      // Limpiar archivo temporal.
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  /// Reconoce el texto de una lista específica de trazos (on-demand).
  ///
  /// C8: Renderiza solo los trazos dados a un PNG temporal y ejecuta OCR.
  /// Útil para reconocer la última acción de escritura sin procesar toda
  /// la página. Devuelve el texto reconocido o string vacío.
  static Future<OcrResult> recognizeStrokes(
    List<Stroke> strokes, {
    required ui.Size sheetSize,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'OCR solo está disponible en Android e iOS.',
      );
    }
    if (strokes.isEmpty) return const OcrResult(text: '', blocks: []);

    // Crear una página temporal solo con estos trazos.
    final tempPage = Page.blank(name: 'ocr_temp');
    tempPage.strokes.addAll(strokes);

    return recognizeText(
      tempPage,
      sheetSize: sheetSize,
      imageCache: {},
    );
  }
}
