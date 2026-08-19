import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Page;

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../canvas/world_painter.dart';

// ============================================================================
// Overlays del canvas: Regla virtual, Lupa, Marching Ants
//
// Extraídos de drawing_canvas.dart para reducir su tamaño y mejorar la
// separación de responsabilidades. Estas funciones dibujan overlays visuales
// sobre el canvas del editor (no son widgets de Flutter, son CustomPainter).
// ============================================================================

/// Dibuja la regla virtual en el canvas.
///
/// La regla es un rectángulo translúcido con marcas de medición que el
/// usuario puede arrastrar y rotar para guiar trazos rectos.
void drawRuler(Canvas canvas, CanvasController controller, Size size) {
  final scale = controller.scale;
  final translate = controller.translate;
  final center = controller.rulerCenter;
  final angle = controller.rulerAngle;
  final halfLen = controller.rulerLength / 2;

  // Convierte el centro de la regla a espacio de pantalla.
  final screenCenter = center * scale + translate;
  final dir = Offset(cos(angle), sin(angle));
  final screenDir = dir * scale;
  final screenHalfLen = halfLen * scale;

  final end1 = screenCenter + screenDir * screenHalfLen;
  final end2 = screenCenter - screenDir * screenHalfLen;

  // Cuerpo de la regla (rectángulo translúcido).
  final perp = Offset(-dir.dy, dir.dx);
  const rulerWidth = kRulerScreenWidth;
  final screenPerp = perp * rulerWidth / 2;

  // Dibuja el cuerpo de la regla.
  canvas.drawPath(
    Path()
      ..moveTo((end1 + screenPerp).dx, (end1 + screenPerp).dy)
      ..lineTo((end2 + screenPerp).dx, (end2 + screenPerp).dy)
      ..lineTo((end2 - screenPerp).dx, (end2 - screenPerp).dy)
      ..lineTo((end1 - screenPerp).dx, (end1 - screenPerp).dy)
      ..close(),
    Paint()
      ..color = kAccentColor.withAlpha(48)
      ..style = PaintingStyle.fill,
  );

  // Borde de la regla.
  canvas.drawLine(
    end1 + screenPerp,
    end2 + screenPerp,
    Paint()
      ..color = kAccentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    end1 - screenPerp,
    end2 - screenPerp,
    Paint()
      ..color = kAccentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  );

  // Línea central (guía de dibujo).
  canvas.drawLine(
    end1,
    end2,
    Paint()
      ..color = kAccentColor.withAlpha(180)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round,
  );

  // Marcas de medición.
  final markCount = (controller.rulerLength / kRulerMarkSpacing).floor();
  for (var i = 0; i <= markCount; i++) {
    final t = (i / markCount) * 2 - 1; // -1 a 1
    final markPos = screenCenter + screenDir * (t * screenHalfLen);
    final isMajor = i % 2 == 0;
    final markLen = isMajor ? rulerWidth * 0.7 : rulerWidth * 0.4;
    final markPerp = perp * markLen / 2;
    canvas.drawLine(
      markPos - markPerp,
      markPos + markPerp,
      Paint()
        ..color = kAccentColor.withAlpha(isMajor ? 200 : 120)
        ..strokeWidth = isMajor ? 1.5 : 1.0,
    );
  }

  // Centro de la regla (handle de arrastre).
  canvas.drawCircle(screenCenter, 10, Paint()..color = kAccentColor);
  canvas.drawCircle(
    screenCenter,
    10,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white,
  );

  // Handles de rotación (extremos).
  for (final end in [end1, end2]) {
    canvas.drawCircle(end, 7, Paint()..color = kAccentColor.withAlpha(180));
    canvas.drawCircle(
      end,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }
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
  final zoom = controller.magnifierZoom;
  final radius = controller.magnifierRadius;

  // Posición de la lupa en pantalla: esquina superior derecha.
  final magnifierCenter = Offset(
    size.width - radius - kMagnifierMargin,
    radius + 40,
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
    Paint()..color = const Color(0xFFF5F5F5),
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
  );
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
