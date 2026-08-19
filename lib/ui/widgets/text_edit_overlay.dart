import '../../constants.dart';
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/text_item.dart';
import '../../utils/theme_colors.dart';

/// Overlay de edición de texto que se superpone al lienzo.
///
/// Muestra un TextField cuando el usuario está editando una caja de texto.
/// Se posiciona en coordenadas del viewport basándose en la posición mundo
/// del TextItem.
class TextEditOverlay extends StatefulWidget {
  final CanvasController controller;

  const TextEditOverlay({super.key, required this.controller});

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  final TextEditingController _textController = TextEditingController();
  TextItem? _editingItem;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final editingId = widget.controller.editingTextId;
        if (editingId == null) {
          _editingItem = null;
          return const SizedBox.shrink();
        }

        // Encuentra el item que se está editando.
        TextItem? item;
        for (final t in widget.controller.page.textItems) {
          if (t.id == editingId) {
            item = t;
            break;
          }
        }

        if (item == null) {
          return const SizedBox.shrink();
        }
        final currentItem = item;

        // Si cambió el item, actualiza el controlador de texto.
        if (_editingItem?.id != currentItem.id) {
          _editingItem = currentItem;
          _textController.text = currentItem.text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: item.text.length),
          );
        }

        // Convierte la posición mundo a viewport.
        final viewport = widget.controller.viewportSize;
        final viewportPos = widget.controller.worldToViewport(
          Offset(item.x - item.width / 2, item.y - item.height / 2),
          viewport,
        );
        final scaledWidth = item.width * widget.controller.scale;
        final fontSize = item.fontSize * widget.controller.scale;

        return Stack(
          children: [
            // Mini-toolbar con botón de enlace.
            Positioned(
              left: viewportPos.dx,
              top: viewportPos.dy - 36,
              child: Material(
                color: kAccentColor,
                borderRadius: BorderRadius.circular(20),
                elevation: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Vincular a página',
                      icon: Icon(
                        currentItem.linkToPageId != null ? Icons.link : Icons.link_off,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _showLinkPicker(currentItem),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
            // Campo de texto.
            Positioned(
              left: viewportPos.dx,
              top: viewportPos.dy,
              width: scaledWidth,
              child: Material(
                color: Colors.white.withAlpha(230),
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: IntrinsicHeight(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: item.color,
                      fontSize: fontSize,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí...',
                      hintStyle: TextStyle(
                        color: ThemeColors.of(context).border,
                        fontSize: fontSize,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(8),
                    ),
                    onChanged: (value) {
                      widget.controller.updateTextItem(
                        currentItem.copyWith(text: value),
                      );
                    },
                    onEditingComplete: () => _finishEditing(currentItem),
                    onSubmitted: (_) => _finishEditing(currentItem),
                  ),
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
      // Si está vacío, elimina la caja de texto.
      widget.controller.removeTextItem(item);
    } else {
      widget.controller.updateTextItem(item.copyWith(text: text));
      widget.controller.commitTextItem(item);
    }
    _editingItem = null;
  }

  /// Muestra el selector de página para vincular un enlace.
  void _showLinkPicker(TextItem item) {
    final doc = widget.controller.document;
    showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vincular a página',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (item.linkToPageId != null)
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text('Quitar enlace'),
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.updateTextItem(
                    item.copyWith(linkToPageId: null),
                  );
                },
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: doc.pages.length,
                itemBuilder: (context, index) {
                  final page = doc.pages[index];
                  final isLinked = item.linkToPageId == page.id;
                  return ListTile(
                    leading: Icon(
                      isLinked ? Icons.link : Icons.description_outlined,
                      color: isLinked ? kAccentColor : null,
                    ),
                    title: Text(page.name),
                    subtitle: Text('Página ${index + 1}'),
                    trailing: isLinked
                        ? const Icon(Icons.check, color: kAccentColor)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.controller.updateTextItem(
                        item.copyWith(linkToPageId: page.id),
                      );
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
