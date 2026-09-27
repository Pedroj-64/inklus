// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ============================================================================
// Selector de color tipo rueda (Hue Ring + Saturation/Brightness Square)
//
// Widget visual que permite elegir un color tocando directamente:
// - Anillo exterior: Matiz (Hue) — arrastrar alrededor del círculo
// - Cuadrado interior: Saturación (eje X) × Brillo (eje Y)
//
// Más intuitivo que sliders para la mayoría de usuarios.
// ============================================================================

/// Widget selector de color con rueda de matiz y cuadrado saturación/brillo.
///
/// Devuelve el color seleccionado en tiempo real via [onColorChanged].
/// Se puede usar como widget embebido o dentro de un diálogo.
class ColorWheelPicker extends StatefulWidget {
  /// Color inicial seleccionado.
  final HSVColor initialColor;

  /// Callback invocado en cada cambio de color (durante el arrastre).
  final ValueChanged<Color> onColorChanged;

  /// Callback invocado al soltar (fin del gesto).
  final ValueChanged<Color>? onColorChangeEnd;

  /// Tamaño del widget (ancho y alto iguales).
  final double size;

  /// Radio del anillo de matiz como fracción del tamaño (0.0–0.5).
  final double ringWidthRatio;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.onColorChangeEnd,
    this.size = 280,
    this.ringWidthRatio = 0.18,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late HSVColor _hsv;

  bool _draggingRing = false;
  bool _draggingSB = false;

  @override
  void initState() {
    super.initState();
    _hsv = widget.initialColor;
  }

  @override
  void didUpdateWidget(ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor && !_draggingRing && !_draggingSB) {
      _hsv = widget.initialColor;
    }
  }

  double get _ringWidth => widget.size * widget.ringWidthRatio;
  double get _outerRadius => widget.size / 2;
  double get _innerRadius => _outerRadius - _ringWidth;
  double get _sbSize => _innerRadius * 1.3; // un poco más grande que el radio interno
  double get _sbRadius => _sbSize / 2;

  Offset get _center => Offset(widget.size / 2, widget.size / 2);

  void _updateFromAngle(Offset local) {
    final d = local - _center;
    final angle = atan2(d.dy, d.dx);
    final dist = d.distance;

    // ¿Está dentro del anillo?
    if (dist >= _innerRadius - 4 && dist <= _outerRadius + 4) {
      _draggingRing = true;
      final hue = ((angle * 180 / pi) % 360 + 360) % 360;
      _hsv = _hsv.withHue(hue);
      widget.onColorChanged(_hsv.toColor());
    }
  }

  void _updateFromSB(Offset local) {
    // Posición relativa al centro del cuadrado SB
    final sbCenter = _center;
    final dx = (local.dx - sbCenter.dx + _sbRadius) / _sbSize;
    final dy = (local.dy - sbCenter.dy + _sbRadius) / _sbSize;
    final sat = dx.clamp(0.0, 1.0);
    final val = (1.0 - dy).clamp(0.0, 1.0);

    _draggingSB = true;
    _hsv = _hsv.withSaturation(sat).withValue(val);
    widget.onColorChanged(_hsv.toColor());
  }

  bool _isInSB(Offset local) {
    final d = local - _center;
    return d.dx.abs() <= _sbRadius && d.dy.abs() <= _sbRadius;
  }

  bool _isInRing(Offset local) {
    final dist = (local - _center).distance;
    return dist >= _innerRadius - 6 && dist <= _outerRadius + 6;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        final local = d.localPosition;
        if (_isInSB(local)) {
          _updateFromSB(local);
        } else if (_isInRing(local)) {
          _updateFromAngle(local);
        }
      },
      onPanUpdate: (d) {
        if (_draggingSB) {
          _updateFromSB(d.localPosition);
        } else if (_draggingRing) {
          _updateFromAngle(d.localPosition);
        }
      },
      onPanEnd: (_) {
        if (_draggingSB || _draggingRing) {
          widget.onColorChangeEnd?.call(_hsv.toColor());
        }
        _draggingRing = false;
        _draggingSB = false;
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ColorWheelPainter(
          hue: _hsv.hue,
          saturation: _hsv.saturation,
          value: _hsv.value,
          ringWidth: _ringWidth,
          outerRadius: _outerRadius,
          innerRadius: _innerRadius,
          sbSize: _sbSize,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter: dibuja el anillo de hue + el cuadrado saturación/brillo
// ---------------------------------------------------------------------------

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;
  final double ringWidth;
  final double outerRadius;
  final double innerRadius;
  final double sbSize;

  /// Bitmap cacheado del cuadrado SB. Se regenera solo cuando cambia el hue.
  static ui.Image? _cachedSBImage;
  static double _cachedHue = -1;

  _ColorWheelPainter({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.ringWidth,
    required this.outerRadius,
    required this.innerRadius,
    required this.sbSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ---- 1. Anillo de matiz (Hue Ring) ----
    _drawHueRing(canvas, center);

    // ---- 2. Cuadrado de saturación/brillo ----
    _drawSBRect(canvas, center);

    // ---- 3. Marcador del matiz en el anillo ----
    _drawHueIndicator(canvas, center);

    // ---- 4. Marcador de saturación/brillo en el cuadrado ----
    _drawSBIndicator(canvas, center);
  }

  /// Dibuja el anillo de arcoíris (Hue 0–360°).
  void _drawHueRing(Canvas canvas, Offset center) {
    const steps = 360;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = ringWidth + 1;

    for (var i = 0; i < steps; i++) {
      final startAngle = (i / steps) * 2 * pi - pi / 2;
      final sweepAngle = (1 / steps) * 2 * pi + 0.02; // ligeramente mayor para evitar gaps
      final color = HSVColor.fromAHSV(1, (i / steps) * 360, 1, 1).toColor();

      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  /// Dibuja el cuadrado de Saturación × Brillo dentro del anillo.
  ///
  /// Implementación: usa un [Image] de un bitmap pequeño (256×256) que
  /// se genera una vez y se cachea para evitar reconstruir pixel a pixel
  /// en cada frame.
  void _drawSBRect(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(
      center: center,
      width: sbSize,
      height: sbSize,
    );

    // Generar el bitmap del cuadrado SB
    final image = _createSBImage();
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    // Borde sutil
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black26,
    );
  }

  /// Crea (o reutiliza) un bitmap 256×256 del cuadrado Saturación × Brillo.
  /// Se cachea estáticamente y solo se regenera cuando cambia el hue.
  ui.Image? _createSBImage() {
    // Reutilizar cache si el hue no cambió significativamente.
    if (_cachedSBImage != null && (_cachedHue - hue).abs() < 0.5) {
      return _cachedSBImage;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 256;

    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        final sat = x / (size - 1);
        final val = 1.0 - (y / (size - 1));
        final color = HSVColor.fromAHSV(1, hue, sat, val).toColor();
        final paint = Paint()..color = color;
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.1, 1.1),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    _cachedSBImage?.dispose();
    _cachedSBImage = picture.toImageSync(size, size);
    _cachedHue = hue;
    return _cachedSBImage;
  }

  /// Dibuja el indicador circular del matiz en el anillo.
  void _drawHueIndicator(Canvas canvas, Offset center) {
    final angle = hue * pi / 180 - pi / 2; // -90° para que 0° esté arriba
    final indicatorRadius = (outerRadius + innerRadius) / 2;
    final pos = center + Offset(cos(angle), sin(angle)) * indicatorRadius;

    // Sombra
    canvas.drawCircle(pos, 10, Paint()..color = Colors.black26);
    // Círculo blanco con borde del color seleccionado
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Centro del color
    canvas.drawCircle(
      pos,
      5,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
  }

  /// Dibuja el indicador de saturación/brillo en el cuadrado SB.
  void _drawSBIndicator(Canvas canvas, Offset center) {
    final sbLeft = center.dx - sbSize / 2;
    final sbTop = center.dy - sbSize / 2;
    final x = sbLeft + saturation * sbSize;
    final y = sbTop + (1.0 - value) * sbSize;
    final pos = Offset(x, y);

    // Sombra
    canvas.drawCircle(pos, 10, Paint()..color = Colors.black26);
    // Borde blanco
    canvas.drawCircle(
      pos,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Centro del color actual
    canvas.drawCircle(
      pos,
      6,
      Paint()..color = HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
    );
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) =>
      oldDelegate.hue != hue ||
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value;
}
