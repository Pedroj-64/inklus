import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;

import '../../constants.dart';
import '../../logic/stroke_engine.dart';
import '../../models/image_item.dart';
import '../../models/page.dart';
import '../../models/stroke.dart';
import '../../models/template.dart';
import '../../models/text_item.dart';

// Re-exportar constantes para compatibilidad con archivos que importan world_painter.
const paperColor = kPaperColorLight;
const deskColor = kDeskColorLight;
const paperColorDark = kPaperColorDark;
const deskColorDark = kDeskColorDark;

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
  bool isDark = false,
}) {
  final template = page.template;

  // ---- Fondo general (omitido si omitTemplate) ----
  // El papel SIEMPRE se mantiene con su color propio (blanco / kPaperColorLight).
  // Solo el "escritorio" alrededor de la hoja se oscurece en modo oscuro.
  if (!omitTemplate) {
    final bg = isDark
        ? (template.isFinite ? kDeskColorDark : kPaperColorLight)
        : (template.isFinite ? kDeskColorLight : kPaperColorLight);
    canvas.drawRect(visibleWorldRect, Paint()..color = bg);
  }

  // ---- Plantilla + contenido: recortado a la hoja si es finita ----
  // Para plantillas finitas, TODO (patrón de la plantilla + imágenes +
  // trazos) se recorta al rect de la hoja. Así el usuario ve claramente
  // dónde puede escribir y dónde no.
  //
  // Excepción: _drawSheet (la hoja blanca con sombra) se dibuja ANTES
  // del clip para que la sombra sea visible sobre el escritorio.
  if (!omitTemplate && template.type == TemplateType.sheet) {
    _drawSheet(canvas, sheetSize, page, isDark: isDark);
  }
  // Para custom finito sin imagen, también dibujar la hoja antes del clip.
  if (!omitTemplate && template.type == TemplateType.custom && !template.infiniteFill) {
    final img = template.imagePath == null ? null : imageCache[template.imagePath];
    _drawSheet(canvas, sheetSize, page, image: img, isDark: isDark);
  }

  canvas.save();
  final sheetRect = Rect.fromCenter(
    center: Offset.zero,
    width: sheetSize.width,
    height: sheetSize.height,
  );
  if (template.isFinite && !omitTemplate) {
    canvas.clipRect(sheetRect);
  }

  if (!omitTemplate) {
    switch (template.type) {
      case TemplateType.blank:
        // Para blank finito, dibujar el papel blanco dentro del clip.
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        break;
      case TemplateType.sheet:
        // Ya dibujado antes del clip (sombra visible).
        // Aquí solo rellenar el rect blanco dentro del clip.
        canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        break;
      case TemplateType.ruled:
        // Para ruled finito, primero dibujar fondo blanco.
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawRuled(canvas, visibleWorldRect, template, isDark: isDark);
        break;
      case TemplateType.grid:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawGrid(canvas, visibleWorldRect, template, isDark: isDark);
        break;
      case TemplateType.custom:
        // Ya dibujado antes del clip si es finito.
        if (template.infiniteFill) {
          final img = template.imagePath == null ? null : imageCache[template.imagePath];
          if (img == null) {
            _drawGrid(canvas, visibleWorldRect, template);
          } else {
            _drawTiledImage(canvas, visibleWorldRect, img);
          }
        }
        // Para custom finito con imagen, el _drawSheet ya rellenó arriba.
        break;
      case TemplateType.music:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawMusicStaff(canvas, visibleWorldRect, template, isDark: isDark);
        break;
      case TemplateType.planner:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawPlanner(canvas, visibleWorldRect, template, isDark: isDark);
        break;
      case TemplateType.habit:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawHabitTracker(canvas, visibleWorldRect, template, isDark: isDark);
        break;
      case TemplateType.dots:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawDotGrid(canvas, visibleWorldRect, template, isDark: isDark);
        break;
    }
  }

  // ---- Contenido: imágenes y trazos ----
  // Para plantillas finitas, ya estamos dentro del clipRect de la hoja.

  // Imágenes (omitidas si omitImages, respeta visibilidad y opacidad de capa)
  if (!omitImages) {
    for (final item in page.images) {
      // Respeta visibilidad de la capa.
      if (item.layerIndex < page.layers.length && !page.layers[item.layerIndex].visible) continue;
      final img = imageCache[item.localPath];
      if (img == null) continue;
      canvas.save();
      // Aplica opacidad de la capa via saveLayer.
      if (item.layerIndex < page.layers.length &&
          page.layers[item.layerIndex].opacity < 1.0) {
        canvas.saveLayer(
          Rect.zero,
          Paint()..color = Colors.white.withValues(alpha: page.layers[item.layerIndex].opacity),
        );
      }
      canvas.translate(item.x, item.y);
      canvas.rotate(item.rotation);
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: item.width,
        height: item.height,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (drawSelection && item.id == selectedImageId) {
        _drawSelection(canvas, item, handleSizeWorld);
      }
      canvas.restore();
    }
  }

  // Trazos (respeta visibilidad y opacidad de la capa)
  for (final stroke in page.strokes) {
    if (stroke.layerIndex < page.layers.length && !page.layers[stroke.layerIndex].visible) continue;      canvas.save();
    if (stroke.layerIndex < page.layers.length &&
        page.layers[stroke.layerIndex].opacity < 1.0) {
      canvas.saveLayer(
        Rect.zero,
        Paint()..color = Colors.white.withValues(alpha: page.layers[stroke.layerIndex].opacity),
      );
    }
    _paintStroke(canvas, stroke);
    if (stroke.layerIndex < page.layers.length &&
        page.layers[stroke.layerIndex].opacity < 1.0) {
      canvas.restore();
    }
    canvas.restore();
  }

  // Cajas de texto (respeta visibilidad y opacidad de la capa)
  for (final item in page.textItems) {
    if (item.layerIndex < page.layers.length && !page.layers[item.layerIndex].visible) continue;
    canvas.save();
    if (item.layerIndex < page.layers.length &&
        page.layers[item.layerIndex].opacity < 1.0) {
      canvas.saveLayer(
        Rect.zero,
        Paint()..color = Colors.white.withValues(alpha: page.layers[item.layerIndex].opacity),
      );
    }
    _paintTextItem(canvas, item);
    if (item.layerIndex < page.layers.length &&
        page.layers[item.layerIndex].opacity < 1.0) {
      canvas.restore();
    }
    canvas.restore();
  }

  canvas.restore();
}

// ---------------------------------------------------------------------------
// Plantillas
// ---------------------------------------------------------------------------

void _drawSheet(Canvas canvas, Size sheetSize, Page page, {ui.Image? image, bool isDark = false}) {
  final sheetRect = Rect.fromCenter(
    center: Offset.zero,
    width: sheetSize.width,
    height: sheetSize.height,
  );
  final rrect = RRect.fromRectAndRadius(sheetRect, const Radius.circular(6));
  final path = Path()..addRRect(rrect);

  // Sombra más pronunciada para que el papel se distinga claramente del
  // escritorio, tanto en tema claro como oscuro.
  canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.5 : 0.25), 18, false);
  // Segunda sombra (más suave) para dar profundidad.
  canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.3 : 0.12), 8, false);

  // El papel siempre es blanco independientemente del tema.
  canvas.drawPath(path, Paint()..color = kPaperColorLight);
  if (image != null) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      sheetRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  // Borde del papel: más visible para delimitar claramente la zona de
  // escritura. En modo oscuro se usa un borde blanco semitransparente.
  canvas.drawRRect(
    rrect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 1.5 : 1.2
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2),
  );
}

/// Ajusta el color de línea para que sea visible sobre el papel.
///
/// Dado que el papel siempre es blanco (incluso en modo oscuro), las líneas
/// solo necesitan ajustarse si son demasiado claras (difíciles de ver sobre
/// fondo blanco).
Color _adaptiveLineColor(PageTemplate template, {bool isDark = false}) {
  // El papel siempre es blanco → las líneas siempre deben ser oscuras
  // y visibles. Si el color original es muy claro, oscurecerlo un poco.
  final hsl = HSLColor.fromColor(template.lineColor);
  if (hsl.lightness > 0.75) {
    return hsl.withLightness(0.60).toColor();
  }
  return template.lineColor;
}

void _drawRuled(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
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

void _drawGrid(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
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

void _paintSprayStroke(Canvas canvas, Stroke stroke) {
  if (stroke.points.length < 2) return;
  final color = StrokeEngine.paintColor(stroke);
  final random = Random(stroke.id.hashCode);
  final paint = Paint()..style = PaintingStyle.fill;
  final radius = stroke.size;
  for (final point in stroke.points) {
    final center = point.offset;
    final count = 12 + random.nextInt(8);
    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = random.nextDouble() * radius;
      final px = center.dx + cos(angle) * dist;
      final py = center.dy + sin(angle) * dist;
      final dotRadius = 0.8 + random.nextDouble() * 2.5;
      paint.color = color.withValues(alpha: 0.15 + random.nextDouble() * 0.35);
      canvas.drawCircle(Offset(px, py), dotRadius, paint);
    }
  }
}

void _paintStroke(Canvas canvas, Stroke stroke) {
  // Aerosol: dibuja partículas dispersas en lugar de un trazo sólido.
  if (stroke.tool == ToolType.spray) {
    _paintSprayStroke(canvas, stroke);
    return;
  }
  // Si tiene fillColorValue, dibuja el relleno primero.
  if (stroke.fillColorValue != null) {
    final fillOutline = StrokeEngine.outlineFor(stroke);
    if (fillOutline.length >= 3) {
      final fillPath = Path()..addPolygon(fillOutline, true);
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = Color(stroke.fillColorValue!)
          ..style = PaintingStyle.fill,
      );
    }
  }
  // Dibuja el borde del trazo.
  final outline = StrokeEngine.outlineFor(stroke);
  if (outline.length < 3) return;
  final path = Path()..addPolygon(outline, true);
  canvas.drawPath(
    path,
    Paint()
      ..color = StrokeEngine.paintColor(stroke)
      ..style = PaintingStyle.fill,
  );

  // Si es una flecha, dibuja la cabeza triangular al final.
  if (stroke.shapeType == 'arrow' && stroke.points.length >= 2) {
    _drawArrowHead(canvas, stroke);
  }
}

/// Dibuja la cabeza de una flecha al final del trazo.
void _drawArrowHead(Canvas canvas, Stroke stroke) {
  final first = stroke.points.first.offset;
  final last = stroke.points.last.offset;
  final dir = last - first;
  if (dir.distance < 10) return;

  final headLength = stroke.size * 3.5; // longitud de la punta
  final headWidth = stroke.size * 2.5;
  final angle = dir.direction;

  // Base de la punta (punto detrás de la punta).
  final base = last - Offset(cos(angle), sin(angle)) * headLength;
  final perp = Offset(-sin(angle), cos(angle));
  final left = base + perp * (headWidth / 2);
  final right = base - perp * (headWidth / 2);

  final arrowPath = Path()
    ..moveTo(last.dx, last.dy)
    ..lineTo(left.dx, left.dy)
    ..lineTo(right.dx, right.dy)
    ..close();

  canvas.drawPath(
    arrowPath,
    Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill,
  );
}

/// Paints reutilizados para selección de imágenes (evita alloc por frame).
final Paint _selectionBorderPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.5
  ..color = kAccentColor;
final Paint _selectionHandleFillPaint = Paint()..color = kAccentColor;
final Paint _selectionHandleStrokePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..color = Colors.white;
final Paint _selectionLinePaint = Paint()
  ..color = kAccentColor
  ..strokeWidth = 2;

void _drawSelection(Canvas canvas, ImageItem item, double handleSize) {
  final rect = item.rect;
  final r = handleSize / 2;
  // Dibuja el borde de selección rotado si es necesario.
  if (item.rotation != 0) {
    canvas.save();
    canvas.translate(item.x, item.y);
    canvas.rotate(item.rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
      _selectionBorderPaint,
    );
    // Asa de redimensionado (esquina inferior derecha en espacio local).
    final handleCenter = Offset(rect.width / 2, rect.height / 2);
    canvas.drawCircle(handleCenter, r, _selectionHandleFillPaint);
    canvas.drawCircle(handleCenter, r, _selectionHandleStrokePaint);
    // Asa de rotación (centro superior).
    final rotHandle = Offset(0, -handleSize * 1.5);
    canvas.drawLine(Offset(0, -rect.height / 2), rotHandle, _selectionLinePaint);
    canvas.drawCircle(rotHandle, r, _selectionHandleFillPaint);
    canvas.drawCircle(rotHandle, r, _selectionHandleStrokePaint);
    canvas.restore();
  } else {
    canvas.drawRect(rect, _selectionBorderPaint);
    final handleCenter = rect.bottomRight;
    canvas.drawCircle(handleCenter, r, _selectionHandleFillPaint);
    canvas.drawCircle(handleCenter, r, _selectionHandleStrokePaint);
    final rotHandle = Offset(rect.center.dx, rect.top - handleSize * 1.5);
    canvas.drawLine(rect.topCenter, rotHandle, _selectionLinePaint);
    canvas.drawCircle(rotHandle, r, _selectionHandleFillPaint);
    canvas.drawCircle(rotHandle, r, _selectionHandleStrokePaint);
  }
}

void _paintTextItem(Canvas canvas, TextItem item) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: item.text,
      style: TextStyle(
        color: item.color,
        fontSize: item.fontSize,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: null,
  );
  textPainter.layout(maxWidth: item.width);
  textPainter.paint(
    canvas,
    Offset(item.x - item.width / 2, item.y - item.height / 2),
  );
}

/// Convierte un stroke a [Path] rellenable (usado también por la capa activa).
Path strokeToPath(List<StrokePoint> points, ToolType tool, double size) {
  final outline = StrokeEngine.outlineForPoints(points, tool, size);
  return Path()..addPolygon(outline, true);
}

/// Pentagrama musical (5 líneas por grupo, infinito).
void _drawMusicStaff(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = 1.0;
  final groupSpacing = template.spacing * 3; // distancia entre grupos
  final lineSpacing = template.spacing * 0.4; // distancia entre líneas
  final startY = (visible.top / groupSpacing).floor() * groupSpacing;
  for (var gy = startY; gy <= visible.bottom; gy += groupSpacing) {
    for (var li = 0; li < 5; li++) {
      final y = gy + li * lineSpacing;
      canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
    }
  }
}

/// Agenda semanal (columnas por día, infinita).
void _drawPlanner(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = 1.0;
  final spacing = template.spacing;
  // Líneas horizontales.
  final startY = (visible.top / spacing).floor() * spacing;
  for (var y = startY; y <= visible.bottom; y += spacing) {
    canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
  }
  // Líneas verticales (separar días).
  final dayWidth = spacing * 3;
  final startX = (visible.left / dayWidth).floor() * dayWidth;
  for (var x = startX; x <= visible.right; x += dayWidth) {
    canvas.drawLine(Offset(x, visible.top), Offset(x, visible.bottom), paint);
  }
}

/// Tracker de hábitos (cuadrícula con checkboxes, infinita).
void _drawHabitTracker(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark).withValues(alpha: 0.5)
    ..strokeWidth = 1.0;
  final spacing = template.spacing;
  final startX = (visible.left / spacing).floor() * spacing;
  final startY = (visible.top / spacing).floor() * spacing;
  // Cuadrícula de puntos/casillas.
  for (var x = startX; x <= visible.right; x += spacing) {
    for (var y = startY; y <= visible.bottom; y += spacing) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: spacing * 0.6, height: spacing * 0.6),
        paint,
      );
    }
  }
}

/// Cuadrícula de puntos (dot grid, infinita).
void _drawDotGrid(Canvas canvas, Rect visible, PageTemplate template, {bool isDark = false}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..style = PaintingStyle.fill;
  final spacing = template.spacing;
  final startX = (visible.left / spacing).floor() * spacing;
  final startY = (visible.top / spacing).floor() * spacing;
  final dotRadius = spacing * 0.06;
  for (var x = startX; x <= visible.right; x += spacing) {
    for (var y = startY; y <= visible.bottom; y += spacing) {
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }
}

/// Rectángulo de contenido de una página (para exportar lienzos infinitos).
Rect contentBounds(Page page, {double padding = kExportContentPadding}) {
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
