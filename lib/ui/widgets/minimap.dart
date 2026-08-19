import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';

/// Minimapa que muestra la posición actual del viewport dentro del mundo.
///
/// Se muestra como un overlay pequeño en la esquina inferior izquierda del
/// editor. Es útil en lienzos infinitos para orientarse al hacer zoom.
class MinimapWidget extends StatelessWidget {
  final CanvasController controller;

  const MinimapWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Solo se muestra si hay contenido real (viewport no es cero).
        if (controller.viewportSize.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => controller.fitView(controller.viewportSize),
          child: Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MinimapPainter(
                scale: controller.scale,
                translate: controller.translate,
                viewportSize: controller.viewportSize,
                sheetSize: controller.sheetSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final double scale;
  final Offset translate;
  final Size viewportSize;
  final Size sheetSize;

  _MinimapPainter({
    required this.scale,
    required this.translate,
    required this.viewportSize,
    required this.sheetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 4.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // Calcular los límites del mundo visible.
    final worldLeft = -translate.dx / scale;
    final worldTop = -translate.dy / scale;
    final worldWidth = viewportSize.width / scale;
    final worldHeight = viewportSize.height / scale;

    // Dibujar fondo del mundo (papel).
    final bgPaint = Paint()..color = const Color(0xFFFEFDF9);
    canvas.drawRect(
      Rect.fromLTWH(padding, padding, drawWidth, drawHeight),
      bgPaint,
    );

    // Dibujar la hoja (si hay tamaño fijo).
    if (sheetSize.width > 0 && sheetSize.height > 0) {
      // La hoja está centrada en el mundo en (0,0).
      // Mapear la hoja al minimapa.
      final scaleX = drawWidth / max(worldWidth, sheetSize.width * 1.5);
      final scaleY = drawHeight / max(worldHeight, sheetSize.height * 1.5);
      final s = scaleX < scaleY ? scaleX : scaleY;

      final sheetCenter = Offset(
        padding + drawWidth / 2 - (worldLeft + worldWidth / 2) * s,
        padding + drawHeight / 2 - (worldTop + worldHeight / 2) * s,
      );

      final sheetMiniRect = Rect.fromCenter(
        center: sheetCenter,
        width: sheetSize.width * s,
        height: sheetSize.height * s,
      );

      canvas.drawRect(
        sheetMiniRect,
        Paint()
          ..color = const Color(0xFFF1F0EC)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        sheetMiniRect,
        Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Dibujar el viewport (rectángulo azul).
    final vpCenter = Offset(
      padding + drawWidth / 2 - (worldLeft + worldWidth / 2) * (drawWidth / worldWidth),
      padding + drawHeight / 2 - (worldTop + worldHeight / 2) * (drawHeight / worldHeight),
    );
    final vpWidth = viewportSize.width * (drawWidth / worldWidth);
    final vpHeight = viewportSize.height * (drawHeight / worldHeight);

    canvas.drawRect(
      Rect.fromCenter(center: vpCenter, width: vpWidth, height: vpHeight),
      Paint()
        ..color = kAccentColor.withAlpha(60)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromCenter(center: vpCenter, width: vpWidth, height: vpHeight),
      Paint()
        ..color = kAccentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  double max(double a, double b) => a > b ? a : b;

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.translate != translate ||
      oldDelegate.viewportSize != viewportSize;
}
