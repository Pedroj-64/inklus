import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';

/// Barra vertical de herramientas.
class ToolRail extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onInsertImage;
  final VoidCallback onTemplates;
  final VoidCallback onLayers;

  const ToolRail({
    super.key,
    required this.controller,
    required this.onInsertImage,
    required this.onTemplates,
    required this.onLayers,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Material(
          color: Colors.white,
          elevation: 2,
          child: Container(
            width: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolButton(
                  icon: Icons.pan_tool_alt,
                  tooltip: 'Seleccionar / mover imágenes',
                  selected: controller.tool == ToolType.select,
                  onTap: () => controller.setTool(ToolType.select),
                ),
                _ToolButton(
                  icon: Icons.edit,
                  tooltip: 'Lapicero',
                  selected: controller.tool == ToolType.pen,
                  onTap: () => controller.setTool(ToolType.pen),
                ),
                _ToolButton(
                  icon: Icons.create,
                  tooltip: 'Lápiz (presión)',
                  selected: controller.tool == ToolType.pencil,
                  onTap: () => controller.setTool(ToolType.pencil),
                ),
                _ToolButton(
                  icon: Icons.border_color,
                  tooltip: 'Resaltador',
                  selected: controller.tool == ToolType.highlighter,
                  onTap: () => controller.setTool(ToolType.highlighter),
                ),
                _ToolButton(
                  icon: Icons.cleaning_services,
                  tooltip: 'Borrador',
                  selected: controller.tool == ToolType.eraser,
                  onTap: () => controller.setTool(ToolType.eraser),
                ),
                _ToolButton(
                  icon: Icons.score,
                  tooltip: 'Selección con lazo',
                  selected: controller.tool == ToolType.lasso,
                  onTap: () => controller.setTool(ToolType.lasso),
                ),
                _ToolButton(
                  icon: Icons.format_color_fill,
                  tooltip: 'Rellenar área (bucket)',
                  selected: controller.tool == ToolType.bucket,
                  onTap: () => controller.setTool(ToolType.bucket),
                ),
                const Divider(height: 16),
                _ToolButton(
                  icon: Icons.add_photo_alternate_outlined,
                  tooltip: 'Insertar imagen del dispositivo',
                  onTap: onInsertImage,
                ),
                _ToolButton(
                  icon: Icons.dashboard_customize_outlined,
                  tooltip: 'Plantillas',
                  onTap: onTemplates,
                ),
                _ToolButton(
                  icon: Icons.layers_outlined,
                  tooltip: 'Capas',
                  onTap: onLayers,
                ),
                _ToolButton(
                  icon: Icons.text_fields,
                  tooltip: 'Caja de texto',
                  selected: controller.tool == ToolType.text,
                  onTap: () => controller.setTool(ToolType.text),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF3B82F6) : const Color(0xFF444444);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: selected ? const Color(0xFFE3EDFF) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
