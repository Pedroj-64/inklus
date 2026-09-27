// SPDX-License-Identifier: GPL-3.0-or-later
import '../../constants.dart';
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';
import '../../utils/theme_colors.dart';

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
          ToolType.calligraphy: 'Caligrafía',
          ToolType.brush: 'Pincel',
          ToolType.eraser: 'Borrador',
          ToolType.select: 'Selección',
          ToolType.lasso: 'Lazo',
          ToolType.bucket: 'Relleno',
          ToolType.text: 'Texto',
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
              SizedBox(height: 4),
              Text(
                'Ajusta la presión, suavizado y fluidez del trazo.',
                style: TextStyle(fontSize: 12, color: ThemeColors.of(context).textSecondary),
              ),
              const SizedBox(height: 16),
              if (!isEditable)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'El borrador y la selección no tienen opciones de trazo.',
                      style: TextStyle(color: ThemeColors.of(context).iconTertiary),
                    ),
                  ),
                )
              else ...[
                // Tamaño rápido (presets estilo Krita)
                const Text(
                  'Tamaño rápido',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _QuickSizeRow(
                  currentSize: controller.toolSize,
                  onSelected: controller.setToolSize,
                  tool: tool,
                ),
                const SizedBox(height: 16),
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
            Icon(icon, size: 18, color: kAccentColor),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeColors.of(context).textHint,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(                  value.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.of(context).textSecondary,
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

/// Fila de tamaños rápidos (presets estilo Krita).
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
    // Presets adaptados por herramienta
    List<(double, String)> presets;
    if (tool == ToolType.highlighter) {
      presets = [(8.0, 'Fino'), (16.0, 'Medio'), (24.0, 'Grueso'), (40.0, 'Extra')];
    } else if (tool == ToolType.pen) {
      presets = [(1.0, '0.5'), (2.0, '1.0'), (3.5, '2.0'), (5.0, '3.0'), (8.0, '5.0')];
    } else if (tool == ToolType.pencil) {
      presets = [(1.0, 'HB'), (2.0, '2B'), (4.0, '4B'), (7.0, '6B')];
    } else if (tool == ToolType.eraser) {
      presets = [(4.0, 'Pequeño'), (12.0, 'Medio'), (24.0, 'Grande'), (48.0, 'Extra')];
    } else {
      presets = [(2.0, 'Fino'), (5.0, 'Medio'), (10.0, 'Grueso'), (20.0, 'Extra')];
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (size, label) = presets[index];
          final isSelected = (currentSize - size).abs() < 0.5;
          return GestureDetector(
            onTap: () => onSelected(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kAccentColor.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? kAccentColor : ThemeColors.of(context).borderLight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Círculo proporcional al tamaño
                  Container(
                    width: size.clamp(4.0, 20.0),
                    height: size.clamp(4.0, 20.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? kAccentColor : ThemeColors.of(context).textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? kAccentColor : ThemeColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
