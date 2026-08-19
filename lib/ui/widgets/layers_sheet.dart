import '../../constants.dart';
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/page.dart';

/// Panel de gestión de capas de la página actual.
///
/// Muestra la lista de capas con opciones de visibilidad, bloqueo,
/// renombrar, añadir y eliminar.
Future<void> showLayersSheet(
  BuildContext context, {
  required CanvasController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _LayersSheet(controller: controller),
  );
}

class _LayersSheet extends StatelessWidget {
  final CanvasController controller;

  const _LayersSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.page.layers;
        final activeIdx = controller.activeLayerIndex;

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
              Row(
                children: [
                  const Text(
                    'Capas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      controller.addLayer();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Añadir capa',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Capa activa: toca para seleccionar. Mantén para opciones.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
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
                    onSelect: () {
                      controller.setActiveLayer(i);
                      Navigator.pop(context);
                    },
                    onRename: () => _renameLayer(context, controller, i),
                    onDelete: layers.length > 1 && i != 0
                        ? () {
                            controller.removeLayer(i);
                            Navigator.pop(context);
                          }
                        : null,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _renameLayer(
      BuildContext context, CanvasController controller, int index) {
    final ctrl = TextEditingController(text: controller.page.layers[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar capa'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              controller.renameLayer(index, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Renombrar'),
          ),
        ],
      ),
    );
  }
}

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
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      onLongPress: onRename,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? kAccentColor : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            // Índice de capa.
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive
                    ? kAccentColor
                    : Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre.
            Expanded(
              child: Text(
                layer.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            // Botón de visibilidad.
            IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                layer.visible ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: layer.visible ? kAccentColor : Colors.black38,
              ),
              tooltip: layer.visible ? 'Ocultar capa' : 'Mostrar capa',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // Botón de bloqueo.
            IconButton(
              onPressed: onToggleLocked,
              icon: Icon(
                layer.locked ? Icons.lock : Icons.lock_open,
                size: 20,
                color: layer.locked ? Colors.orange : Colors.black38,
              ),
              tooltip: layer.locked ? 'Desbloquear' : 'Bloquear',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // Botón de eliminar (no para la capa 0).
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                tooltip: 'Eliminar capa',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }
}
