// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/date_utils.dart' as date_util;
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/dialogs.dart';
import 'widgets/page_scaffold.dart';

/// Pantalla de papelera: muestra los cuadernos eliminados y permite
/// recuperarlos o eliminarlos definitivamente.
class TrashScreen extends StatefulWidget {
  final StorageService storage;

  const TrashScreen({
    super.key,
    required this.storage,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashEntry>? _trashMetas;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    final metas = await widget.storage.loadTrash();
    if (!mounted) return;
    setState(() => _trashMetas = metas);
  }

  Future<void> _restore(TrashEntry meta) async {
    await widget.storage.restoreFromTrash(meta.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${meta.title}" restaurado')),
    );
    await _loadTrash();
  }

  Future<void> _purge(TrashEntry meta) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Eliminar definitivamente',
      message: 'Se eliminará "${meta.title}" permanentemente. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok) return;
    await widget.storage.purgeFromTrash(meta.id);
    await _loadTrash();
  }

  Future<void> _emptyTrash() async {
    if (_trashMetas == null || _trashMetas!.isEmpty) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Vaciar papelera',
      message: 'Se eliminarán permanentemente ${_trashMetas!.length} '
          'elemento(s). Esta acción no se puede deshacer.',
      confirmLabel: 'Vaciar',
      destructive: true,
    );
    if (!ok) return;
    await widget.storage.emptyTrash();
    await _loadTrash();
  }

  @override
  Widget build(BuildContext context) {
    final metas = _trashMetas;
    return InklusPage(
      title: 'Papelera',
      subtitle: metas == null || metas.isEmpty
          ? 'Lo que elimines se guarda aquí 30 días'
          : '${metas.length} elemento(s) · se borran solos a los 30 días',
      icon: Icons.delete_outline,
      maxWidth: 820,
      headerTrailing: metas != null && metas.isNotEmpty
          ? TextButton.icon(
              onPressed: _emptyTrash,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Vaciar'),
              style: TextButton.styleFrom(foregroundColor: context.inklus.danger),
            )
          : null,
      slivers: [
        if (metas == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (metas.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.delete_sweep_outlined,
              title: 'Papelera vacía',
              message: 'Los cuadernos y notas que elimines se guardarán aquí '
                  'durante 30 días antes de borrarse definitivamente.',
            ),
          )
        else
          SliverToBoxAdapter(
            child: SectionCard(
              children: [for (final meta in metas) _tile(meta)],
            ),
          ),
      ],
    );
  }

  Widget _tile(TrashEntry meta) {
    final what = switch (meta.kind) {
      TrashKind.notebook =>
        'Cuaderno · ${meta.noteCount} nota${meta.noteCount == 1 ? '' : 's'}',
      TrashKind.note => meta.notebookTitle == null
          ? 'Nota'
          : 'Nota de «${meta.notebookTitle}»',
      TrashKind.legacyDocument => 'Cuaderno (formato antiguo)',
    };
    final left = meta.daysLeft;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
      leading: _TrashThumb(meta: meta),
      title: Text(
        meta.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.titleMedium,
      ),
      subtitle: Text(
        '$what · ${date_util.deletedAgo(meta.deletedAt)} · '
        '${left <= 1 ? 'se borra mañana' : 'quedan $left días'}',
        style: context.text.bodyMedium
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: meta.kind == TrashKind.note ? 'Devolver a su cuaderno' : 'Restaurar',
            icon: const Icon(Icons.restore_from_trash),
            onPressed: () => _restore(meta),
          ),
          IconButton(
            tooltip: 'Eliminar definitivamente',
            icon: Icon(Icons.delete_forever, color: context.inklus.danger),
            onPressed: () => _purge(meta),
          ),
        ],
      ),
    );
  }
}

/// Miniatura simple en la papelera (sin renderizar la página): el color de
/// portada del cuaderno si lo tiene.
class _TrashThumb extends StatelessWidget {
  final TrashEntry meta;

  const _TrashThumb({required this.meta});

  @override
  Widget build(BuildContext context) {
    final color = meta.colorValue == null ? null : Color(meta.colorValue!);
    return Container(
      width: Sizes.minTouch,
      height: Sizes.minTouch,
      decoration: BoxDecoration(
        color: color?.withAlpha(30) ?? context.colors.surfaceContainerHighest,
        borderRadius: Radii.smAll,
        border: color == null ? null : Border.all(color: color, width: 1.5),
      ),
      child: Icon(
        meta.kind == TrashKind.note ? Icons.sticky_note_2_outlined : Icons.book_outlined,
        color: color ?? context.colors.onSurfaceVariant,
        size: Sizes.toolIcon,
      ),
    );
  }
}
