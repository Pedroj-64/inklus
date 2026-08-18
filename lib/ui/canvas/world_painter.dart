import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;

import '../../logic/stroke_engine.dart';
import '../../models/image_item.dart';
import '../../models/page.dart';
import '../../models/stroke.dart';
import '../../models/template.dart';

/// Colores de papel.
const paperColor = Color(0xFFFEFDF9);
const deskColor = Color(0xFFEFEDE8);

/// Pinta el "mundo" (plantilla + imágenes + trazos) dentro de
/// [visibleWorldRect].
///
/// Se usa tanto en pantalla (con la transformación de vista aplicada por el
/// llamador) como en la exportación a imagen/PDF (con rect del contenido).
/// De esta forma lo que ves es exactamente lo que exportas.
///
/// [omitTemplate] = true: no dibuja la plantilla (fondo transparente).
/// [omitImages] = true: no dibuja imágenes (solo trazos).
void paintWorld(
  Canvas canvas, {
  required Rect visibleWorldRect,
  required Page page,
  required Size sheetSize,
  required Map<String, ui.Image> imageCache,
  bool drawSelection = false,
  String? selectedImageId,
  double handleSizeWorld = 24,
  bool omitTemplate = false,
  bool omitImages = false,
}) {
  final template = page.template;

  // ---- Fondo general (omitido si omitTemplate) ----
  if (!omitTemplate) {
    canvas.drawRect(visibleWorldRect, Paint()..color = template.isFinite ? deskColor : paperColor);
  }

  // ---- Plantilla (omitida si omitTemplate) ----
  if (!omitTemplate) {
    switch (template.type) {
      case TemplateType.blank:
        break;
      case TemplateType.sheet:
        _drawSheet(canvas, sheetSize, page);
        break;
      case TemplateType.ruled:
        _drawRuled(canvas, visibleWorldRect, template);
        break;
      case TemplateType.grid:
        _drawGrid(canvas, visibleWorldRect, template);
        break;
      case TemplateType.custom:
        final img = template.imagePath == null ? null : imageCache[template.imagePath];
        if (img == null) {
          if (template.infiniteFill) {
            _drawGrid(canvas, visibleWorldRect, template);
          } else {
            _drawSheet(canvas, sheetSize, page);
          }
        } else if (template.infiniteFill) {
          _drawTiledImage(canvas, visibleWorldRect, img);
        } else {
          _drawSheet(canvas, sheetSize, page, image: img);
        }
        break;
    }
  }

  // ---- Contenido: imágenes y trazos (recortado a la hoja si es finita) ----
  canvas.save();
  if (template.isFinite && !omitTemplate) {
    final sheetRect = Rect.fromCenter(
      center: Offset.zero,
      width: sheetSize.width,
      height: sheetSize.height,
    );
    canvas.clipRect(sheetRect);
  }

  // Imágenes (omitidas si omitImages)
  if (!omitImages) {
    for (final item in page.images) {
      final img = imageCache[item.localPath];
      if (img == null) continue;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        item.rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (drawSelection && item.id == selectedImageId) {
        _drawSelection(canvas, item, handleSizeWorld);
      }
    }
  }

  for (final stroke in page.strokes) {
    _paintStroke(canvas, stroke);
  }
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Plantillas
// ---------------------------------------------------------------------------

void _drawSheet(Canvas canvas, Size sheetSize, Page page, {ui.Image? image}) {
  final sheetRect = Rect.fromCenter(
    center: Offset.zero,
    width: sheetSize.width,
    height: sheetSize.height,
  );
  final path = Path()..addRRect(RRect.fromRectAndRadius(sheetRect, const Radius.circular(4)));
  canvas.drawShadow(path, Colors.black26, 10, false);
  canvas.drawPath(path, Paint()..color = paperColor);
  if (image != null) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      sheetRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(sheetRect, const Radius.circular(4)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.15),
  );
}

void _drawRuled(Canvas canvas, Rect visible, PageTemplate template) {
  final paint = Paint()
    ..color = template.lineColor
    ..strokeWidth = 1.0;
  final spacing = template.spacing;
  // Líneas de texto.
  final startY = (visible.top / spacing).floor() * spacing;
  for (var y = startY; y <= visible.bottom; y += spacing) {
    canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
  }
  // Margen vertical tipo cuaderno.
  final margin = spacing * 1.6;
  canvas.drawLine(
    Offset(margin, visible.top),
    Offset(margin, visible.bottom),
    Paint()
      ..color = const Color(0xFFE57373)
      ..strokeWidth = 1.2,
  );
}

void _drawGrid(Canvas canvas, Rect visible, PageTemplate template) {
  final paint = Paint()
    ..color = template.lineColor
    ..strokeWidth = 1.0;
  final spacing = template.spacing;
  final startX = (visible.left / spacing).floor() * spacing;
  final startY = (visible.top / spacing).floor() * spacing;
  for (var x = startX; x <= visible.right; x += spacing) {
    canvas.drawLine(Offset(x, visible.top), Offset(x, visible.bottom), paint);
  }
  for (var y = startY; y <= visible.bottom; y += spacing) {
    canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
  }
}

void _drawTiledImage(Canvas canvas, Rect visible, ui.Image img) {
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  final startX = (visible.left / w).floor();
  final endX = (visible.right / w).ceil();
  final startY = (visible.top / h).floor();
  final endY = (visible.bottom / h).ceil();
  final paint = Paint()..filterQuality = FilterQuality.low;
  final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
  for (var ix = startX; ix <= endX; ix++) {
    for (var iy = startY; iy <= endY; iy++) {
      canvas.drawImageRect(
        img,
        src,
        Rect.fromLTWH(ix * w, iy * h, w, h),
        paint,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Contenido
// ---------------------------------------------------------------------------

void _paintStroke(Canvas canvas, Stroke stroke) {
  final outline = StrokeEngine.outlineFor(stroke);
  if (outline.length < 3) return;
  final path = Path()..addPolygon(outline, true);
  canvas.drawPath(
    path,
    Paint()
      ..color = StrokeEngine.paintColor(stroke)
      ..style = PaintingStyle.fill,
  );
}

void _drawSelection(Canvas canvas, ImageItem item, double handleSize) {
  final rect = item.rect;
  final border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF3B82F6);
  canvas.drawRect(rect, border);
  // Asa de redimensionado en la esquina inferior derecha.
  final handleCenter = rect.bottomRight;
  canvas.drawCircle(
    handleCenter,
    handleSize / 2,
    Paint()..color = const Color(0xFF3B82F6),
  );
  canvas.drawCircle(
    handleCenter,
    handleSize / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white,
  );
}

/// Convierte un stroke a [Path] rellenable (usado también por la capa activa).
Path strokeToPath(List<StrokePoint> points, ToolType tool, double size) {
  final outline = StrokeEngine.outlineForPoints(points, tool, size);
  return Path()..addPolygon(outline, true);
}

/// Rectángulo de contenido de una página (para exportar lienzos infinitos).
Rect contentBounds(Page page, {double padding = 100}) {
  var bounds = Rect.zero;
  var hasContent = false;
  for (final s in page.strokes) {
    for (final p in s.points) {
      final r = Rect.fromCenter(center: p.offset, width: s.size * 2, height: s.size * 2);
      bounds = hasContent ? bounds.expandToInclude(r) : r;
      hasContent = true;
    }
  }
  for (final i in page.images) {
    final r = i.rect;
    bounds = hasContent ? bounds.expandToInclude(r) : r;
    hasContent = true;
  }
  if (!hasContent) {
    return const Rect.fromLTWH(-400, -300, 800, 600);
  }
  return bounds.inflate(padding);
}
