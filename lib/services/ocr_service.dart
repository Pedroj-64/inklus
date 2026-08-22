import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ink;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
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
/// **Estrategia principal**: usa `google_mlkit_digital_ink_recognition` que
/// trabaja directamente con los trazos vectoriales (coordenadas de mundo),
/// sin necesidad de renderizar a bitmap. Esto da mejor precisión y permite
/// reconocer texto por trazos individuales.
///
/// **Fallback**: si no hay trazos disponibles o el reconocimiento de tinta
/// falla, usa `google_mlkit_text_recognition` sobre un bitmap renderizado.
class OcrService {
  const OcrService._();

  /// Idioma BCP-47 para reconocimiento de tinta.
  /// 'es' = español; se puede ampliar a otros idiomas.
  static const String _inkLanguageCode = 'es';

  /// Plataformas soportadas (Android/iOS).
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // -------------------------------------------------------------------------
  // Modelo de tinta (descarga y cache)
  // -------------------------------------------------------------------------

  static bool _modelDownloaded = false;

  /// Verifica y descarga el modelo de reconocimiento de tinta si es necesario.
  ///
  /// Llamar antes de `recognizeStrokes()` para garantizar que el modelo
  /// esté disponible. Es silencioso: si la descarga falla, se devuelve false
  /// para que el caller pueda usar el fallback de bitmap.
  static Future<bool> ensureInkModel() async {
    if (!isSupported) return false;
    if (_modelDownloaded) return true;
    try {
      final manager = ink.DigitalInkRecognizerModelManager();
      final model = _inkLanguageCode;
      final downloaded = await manager.isModelDownloaded(model);
      if (!downloaded) {
        final ok = await manager.downloadModel(model);
        _modelDownloaded = ok;
        return ok;
      }
      _modelDownloaded = true;
      return true;
    } catch (e) {
      debugPrint('OcrService.ensureInkModel: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Método principal: reconocimiento de tinta vectorial (preferred)
  // -------------------------------------------------------------------------

  /// Reconoce texto a partir de trazos vectoriales directamente.
  ///
  /// [strokes] son los trazos de la página en coordenadas de mundo.
  /// Convierte cada trazo al formato `Ink` de ML Kit, que espera
  /// `StrokePoint(x, y, t)` — los timestamps se sintetizan a partir
  /// del orden de los puntos.
  ///
  /// Devuelve el texto reconocido con sus bloques posicionados.
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

    // Asegurar que el modelo de tinta esté descargado.
    final modelReady = await ensureInkModel();
    if (!modelReady) {
      // Fallback: renderizar a bitmap y usar text recognition.
      return _recognizeFallback(strokes, sheetSize: sheetSize);
    }

    // Convertir nuestros Stroke al formato Ink de ML Kit.
    final inkStrokes = _convertToInkStrokes(strokes);
    final inkData = ink.Ink()..strokes = inkStrokes;

    // Contexto de reconocimiento: usa el tamaño de la hoja como área
    // de escritura para mejorar la precisión.
    final context = ink.DigitalInkRecognitionContext(
      writingArea: ink.WritingArea(
        width: sheetSize.width,
        height: sheetSize.height,
      ),
    );

    final recognizer = ink.DigitalInkRecognizer(
      languageCode: _inkLanguageCode,
    );

    try {
      final candidates = await recognizer.recognize(
        inkData,
        context: context,
      );

      if (candidates.isEmpty) {
        return const OcrResult(text: '', blocks: []);
      }

      // El mejor candidato (mayor score).
      final best = candidates.first;
      final text = best.text;

      if (text.isEmpty) {
        return const OcrResult(text: '', blocks: []);
      }

      // Para la tinta vectorial, no tenemos bounding boxes precisos
      // por bloque de texto (ML Kit solo devuelve el texto completo).
      // Estimamos la posición basándonos en los puntos de los trazos.
      final bounds = _estimateTextBounds(strokes);

      final blocks = [
        OcrBlock(
          text: text,
          x: bounds.left,
          y: bounds.top,
          width: bounds.width,
          height: bounds.height,
        ),
      ];

      return OcrResult(text: text, blocks: blocks);
    } finally {
      recognizer.close();
    }
  }

  /// Reconoce texto de TODA la página usando tinta vectorial.
  ///
  /// Convenience method que toma una [Page] completa y extrae todos sus trazos.
  static Future<OcrResult> recognizePageInk(
    Page page, {
    required ui.Size sheetSize,
  }) async {
    // Filtrar trazos visibles (no borrador, no herramientas especiales).
    final inkStrokes = page.strokes
        .where((s) =>
            s.tool != ToolType.eraser &&
            s.tool != ToolType.select &&
            s.tool != ToolType.lasso &&
            s.tool != ToolType.bucket &&
            s.tool != ToolType.text)
        .toList();

    return recognizeStrokes(inkStrokes, sheetSize: sheetSize);
  }

  // -------------------------------------------------------------------------
  // Método legacy: reconocimiento por bitmap (fallback)
  // -------------------------------------------------------------------------

  /// Reconoce el texto de una página renderizada como imagen (fallback).
  ///
  /// Se usa cuando:
  /// 1. El modelo de tinta no está disponible.
  /// 2. Se necesita reconocimiento de texto impreso (no escrito a mano).
  /// 3. Hay imágenes en la página que contienen texto.
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
      options: const ExportOptions(maxDimension: kOcrResolution),
    );

    // 2) Guardar en archivo temporal.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inklus_ocr_temp.png');
    await file.writeAsBytes(pngBytes);

    // 3) Ejecutar ML Kit text recognition (bitmap).
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

  // -------------------------------------------------------------------------
  // Método unificado: inteligentemente elige la mejor estrategia
  // -------------------------------------------------------------------------

  /// Reconoce el texto de una página usando la mejor estrategia disponible.
  ///
  /// Intenta primero el reconocimiento de tinta vectorial (más preciso
  /// para escritura a mano). Si no hay trazos o falla, cae al bitmap.
  static Future<OcrResult> recognizeSmart(
    Page page, {
    required ui.Size sheetSize,
    required Map<String, ui.Image> imageCache,
    ImageService? imageService,
  }) async {
    // Filtrar trazos de escritura (no borradores ni herramientas especiales).
    final inkStrokes = page.strokes
        .where((s) =>
            s.tool != ToolType.eraser &&
            s.tool != ToolType.select &&
            s.tool != ToolType.lasso &&
            s.tool != ToolType.bucket &&
            s.tool != ToolType.text)
        .toList();

    // Si hay trazos vectoriales, intentar reconocimiento de tinta.
    if (inkStrokes.isNotEmpty) {
      try {
        final inkResult = await recognizeStrokes(
          inkStrokes,
          sheetSize: sheetSize,
        );
        // Si la tinta devolvió texto, usarlo.
        if (!inkResult.isEmpty) return inkResult;
      } catch (e) {
        debugPrint('OcrService.recognizeSmart (ink): $e');
        // Continuar con fallback.
      }
    }

    // Fallback: bitmap (captura también texto impreso e imágenes).
    return recognizeText(
      page,
      sheetSize: sheetSize,
      imageCache: imageCache,
      imageService: imageService,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers de conversión
  // -------------------------------------------------------------------------

  /// Convierte nuestros [Stroke] al formato `ink.Stroke` de ML Kit.
  ///
  /// Sintetiza timestamps crecientes (1ms por punto) ya que nuestro modelo
  /// no almacena tiempo. El orden de los puntos preserva la secuencia
  /// temporal del trazo original.
  static List<ink.Stroke> _convertToInkStrokes(List<Stroke> strokes) {
    final result = <ink.Stroke>[];
    var baseTime = 0; // timestamp base creciente entre trazos.

    for (final stroke in strokes) {
      final inkPoints = <ink.StrokePoint>[];
      for (var i = 0; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        // Timestamp sintético: 1ms por punto, con 50ms entre trazos.
        final t = baseTime + i;
        inkPoints.add(ink.StrokePoint(
          x: p.x,
          y: p.y,
          t: t,
        ));
      }
      if (inkPoints.isNotEmpty) {
        final inkStroke = ink.Stroke()..points = inkPoints;
        result.add(inkStroke);
      }
      // Siguiente trazo empieza con un gap de 50ms.
      baseTime += stroke.points.length + 50;
    }

    return result;
  }

  /// Estima los límites del texto basándose en los puntos de los trazos.
  ///
  /// Devuelve un [Rect] que contiene todos los puntos de los trazos,
  /// con un margen para el grosor del trazo.
  static ui.Rect _estimateTextBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return ui.Rect.zero;

    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    var maxSize = 0.0;

    for (final stroke in strokes) {
      for (final p in stroke.points) {
        if (p.x < left) left = p.x;
        if (p.y < top) top = p.y;
        if (p.x > right) right = p.x;
        if (p.y > bottom) bottom = p.y;
      }
      if (stroke.size > maxSize) maxSize = stroke.size;
    }

    // Incluir el grosor del trazo más ancho.
    final margin = maxSize;
    return ui.Rect.fromLTRB(
      left - margin,
      top - margin,
      right + margin,
      bottom + margin,
    );
  }

  /// Fallback: renderiza solo los trazos dados a un PNG temporal y ejecuta
  /// text recognition por bitmap.
  static Future<OcrResult> _recognizeFallback(
    List<Stroke> strokes, {
    required ui.Size sheetSize,
  }) async {
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
