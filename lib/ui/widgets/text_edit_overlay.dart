// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/text_item.dart';
import '../canvas/world_painter.dart' show textItemAlign, textItemStyle;
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';

/// Edición en el lienzo de una caja de texto.
///
/// Muestra un campo de texto exactamente donde está la caja (mismo estilo
/// que al pintarla: [textItemStyle]) y, encima, una barra de formato:
/// negrita, cursiva, subrayado, alineación, familia, tamaño, enlace a
/// página y eliminar.
class TextEditOverlay extends StatefulWidget {
  const TextEditOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  final TextEditingController _textController = TextEditingController();
  String? _editingId;

  CanvasController get _c => widget.controller;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  TextItem? _currentItem() {
    final id = _c.editingTextId;
    if (id == null) return null;
    for (final t in _c.page.textItems) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Aplica un cambio de formato conservando el texto escrito.
  void _update(TextItem Function(TextItem) change) {
    final item = _currentItem();
    if (item == null) return;
    _c.updateTextItem(change(item.copyWith(text: _textController.text)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final item = _currentItem();
        if (item == null) {
          _editingId = null;
          return const SizedBox.shrink();
        }
        if (_editingId != item.id) {
          _editingId = item.id;
          _textController.text = item.text;
          _textController.selection =
              TextSelection.collapsed(offset: item.text.length);
        }

        final topLeft = _c.worldToViewport(
          Offset(item.x - item.width / 2, item.y - item.height / 2),
          _c.viewportSize,
        );
        final width = item.width * _c.scale;
        // La barra va encima de la caja; si no cabe, debajo del borde superior.
        final barTop = topLeft.dy - 56 < Spacing.sm ? Spacing.sm : topLeft.dy - 56;

        return Stack(
          children: [
            Positioned(
              left: topLeft.dx.clamp(Spacing.sm, double.infinity),
              top: barTop,
              // Misma "región" que el campo: tocar la barra no cuenta como
              // tocar fuera (si no, pulsar Negrita cerraría la edición).
              child: TextFieldTapRegion(
                child: _FormatBar(
                  item: item,
                  onUpdate: _update,
                  onLink: () => _showLinkPicker(item),
                  onDelete: () => _c.removeTextItem(item),
                ),
              ),
            ),
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: width,
              child: Material(
                color: context.inklus.paper.withValues(alpha: 0.94),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: Radii.smAll,
                  side: BorderSide(color: context.colors.primary, width: 1.5),
                ),
                child: TextField(
                  controller: _textController,
                  style: textItemStyle(item, scale: _c.scale),
                  textAlign: textItemAlign(item),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Escribe aquí…',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(Spacing.sm),
                    hintStyle: textItemStyle(item, scale: _c.scale)
                        .copyWith(color: Colors.black38),
                  ),
                  onChanged: (value) => _c.updateTextItem(item.copyWith(text: value)),
                  onTapOutside: (_) => _finishEditing(item),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _finishEditing(TextItem item) {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _c.removeTextItem(item); // una caja vacía no se guarda
    } else {
      _c.updateTextItem(item.copyWith(text: text));
      _c.commitTextItem(item);
    }
    _editingId = null;
  }

  /// Selector de página para convertir la caja en un enlace interno.
  void _showLinkPicker(TextItem item) {
    final pages = _c.pages;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Vincular a página', style: context.text.titleMedium),
            ),
            if (item.linkToPageId != null)
              ListTile(
                leading: Icon(Icons.link_off, color: context.inklus.danger),
                title: const Text('Quitar enlace'),
                onTap: () {
                  Navigator.pop(context);
                  _update((t) => t.copyWith(clearLink: true));
                },
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final linked = item.linkToPageId == page.id;
                  return ListTile(
                    leading: Icon(linked ? Icons.link : Icons.description_outlined),
                    title: Text(page.name),
                    subtitle: Text('Página ${index + 1}'),
                    selected: linked,
                    onTap: () {
                      Navigator.pop(context);
                      _update((t) => t.copyWith(linkToPageId: page.id));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de formato de la caja de texto.
class _FormatBar extends StatelessWidget {
  const _FormatBar({
    required this.item,
    required this.onUpdate,
    required this.onLink,
    required this.onDelete,
  });

  final TextItem item;
  final void Function(TextItem Function(TextItem)) onUpdate;
  final VoidCallback onLink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nextAlign = TextItem.alignments[
        (TextItem.alignments.indexOf(item.align) + 1) % TextItem.alignments.length];
    final nextFamily = TextItem.families[
        (TextItem.families.indexOf(item.fontFamily) + 1) % TextItem.families.length];
    return Material(
      color: context.colors.surfaceContainerHigh,
      elevation: 4,
      borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggle(context, Icons.format_bold, 'Negrita', item.bold,
                () => onUpdate((t) => t.copyWith(bold: !t.bold))),
            _toggle(context, Icons.format_italic, 'Cursiva', item.italic,
                () => onUpdate((t) => t.copyWith(italic: !t.italic))),
            _toggle(context, Icons.format_underlined, 'Subrayado', item.underline,
                () => onUpdate((t) => t.copyWith(underline: !t.underline))),
            IconButton(
              tooltip: 'Alineación',
              icon: Icon(switch (item.align) {
                'center' => Icons.format_align_center,
                'right' => Icons.format_align_right,
                _ => Icons.format_align_left,
              }),
              onPressed: () => onUpdate((t) => t.copyWith(align: nextAlign)),
            ),
            TextButton(
              onPressed: () => onUpdate((t) => t.copyWith(fontFamily: nextFamily)),
              child: Text(switch (item.fontFamily) {
                'serif' => 'Serif',
                'mono' => 'Mono',
                _ => 'Sans',
              }),
            ),
            IconButton(
              tooltip: 'Más pequeño',
              icon: const Icon(Icons.text_decrease),
              onPressed: () => onUpdate(
                  (t) => t.copyWith(fontSize: (t.fontSize - 2).clamp(8.0, 200.0))),
            ),
            Text('${item.fontSize.round()}', style: context.text.labelLarge),
            IconButton(
              tooltip: 'Más grande',
              icon: const Icon(Icons.text_increase),
              onPressed: () => onUpdate(
                  (t) => t.copyWith(fontSize: (t.fontSize + 2).clamp(8.0, 200.0))),
            ),
            IconButton(
              tooltip: item.linkToPageId != null ? 'Enlace a página (activo)' : 'Vincular a página',
              isSelected: item.linkToPageId != null,
              icon: const Icon(Icons.link),
              onPressed: onLink,
            ),
            IconButton(
              tooltip: 'Eliminar caja de texto',
              icon: Icon(Icons.delete_outline, color: context.inklus.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context, IconData icon, String label, bool on, VoidCallback onTap) =>
      IconButton(
        tooltip: label,
        isSelected: on,
        style: on
            ? IconButton.styleFrom(backgroundColor: context.colors.primaryContainer)
            : null,
        icon: Icon(icon),
        onPressed: onTap,
      );
}
