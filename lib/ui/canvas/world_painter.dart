// SPDX-License-Identifier: GPL-3.0-or-later
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
import '../../models/text_layout.dart';

export '../../models/text_layout.dart' show textItemAlign, textItemStyle;

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
/// [paintDesk] = false: no pinta el fondo del escritorio (cuando se pintan
/// varias hojas apiladas, solo la primera lo pinta; si no, taparía a las
/// vecinas ya dibujadas).
void paintWorld(
  Canvas canvas, {
  required Rect visibleWorldRect,
  required Page page,
  required Size sheetSize,
  required Map<String, ui.Image> imageCache,
  bool omitTemplate = false,
  double viewScale = 1,
  bool omitImages = false,
  bool isDark = false,
  bool paintDesk = true,
}) {
  final template = page.template;

  // ---- Fondo general (omitido si omitTemplate) ----
  // El papel SIEMPRE se mantiene con su color propio (blanco / kPaperColorLight).
  // Solo el "escritorio" alrededor de la hoja se oscurece en modo oscuro.
  if (!omitTemplate && paintDesk) {
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
        _drawRuled(
          canvas,
          visibleWorldRect,
          template,
          isDark: isDark,
          // En hoja finita el margen va respecto al borde izquierdo de la hoja
          // (centrada en el origen); en lienzo infinito, respecto al origen.
          marginOriginX: template.isFinite ? sheetRect.left : 0,
          viewScale: viewScale,
        );
        break;
      case TemplateType.grid:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawGrid(canvas, visibleWorldRect, template, isDark: isDark, viewScale: viewScale);
        break;
      case TemplateType.custom:
        // Ya dibujado antes del clip si es finito.
        if (template.infiniteFill) {
          final img = template.imagePath == null ? null : imageCache[template.imagePath];
          if (img == null) {
            _drawGrid(canvas, visibleWorldRect, template, viewScale: viewScale);
          } else {
            _drawTiledImage(canvas, visibleWorldRect, img, viewScale: viewScale);
          }
        }
        // Para custom finito con imagen, el _drawSheet ya rellenó arriba.
        break;
      case TemplateType.music:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawMusicStaff(canvas, visibleWorldRect, template, isDark: isDark, viewScale: viewScale);
        break;
      case TemplateType.planner:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawPlanner(canvas, visibleWorldRect, template, isDark: isDark, viewScale: viewScale);
        break;
      case TemplateType.habit:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawHabitTracker(canvas, visibleWorldRect, template, isDark: isDark, viewScale: viewScale);
        break;
      case TemplateType.dots:
        if (template.isFinite) {
          canvas.drawRect(sheetRect, Paint()..color = kPaperColorLight);
        }
        _drawDotGrid(canvas, visibleWorldRect, template, isDark: isDark, viewScale: viewScale);
        break;
    }
  }

  // ---- Contenido: imágenes, trazos y textos ----
  // Para plantillas finitas, ya estamos dentro del clipRect de la hoja.
  // Solo se pinta lo que intersecta [visibleWorldRect] (culling): con miles
  // de trazos, el coste por frame depende de lo visible, no del total.
  final layers = _LayerPainter(canvas, page, visibleWorldRect);

  if (!omitImages) {
    for (final item in page.images) {
      if (!visibleWorldRect.overlaps(_imageBounds(item))) continue;
      final img = imageCache[item.localPath];
      if (img == null) continue;
      if (!layers.enter(item.layerIndex)) continue;
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.rotation);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: item.width, height: item.height),
        _imagePaint,
      );
      canvas.restore();
    }
  }

  for (final stroke in page.strokes) {
    if (!visibleWorldRect.overlaps(stroke.paintBounds)) continue;
    if (!layers.enter(stroke.layerIndex)) continue;
    paintStroke(canvas, stroke);
  }

  for (final item in page.textItems) {
    if (!layers.enter(item.layerIndex)) continue;
    _paintTextItem(canvas, item);
  }
  layers.close();

  canvas.restore();
}

final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;

/// Rect que contiene la imagen aunque esté rotada (círculo circunscrito).
Rect _imageBounds(ImageItem item) {
  final r = sqrt(item.width * item.width + item.height * item.height) / 2;
  return Rect.fromCircle(center: Offset(item.x, item.y), radius: r);
}

/// Aplica visibilidad y opacidad de capa al pintar elementos en orden.
///
/// Los elementos consecutivos de una misma capa translúcida comparten un
/// único `saveLayer` (antes había uno por elemento, con `Rect.zero` como
/// límites, lo que podía recortar el contenido). Así además los trazos que
/// se solapan dentro de la capa no se oscurecen entre sí.
class _LayerPainter {
  final Canvas canvas;
  final Page page;
  final Rect bounds;
  int? _open;

  _LayerPainter(this.canvas, this.page, this.bounds);

  /// Prepara el canvas para pintar un elemento de [layerIndex]. Devuelve
  /// false si la capa está oculta (el elemento no debe pintarse).
  bool enter(int layerIndex) {
    final layer = layerIndex < page.layers.length ? page.layers[layerIndex] : null;
    if (layer != null && !layer.visible) return false;
    final opacity = layer?.opacity ?? 1.0;
    if (_open != null && _open != layerIndex) close();
    if (opacity < 1.0 && _open == null) {
      canvas.saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
      _open = layerIndex;
    }
    return true;
  }

  void close() {
    if (_open != null) {
      canvas.restore();
      _open = null;
    }
  }
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

/// Nivel de detalle de los patrones de plantilla.
///
/// Devuelve el espaciado efectivo: si en pantalla las líneas/puntos quedarían
/// a menos de [minPx] píxeles, se duplica el espaciado (se dibuja una de cada
/// 2, 4, 8…). Así al alejar el zoom en un lienzo infinito no se generan
/// cientos de miles de primitivas por frame y el patrón sigue siendo legible.
double _lodSpacing(double spacing, double viewScale, double minPx) {
  if (spacing <= 0) return 1e9; // defensivo: nunca dividir por 0
  var s = spacing;
  while (s * viewScale < minPx) {
    s *= 2;
  }
  return s;
}

/// Grosor de línea en unidades de mundo para que mida [px] en pantalla
/// (líneas nítidas a cualquier zoom: ni desaparecen ni engordan).
double _hairline(double viewScale, [double px = 1]) =>
    px / (viewScale <= 0 ? 1 : viewScale);

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

void _drawRuled(
  Canvas canvas,
  Rect visible,
  PageTemplate template, {
  bool isDark = false,
  double marginOriginX = 0,
  double viewScale = 1,
}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = _hairline(viewScale);
  final spacing = _lodSpacing(template.spacing, viewScale, 5);
  // Líneas de texto.
  final startY = (visible.top / spacing).floor() * spacing;
  for (var y = startY; y <= visible.bottom; y += spacing) {
    canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
  }
  // Margen vertical tipo cuaderno.
  final margin = marginOriginX + template.spacing * 1.6;
  canvas.drawLine(
    Offset(margin, visible.top),
    Offset(margin, visible.bottom),
    Paint()
      ..color = const Color(0xFFE57373)
      ..strokeWidth = _hairline(viewScale, 1.3),
  );
}

void _drawGrid(Canvas canvas, Rect visible, PageTemplate template,
    {bool isDark = false, double viewScale = 1}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = _hairline(viewScale);
  final spacing = _lodSpacing(template.spacing, viewScale, 6);
  final startX = (visible.left / spacing).floor() * spacing;
  final startY = (visible.top / spacing).floor() * spacing;
  for (var x = startX; x <= visible.right; x += spacing) {
    canvas.drawLine(Offset(x, visible.top), Offset(x, visible.bottom), paint);
  }
  for (var y = startY; y <= visible.bottom; y += spacing) {
    canvas.drawLine(Offset(visible.left, y), Offset(visible.right, y), paint);
  }
}

void _drawTiledImage(Canvas canvas, Rect visible, ui.Image img, {double viewScale = 1}) {
  if (img.width == 0 || img.height == 0) return;
  final w = img.width.toDouble();
  final h = img.height.toDouble();
  // Demasiadas teselas diminutas al alejar el zoom: no vale la pena dibujarlas.
  if ((visible.width / w) * (visible.height / h) > 400) return;
  final startX = (visible.left / w).floor();
  final endX = (visible.right / w).ceil() - 1;
  final startY = (visible.top / h).floor();
  final endY = (visible.bottom / h).ceil() - 1;
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

/// Partículas del aerosol cacheadas como Picture por instancia de trazo
/// (antes se generaban 12-20 círculos por punto en cada repintado).
final Expando<ui.Picture> _sprayCache = Expando('spray');

/// Dibuja las partículas del aerosol. Semilla determinista por id: el
/// resultado es idéntico mientras se dibuja y una vez confirmado.
void _drawSprayParticles(Canvas canvas, Stroke stroke) {
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
      final dotRadius = 0.8 + random.nextDouble() * 2.5;
      paint.color = color.withValues(alpha: 0.15 + random.nextDouble() * 0.35);
      canvas.drawCircle(
        Offset(center.dx + cos(angle) * dist, center.dy + sin(angle) * dist),
        dotRadius,
        paint,
      );
    }
  }
}

final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

/// Pinta un trazo confirmado (usa Paths/Pictures cacheados).
void paintStroke(Canvas canvas, Stroke stroke) {
  // Aerosol: partículas dispersas en lugar de un trazo sólido.
  if (stroke.tool == ToolType.spray) {
    if (stroke.points.length < 2) return;
    var picture = _sprayCache[stroke];
    if (picture == null) {
      final recorder = ui.PictureRecorder();
      _drawSprayParticles(Canvas(recorder), stroke);
      picture = recorder.endRecording();
      _sprayCache[stroke] = picture;
    }
    canvas.drawPicture(picture);
    return;
  }
  if (StrokeEngine.outlineFor(stroke).length < 3) return;
  final path = StrokeEngine.pathFor(stroke);
  // Si tiene fillColorValue, dibuja el relleno primero.
  if (stroke.fillColorValue != null) {
    _fillPaint.color = Color(stroke.fillColorValue!);
    canvas.drawPath(path, _fillPaint);
  }
  _fillPaint.color = StrokeEngine.paintColor(stroke);
  canvas.drawPath(path, _fillPaint);

  // Si es una flecha, dibuja la cabeza triangular al final.
  if (stroke.shapeType == 'arrow' && stroke.points.length >= 2) {
    _drawArrowHead(canvas, stroke);
  }
}

/// Pinta el trazo en progreso (puntos aún cambiando: sin caché). Usa el
/// mismo color/alpha y los mismos ajustes que tendrá al confirmarse.
void paintActiveStroke(Canvas canvas, Stroke stroke) {
  if (stroke.points.length < 2) return;
  if (stroke.tool == ToolType.spray) {
    _drawSprayParticles(canvas, stroke);
    return;
  }
  final outline = StrokeEngine.outlineForPoints(
    stroke.points,
    stroke.tool,
    stroke.size,
    thinning: stroke.thinning,
    smoothing: stroke.smoothing,
    streamline: stroke.streamline,
  );
  if (outline.length < 3) return;
  _fillPaint.color = StrokeEngine.paintColor(stroke);
  canvas.drawPath(Path()..addPolygon(outline, true), _fillPaint);
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

  _fillPaint.color = StrokeEngine.paintColor(stroke);
  canvas.drawPath(arrowPath, _fillPaint);
}

void _paintTextItem(Canvas canvas, TextItem item) {
  final textPainter = TextPainter(
    text: buildTextItemSpan(item, item.text, item.runs, textItemStyle(item)),
    textAlign: textItemAlign(item),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(minWidth: item.width, maxWidth: item.width);
  textPainter.paint(
    canvas,
    Offset(item.x - item.width / 2, item.y - item.height / 2),
  );
  textPainter.dispose();
}

/// Pentagrama musical (5 líneas por grupo, infinito).
void _drawMusicStaff(Canvas canvas, Rect visible, PageTemplate template,
    {bool isDark = false, double viewScale = 1}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = _hairline(viewScale);
  // Con el zoom muy alejado las 5 líneas se funden: no dibujar.
  if (template.spacing * 0.4 * viewScale < 2) return;
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
void _drawPlanner(Canvas canvas, Rect visible, PageTemplate template,
    {bool isDark = false, double viewScale = 1}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..strokeWidth = _hairline(viewScale);
  final spacing = _lodSpacing(template.spacing, viewScale, 5);
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
void _drawHabitTracker(Canvas canvas, Rect visible, PageTemplate template,
    {bool isDark = false, double viewScale = 1}) {
  // Casillas con contorno (antes salían como cuadrados rellenos).
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark).withValues(alpha: 0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = _hairline(viewScale);
  final spacing = _lodSpacing(template.spacing, viewScale, 10);
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
void _drawDotGrid(Canvas canvas, Rect visible, PageTemplate template,
    {bool isDark = false, double viewScale = 1}) {
  final paint = Paint()
    ..color = _adaptiveLineColor(template, isDark: isDark)
    ..style = PaintingStyle.fill;
  final spacing = _lodSpacing(template.spacing, viewScale, 10);
  final startX = (visible.left / spacing).floor() * spacing;
  final startY = (visible.top / spacing).floor() * spacing;
  // Punto de al menos ~1.2 px en pantalla para que no desaparezca.
  final dotRadius = max(template.spacing * 0.06, _hairline(viewScale, 1.2));
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
    if (s.points.isEmpty) continue;
    final r = s.paintBounds;
    bounds = hasContent ? bounds.expandToInclude(r) : r;
    hasContent = true;
  }
  for (final i in page.images) {
    final r = _imageBounds(i);
    bounds = hasContent ? bounds.expandToInclude(r) : r;
    hasContent = true;
  }
  for (final t in page.textItems) {
    final r = Rect.fromCenter(center: Offset(t.x, t.y), width: t.width, height: t.height);
    bounds = hasContent ? bounds.expandToInclude(r) : r;
    hasContent = true;
  }
  if (!hasContent) {
    return const Rect.fromLTWH(-400, -300, 800, 600);
  }
  return bounds.inflate(padding);
}
