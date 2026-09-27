// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../logic/ruler.dart';
import '../canvas/world_painter.dart';

// ============================================================================
// Overlays del canvas: Regla virtual, Lupa, Marching Ants
//
// Extraídos de drawing_canvas.dart para reducir su tamaño y mejorar la
// separación de responsabilidades. Estas funciones dibujan overlays visuales
// sobre el canvas del editor (no son widgets de Flutter, son CustomPainter).
// ============================================================================

/// Dibuja la regla virtual en el canvas (en espacio de pantalla).
///
/// La regla tiene tamaño constante en pantalla (ver [RulerGeometry]) y su
/// escala está en centímetros **de la hoja** (coincide con la página A4 a
/// cualquier zoom).
void drawRuler(Canvas canvas, CanvasController controller, Size size) {
  switch (controller.rulerType) {
    case RulerType.straight:
      _drawStraightRuler(canvas, controller);
      break;
    case RulerType.protractor:
      _drawProtractor(canvas, controller);
      break;
  }
}

// Estilo "acrílico": cuerpo blanco translúcido, marcas oscuras. Se lee bien
// sobre papel blanco y sobre el escritorio oscuro.
const Color _rulerBody = Color(0xD9FFFFFF);
const Color _rulerBorder = Color(0x33000000);
const Color _rulerTick = Color(0xCC1F2937);
const Color _rulerTickMinor = Color(0x801F2937);

final Paint _rulerBodyPaint = Paint()..color = _rulerBody;
final Paint _rulerBorderPaint = Paint()
  ..color = _rulerBorder
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;
final Paint _tickPaint = Paint()..strokeWidth = 1;
final Paint _snapEdgePaint = Paint()
  ..color = kAccentColor
  ..strokeWidth = 3
  ..strokeCap = StrokeCap.round;

void _drawLabel(Canvas canvas, String text, Offset center,
    {double fontSize = 11, Color color = _rulerTick, FontWeight weight = FontWeight.w600}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Píldora con el ángulo actual (siempre legible: nunca boca abajo).
void _drawAnglePill(Canvas canvas, double angle) {
  final deg = RulerGeometry.degrees(angle);
  var shown = deg.round();
  if (shown > 90) shown -= 180;
  if (shown < -90) shown += 180;
  final text = '${shown.abs()}°';
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final rect = Rect.fromCenter(center: Offset.zero, width: tp.width + 16, height: tp.height + 6);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(20)),
    Paint()..color = kAccentColor,
  );
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
}

void _drawStraightRuler(Canvas canvas, CanvasController controller) {
  final g = controller.rulerGeometry;
  final screenCenter = g.center * controller.scale + controller.translate;
  const len = RulerGeometry.lengthPx;
  const w = RulerGeometry.widthPx;

  canvas.save();
  canvas.translate(screenCenter.dx, screenCenter.dy);
  canvas.rotate(g.angle);

  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: len, height: w),
    const Radius.circular(10),
  );
  canvas.drawShadow(Path()..addRRect(body), Colors.black, 6, true);
  canvas.drawRRect(body, _rulerBodyPaint);
  canvas.drawRRect(body, _rulerBorderPaint);

  // Escala: cm de la hoja → px de pantalla según el zoom.
  final cmPx = kWorldUnitsPerCm * controller.scale;
  final mmPx = cmPx / 10;
  final showMm = mmPx >= 4;
  final showHalf = cmPx / 2 >= 6;
  final labelEvery = cmPx >= 22 ? 1 : (cmPx >= 8 ? 5 : 10);
  const start = -len / 2 + 14; // el 0 no queda pegado al borde
  const end = len / 2 - 14;
  final step = showMm ? mmPx : (showHalf ? cmPx / 2 : cmPx);
  final perCm = (cmPx / step).round();
  var i = 0;
  for (var x = start; x <= end + 0.01; x += step, i++) {
    final isCm = i % perCm == 0;
    final isHalf = !isCm && perCm >= 2 && i % (perCm ~/ 2) == 0;
    final tick = isCm ? 16.0 : (isHalf ? 11.0 : 6.0);
    _tickPaint.color = isCm ? _rulerTick : _rulerTickMinor;
    // Marcas en ambos bordes (como una regla real).
    canvas.drawLine(Offset(x, -w / 2), Offset(x, -w / 2 + tick), _tickPaint);
    canvas.drawLine(Offset(x, w / 2), Offset(x, w / 2 - tick * 0.6), _tickPaint);
    final cm = i ~/ perCm;
    if (isCm && cm % labelEvery == 0) {
      _drawLabel(canvas, '$cm', Offset(x, -w / 2 + 26));
    }
  }

  // Borde en uso (el trazo se está dibujando a lo largo de él).
  final snap = controller.activeRulerSnap;
  if (snap == RulerSnap.edgeTop || snap == RulerSnap.edgeBottom) {
    final y = snap == RulerSnap.edgeTop ? -w / 2 : w / 2;
    canvas.drawLine(Offset(-len / 2 + 6, y), Offset(len / 2 - 6, y), _snapEdgePaint);
  }

  // Ángulo en el centro (legible: se endereza si la regla está invertida).
  canvas.translate(0, w / 2 - 16);
  if (cos(g.angle) < 0) canvas.rotate(pi);
  _drawAnglePill(canvas, g.angle);
  canvas.restore();
}

void _drawProtractor(Canvas canvas, CanvasController controller) {
  final g = controller.rulerGeometry;
  final screenCenter = g.center * controller.scale + controller.translate;
  const r = RulerGeometry.protractorRadiusPx;

  canvas.save();
  canvas.translate(screenCenter.dx, screenCenter.dy);
  canvas.rotate(g.angle);

  // Semicírculo "encima" de la base (y negativa en el marco local).
  final body = Path()
    ..moveTo(-r - 10, 0)
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r + 10), pi, pi, false)
    ..lineTo(r + 10, 14)
    ..lineTo(-r - 10, 14)
    ..close();
  canvas.drawShadow(body, Colors.black, 6, true);
  canvas.drawPath(body, _rulerBodyPaint);
  canvas.drawPath(body, _rulerBorderPaint);

  for (var deg = 0; deg <= 180; deg++) {
    final a = pi + deg * pi / 180; // 0° a la derecha... en sentido antihorario
    final dir = Offset(cos(a), sin(a));
    final is10 = deg % 10 == 0;
    final is5 = deg % 5 == 0;
    final tick = is10 ? 16.0 : (is5 ? 10.0 : 5.0);
    _tickPaint.color = is10 ? _rulerTick : _rulerTickMinor;
    canvas.drawLine(dir * r, dir * (r - tick), _tickPaint);
    if (is10) {
      // Escala exterior 0→180 e interior 180→0, como un transportador real.
      _drawLabel(canvas, '${180 - deg}', dir * (r - 28), fontSize: 10);
      if (deg % 30 == 0) {
        _drawLabel(canvas, '$deg', dir * (r - 48),
            fontSize: 9, color: _rulerTickMinor, weight: FontWeight.w500);
      }
    }
  }
  // Base y punto central.
  _tickPaint.color = _rulerTick;
  canvas.drawLine(const Offset(-r, 0), const Offset(r, 0), _tickPaint);
  canvas.drawCircle(Offset.zero, 4, Paint()..color = kAccentColor);

  final snap = controller.activeRulerSnap;
  if (snap == RulerSnap.arc) {
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), pi, pi, false,
        Paint()
          ..color = kAccentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  } else if (snap == RulerSnap.baseline) {
    canvas.drawLine(const Offset(-r, 0), const Offset(r, 0), _snapEdgePaint);
  }

  canvas.translate(0, -r * 0.35);
  if (cos(g.angle) < 0) canvas.rotate(pi);
  _drawAnglePill(canvas, g.angle);
  canvas.restore();
}

/// Dibuja la lupa (vista magnificada circular) cerca del stylus.
///
/// Muestra una copia ampliada del contenido del mundo en la posición actual
/// del trazo, para que el usuario pueda ver detalles mientras escribe.
void drawMagnifier(
  Canvas canvas,
  CanvasController controller,
  Size size,
  Map<String, ui.Image> imageCache,
) {
  final worldPos = controller.magnifierPosition;
  // Aumento RELATIVO a la vista actual (antes era absoluto: con zoom alto
  // la "lupa" podía incluso mostrar el contenido más pequeño).
  final zoom = controller.magnifierZoom * controller.scale;
  final radius = controller.magnifierRadius * 1.5;

  // La lupa sigue al lápiz: arriba a la izquierda de la punta (para no
  // taparla con la mano de un diestro); si no cabe, se recoloca dentro.
  final pen = worldPos * controller.scale + controller.translate;
  var magnifierCenter = pen + Offset(-radius * 1.3, -radius * 1.5);
  magnifierCenter = Offset(
    magnifierCenter.dx.clamp(radius + kMagnifierMargin, size.width - radius - kMagnifierMargin),
    magnifierCenter.dy.clamp(radius + kMagnifierMargin, size.height - radius - kMagnifierMargin),
  );

  // Dibuja el fondo circular.
  canvas.save();
  canvas.clipPath(
    Path()..addOval(Rect.fromCircle(center: magnifierCenter, radius: radius)),
  );

  // Fondo de la lupa.
  canvas.drawCircle(
    magnifierCenter,
    radius,
    Paint()..color = kPaperColorLight,
  );

  // Renderiza el contenido del mundo en la lupa.
  canvas.save();
  canvas.translate(magnifierCenter.dx, magnifierCenter.dy);
  canvas.scale(zoom);
  canvas.translate(-worldPos.dx, -worldPos.dy);

  // Dibuja un parche del mundo usando world_painter.
  final patchSize = Size(radius * 2 / zoom, radius * 2 / zoom);
  final patchRect = Rect.fromCenter(
    center: worldPos,
    width: patchSize.width,
    height: patchSize.height,
  );
  paintWorld(
    canvas,
    visibleWorldRect: patchRect,
    page: controller.page,
    sheetSize: controller.sheetSize,
    imageCache: imageCache,
    viewScale: zoom,
  );
  // El trazo en curso también se ve ampliado.
  final active = controller.activeStroke;
  if (active != null) paintActiveStroke(canvas, active);
  canvas.restore();
  canvas.restore();

  // Borde de la lupa.
  canvas.drawCircle(
    magnifierCenter,
    radius,
    Paint()
      ..color = kAccentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  // Cruz central (punto de referencia).
  const crossSize = 8.0;
  canvas.drawLine(
    Offset(magnifierCenter.dx - crossSize, magnifierCenter.dy),
    Offset(magnifierCenter.dx + crossSize, magnifierCenter.dy),
    Paint()
      ..color = kAccentColor.withAlpha(180)
      ..strokeWidth = 1.5,
  );
  canvas.drawLine(
    Offset(magnifierCenter.dx, magnifierCenter.dy - crossSize),
    Offset(magnifierCenter.dx, magnifierCenter.dy + crossSize),
    Paint()
      ..color = kAccentColor.withAlpha(180)
      ..strokeWidth = 1.5,
  );
}

/// Dibuja un borde de "marching ants" (línea punteada animada).
///
/// Se usa para rodear la selección de trazos con el lazo.
void drawMarchingAnts(Canvas canvas, Rect rect, double scale) {
  final paint = Paint()
    ..color = kAccentColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 / scale
    ..strokeCap = StrokeCap.round;
  final dashLength = 8.0 / scale;
  final gapLength = 4.0 / scale;
  final path = Path();
  // Top
  addDashedLine(path, rect.topLeft, rect.topRight, dashLength, gapLength);
  // Right
  addDashedLine(path, rect.topRight, rect.bottomRight, dashLength, gapLength);
  // Bottom
  addDashedLine(path, rect.bottomRight, rect.bottomLeft, dashLength, gapLength);
  // Left
  addDashedLine(path, rect.bottomLeft, rect.topLeft, dashLength, gapLength);
  canvas.drawPath(path, paint);
}

/// Añade una línea punteada a un [Path].
void addDashedLine(
  Path path,
  Offset start,
  Offset end,
  double dash,
  double gap,
) {
  final length = (end - start).distance;
  if (length == 0) return;
  final dir = (end - start) / length;
  var pos = 0.0;
  while (pos < length) {
    final p1 = start + dir * pos;
    final p2 = start + dir * min(pos + dash, length);
    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    pos += dash + gap;
  }
}
