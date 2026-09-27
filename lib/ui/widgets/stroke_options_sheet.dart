// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';
import '../editor/tool_visuals.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import 'page_scaffold.dart';

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
        final isEditable = tool != ToolType.eraser && tool != ToolType.select;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetHeader(
                  icon: ToolVisuals.icon(tool),
                  title: 'Opciones de ${ToolVisuals.label(tool).toLowerCase()}',
                  subtitle: 'Presión, suavizado y fluidez del trazo',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                  child: !isEditable
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
                          child: Text(
                            'El borrador y la selección no tienen opciones de trazo.',
                            style: context.text.bodyLarge
                                ?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tamaño rápido', style: context.text.titleSmall),
                            const SizedBox(height: Spacing.sm),
                            _QuickSizeRow(
                              currentSize: controller.toolSize,
                              onSelected: controller.setToolSize,
                              tool: tool,
                            ),
                            const SizedBox(height: Spacing.lg),
                            _OptionSlider(
                              label: 'Variación con la presión',
                              value: controller.thinning,
                              min: -1,
                              max: 1,
                              icon: Icons.straighten,
                              description: 'Cuánto cambia el grosor al apretar',
                              onChanged: controller.setThinning,
                            ),
                            _OptionSlider(
                              label: 'Suavizado',
                              value: controller.smoothing,
                              min: 0,
                              max: 1,
                              icon: Icons.waves,
                              description: 'Redondea las curvas del trazo',
                              onChanged: controller.setSmoothing,
                            ),
                            _OptionSlider(
                              label: 'Estabilizador',
                              value: controller.streamline,
                              min: 0,
                              max: 1,
                              icon: Icons.speed,
                              description: 'Reduce el temblor del pulso',
                              onChanged: controller.setStreamline,
                            ),
                          ],
                        ),
                ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.primary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.titleSmall),
                    Text(
                      description,
                      style: context.text.bodySmall
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: context.text.labelLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
          Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Fila de tamaños rápidos (presets por herramienta).
class _QuickSizeRow extends StatelessWidget {
  final double currentSize;
  final ValueChanged<double> onSelected;
  final ToolType tool;

  const _QuickSizeRow({
    required this.currentSize,
    required this.onSelected,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    final presets = switch (tool) {
      ToolType.highlighter => [(8.0, 'Fino'), (16.0, 'Medio'), (24.0, 'Grueso'), (40.0, 'Extra')],
      ToolType.pen => [(1.0, '0.5'), (2.0, '1.0'), (3.5, '2.0'), (5.0, '3.0'), (8.0, '5.0')],
      ToolType.pencil => [(1.0, 'HB'), (2.0, '2B'), (4.0, '4B'), (7.0, '6B')],
      ToolType.eraser => [(4.0, 'Pequeño'), (12.0, 'Medio'), (24.0, 'Grande'), (48.0, 'Extra')],
      _ => [(2.0, 'Fino'), (5.0, 'Medio'), (10.0, 'Grueso'), (20.0, 'Extra')],
    };

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final (size, label) in presets)
          ChoiceChip(
            showCheckmark: false,
            selected: (currentSize - size).abs() < 0.5,
            onSelected: (_) => onSelected(size),
            avatar: Container(
              width: size.clamp(4.0, 18.0),
              height: size.clamp(4.0, 18.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.onSurface,
              ),
            ),
            label: Text(label),
          ),
      ],
    );
  }
}
