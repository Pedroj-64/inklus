import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';
import '../../utils/theme_colors.dart';

/// Barra vertical de herramientas colapsable tipo Canva.
///
/// Cuando está colapsada solo muestra el icono de la herramienta activa
/// y un botón para expandir. Cuando está expandida, muestra todas las
/// herramientas con un botón para colapsar.
class ToolRail extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onInsertImage;
  final VoidCallback onTemplates;
  final VoidCallback onLayers;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final bool layersSidebarOpen;

  const ToolRail({
    super.key,
    required this.controller,
    required this.onInsertImage,
    required this.onTemplates,
    required this.onLayers,
    this.collapsed = false,
    required this.onToggleCollapsed,
    this.layersSidebarOpen = false,
  });

  /// Icono de la herramienta activa (para modo colapsado).
  IconData _toolIcon(ToolType tool, bool rulerEnabled, bool magnifierEnabled) {
    if (rulerEnabled) return Icons.straighten;
    if (magnifierEnabled) return Icons.search;
    switch (tool) {
      case ToolType.select:
        return Icons.pan_tool_alt;
      case ToolType.pen:
        return Icons.edit;
      case ToolType.pencil:
        return Icons.create;
      case ToolType.highlighter:
        return Icons.border_color;
      case ToolType.calligraphy:
        return Icons.brush;
      case ToolType.brush:
        return Icons.format_paint;
      case ToolType.eraser:
        return Icons.cleaning_services;
      case ToolType.lasso:
        return Icons.score;
      case ToolType.bucket:
        return Icons.format_color_fill;
      case ToolType.text:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (collapsed) {
          return _CollapsedRail(
            icon: _toolIcon(
              controller.tool,
              controller.rulerEnabled,
              controller.magnifierEnabled,
            ),
            isDark: isDark,
            onExpand: onToggleCollapsed,
          );
        }

        return _ExpandedRail(
          controller: controller,
          isDark: isDark,
          onInsertImage: onInsertImage,
          onTemplates: onTemplates,
          onLayers: onLayers,
          onCollapse: onToggleCollapsed,
          layersSidebarOpen: layersSidebarOpen,
        );
      },
    );
  }
}

/// Versión colapsada: solo el icono de herramienta activa + botón expandir.
class _CollapsedRail extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onExpand;

  const _CollapsedRail({
    required this.icon,
    required this.isDark,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          // Icono de herramienta activa
          _ToolButton(
            icon: icon,
            tooltip: 'Herramienta activa',
            selected: true,
            onTap: onExpand,
          ),
          // Botón expandir
          _ToolButton(
            icon: Icons.chevron_right,
            tooltip: 'Expandir barra',
            onTap: onExpand,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Versión expandida: todas las herramientas + botón colapsar.
class _ExpandedRail extends StatelessWidget {
  final CanvasController controller;
  final bool isDark;
  final VoidCallback onInsertImage;
  final VoidCallback onTemplates;
  final VoidCallback onLayers;
  final VoidCallback onCollapse;
  final bool layersSidebarOpen;

  const _ExpandedRail({
    required this.controller,
    required this.isDark,
    required this.onInsertImage,
    required this.onTemplates,
    required this.onLayers,
    required this.onCollapse,
    this.layersSidebarOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        width: 56,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            // Botón colapsar
            _ToolButton(
              icon: Icons.chevron_left,
              tooltip: 'Colapsar barra',
              onTap: onCollapse,
            ),
            // Grupo: selección
            _ToolButton(
              icon: Icons.pan_tool_alt,
              tooltip: 'Seleccionar / mover',
              selected: controller.tool == ToolType.select,
              onTap: () => controller.setTool(ToolType.select),
            ),
            // Grupo: escritura
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
              icon: Icons.brush,
              tooltip: 'Caligrafía',
              selected: controller.tool == ToolType.calligraphy,
              onTap: () => controller.setTool(ToolType.calligraphy),
            ),
            _ToolButton(
              icon: Icons.format_paint,
              tooltip: 'Pincel',
              selected: controller.tool == ToolType.brush,
              onTap: () => controller.setTool(ToolType.brush),
            ),
            // Grupo: borrador y selección
            _ToolButton(
              icon: Icons.cleaning_services,
              tooltip: 'Borrador',
              selected: controller.tool == ToolType.eraser,
              onTap: () => controller.setTool(ToolType.eraser),
            ),
            _ToolButton(
              icon: Icons.score,
              tooltip: 'Lazo',
              selected: controller.tool == ToolType.lasso,
              onTap: () => controller.setTool(ToolType.lasso),
            ),
            _ToolButton(
              icon: Icons.format_color_fill,
              tooltip: 'Rellenar (bucket)',
              selected: controller.tool == ToolType.bucket,
              onTap: () => controller.setTool(ToolType.bucket),
            ),
            // Separador visual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            // Grupo: herramientas especiales
            _ToolButton(
              icon: controller.rulerType == RulerType.protractor
                  ? Icons.contrast
                  : Icons.straighten,
              tooltip: controller.rulerType == RulerType.protractor
                  ? 'Transportador'
                  : 'Regla virtual',
              selected: controller.rulerEnabled,
              onTap: controller.cycleRulerType,
            ),
            _ToolButton(
              icon: Icons.search,
              tooltip: 'Lupa',
              selected: controller.magnifierEnabled,
              onTap: controller.toggleMagnifier,
            ),
            // Separador visual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            // Grupo: insertar
            _ToolButton(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: 'Insertar imagen',
              onTap: onInsertImage,
            ),
            _ToolButton(
              icon: Icons.dashboard_customize_outlined,
              tooltip: 'Plantillas',
              onTap: onTemplates,
            ),
            _ToolButton(
              icon: layersSidebarOpen ? Icons.layers : Icons.layers_outlined,
              tooltip: layersSidebarOpen ? 'Cerrar capas' : 'Capas',
              selected: layersSidebarOpen,
              onTap: onLayers,
            ),
            _ToolButton(
              icon: Icons.text_fields,
              tooltip: 'Texto',
              selected: controller.tool == ToolType.text,
              onTap: () => controller.setTool(ToolType.text),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        selected ? kAccentColor : (isDark ? Colors.white60 : ThemeColors.of(context).textSecondary);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? kAccentDark : kAccentLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
