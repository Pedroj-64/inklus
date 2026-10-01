// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import '../theme/inklus_colors.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../models/page.dart';
import 'dialogs.dart';
import '../../l10n/l10n.dart';

/// Sidebar docked para gestión de capas.
///
/// Se muestra como panel fijo a la izquierda del canvas (~240px).
/// Empuja/reduce el canvas (patrón Canva) en vez de superponerse.
/// Soporta: visibilidad, bloqueo, opacidad, renombrar, reordenar, eliminar.
class LayersSidebar extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onClose;

  const LayersSidebar({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.page.layers;
        final activeIdx = controller.activeLayerIndex;

        return Container(
          width: 240,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            border: Border(
              right: BorderSide(
                color: context.colors.outlineVariant,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
                child: Row(
                  children: [
                    Icon(Icons.layers, size: 18, color: context.colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.tbLayers,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: context.l10n.layerAdd,
                      onPressed: () => controller.addLayer(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: context.l10n.commonClose,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Lista de capas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  itemCount: layers.length,
                  itemBuilder: (context, i) {
                    final layer = layers[i];
                    final isActive = i == activeIdx;
                    return _LayerTile(
                      layer: layer,
                      index: i,
                      isActive: isActive,
                      isDefault: i == 0,
                      onToggleVisibility: () =>
                          controller.toggleLayerVisibility(i),
                      onToggleLocked: () => controller.toggleLayerLocked(i),
                      onSelect: () => controller.setActiveLayer(i),
                      onRename: () => _renameLayer(context, i),
                      onDelete: layers.length > 1 && i != 0
                          ? () => controller.removeLayer(i)
                          : null,
                      onOpacityChanged: (v) =>
                          controller.setLayerOpacity(i, v),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameLayer(BuildContext context, int index) async {
    final name = await showTextPrompt(
      context,
      title: context.l10n.layerRename,
      hint: context.l10n.createName,
      initialValue: controller.page.layers[index].name,
      confirmLabel: context.l10n.libRename,
    );
    if (name != null && name.trim().isNotEmpty) {
      controller.renameLayer(index, name.trim());
    }
  }
}

/// Tile individual de una capa con controles de visibilidad, bloqueo y opacidad.
class _LayerTile extends StatelessWidget {
  final Layer layer;
  final int index;
  final bool isActive;
  final bool isDefault;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLocked;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback? onDelete;
  final ValueChanged<double> onOpacityChanged;

  const _LayerTile({
    required this.layer,
    required this.index,
    required this.isActive,
    required this.isDefault,
    required this.onToggleVisibility,
    required this.onToggleLocked,
    required this.onSelect,
    required this.onRename,
    this.onDelete,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                ? kAccentDark.withAlpha(80)
                : const Color(0xFFE3EDFF))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? context.colors.primary
              : context.colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        onLongPress: onRename,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila principal: nombre + controles
              Row(
                children: [
                  // Índice de capa
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.colors.primary
                          : context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Nombre
                  Expanded(
                    child: Text(
                      layer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  // Visibilidad
                  GestureDetector(
                    onTap: onToggleVisibility,
                    child: Icon(
                      layer.visible ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                      color: layer.visible
                          ? context.colors.primary
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Bloqueo
                  GestureDetector(
                    onTap: onToggleLocked,
                    child: Icon(
                      layer.locked ? Icons.lock : Icons.lock_open,
                      size: 18,
                      color: layer.locked ? context.inklus.warning : context.colors.onSurfaceVariant,
                    ),
                  ),
                  // Eliminar
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: context.inklus.danger,
                      ),
                    ),
                  ],
                ],
              ),
              // Slider de opacidad
              if (layer.opacity < 1.0 || isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.opacity,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: layer.opacity,
                            min: 0.0,
                            max: 1.0,
                            onChanged: onOpacityChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${(layer.opacity * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
