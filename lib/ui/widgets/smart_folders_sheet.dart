import '../../constants.dart';
import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../utils/theme_colors.dart';

/// Tipo de carpeta dinámica.
enum SmartFolderType {
  all('Todos', Icons.folder_outlined),
  recent('Recientes', Icons.access_time),
  thisWeek('Esta semana', Icons.date_range),
  byColor('Por color', Icons.palette_outlined),
  byTag('Por etiqueta', Icons.label_outline),
  noTags('Sin etiquetas', Icons.label_off_outlined);

  final String label;
  final IconData icon;
  const SmartFolderType(this.label, this.icon);
}

/// Carpeta dinámica con su filtro aplicado.
class SmartFolder {
  final SmartFolderType type;
  final String? tagFilter;
  final int? colorFilter;

  const SmartFolder({
    required this.type,
    this.tagFilter,
    this.colorFilter,
  });

  String get displayName {
    switch (type) {
      case SmartFolderType.all:
        return 'Todos';
      case SmartFolderType.recent:
        return 'Recientes';
      case SmartFolderType.thisWeek:
        return 'Esta semana';
      case SmartFolderType.byColor:
        return colorFilter != null ? _colorName(colorFilter!) : 'Por color';
      case SmartFolderType.byTag:
        return tagFilter ?? 'Por etiqueta';
      case SmartFolderType.noTags:
        return 'Sin etiquetas';
    }
  }

  String _colorName(int color) {
    switch (color) {
      case 0xFF3B82F6: return 'Azul'; // kAccentColor.toARGB32()
      case 0xFF4CAF50: return 'Verde';
      case 0xFFE53935: return 'Rojo';
      case 0xFFFF9800: return 'Naranja';
      case 0xFF9C27B0: return 'Morado';
      case 0xFFEC407A: return 'Rosa';
      case 0xFF26C6DA: return 'Turquesa';
      case 0xFF78909C: return 'Gris';
      default: return 'Otro';
    }
  }

  /// Filtra la lista de metas según el criterio de esta carpeta.
  List<NotebookMeta> apply(List<NotebookMeta> metas) {
    switch (type) {
      case SmartFolderType.all:
        return metas;
      case SmartFolderType.recent:
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        return metas.where((m) => m.updatedAt.isAfter(cutoff)).toList();
      case SmartFolderType.thisWeek:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return metas.where((m) => m.updatedAt.isAfter(start)).toList();
      case SmartFolderType.byColor:
        if (colorFilter == null) return metas;
        return metas.where((m) => m.colorValue == colorFilter).toList();
      case SmartFolderType.byTag:
        if (tagFilter == null) return metas;
        return metas.where((m) => m.tags.contains(tagFilter)).toList();
      case SmartFolderType.noTags:
        return metas.where((m) => m.tags.isEmpty).toList();
    }
  }
}

/// Muestra un bottom sheet con las carpetas dinámicas disponibles.
///
/// Devuelve la carpeta seleccionada o null si se cancela.
Future<SmartFolder?> showSmartFoldersSheet({
  required BuildContext context,
  required List<NotebookMeta> metas,
  required SmartFolder? currentFolder,
}) async {
  // Recopilar todas las etiquetas únicas de todos los cuadernos.
  final allTags = <String>{};
  final allColors = <int>{};
  for (final m in metas) {
    allTags.addAll(m.tags);
    if (m.colorValue != null) allColors.add(m.colorValue!);
  }

  return showModalBottomSheet<SmartFolder>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SmartFoldersSheet(
      metas: metas,
      allTags: allTags.toList()..sort(),
      allColors: allColors.toList(),
      currentFolder: currentFolder,
    ),
  );
}

class _SmartFoldersSheet extends StatelessWidget {
  final List<NotebookMeta> metas;
  final List<String> allTags;
  final List<int> allColors;
  final SmartFolder? currentFolder;

  const _SmartFoldersSheet({
    required this.metas,
    required this.allTags,
    required this.allColors,
    this.currentFolder,
  });

  bool _isSelected(SmartFolder folder) {
    if (currentFolder == null) return folder.type == SmartFolderType.all;
    if (folder.type != currentFolder!.type) return false;
    if (folder.type == SmartFolderType.byTag) {
      return folder.tagFilter == currentFolder!.tagFilter;
    }
    if (folder.type == SmartFolderType.byColor) {
      return folder.colorFilter == currentFolder!.colorFilter;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
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
            const Text(
              'Carpetas inteligentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Organiza tus cuadernos automáticamente',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Carpetas principales.
            _buildFolderItem(
              context,
              SmartFolder(type: SmartFolderType.all),
              metas.length,
            ),
            _buildFolderItem(
              context,
              SmartFolder(type: SmartFolderType.recent),
              SmartFolder(type: SmartFolderType.recent).apply(metas).length,
            ),
            _buildFolderItem(
              context,
              SmartFolder(type: SmartFolderType.thisWeek),
              SmartFolder(type: SmartFolderType.thisWeek).apply(metas).length,
            ),
            _buildFolderItem(
              context,
              SmartFolder(type: SmartFolderType.noTags),
              SmartFolder(type: SmartFolderType.noTags).apply(metas).length,
            ),

            // Por color.
            if (allColors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'POR COLOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.of(context).textHint,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allColors.map((color) {
                  final folder = SmartFolder(
                    type: SmartFolderType.byColor,
                    colorFilter: color,
                  );
                  final count = folder.apply(metas).length;
                  final selected = _isSelected(folder);
                  return ChoiceChip(
                    label: Text('$count'),
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => Navigator.pop(context, folder),
                    selectedColor: Color(color).withAlpha(30),
                    side: BorderSide(
                      color: selected ? Color(color) : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Por etiqueta.
            if (allTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'POR ETIQUETA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.of(context).textHint,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags.map((tag) {
                  final folder = SmartFolder(
                    type: SmartFolderType.byTag,
                    tagFilter: tag,
                  );
                  final count = folder.apply(metas).length;
                  final selected = _isSelected(folder);
                  return FilterChip(
                    avatar: Icon(
                      Icons.label,
                      size: 16,
                      color: selected ? kAccentColor : Colors.grey,
                    ),
                    label: Text('$tag ($count)'),
                    selected: selected,
                    onSelected: (_) => Navigator.pop(context, folder),
                    backgroundColor: selected
                        ? kAccentColor.withAlpha(20)
                        : null,
                    side: BorderSide(
                      color: selected
                          ? kAccentColor
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFolderItem(
    BuildContext context,
    SmartFolder folder,
    int count,
  ) {
    final selected = _isSelected(folder);
    return ListTile(
      leading: Icon(
        folder.type.icon,
        color: selected ? kAccentColor : Colors.grey.shade600,
      ),
      title: Text(
        folder.displayName,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? kAccentColor : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? kAccentColor.withAlpha(20)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? kAccentColor : Colors.grey,
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check, color: kAccentColor, size: 20),
          ],
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => Navigator.pop(context, folder),
    );
  }
}
