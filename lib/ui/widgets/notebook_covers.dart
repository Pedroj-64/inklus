// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Tipos de portada disponibles para el cuaderno.
enum CoverStyle { simple, circle, waves, dots, lines, custom }

/// Painter de portada de cuaderno.
///
/// Cada estilo es un diseño limpio y minimalista que se adapta al color
/// de portada asignado al cuaderno.
class NotebookCoverPainter extends CustomPainter {
  final CoverStyle style;
  final Color color;
  final bool isDark;

  NotebookCoverPainter({
    required this.style,
    required this.color,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case CoverStyle.simple:
        _paintSimple(canvas, size);
        break;
      case CoverStyle.circle:
        _paintCircle(canvas, size);
        break;
      case CoverStyle.waves:
        _paintWaves(canvas, size);
        break;
      case CoverStyle.dots:
        _paintDots(canvas, size);
        break;
      case CoverStyle.lines:
        _paintLines(canvas, size);
        break;
      case CoverStyle.custom:
        // Fallback: gradiente con el color asignado.
        _paintSimple(canvas, size);
        break;
    }
  }

  /// Estilo 1: Fondo con gradiente y líneas diagonales sutiles.
  void _paintSimple(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [color, _darken(color, 0.3)],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    // Líneas diagonales sutiles
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final spacing = size.width / 8;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
    }
  }

  /// Estilo 2: Círculo grande centrado.
  void _paintCircle(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    final circlePaint = Paint()..color = Colors.white.withAlpha(25);
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.width * 0.35;
    canvas.drawCircle(center, radius, circlePaint);

    // Anillo exterior
    final ringPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius + 20, ringPaint);
  }

  /// Estilo 3: Olas horizontales en la parte inferior.
  void _paintWaves(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    final wavePaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var w = 0; w < 4; w++) {
      final path = Path();
      final yBase = size.height * 0.55 + w * 30.0;
      path.moveTo(0, yBase);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y = yBase + sin((x / size.width) * pi * 3 + w * 0.8) * (15 + w * 5.0);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  /// Estilo 4: Grid de puntos sutil.
  void _paintDots(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    final dotPaint = Paint()..color = Colors.white.withAlpha(30);
    final spacing = size.width / 10;
    final startY = size.height * 0.25;
    final endY = size.height * 0.75;

    for (var y = startY; y < endY; y += spacing) {
      for (var x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }
  }

  /// Estilo 5: Líneas horizontales tipo cuaderno.
  void _paintLines(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      bgPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..strokeWidth = 1;

    final startY = size.height * 0.3;
    final endY = size.height * 0.8;
    final spacing = 28.0;

    for (var y = startY; y < endY; y += spacing) {
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), linePaint);
    }

    // Margen vertical
    final marginPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(60, startY - 10), Offset(60, endY + 10), marginPaint);
  }

  /// Oscurece un color un porcentaje dado.
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant NotebookCoverPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color || oldDelegate.isDark != isDark;
}

/// Nombre legible de cada estilo de portada.
const Map<CoverStyle, String> coverStyleNames = {
  CoverStyle.simple: 'Simple',
  CoverStyle.circle: 'Círculo',
  CoverStyle.waves: 'Olas',
  CoverStyle.dots: 'Puntos',
  CoverStyle.lines: 'Líneas',
  CoverStyle.custom: 'Imagen',
};

/// Icono representativo de cada estilo.
const Map<CoverStyle, IconData> coverStyleIcons = {
  CoverStyle.simple: Icons.gradient,
  CoverStyle.circle: Icons.circle_outlined,
  CoverStyle.waves: Icons.waves,
  CoverStyle.dots: Icons.grain,
  CoverStyle.lines: Icons.format_list_bulleted,
  CoverStyle.custom: Icons.image_outlined,
};
