import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/date_utils.dart' as date_util;
import '../utils/theme_colors.dart';

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
  List<NotebookMeta>? _trashMetas;

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

  Future<void> _restore(NotebookMeta meta) async {
    await widget.storage.restoreFromTrash(meta.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${meta.title}" restaurado')),
    );
    await _loadTrash();
  }

  Future<void> _purge(NotebookMeta meta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text(
          'Se eliminará "${meta.title}" permanentemente. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.storage.purgeFromTrash(meta.id);
    await _loadTrash();
  }

  Future<void> _emptyTrash() async {
    if (_trashMetas == null || _trashMetas!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar papelera'),
        content: Text(
          'Se eliminarán permanentemente ${_trashMetas!.length} cuaderno(s). '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.storage.emptyTrash();
    await _loadTrash();
  }

  @override
  Widget build(BuildContext context) {
    final metas = _trashMetas;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text(
              'Papelera',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (metas != null && metas.isNotEmpty)
            IconButton(
              tooltip: 'Vaciar papelera',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _emptyTrash,
            ),
        ],
      ),
      body: metas == null
          ? const Center(child: CircularProgressIndicator())
          : metas.isEmpty
              ? _buildEmptyState()
              : _buildList(metas),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_sweep_outlined,
            size: 72,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Papelera vacía',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Los cuadernos que elimines se guardarán aquí\ndurante 30 días antes de borrarse definitivamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : ThemeColors.of(context).textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<NotebookMeta> metas) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: metas.length,
      itemBuilder: (context, index) {
        final meta = metas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _TrashThumb(meta: meta),
            title: Text(
              meta.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              date_util.deletedAgo(meta.updatedAt),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Restaurar',
                  icon: const Icon(Icons.restore_from_trash),
                  onPressed: () => _restore(meta),
                ),
                IconButton(
                  tooltip: 'Eliminar definitivamente',
                  icon: const Icon(Icons.delete_forever, color: Color(0xFFD32F2F)),
                  onPressed: () => _purge(meta),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

/// Miniatura simple en la papelera (sin renderizar la página).
class _TrashThumb extends StatelessWidget {
  final NotebookMeta meta;

  const _TrashThumb({required this.meta});

  @override
  Widget build(BuildContext context) {
    final hasColor = meta.colorValue != null;
    final color = hasColor ? Color(meta.colorValue!) : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: hasColor ? color!.withAlpha(30) : const Color(0xFFF1F0EC),
        borderRadius: BorderRadius.circular(8),
        border: hasColor ? Border.all(color: color!, width: 1.5) : null,
      ),
      child: Icon(
        Icons.description_outlined,
        color: hasColor ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.white38 : ThemeColors.of(context).iconTertiary),
        size: 24,
      ),
    );
  }
}
