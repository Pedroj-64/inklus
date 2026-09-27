// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

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

  static String label(ToolType tool) => switch (tool) {
        ToolType.pen => 'Bolígrafo',
        ToolType.pencil => 'Lápiz',
        ToolType.calligraphy => 'Pluma caligráfica',
        ToolType.brush => 'Pincel',
        ToolType.marker => 'Marcador',
        ToolType.spray => 'Aerosol',
        ToolType.highlighter => 'Resaltador',
        ToolType.eraser => 'Borrador',
        ToolType.select => 'Mover / seleccionar',
        ToolType.lasso => 'Lazo',
        ToolType.bucket => 'Rellenar',
        ToolType.text => 'Texto',
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
