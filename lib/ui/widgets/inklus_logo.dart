// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Marca de Inklus: una plumilla estilizada sobre una gota de tinta.
/// Vectorial (CustomPainter): nítida a cualquier tamaño y sin dependencias.
class InklusLogo extends StatelessWidget {
  const InklusLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Inklus',
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(ink: scheme.primary, nib: scheme.onPrimary),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.ink, required this.nib});

  final Color ink;
  final Color nib;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Fondo: squircle con la tinta de marca.
    final bg = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.28));
    canvas.drawRRect(bg, Paint()..color = ink);

    // Plumilla: rombo alargado con ranura y respiradero.
    final nibPath = Path()
      ..moveTo(s * 0.50, s * 0.16)
      ..lineTo(s * 0.72, s * 0.50)
      ..lineTo(s * 0.50, s * 0.84)
      ..lineTo(s * 0.28, s * 0.50)
      ..close();
    canvas.drawPath(nibPath, Paint()..color = nib);
    final slit = Paint()
      ..color = ink
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * 0.50, s * 0.46), Offset(s * 0.50, s * 0.80), slit);
    canvas.drawCircle(Offset(s * 0.50, s * 0.43), s * 0.055, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.ink != ink || old.nib != nib;
}
