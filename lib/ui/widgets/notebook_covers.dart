// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Tipos de portada disponibles para el cuaderno.
///
/// Se guardan por `name` en el índice: **no renombrar** los existentes
/// (`simple`…`lines`, `custom`); los nuevos se añaden al final.
enum CoverStyle { simple, circle, waves, dots, lines, custom, classic, geometric, aurora }

/// Estilos que se dibujan con [NotebookCoverPainter] (todos menos `custom`).
const List<CoverStyle> kPaintedCoverStyles = [
  CoverStyle.simple,
  CoverStyle.classic,
  CoverStyle.aurora,
  CoverStyle.waves,
  CoverStyle.geometric,
  CoverStyle.circle,
  CoverStyle.dots,
  CoverStyle.lines,
];

/// Painter de portada de cuaderno.
///
/// Todas las portadas comparten el mismo "cuerpo" de cuaderno (degradado
/// del color elegido, lomo a la izquierda, brillo superior) y cambian la
/// decoración. Las medidas son proporcionales: se ven igual de pequeñas
/// (lista) que grandes (vista previa).
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
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide * 0.06)));
    _body(canvas, size);
    switch (style) {
      case CoverStyle.simple:
      case CoverStyle.custom: // (sin imagen, vuelve al degradado)
        _paintSimple(canvas, size);
      case CoverStyle.circle:
        _paintCircle(canvas, size);
      case CoverStyle.waves:
        _paintWaves(canvas, size);
      case CoverStyle.dots:
        _paintDots(canvas, size);
      case CoverStyle.lines:
        _paintLines(canvas, size);
      case CoverStyle.classic:
        _paintClassic(canvas, size);
      case CoverStyle.geometric:
        _paintGeometric(canvas, size);
      case CoverStyle.aurora:
        _paintAurora(canvas, size);
    }
    _spineAndSheen(canvas, size);
    canvas.restore();
  }

  // ---- Cuerpo común ----------------------------------------------------

  void _body(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [_lighten(color, 0.07), color, _darken(color, 0.22)],
          const [0, 0.45, 1],
        ),
    );
  }

  /// Lomo con costura y brillo suave arriba: da volumen de cuaderno real.
  void _spineAndSheen(Canvas canvas, Size size) {
    final w = size.width;
    final spine = w * 0.075;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, spine, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(spine, 0),
          [Colors.black.withAlpha(70), Colors.black.withAlpha(15)],
        ),
    );
    canvas.drawLine(
      Offset(spine, 0),
      Offset(spine, size.height),
      Paint()
        ..color = Colors.white.withAlpha(45)
        ..strokeWidth = max(1, w * 0.006),
    );
    // Costura punteada junto al lomo.
    final stitch = Paint()..color = Colors.white.withAlpha(60);
    final gap = size.height / 22;
    for (var y = gap; y < size.height - gap / 2; y += gap) {
      canvas.drawCircle(Offset(spine * 1.9, y), max(0.8, w * 0.005), stitch);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height * 0.45),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height * 0.45),
          [Colors.white.withAlpha(34), Colors.white.withAlpha(0)],
        ),
    );
  }

  // ---- Estilos ---------------------------------------------------------

  /// Degradado con un resplandor y una banda diagonal suave.
  void _paintSimple(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.18),
      size.width * 0.55,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.85, size.height * 0.18),
          size.width * 0.55,
          [Colors.white.withAlpha(60), Colors.white.withAlpha(0)],
        ),
    );
    final band = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.55, size.height)
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.25)
      ..close();
    canvas.drawPath(band, Paint()..color = Colors.white.withAlpha(14));
  }

  /// Cuaderno clásico: cinta elástica y placa para el título.
  void _paintClassic(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.80, 0, w * 0.045, h),
      Paint()..color = Colors.black.withAlpha(60),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.80, 0, w * 0.012, h),
      Paint()..color = Colors.white.withAlpha(35),
    );
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.34, w * 0.58, h * 0.22),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(plate, Paint()..color = Colors.black.withAlpha(46));
    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, w * 0.008)
        ..color = Colors.white.withAlpha(110),
    );
    canvas.drawRRect(
      plate.deflate(w * 0.018),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.6, w * 0.004)
        ..color = Colors.white.withAlpha(60),
    );
  }

  /// Manchas de color difuminadas (tonos vecinos del color base).
  void _paintAurora(Canvas canvas, Size size) {
    final blur = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.16);
    void blob(Offset c, double r, Color col) {
      canvas.drawCircle(c, r, blur..color = col);
    }

    blob(Offset(size.width * 0.25, size.height * 0.30), size.width * 0.36,
        _shiftHue(color, 40).withAlpha(170));
    blob(Offset(size.width * 0.80, size.height * 0.55), size.width * 0.40,
        _shiftHue(color, -45).withAlpha(150));
    blob(Offset(size.width * 0.40, size.height * 0.88), size.width * 0.45,
        _lighten(color, 0.18).withAlpha(140));
  }

  /// Triángulos y círculos planos superpuestos.
  void _paintGeometric(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final light = Paint()..color = Colors.white.withAlpha(30);
    final dark = Paint()..color = Colors.black.withAlpha(36);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, h)
        ..lineTo(w * 0.62, h * 0.52)
        ..lineTo(w * 1.1, h)
        ..close(),
      dark,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.45, h)
        ..lineTo(w * 0.85, h * 0.66)
        ..lineTo(w * 1.2, h)
        ..close(),
      light,
    );
    canvas.drawCircle(Offset(w * 0.68, h * 0.24), w * 0.17, light);
    canvas.drawCircle(Offset(w * 0.68, h * 0.24), w * 0.17,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, w * 0.008)
          ..color = Colors.white.withAlpha(90));
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.18, w * 0.018),
        Paint()..color = Colors.white.withAlpha(120));
  }

  /// Anillos concéntricos desde un "sol" arriba.
  void _paintCircle(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.56, size.height * 0.36);
    for (var i = 4; i >= 1; i--) {
      canvas.drawCircle(
        c,
        size.width * (0.13 + i * 0.12),
        Paint()..color = Colors.white.withAlpha(8 + (5 - i) * 7),
      );
    }
    canvas.drawCircle(
      c,
      size.width * 0.13,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          size.width * 0.13,
          [Colors.white.withAlpha(150), Colors.white.withAlpha(60)],
        ),
    );
  }

  /// Olas rellenas, cada capa más oscura.
  void _paintWaves(Canvas canvas, Size size) {
    for (var i = 0; i < 4; i++) {
      final base = size.height * (0.52 + i * 0.12);
      final amp = size.height * (0.035 + i * 0.006);
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 2; x += 2) {
        final y = base + sin((x / size.width) * pi * 2.2 + i * 1.1) * amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = (i.isEven ? Colors.white : Colors.black).withAlpha(i.isEven ? 22 : 30));
    }
  }

  /// Trama de puntos (semitono) que crece hacia la esquina inferior.
  void _paintDots(Canvas canvas, Size size) {
    final step = size.width / 9;
    final paint = Paint()..color = Colors.white.withAlpha(70);
    for (var y = step; y < size.height; y += step) {
      for (var x = step; x < size.width; x += step) {
        final t = ((x / size.width) * 0.5 + (y / size.height) * 0.5).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(x, y), step * (0.05 + 0.2 * t), paint);
      }
    }
  }

  /// Hoja rayada con margen, como un cuaderno escolar.
  void _paintLines(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = Paint()
      ..color = Colors.white.withAlpha(46)
      ..strokeWidth = max(0.8, w * 0.005);
    final gap = h / 16;
    for (var y = gap * 4; y < h - gap; y += gap) {
      canvas.drawLine(Offset(w * 0.12, y), Offset(w * 0.92, y), line);
    }
    canvas.drawLine(
      Offset(w * 0.24, gap * 3),
      Offset(w * 0.24, h - gap * 0.6),
      Paint()
        ..color = Colors.white.withAlpha(95)
        ..strokeWidth = max(1, w * 0.007),
    );
  }

  // ---- Color -----------------------------------------------------------

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _shiftHue(Color c, double degrees) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }

  @override
  bool shouldRepaint(covariant NotebookCoverPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color || oldDelegate.isDark != isDark;
}

/// Nombre traducido de un color de portada (`kCoverColors`); `null` = sin color.
String coverColorName(AppLocalizations l10n, int? value) => switch (value) {
      null => l10n.colorNone,
      0xFF3B82F6 => l10n.colorBlue,
      0xFF4CAF50 => l10n.colorGreen,
      0xFFE53935 => l10n.colorRed,
      0xFFFF9800 => l10n.colorOrange,
      0xFF9C27B0 => l10n.colorPurple,
      0xFFEC407A => l10n.colorPink,
      0xFF26C6DA => l10n.colorTurquoise,
      0xFF78909C => l10n.colorGray,
      _ => l10n.smartOther,
    };

/// Nombre traducido de cada estilo de portada.
String coverStyleName(AppLocalizations l10n, CoverStyle s) => switch (s) {
      CoverStyle.simple => l10n.coverSimple,
      CoverStyle.classic => l10n.coverClassic,
      CoverStyle.aurora => l10n.coverAurora,
      CoverStyle.waves => l10n.coverWaves,
      CoverStyle.geometric => l10n.coverGeometric,
      CoverStyle.circle => l10n.coverSun,
      CoverStyle.dots => l10n.coverDots,
      CoverStyle.lines => l10n.coverLines,
      CoverStyle.custom => l10n.createYourImage,
    };

/// Títulos por defecto que la app guarda en español (`Sin título`, `Mi
/// cuaderno`): al mostrarlos se traducen; los títulos del usuario no se tocan.
String displayTitle(AppLocalizations l10n, String title) => switch (title) {
      'Sin título' => l10n.untitled,
      'Mi cuaderno' => l10n.defaultNotebookTitle,
      _ => title,
    };

/// Icono representativo de cada estilo.
const Map<CoverStyle, IconData> coverStyleIcons = {
  CoverStyle.simple: Icons.gradient,
  CoverStyle.classic: Icons.menu_book_outlined,
  CoverStyle.aurora: Icons.blur_on,
  CoverStyle.waves: Icons.waves,
  CoverStyle.geometric: Icons.change_history,
  CoverStyle.circle: Icons.wb_sunny_outlined,
  CoverStyle.dots: Icons.grain,
  CoverStyle.lines: Icons.format_list_bulleted,
  CoverStyle.custom: Icons.add_photo_alternate_outlined,
};
