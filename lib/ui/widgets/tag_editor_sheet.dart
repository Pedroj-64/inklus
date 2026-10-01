// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import 'page_scaffold.dart';
import '../../l10n/l10n.dart';

/// Bottom sheet para gestionar las etiquetas de un cuaderno.
///
/// Muestra las etiquetas existentes del cuaderno como chips seleccionables,
/// permite crear nuevas etiquetas y eliminar las existentes.
Future<List<String>?> showTagEditor({
  required BuildContext context,
  required List<String> currentTags,
  required List<String> allAvailableTags,
}) async {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TagEditorSheet(
      currentTags: currentTags,
      allAvailableTags: allAvailableTags,
    ),
  );
}

class _TagEditorSheet extends StatefulWidget {
  final List<String> currentTags;
  final List<String> allAvailableTags;

  const _TagEditorSheet({
    required this.currentTags,
    required this.allAvailableTags,
  });

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late List<String> _selected;
  late List<String> _available;
  final _newTagController = TextEditingController();

  // Colores predefinidos para las etiquetas.
  static const _tagColors = [
    kAccentColor, // azul
    Color(0xFF10B981), // verde
    Color(0xFFF59E0B), // ámbar
    Color(0xFFEF4444), // rojo
    Color(0xFF8B5CF6), // morado
    Color(0xFFEC407A), // rosa
    Color(0xFF26C6DA), // turquesa
    Color(0xFF78909C), // gris
  ];

  Color _tagColor(String tag) {
    final idx = tag.hashCode.abs() % _tagColors.length;
    return _tagColors[idx];
  }

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentTags);
    // Filtrar tags disponibles que no estén ya seleccionadas.
    _available = widget.allAvailableTags
        .where((t) => !_selected.contains(t))
        .toList();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _selected.contains(trimmed)) return;
    setState(() {
      _selected.add(trimmed);
      _available.remove(trimmed);
    });
    _newTagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _selected.remove(tag);
      if (!_available.contains(tag)) _available.add(tag);
    });
  }

  void _toggleTag(String tag) {
    if (_selected.contains(tag)) {
      _removeTag(tag);
    } else {
      _addTag(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.text.titleSmall
        ?.copyWith(color: context.colors.onSurfaceVariant);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          Spacing.xl,
          0,
          Spacing.xl,
          Spacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          SheetHeader(
            icon: Icons.sell_outlined,
            title: context.l10n.tagTitle,
            subtitle: context.l10n.tagSubtitle,
          ),

          // Tags seleccionadas.
          if (_selected.isNotEmpty) ...[
            Text(context.l10n.tagActive, style: labelStyle),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final tag in _selected)
                  Chip(
                    label: Text(tag),
                    backgroundColor: _tagColor(tag).withAlpha(30),
                    labelStyle: context.text.labelLarge
                        ?.copyWith(color: _tagColor(tag)),
                    deleteIcon: Icon(Icons.close, size: 18, color: _tagColor(tag)),
                    onDeleted: () => _removeTag(tag),
                    side: BorderSide(color: _tagColor(tag).withAlpha(80)),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
          ],

          // Tags disponibles.
          if (_available.isNotEmpty) ...[
            Text(context.l10n.tagOthers, style: labelStyle),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final tag in _available)
                  ActionChip(
                    label: Text(tag),
                    onPressed: () => _toggleTag(tag),
                    avatar: Icon(Icons.add, size: 18, color: _tagColor(tag)),
                    labelStyle: context.text.labelLarge
                        ?.copyWith(color: context.colors.onSurface),
                    side: BorderSide(color: _tagColor(tag).withAlpha(60)),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
          ],

          // Crear nueva etiqueta.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newTagController,
                  decoration: InputDecoration(hintText: context.l10n.tagNew),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              IconButton.filled(
                tooltip: context.l10n.tagAdd,
                onPressed: () => _addTag(_newTagController.text),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed: () => Navigator.pop(context, _selected),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(Sizes.minTouch)),
            child: Text(context.l10n.tagSave),
          ),
        ],
      ),
    );
  }
}
