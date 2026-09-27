// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/storage_service.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import 'page_scaffold.dart';

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

  static String _colorName(int color) => kCoverColors
      .firstWhere((c) => c.$2 == color, orElse: () => ('Otro', null))
      .$1;

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
    final labelStyle = context.text.titleSmall
        ?.copyWith(color: context.colors.onSurfaceVariant);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
        children: [
          const SheetHeader(
            icon: Icons.auto_awesome_outlined,
            title: 'Carpetas inteligentes',
            subtitle: 'Organiza tus cuadernos automáticamente',
          ),
          for (final type in const [
            SmartFolderType.all,
            SmartFolderType.recent,
            SmartFolderType.thisWeek,
            SmartFolderType.noTags,
          ])
            _buildFolderItem(context, SmartFolder(type: type)),

          if (allColors.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text('Por color', style: labelStyle),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final color in allColors)
                  _chip(
                    context,
                    SmartFolder(type: SmartFolderType.byColor, colorFilter: color),
                    avatar: Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(color: Color(color), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ],

          if (allTags.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text('Por etiqueta', style: labelStyle),
            ),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final tag in allTags)
                  _chip(
                    context,
                    SmartFolder(type: SmartFolderType.byTag, tagFilter: tag),
                    avatar: const Icon(Icons.label_outline, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, SmartFolder folder, {required Widget avatar}) {
    return FilterChip(
      avatar: avatar,
      label: Text('${folder.displayName} · ${folder.apply(metas).length}'),
      selected: _isSelected(folder),
      showCheckmark: false,
      onSelected: (_) => Navigator.pop(context, folder),
    );
  }

  Widget _buildFolderItem(BuildContext context, SmartFolder folder) {
    final selected = _isSelected(folder);
    final count = folder.apply(metas).length;
    final accent = selected ? context.colors.primary : context.colors.onSurfaceVariant;
    return ListTile(
      selected: selected,
      selectedTileColor: context.colors.secondaryContainer,
      leading: Icon(folder.type.icon, color: accent),
      title: Text(folder.displayName, style: context.text.titleMedium),
      trailing: Text(
        '$count',
        style: context.text.labelLarge?.copyWith(color: accent),
      ),
      shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      onTap: () => Navigator.pop(context, folder),
    );
  }
}
