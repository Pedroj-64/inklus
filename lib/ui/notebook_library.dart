import 'dart:typed_data';

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/drive_sync_service.dart';
import '../services/export_service.dart';
import '../services/image_service.dart';
import '../services/inklus_format.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'trash_screen.dart';

/// Biblioteca de cuadernos (pantalla de inicio).
///
/// Muestra la lista de cuadernos guardados con una miniatura de su primera
/// página y permite crear, abrir, renombrar, duplicar, eliminar, buscar,
/// ordenar y asignar color de portada. Al tocar un cuaderno se navega al
/// editor ([HomeScreen]); al volver, se refresca la lista.
class NotebookLibraryScreen extends StatefulWidget {
  const NotebookLibraryScreen({super.key});

  @override
  State<NotebookLibraryScreen> createState() => _NotebookLibraryScreenState();
}

class _NotebookLibraryScreenState extends State<NotebookLibraryScreen> {
  final StorageService _storage = StorageService();
  final ImageService _imageService = ImageService();

  /// null mientras carga el índice por primera vez.
  List<NotebookMeta>? _metas;

  /// Cache de miniaturas por id de cuaderno (bytes PNG ya renderizados).
  final Map<String, Future<Uint8List>> _thumbs = {};

  /// Texto de búsqueda.
  String _searchQuery = '';

  /// Criterio de ordenación.
  _SortBy _sortBy = _SortBy.updatedDesc;

  @override
  void initState() {
    super.initState();
    _reload();
    // Restaura la sesión de Google (silenciosa).
    DriveSyncService.instance.restoreSession();
  }

  Future<void> _reload() async {
    final metas = await _storage.loadIndex();
    if (!mounted) return;
    setState(() => _metas = metas);
  }

  /// Lista filtrada y ordenada de cuadernos.
  List<NotebookMeta> get _filteredMetas {
    var list = _metas ?? [];
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) => m.title.toLowerCase().contains(q)).toList();
    }
    switch (_sortBy) {
      case _SortBy.updatedDesc:
        list = List.of(list)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _SortBy.updatedAsc:
        list = List.of(list)
          ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case _SortBy.titleAsc:
        list = List.of(list)
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _SortBy.titleDesc:
        list = List.of(list)
          ..sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    }
    return list;
  }

  Future<Uint8List> _thumbFor(NotebookMeta meta) =>
      _thumbs.putIfAbsent(meta.id, () => _renderThumb(meta));

  Future<Uint8List> _renderThumb(NotebookMeta meta) async {
    final doc = await _storage.load(meta.id);
    if (doc == null || doc.pages.isEmpty) {
      throw StateError('Cuaderno sin contenido');
    }
    final page = doc.pages.first;
    for (final item in page.images) {
      await _imageService.ensureCached(item.localPath);
    }
    final templatePath = page.template.imagePath;
    if (templatePath != null) {
      await _imageService.ensureCached(templatePath);
    }
    return ExportService.renderPagePng(
      page,
      sheetSize: page.template.sheetSize,
      imageCache: _imageService.cache,
      options: const ExportOptions(maxDimension: 480),
    );
  }

  // -------------------------------------------------------------------------
  // Acciones sobre cuadernos
  // -------------------------------------------------------------------------

  Future<void> _openNotebook(NotebookMeta meta) => _openNotebookById(meta.id);

  Future<void> _createNotebook() async {
    final count = (_metas?.length ?? 0) + 1;
    final name = await _promptText(
      titulo: 'Nuevo cuaderno',
      hint: 'Nombre',
      prefilled: 'Cuaderno $count',
    );
    if (name == null) return;
    final doc = await _storage.create(title: name);
    if (!mounted) return;
    await _reload();
    await _openNotebookById(doc.id);
  }

  Future<void> _renameNotebook(NotebookMeta meta) async {
    final name = await _promptText(
      titulo: 'Renombrar cuaderno',
      hint: 'Nombre',
      prefilled: meta.title,
    );
    if (name == null) return;
    await _storage.rename(meta.id, name);
    await _reload();
  }

  Future<void> _duplicateNotebook(NotebookMeta meta) async {
    await _storage.duplicate(meta.id);
    await _reload();
  }

  Future<void> _deleteNotebook(NotebookMeta meta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuaderno'),
        content: Text(
          'Se enviará "${meta.title}" a la papelera. '
          'Podrás recuperarlo desde ahí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _storage.delete(meta.id);
    _thumbs.remove(meta.id);
    await _reload();
  }

  /// Asigna un color de portada al cuaderno.
  Future<void> _setNotebookColor(NotebookMeta meta) async {
    final colors = <(String, int?)>[
      ('Sin color', null),
      ('Azul', const Color(0xFF3B82F6).toARGB32()),
      ('Verde', const Color(0xFF4CAF50).toARGB32()),
      ('Rojo', const Color(0xFFE53935).toARGB32()),
      ('Naranja', const Color(0xFFFF9800).toARGB32()),
      ('Morado', const Color(0xFF9C27B0).toARGB32()),
      ('Rosa', const Color(0xFFEC407A).toARGB32()),
      ('Turquesa', const Color(0xFF26C6DA).toARGB32()),
      ('Gris', const Color(0xFF78909C).toARGB32()),
    ];
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Color de portada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: colors.map((c) {
                final isSelected = c.$2 == meta.colorValue;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, c.$2),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.$2 != null ? Color(c.$2!) : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.black26,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: c.$2 == null
                        ? const Icon(Icons.close, size: 20, color: Colors.black38)
                        : isSelected
                            ? const Icon(Icons.check, size: 20, color: Colors.white)
                            : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (selected == null && meta.colorValue == null) return;
    await _storage.setColor(meta.id, selected);
    await _reload();
  }

  /// Importa un archivo .inklus desde el dispositivo.
  Future<void> _importInklus() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['inklus'],
      );
      if (files.isEmpty) return;
      final filePath = files.first.path!;
      final bytes = await File(filePath).readAsBytes();
      final doc = await InklusFormat.importBytes(bytes);
      await _storage.save(doc);
      if (!mounted) return;
      _snack('Cuaderno "${doc.title}" importado');
      await _reload();
    } catch (e) {
      _snack('Error al importar: $e');
    }
  }

  Future<void> _openNotebookById(String id) async {
    final doc = await _storage.load(id);
    if (!mounted || doc == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(document: doc),
      ),
    );
    _thumbs.clear();
    await _reload();
  }

  Future<void> _openTrash() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrashScreen(storage: _storage),
      ),
    );
    _thumbs.clear();
    await _reload();
  }

  Future<String?> _promptText({
    required String titulo,
    required String hint,
    required String prefilled,
  }) async {
    final controller = TextEditingController(text: prefilled);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return null;
    return result.trim();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final metas = _metas;
    final filtered = metas == null ? null : _filteredMetas;
    return Scaffold(
      backgroundColor: const Color(0xFFEFEDE8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text(
              'Inklus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Botón papelera
          IconButton(
            tooltip: 'Papelera',
            icon: const Icon(Icons.delete_outline),
            onPressed: _openTrash,
          ),
          // Botón importar .inklus
          IconButton(
            tooltip: 'Importar cuaderno (.inklus)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _importInklus,
          ),
          // Contador de cuadernos
          if (metas != null && metas.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${metas.length}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
          // Menú de ordenación
          if (metas != null && metas.length > 1)
            PopupMenuButton<_SortBy>(
              tooltip: 'Ordenar',
              icon: const Icon(Icons.sort),
              onSelected: (v) => setState(() => _sortBy = v),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _SortBy.updatedDesc,
                  child: Text('Más recientes primero'),
                ),
                const PopupMenuItem(
                  value: _SortBy.updatedAsc,
                  child: Text('Más antiguos primero'),
                ),
                const PopupMenuItem(
                  value: _SortBy.titleAsc,
                  child: Text('Título A→Z'),
                ),
                const PopupMenuItem(
                  value: _SortBy.titleDesc,
                  child: Text('Título Z→A'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear cuaderno',
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        onPressed: _createNotebook,
        child: const Icon(Icons.add),
      ),
      body: metas == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda
                if (metas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar cuadernos...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                // Contenido
                Expanded(
                  child: filtered == null
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : _buildGrid(filtered),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.menu_book_outlined,
            size: 72,
            color: Colors.black.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No se encontraron cuadernos'
                : 'Todavía no tienes cuadernos',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Prueba con otro nombre.'
                : 'Crea tu primer cuaderno para empezar a escribir.',
            style: const TextStyle(color: Colors.black54),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createNotebook,
              icon: const Icon(Icons.add),
              label: const Text('Crear cuaderno'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<NotebookMeta> metas) {
    return ListenableBuilder(
      listenable: DriveSyncService.instance,
      builder: (context, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 268,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: metas.length,
          itemBuilder: (context, index) {
            final meta = metas[index];
            final syncStatus = meta.isSyncEnabled
                ? DriveSyncService.instance.statusFor(meta.id)
                : SyncStatus.disabled;
            return _NotebookCard(
              meta: meta,
              thumb: _thumbFor(meta),
              syncStatus: syncStatus,
              onTap: () => _openNotebook(meta),
              onRename: () => _renameNotebook(meta),
              onDuplicate: () => _duplicateNotebook(meta),
              onDelete: () => _deleteNotebook(meta),
              onSetColor: () => _setNotebookColor(meta),
            );
          },
        );
      },
    );
  }
}

/// Criterios de ordenación.
enum _SortBy { updatedDesc, updatedAsc, titleAsc, titleDesc }

/// Tarjeta de un cuaderno: miniatura de la primera página + título + fecha.
class _NotebookCard extends StatelessWidget {
  final NotebookMeta meta;
  final Future<Uint8List> thumb;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSetColor;
  final SyncStatus syncStatus;

  const _NotebookCard({
    required this.meta,
    required this.thumb,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSetColor,
    this.syncStatus = SyncStatus.pending,
  });

  @override
  Widget build(BuildContext context) {
    final hasColor = meta.colorValue != null;
    final color = hasColor ? Color(meta.colorValue!) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura de la primera página con color de portada.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo con color de portada o gris por defecto.
                  Container(
                    color: hasColor
                        ? color!.withAlpha(30)
                        : const Color(0xFFF1F0EC),
                    alignment: Alignment.center,
                    child: FutureBuilder<Uint8List>(
                      future: thumb,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        }
                        if (snapshot.hasError) {
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black38,
                            size: 40,
                          );
                        }
                        return const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ),
                  // Barra de color en la parte superior.
                  if (hasColor)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 4,
                      child: Container(color: color),
                    ),
                  // Menú contextual.
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      tooltip: 'Opciones del cuaderno',
                      onSelected: (v) {
                        switch (v) {
                          case 'rename':
                            onRename();
                          case 'duplicate':
                            onDuplicate();
                          case 'color':
                            onSetColor();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Renombrar'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.copy_outlined),
                            title: Text('Duplicar'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'color',
                          child: ListTile(
                            leading: Icon(Icons.palette_outlined),
                            title: Text('Color de portada'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Color(0xFFD32F2F),
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: Color(0xFFD32F2F)),
                            ),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _SyncIcon(status: syncStatus),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relativeTime(meta.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fecha relativa corta sin dependencias externas.
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'ahora mismo';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  final t = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year}';
}

/// Icono que muestra el estado de sincronización de un cuaderno.
class _SyncIcon extends StatelessWidget {
  final SyncStatus status;
  const _SyncIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return const Icon(
          Icons.cloud_done,
          size: 16,
          color: Color(0xFF3B82F6),
        );
      case SyncStatus.syncing:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case SyncStatus.error:
        return const Icon(
          Icons.sync_problem,
          size: 16,
          color: Color(0xFFE53935),
        );
      case SyncStatus.disabled:
        return const Icon(
          Icons.cloud_off,
          size: 16,
          color: Colors.black26,
        );
      case SyncStatus.pending:
        return const Icon(
          Icons.cloud_upload_outlined,
          size: 16,
          color: Colors.black38,
        );
    }
  }
}
