// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/stroke.dart';

/// Icono y nombre visible de cada herramienta. **Única fuente**: la barra,
/// los popovers y las etiquetas de accesibilidad leen de aquí.
abstract final class ToolVisuals {
  static IconData icon(ToolType tool) => switch (tool) {
        ToolType.pen => Icons.edit,
        ToolType.pencil => Icons.draw,
        ToolType.calligraphy => Icons.history_edu,
        ToolType.brush => Icons.brush,
        ToolType.marker => Icons.format_paint,
        ToolType.spray => Icons.grain,
        ToolType.highlighter => Icons.border_color,
        ToolType.eraser => Icons.cleaning_services,
        ToolType.select => Icons.pan_tool_alt,
        ToolType.lasso => Icons.gesture,
        ToolType.bucket => Icons.format_color_fill,
        ToolType.text => Icons.text_fields,
      };

  static String label(BuildContext context, ToolType tool) => switch (tool) {
        ToolType.pen => context.l10n.toolPen,
        ToolType.pencil => context.l10n.toolPencil,
        ToolType.calligraphy => context.l10n.toolCalligraphy,
        ToolType.brush => context.l10n.toolBrush,
        ToolType.marker => context.l10n.toolMarker,
        ToolType.spray => context.l10n.toolSpray,
        ToolType.highlighter => context.l10n.popHighlighter,
        ToolType.eraser => context.l10n.toolEraser,
        ToolType.select => context.l10n.toolSelect,
        ToolType.lasso => context.l10n.toolLasso,
        ToolType.bucket => context.l10n.toolFill,
        ToolType.text => context.l10n.toolText,
      };


  /// Herramientas de tinta que puede usar una pluma favorita.
  static const penTools = [
    ToolType.pen,
    ToolType.pencil,
    ToolType.calligraphy,
    ToolType.brush,
    ToolType.marker,
    ToolType.spray,
  ];
}
