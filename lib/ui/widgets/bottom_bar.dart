import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';

/// Paleta de colores por defecto.
const kPalette = <Color>[
  Color(0xFF1A1A1A),
  Color(0xFF6B7280),
  Color(0xFFB3261E),
  Color(0xFFE8590C),
  Color(0xFFF5A623),
  Color(0xFF37B24D),
  Color(0xFF0CA678),
  Color(0xFF1C7ED6),
  Color(0xFF4263EB),
  Color(0xFF7048E8),
  Color(0xFFD6336C),
  Color(0xFF8D6E63),
];

const _toolLabels = {
  ToolType.pen: 'Lapicero',
  ToolType.pencil: 'Lápiz',
  ToolType.highlighter: 'Resaltador',
  ToolType.eraser: 'Borrador',
  ToolType.select: '',
};

/// Barra inferior: color + tamaño + opciones de escritura.
class BottomBar extends StatelessWidget {
  final CanvasController controller;

  const BottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isEraser = controller.tool == ToolType.eraser;
        final isSelect = controller.tool == ToolType.select;
        final range = controller.sizeRange;
        return Material(
          color: Colors.white,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // ---- Paleta de colores (oculta con borrador/selección) ----
                if (!isEraser && !isSelect) ...[
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kPalette.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          if (i == kPalette.length) {
                            return _CustomColorSwatch(
                              controller: controller,
                            );
                          }
                          final color = kPalette[i];
                          return _ColorSwatch(
                            color: color,
                            selected: controller.color == color,
                            onTap: () => controller.setColor(color),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // ---- Tamaño de la herramienta ----
                if (!isSelect) ...[
                  const Icon(Icons.tune, size: 20, color: Colors.black54),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 190,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEraser
                              ? 'Tamaño borrador'
                              : 'Tamaño ${_toolLabels[controller.tool]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Slider(
                          value: controller.toolSize,
                          min: range.$1,
                          max: range.$2,
                          onChanged: controller.setToolSize,
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // ---- Dibujar con el dedo (alternable) ----
                Tooltip(
                  message: controller.fingerDrawingEnabled
                      ? 'Dibujo con dedo: activado'
                      : 'Dibujo con dedo: desactivado (solo stylus)',
                  child: IconButton(
                    onPressed: () => controller.setFingerDrawing(
                      !controller.fingerDrawingEnabled,
                    ),
                    icon: Icon(
                      controller.fingerDrawingEnabled
                          ? Icons.back_hand
                          : Icons.back_hand_outlined,
                      color: controller.fingerDrawingEnabled
                          ? const Color(0xFF3B82F6)
                          : Colors.black38,
                    ),
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

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CustomColorSwatch extends StatelessWidget {
  final CanvasController controller;

  const _CustomColorSwatch({required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCustomColorDialog(context, controller),
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
        ),
        child: const Icon(Icons.add, size: 18, color: Colors.white),
      ),
    );
  }
}

/// Diálogo de color personalizado (Matiz/Saturación/Valor).
Future<void> showCustomColorDialog(
  BuildContext context,
  CanvasController controller,
) async {
  var hsv = HSVColor.fromColor(controller.color);
  final result = await showDialog<Color>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Color personalizado'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hsv.toColor(),
                  border: Border.all(color: Colors.black26),
                ),
              ),
              const SizedBox(height: 12),
              _HsvSlider(
                label: 'Matiz',
                value: hsv.hue,
                min: 0,
                max: 360,
                onChanged: (v) => setState(() => hsv = hsv.withHue(v)),
              ),
              _HsvSlider(
                label: 'Saturación',
                value: hsv.saturation,
                min: 0,
                max: 1,
                onChanged: (v) => setState(() => hsv = hsv.withSaturation(v)),
              ),
              _HsvSlider(
                label: 'Brillo',
                value: hsv.value,
                min: 0,
                max: 1,
                onChanged: (v) => setState(() => hsv = hsv.withValue(v)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, hsv.toColor()),
            child: const Text('Usar'),
          ),
        ],
      ),
    ),
  );
  if (result != null) controller.setColor(result);
}

class _HsvSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _HsvSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
