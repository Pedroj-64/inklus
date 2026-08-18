import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';

/// Panel de opciones de escritura: ajusta los parámetros de presión,
/// suavizado y streamline de la herramienta actual.
///
/// Se abre como bottom sheet desde la barra inferior.
Future<void> showStrokeOptionsSheet(
  BuildContext context, {
  required CanvasController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _StrokeOptionsSheet(controller: controller),
  );
}

class _StrokeOptionsSheet extends StatelessWidget {
  final CanvasController controller;

  const _StrokeOptionsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tool = controller.tool;
        final isEditable =
            tool != ToolType.eraser && tool != ToolType.select;

        final toolNames = {
          ToolType.pen: 'Lapicero',
          ToolType.pencil: 'Lápiz',
          ToolType.highlighter: 'Resaltador',
          ToolType.eraser: 'Borrador',
          ToolType.select: 'Selección',
        };

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opciones de ${toolNames[tool] ?? tool.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ajusta la presión, suavizado y fluidez del trazo.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              if (!isEditable)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'El borrador y la selección no tienen opciones de trazo.',
                      style: TextStyle(color: Colors.black38),
                    ),
                  ),
                )
              else ...[
                _OptionSlider(
                  label: 'Delgadez (thinning)',
                  value: controller.thinning,
                  min: -1,
                  max: 1,
                  icon: Icons.straighten,
                  description: 'Variación del grosor según presión',
                  onChanged: controller.setThinning,
                ),
                const SizedBox(height: 12),
                _OptionSlider(
                  label: 'Suavizado (smoothing)',
                  value: controller.smoothing,
                  min: 0,
                  max: 1,
                  icon: Icons.waves,
                  description: 'Suaviza las curvas del trazo',
                  onChanged: controller.setSmoothing,
                ),
                const SizedBox(height: 12),
                _OptionSlider(
                  label: 'Fluidez (streamline)',
                  value: controller.streamline,
                  min: 0,
                  max: 1,
                  icon: Icons.speed,
                  description: 'Reduce el temblor del trazo',
                  onChanged: controller.setStreamline,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _OptionSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final String description;
  final ValueChanged<double> onChanged;

  const _OptionSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                value.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
