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
/// La regla puede ser recta o transportador, según [controller.rulerType].
void drawRuler(Canvas canvas, CanvasController controller, Size size) {
  switch (controller.rulerType) {
    case RulerType.straight:
      _drawStraightRuler(canvas, controller, size);
      break;
    case RulerType.protractor:
      _drawProtractor(canvas, controller, size);
      break;
  }
}

// ---------------------------------------------------------------------------
// Regla recta
// ---------------------------------------------------------------------------

void _drawStraightRuler(Canvas canvas, CanvasController controller, Size size) {
  final scale = controller.scale;
  final translate = controller.translate;
  final center = controller.rulerCenter;
  final angle = controller.rulerAngle;
  final halfLen = controller.rulerLength / 2;

  final screenCenter = center * scale + translate;
  final dir = Offset(cos(angle), sin(angle));
  final screenDir = dir * scale;
  final screenHalfLen = halfLen * scale;

  final end1 = screenCenter + screenDir * screenHalfLen;
  final end2 = screenCenter - screenDir * screenHalfLen;
  const rulerWidth = kRulerScreenWidth;

  // Rotar al ángulo de la regla.
  canvas.save();
  canvas.translate(screenCenter.dx, screenCenter.dy);
  canvas.rotate(angle);
  canvas.translate(-screenCenter.dx, -screenCenter.dy);

  // Fondo semitransparente.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: screenCenter, width: screenHalfLen * 2, height: rulerWidth),
      const Radius.circular(4),
    ),
    Paint()
      ..color = const Color(0xFFF5F0E8).withAlpha(220)
      ..style = PaintingStyle.fill,
  );

  // Borde.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: screenCenter, width: screenHalfLen * 2, height: rulerWidth),
      const Radius.circular(4),
    ),
    Paint()
      ..color = const Color(0xFF8B7355).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  // Línea central de guía.
  canvas.drawLine(
    Offset(screenCenter.dx - screenHalfLen + 8, screenCenter.dy),
    Offset(screenCenter.dx + screenHalfLen - 8, screenCenter.dy),
    Paint()
      ..color = const Color(0xFF3B82F6).withAlpha(160)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round,
  );

  // Marcas de medición y números.
  final markCount = (controller.rulerLength / kRulerMarkSpacing).floor();
  final markSpacing = (screenHalfLen * 2) / markCount;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);

  for (var i = 0; i <= markCount; i++) {
    final x = screenCenter.dx - screenHalfLen + i * markSpacing;
    final isMajor = i % 2 == 0;
    final markLen = isMajor ? rulerWidth * 0.65 : rulerWidth * 0.35;
    final markY = screenCenter.dy - rulerWidth / 2 + 2;

    // Marca.
    canvas.drawLine(
      Offset(x, markY),
      Offset(x, markY + markLen),
      Paint()
        ..color = const Color(0xFF333333).withAlpha(isMajor ? 200 : 120)
        ..strokeWidth = isMajor ? 1.2 : 0.8,
    );

    // Número en marcas mayores.
    if (isMajor && i > 0 && i < markCount) {
      final cm = i ~/ 2;
      textPainter.text = TextSpan(
        text: '$cm',
        style: const TextStyle(
          fontSize: 7,
          color: Color(0xFF555555),
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, markY + markLen + 1),
      );
    }
  }

  canvas.restore();

  // Centro de la regla (handle de arrastre).
  canvas.drawCircle(screenCenter, 9, Paint()..color = kAccentColor);
  canvas.drawCircle(
    screenCenter,
    9,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white,
  );

  // Handles de rotación (extremos).
  for (final end in [end1, end2]) {
    canvas.drawCircle(end, 6, Paint()..color = kAccentColor.withAlpha(180));
    canvas.drawCircle(
      end,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }
}

// ---------------------------------------------------------------------------
// Transportador
// ---------------------------------------------------------------------------

void _drawProtractor(Canvas canvas, CanvasController controller, Size size) {
  final scale = controller.scale;
  final translate = controller.translate;
  final center = controller.rulerCenter;
  final angle = controller.rulerAngle;

  final screenCenter = center * scale + translate;
  final radius = kProtractorRadius * scale;

  canvas.save();
  canvas.translate(screenCenter.dx, screenCenter.dy);
  canvas.rotate(angle);

  // Fondo del transportador.
  final bgPath = Path()
    ..addArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -pi / 2, // empieza arriba
      pi, // semicírculo
    )
    ..lineTo(0, 0)
    ..close();

  canvas.drawPath(
    bgPath,
    Paint()
      ..color = const Color(0xFFF5F0E8).withAlpha(210)
      ..style = PaintingStyle.fill,
  );

  // Borde del transportador.
  canvas.drawPath(
    bgPath,
    Paint()
      ..color = const Color(0xFF8B7355).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );

  // Marcas de grados.
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  for (var deg = 0; deg <= 180; deg += 5) {
    final rad = (deg - 90) * pi / 180; // -90 para que 0° esté a la derecha
    final cosR = cos(rad);
    final sinR = sin(rad);

    final isMajor = deg % 30 == 0;
    final isMedium = deg % 10 == 0;
    final innerR = isMajor ? radius * 0.72 : (isMedium ? radius * 0.80 : radius * 0.88);
    final outerR = radius * 0.95;

    // Línea de marca.
    canvas.drawLine(
      Offset(innerR * cosR, innerR * sinR),
      Offset(outerR * cosR, outerR * sinR),
      Paint()
        ..color = const Color(0xFF333333).withAlpha(isMajor ? 220 : (isMedium ? 160 : 100))
        ..strokeWidth = isMajor ? 1.5 : (isMedium ? 1.0 : 0.6),
    );

    // Números cada 30°.
    if (isMajor) {
      final labelR = radius * 0.62;
      final labelAngle = (deg - 90) * pi / 180;
      final showDeg = deg;
      textPainter.text = TextSpan(
        text: '$showDeg°',
        style: const TextStyle(
          fontSize: 8,
          color: Color(0xFF444444),
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      // Rotar el texto para que sea legible.
      canvas.save();
      canvas.translate(labelR * cos(labelAngle), labelR * sin(labelAngle));
      canvas.rotate(labelAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  // Línea de base (horizontal).
  canvas.drawLine(
    Offset(-radius * 0.95, 0),
    Offset(radius * 0.95, 0),
    Paint()
      ..color = const Color(0xFF8B7355).withAlpha(120)
      ..strokeWidth = 1.0,
  );

  // Línea vertical de referencia (0° arriba).
  canvas.drawLine(
    Offset(0, 0),
    Offset(0, -radius * 0.72),
    Paint()
      ..color = const Color(0xFF3B82F6).withAlpha(160)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round,
  );

  canvas.restore();

  // Centro del transportador (handle de arrastre).
  canvas.drawCircle(screenCenter, 8, Paint()..color = kAccentColor);
  canvas.drawCircle(
    screenCenter,
    8,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white,
  );

  // Handle de rotación.
  final rotAngle = angle - pi / 2;
  final rotHandle = screenCenter + Offset(cos(rotAngle), sin(rotAngle)) * radius * 0.72;
  canvas.drawCircle(rotHandle, 6, Paint()..color = kAccentColor.withAlpha(180));
  canvas.drawCircle(
    rotHandle,
    6,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white,
  );
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
