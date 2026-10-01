// SPDX-License-Identifier: GPL-3.0-or-later
import '../l10n/l10n.dart';
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
      SnackBar(content: Text(context.l10n.trashRestoredMsg(meta.title))),
    );
    await _loadTrash();
  }

  Future<void> _purge(TrashEntry meta) async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.trashDeleteForever,
      message: context.l10n.trashPurgeBody(meta.title),
      confirmLabel: context.l10n.libDelete,
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
      title: context.l10n.trashEmptyTitle,
      message: context.l10n.trashEmptyBody(_trashMetas!.length),
      confirmLabel: context.l10n.trashEmpty,
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
      title: context.l10n.libTrash,
      subtitle: metas == null || metas.isEmpty
          ? context.l10n.trashSubtitleEmpty
          : context.l10n.trashSubtitleCount(metas.length),
      icon: Icons.delete_outline,
      maxWidth: 820,
      headerTrailing: metas != null && metas.isNotEmpty
          ? TextButton.icon(
              onPressed: _emptyTrash,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(context.l10n.trashEmpty),
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.delete_sweep_outlined,
              title: context.l10n.trashEmptyState,
              message: context.l10n.trashEmptyStateBody,
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
        context.l10n.trashNotebookKind(meta.noteCount),
      TrashKind.note => meta.notebookTitle == null
          ? context.l10n.trashNote
          : context.l10n.trashNoteOf(meta.notebookTitle!),
      TrashKind.legacyDocument => context.l10n.trashLegacy,
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
        context.l10n.trashInfoLine(
          what,
          date_util.deletedAgo(context.l10n, meta.deletedAt),
          left <= 1 ? context.l10n.trashLeftTomorrow : context.l10n.trashLeftDays(left),
        ),
        style: context.text.bodyMedium
            ?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: meta.kind == TrashKind.note ? context.l10n.trashReturn : context.l10n.commonRestore,
            icon: const Icon(Icons.restore_from_trash),
            onPressed: () => _restore(meta),
          ),
          IconButton(
            tooltip: context.l10n.trashDeleteForever,
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
