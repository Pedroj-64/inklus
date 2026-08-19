import '../../constants.dart';
import 'package:flutter/material.dart';
import '../../utils/theme_colors.dart';

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
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Etiquetas del cuaderno',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tags seleccionadas.
            if (_selected.isNotEmpty) ...[
              Text(
                'Etiquetas activas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selected.map((tag) {
                  final color = _tagColor(tag);
                  return Chip(
                    label: Text(tag),
                    backgroundColor: color.withAlpha(30),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    deleteIcon: Icon(Icons.close, size: 18, color: color),
                    onDeleted: () => _removeTag(tag),
                    side: BorderSide(color: color.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Tags disponibles.
            if (_available.isNotEmpty) ...[
              Text(
                'Otras etiquetas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _available.map((tag) {
                  final color = _tagColor(tag);
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () => _toggleTag(tag),
                    backgroundColor: color.withAlpha(15),
                    labelStyle: TextStyle(
                      color: color.withAlpha(180),
                      fontSize: 13,
                    ),
                    side: BorderSide(color: color.withAlpha(40)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Crear nueva etiqueta.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    decoration: InputDecoration(
                      hintText: 'Nueva etiqueta...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withAlpha(80),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _addTag(_newTagController.text),
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botón guardar.
            FilledButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: kAccentColor,
              ),
              child: const Text('Guardar etiquetas'),
            ),
          ],
        ),
      ),
    );
  }
}
