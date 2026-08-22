import '../constants.dart';
import 'dart:typed_data';

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/document.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../services/drive_sync_service.dart';
import '../services/export_service.dart';
import '../services/image_service.dart';
import '../services/inklus_format.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart' as date_util;
import 'note_list_screen.dart';
import 'trash_screen.dart';
import 'widgets/smart_folders_sheet.dart';
import 'widgets/tag_editor_sheet.dart';
import '../utils/theme_colors.dart';
import 'create_notebook_screen.dart';
import 'settings_screen.dart';
import 'widgets/notebook_covers.dart';

/// Biblioteca de cuadernos (pantalla de inicio).
///
/// Muestra la lista de cuadernos guardados con una miniatura de su primera
/// página y permite crear, abrir, renombrar, duplicar, eliminar, buscar,
/// ordenar y asignar color de portada. Al tocar un cuaderno se navega al
/// editor ([HomeScreen]); al volver, se refresca la lista.
class NotebookLibraryScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const NotebookLibraryScreen({super.key, this.onToggleTheme});

  @override
  State<NotebookLibraryScreen> createState() => _NotebookLibraryScreenState();
}

class _NotebookLibraryScreenState extends State<NotebookLibraryScreen> {
  final StorageService _storage = StorageService.instance;
  final ImageService _imageService = ImageService();

  /// null mientras carga el índice por primera vez.
  List<NotebookMeta>? _metas;

  /// Cache de miniaturas por id de cuaderno (bytes PNG ya renderizados).
  final Map<String, Future<Uint8List>> _thumbs = {};

  /// Versión de cada thumbnail (updatedAt del notebook). Solo se
  /// regenera la miniatura si el notebook fue modificado desde la
  /// última vez que se renderizó, evitando re-render innecesario.
  final Map<String, DateTime> _thumbVersions = {};

  /// Texto de búsqueda.
  String _searchQuery = '';

  /// Criterio de ordenación.
  _SortBy _sortBy = _SortBy.updatedDesc;

  /// Carpeta dinámica activa (null = ver todos).
  SmartFolder? _activeFolder;

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

    // Aplicar carpeta dinámica.
    if (_activeFolder != null) {
      list = _activeFolder!.apply(list);
    }

    // Aplicar búsqueda (título + tags).
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        if (m.title.toLowerCase().contains(q)) return true;
        if (m.tags.any((t) => t.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
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

  Future<Uint8List> _thumbFor(NotebookMeta meta) {
    final cached = _thumbs[meta.id];
    if (cached != null && _thumbVersions[meta.id] == meta.updatedAt) {
      return cached;
    }
    // Regenerar solo si el contenido cambió.
    final future = _renderThumb(meta);
    _thumbs[meta.id] = future;
    _thumbVersions[meta.id] = meta.updatedAt;
    return future;
  }

  Future<Uint8List> _renderThumb(NotebookMeta meta) async {
    final nb = await _storage.loadNotebook(meta.id);
    if (nb == null || nb.notes.isEmpty || nb.notes.first.pages.isEmpty) {
      throw StateError('Cuaderno sin contenido');
    }
    final page = nb.notes.first.pages.first;
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
  // Acciones de navegación
  // -------------------------------------------------------------------------

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Acciones sobre cuadernos
  // -------------------------------------------------------------------------

  Future<void> _openNotebook(NotebookMeta meta) => _openNotebookById(meta.id);

  Future<void> _createNotebook() async {
    final count = (_metas?.length ?? 0) + 1;
    final result = await Navigator.of(context).push<CreateNotebookResult>(
      MaterialPageRoute(
        builder: (_) => CreateNotebookScreen(notebookCount: count),
      ),
    );
    if (result == null) return;
    final nb = await _storage.createNotebook(
      title: result.name,
      template: result.template,
      coverStyle: result.coverStyle.name,
      coverImagePath: result.coverImagePath,
      colorValue: result.coverColorValue,
    );
    if (!mounted) return;
    await _reload();
    await _openNotebookById(nb.id);
  }


  Future<void> _renameNotebook(NotebookMeta meta) async {
    final name = await _promptText(
      titulo: 'Renombrar cuaderno',
      hint: 'Nombre',
      prefilled: meta.title,
    );
    if (name == null) return;
    await _storage.renameNotebook(meta.id, name);
    await _reload();
  }

  Future<void> _duplicateNotebook(NotebookMeta meta) async {
    await _storage.duplicateNotebook(meta.id);
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
    await _storage.deleteNotebook(meta.id);
    _thumbs.remove(meta.id);
    _thumbVersions.remove(meta.id);
    await _reload();
  }

  /// Asigna un color de portada al cuaderno.
  Future<void> _setNotebookColor(NotebookMeta meta) async {
    final colors = <(String, int?)>[
      ('Sin color', null),
      ('Azul', kAccentColor.toARGB32()),
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
                      color: c.$2 != null ? Color(c.$2!) : (Theme.of(context).brightness == Brightness.dark ? kSurfaceDark : kSurfaceLight),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white24
                                : ThemeColors.of(context).border),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: c.$2 == null
                        ? Icon(Icons.close, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : ThemeColors.of(context).iconTertiary)
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
    await _storage.setNotebookColor(meta.id, selected);
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
      final result = await InklusFormat.importAuto(bytes);

      if (result is Notebook) {
        // v2: Notebook completo con notes individuales.
        await _storage.saveNotebook(result);
        if (!mounted) return;
        _snack('Cuaderno "${result.title}" importado (${result.notes.length} nota(s))');
      } else if (result is Document) {
        // v1 legacy: Document → Notebook con un Note.
        final note = Note(
          id: 'note_${result.id}',
          title: result.title,
          createdAt: result.createdAt,
          updatedAt: result.updatedAt,
          pages: result.pages,
        );
        final nb = await _storage.createNotebook(
          title: result.title,
        );
        await _storage.saveNote(nb.id, note);
        if (!mounted) return;
        _snack('Cuaderno "${result.title}" importado (formato legacy)');
      }
      await _reload();
    } catch (e) {
      _snack('Error al importar: $e');
    }
  }

  Future<void> _openNotebookById(String id) async {
    final nb = await _storage.loadNotebook(id);
    if (!mounted || nb == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteListScreen(notebook: nb),
      ),
    );
    // No limpiar _thumbs: la caché versionada se invalida
    // automáticamente si el notebook fue modificado (updatedAt).
    await _reload();
  }

  Future<void> _openTrash() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrashScreen(storage: _storage),
      ),
    );
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

  Future<void> _showSmartFolders() async {
    final metas = _metas;
    if (metas == null || metas.isEmpty) return;
    final folder = await showSmartFoldersSheet(
      context: context,
      metas: metas,
      currentFolder: _activeFolder,
    );
    if (folder != null) {
      setState(() => _activeFolder = folder);
    }
  }

  /// Edita las etiquetas de un cuaderno.
  Future<void> _editTags(NotebookMeta meta) async {
    final allTags = await _storage.allTags();
    if (!mounted) return;
    final result = await showTagEditor(
      context: context,
      currentTags: meta.tags,
      allAvailableTags: allTags,
    );
    if (result != null) {
      await _storage.setNotebookTags(meta.id, result);
      await _reload();
    }
  }

  void _showSortSheet() {
    showModalBottomSheet<_SortBy>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Ordenar cuadernos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _SortOption(
              icon: Icons.access_time,
              label: 'Más recientes primero',
              selected: _sortBy == _SortBy.updatedDesc,
              onTap: () => Navigator.pop(context, _SortBy.updatedDesc),
            ),
            _SortOption(
              icon: Icons.access_time_filled,
              label: 'Más antiguos primero',
              selected: _sortBy == _SortBy.updatedAsc,
              onTap: () => Navigator.pop(context, _SortBy.updatedAsc),
            ),
            _SortOption(
              icon: Icons.sort_by_alpha,
              label: 'Título A → Z',
              selected: _sortBy == _SortBy.titleAsc,
              onTap: () => Navigator.pop(context, _SortBy.titleAsc),
            ),
            _SortOption(
              icon: Icons.sort_by_alpha,
              label: 'Título Z → A',
              selected: _sortBy == _SortBy.titleDesc,
              onTap: () => Navigator.pop(context, _SortBy.titleDesc),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((v) {
      if (v != null) setState(() => _sortBy = v);
    });
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final metas = _metas;
    final filtered = metas == null ? null : _filteredMetas;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.edit, color: kAccentColor),
            SizedBox(width: 8),
            Text(
              'Inklus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Botón configuración
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          // Menú de más opciones (acciones secundarias agrupadas)
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'sort':
                  _showSortSheet();
                case 'smartFolders':
                  _showSmartFolders();
                case 'import':
                  _importInklus();
                case 'trash':
                  _openTrash();
                case 'theme':
                  widget.onToggleTheme?.call();
              }
            },
            itemBuilder: (context) => [
              // Organización
              PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: const Icon(Icons.sort),
                  title: const Text('Ordenar'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'smartFolders',
                child: ListTile(
                  leading: const Icon(Icons.folder_special),
                  title: const Text('Carpetas inteligentes'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              // Datos
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Importar cuaderno .inklus'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Papelera'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              // Apariencia
              PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  title: Text(isDark ? 'Modo claro' : 'Modo oscuro'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear cuaderno',
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        onPressed: _createNotebook,
        child: const Icon(Icons.add),
      ),
      body: metas == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Indicador de carpeta activa + barra de búsqueda
                if (metas.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      children: [
                        // Chip de carpeta activa.
                        if (_activeFolder != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _activeFolder!.type.icon,
                                  size: 16,
                                  color: kAccentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _activeFolder!.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kAccentColor,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _activeFolder = null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Ver todos'),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o etiqueta...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? kSearchDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustración del estado vacío
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kAccentColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.menu_book_outlined,
                size: 48,
                color: kAccentColor.withAlpha(150),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No se encontraron cuadernos'
                  : 'Empieza a escribir',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Prueba con otro nombre o etiqueta.'
                  : 'Crea un cuaderno nuevo o importa uno existente\npara comenzar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : ThemeColors.of(context).textSecondary,
                height: 1.4,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 28),
              // Acción primaria: crear cuaderno
              FilledButton.icon(
                onPressed: _createNotebook,
                icon: const Icon(Icons.add),
                label: const Text('Crear cuaderno'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 15),
                  minimumSize: const Size(200, 48),
                ),
              ),
              const SizedBox(height: 12),
              // Acción secundaria: importar
              OutlinedButton.icon(
                onPressed: _importInklus,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Importar .inklus'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : ThemeColors.of(context).border,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<NotebookMeta> metas) {
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
        return _NotebookCard(
          meta: meta,
          thumb: _thumbFor(meta),
          onTap: () => _openNotebook(meta),
          onRename: () => _renameNotebook(meta),
          onDuplicate: () => _duplicateNotebook(meta),
          onDelete: () => _deleteNotebook(meta),
          onSetColor: () => _setNotebookColor(meta),
          onEditTags: () => _editTags(meta),
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
  final VoidCallback onEditTags;

  const _NotebookCard({
    required this.meta,
    required this.thumb,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSetColor,
    required this.onEditTags,
  });

  @override
  Widget build(BuildContext context) {
    final hasColor = meta.colorValue != null;
    final color = hasColor ? Color(meta.colorValue!) : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura de la primera página con portada estética.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Portada: solo muestra el diseño de portada (color/pattern/imagen),
                  // SIN previsualizar el contenido interno de las notas.
                  _NotebookCover(
                    color: color,
                    title: meta.title,
                    isDark: isDark,
                    coverStyle: meta.coverStyle,
                    coverImagePath: meta.coverImagePath,
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
                          case 'tags':
                            onEditTags();
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
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'tags',
                          child: ListTile(
                            leading: Icon(Icons.label_outline),
                            title: Text('Etiquetas'),
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
                      _SyncIcon(notebookId: meta.id, syncEnabled: meta.isSyncEnabled),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date_util.relativeTime(meta.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : ThemeColors.of(context).textSecondary,
                    ),
                  ),
                  // Tags del cuaderno.
                  if (meta.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: meta.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: kAccentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono que muestra el estado de sincronización de un cuaderno.
/// Se auto-suscribe a DriveSyncService para actualizarse solo cuando
/// cambia el estado de ESTE cuaderno, sin reconstruir toda la grilla.
class _SyncIcon extends StatelessWidget {
  final String notebookId;
  final bool syncEnabled;
  const _SyncIcon({required this.notebookId, required this.syncEnabled});

  @override
  Widget build(BuildContext context) {
    if (!syncEnabled) {
      return Icon(
        Icons.cloud_off,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : ThemeColors.of(context).border,
      );
    }
    return ListenableBuilder(
      listenable: DriveSyncService.instance,
      builder: (context, _) {
        final status = DriveSyncService.instance.statusFor(notebookId);
        return _buildIcon(context, status);
      },
    );
  }

  Widget _buildIcon(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Icon(
          Icons.cloud_done,
          size: 16,
          color: kAccentColor,
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
        return Icon(
          Icons.cloud_off,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : ThemeColors.of(context).border,
        );
      case SyncStatus.pending:
        return Icon(
          Icons.cloud_upload_outlined,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : ThemeColors.of(context).iconTertiary,
        );
    }
  }
}

/// Opción de ordenación en el bottom sheet.
class _SortOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? kAccentColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : ThemeColors.of(context).textSecondary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? kAccentColor : null,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: kAccentColor, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

/// Portada estética para cuadernos sin contenido.
/// Muestra un gradiente con icono y título estilizado.
class _NotebookCover extends StatelessWidget {
  final Color? color;
  final String title;
  final bool isDark;
  final String coverStyle;
  final String? coverImagePath;

  const _NotebookCover({
    required this.color,
    required this.title,
    required this.isDark,
    this.coverStyle = 'simple',
    this.coverImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? (isDark
        ? kAccentDark
        : kAccentColor);

    // Convierte el string coverStyle a CoverStyle enum.
    final style = CoverStyle.values.firstWhere(
      (s) => s.name == coverStyle,
      orElse: () => CoverStyle.simple,
    );

    // Si es estilo custom con imagen, mostrar la imagen.
    if (style == CoverStyle.custom && coverImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(coverImagePath!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => CustomPaint(
            painter: NotebookCoverPainter(
              style: CoverStyle.simple,
              color: baseColor,
              isDark: isDark,
            ),
            child: Center(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: ThemeColors.of(context).border)],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: NotebookCoverPainter(
        style: style,
        color: baseColor,
        isDark: isDark,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 4, color: ThemeColors.of(context).border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

