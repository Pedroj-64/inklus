import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/text_item.dart';

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

        // Si cambió el item, actualiza el controlador de texto.
        if (_editingItem?.id != item.id) {
          _editingItem = item;
          _textController.text = item.text;
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

        return Positioned(
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
                    color: Colors.black26,
                    fontSize: fontSize,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(8),
                ),
                onChanged: (value) {
                  final current = item;
                  if (current != null) {
                    widget.controller.updateTextItem(
                      current.copyWith(text: value),
                    );
                  }
                },
                onEditingComplete: () {
                  final current = item;
                  if (current != null) _finishEditing(current);
                },
                onSubmitted: (_) {
                  final current = item;
                  if (current != null) _finishEditing(current);
                },
              ),
            ),
          ),
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
}
