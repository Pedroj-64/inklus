// SPDX-License-Identifier: GPL-3.0-or-later
import '../constants.dart';

import 'dart:io';

import 'package:flutter/material.dart';

import '../services/drive_sync_service.dart';
import '../services/import_service.dart';
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
import 'widgets/dialogs.dart';
import '../theme_controller.dart';
import 'home_screen.dart';
import 'widgets/search_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/inklus_logo.dart';
import 'marketplace_screen.dart';

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

  /// null mientras carga el índice por primera vez.
  List<NotebookMeta>? _metas;

  /// Texto de búsqueda.
  String _searchQuery = '';

  /// Criterio de ordenación.
  _SortBy _sortBy = _SortBy.updatedDesc;

  /// Carpeta dinámica activa (null = ver todos).
  SmartFolder? _activeFolder;

  /// Sección de la navegación lateral.
  _Section _section = _Section.all;

  /// Vista en cuadrícula (portadas) o lista (compacta). Se recuerda.
  bool _listView = false;
  static const _prefListView = 'library_list_view';

  Future<void> _loadViewPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_prefListView) ?? false;
      if (mounted && v != _listView) setState(() => _listView = v);
    } catch (_) {}
  }

  void _setListView(bool list) {
    setState(() => _listView = list);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_prefListView, list))
        .catchError((_) => false);
  }

  Future<void> _toggleFavorite(NotebookMeta meta) async {
    await _storage.setFavorite(meta.id, !meta.favorite);
    await _reload();
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _loadViewPref();
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

    // Sección de la navegación lateral.
    switch (_section) {
      case _Section.all:
        break;
      case _Section.recent:
        final since = DateTime.now().subtract(const Duration(days: 7));
        list = list.where((m) => m.updatedAt.isAfter(since)).toList();
      case _Section.favorites:
        list = list.where((m) => m.favorite).toList();
    }

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

  /// Importa un cuaderno `.inklus` o un respaldo completo `.zip` (el tipo se
  /// detecta por el contenido, ver [ImportService]).
  Future<void> _importInklus() async {
    try {
      final bytes = await ImportService.pickFile();
      if (bytes == null || !mounted) return;
      final result = await runWithLoading(context, () => ImportService.importBytes(bytes));
      await _reload();
      _snack(result.message);
    } catch (e) {
      _snack(e is FormatException ? e.message : 'Error al importar: $e');
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

  /// Búsqueda global de contenido; abre la nota en la página encontrada.
  Future<void> _searchInContent() async {
    await showSearchSheet(
      context,
      initialQuery: _searchQuery,
      onOpen: (result, match) async {
        final note = await _storage.loadNote(result.noteId);
        if (note == null || !mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HomeScreen(
            note: note,
            notebookId: result.notebookId,
            initialPage: match.pageIndex < 0 ? 0 : match.pageIndex,
          ),
        ));
        await _reload();
      },
    );
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
    final result = await showTextPrompt(
      context,
      title: titulo,
      hint: hint,
      initialValue: prefilled,
      confirmLabel: 'Guardar',
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
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.compact + 240;
    final content = metas == null
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(metas.length)),
              ..._buildContentSlivers(),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: const _Brand(),
              actions: [_moreMenu()],
            ),
      drawer: wide ? null : Drawer(child: SafeArea(child: _navList(inDrawer: true))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNotebook,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cuaderno'),
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  SizedBox(width: 248, child: _navList(inDrawer: false)),
                  VerticalDivider(width: 1, color: context.colors.outlineVariant),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }

  /// Navegación: secciones, carpetas inteligentes, papelera y ajustes.
  Widget _navList({required bool inDrawer}) {
    Widget tile(IconData icon, String label, bool selected, VoidCallback onTap, {int? count}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xxs),
          child: ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: count == null ? null : Text('$count', style: context.text.labelMedium),
            selected: selected,
            selectedTileColor: context.colors.secondaryContainer,
            shape: const StadiumBorder(),
            onTap: () {
              if (inDrawer) Navigator.pop(context);
              onTap();
            },
          ),
        );
    final all = _metas ?? const <NotebookMeta>[];
    void go(_Section s) => setState(() {
          _section = s;
          _activeFolder = null;
        });
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.lg, Spacing.lg),
          child: _Brand(),
        ),
        tile(Icons.auto_stories_outlined, 'Todos',
            _section == _Section.all && _activeFolder == null, () => go(_Section.all),
            count: all.length),
        tile(Icons.schedule, 'Recientes', _section == _Section.recent, () => go(_Section.recent)),
        tile(Icons.star_outline, 'Favoritos', _section == _Section.favorites,
            () => go(_Section.favorites),
            count: all.where((m) => m.favorite).length),
        tile(Icons.folder_special_outlined, 'Carpetas', _activeFolder != null,
            _showSmartFolders),
        tile(Icons.storefront_outlined, 'Marketplace', false, () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
          );
        }),
        const Divider(indent: Spacing.xl, endIndent: Spacing.xl),
        tile(Icons.file_download_outlined, 'Importar .inklus', false, _importInklus),
        tile(Icons.delete_outline, 'Papelera', false, _openTrash),
        tile(Icons.settings_outlined, 'Configuración', false, _openSettings),
      ],
    );
  }

  /// Menú ⋮ (solo en pantallas estrechas; en tablet todo está en el lateral).
  Widget _moreMenu() => MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: Icon(context.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                (widget.onToggleTheme ?? () => ThemeModeController.toggle(context))(),
            child: Text(context.isDark ? 'Modo claro' : 'Modo oscuro'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            child: const Text('Configuración'),
          ),
        ],
        builder: (context, menu, _) => IconButton(
          tooltip: 'Más opciones',
          icon: const Icon(Icons.more_vert),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        ),
      );

  String get _sectionTitle => _activeFolder?.displayName ??
      switch (_section) {
        _Section.all => 'Mis cuadernos',
        _Section.recent => 'Recientes',
        _Section.favorites => 'Favoritos',
      };

  /// Título, búsqueda y controles de orden/vista.
  Widget _buildHeader(int total) {
    final shown = _filteredMetas.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.xl, Spacing.xl, Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(_sectionTitle, style: context.text.headlineMedium),
              ),
              if (_activeFolder != null)
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar filtro'),
                  onPressed: () => setState(() => _activeFolder = null),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            shown == total ? '$total cuaderno(s)' : '$shown de $total cuaderno(s)',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.lg),
          SearchBar(
            hintText: 'Buscar por nombre o etiqueta',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(context.colors.surfaceContainerHigh),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: Spacing.lg),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
            trailing: [
              Tooltip(
                message: 'Buscar dentro de las notas (texto y escritura)',
                child: TextButton.icon(
                  icon: const Icon(Icons.manage_search),
                  label: const Text('En el contenido'),
                  onPressed: _searchInContent,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.sort, size: 18),
                label: Text(switch (_sortBy) {
                  _SortBy.updatedDesc => 'Más recientes',
                  _SortBy.updatedAsc => 'Más antiguos',
                  _SortBy.titleAsc => 'Nombre A–Z',
                  _SortBy.titleDesc => 'Nombre Z–A',
                }),
                onPressed: _showSortSheet,
              ),
              const Spacer(),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.grid_view), tooltip: 'Cuadrícula'),
                  ButtonSegment(value: true, icon: Icon(Icons.view_list), tooltip: 'Lista'),
                ],
                selected: {_listView},
                onSelectionChanged: (v) => _setListView(v.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    final metas = _filteredMetas;
    if (metas.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())];
    }
    Widget card(NotebookMeta meta) => _NotebookCard(
          meta: meta,
          compact: _listView,
          onTap: () => _openNotebook(meta),
          onRename: () => _renameNotebook(meta),
          onDuplicate: () => _duplicateNotebook(meta),
          onDelete: () => _deleteNotebook(meta),
          onSetColor: () => _setNotebookColor(meta),
          onEditTags: () => _editTags(meta),
          onToggleFavorite: () => _toggleFavorite(meta),
        );
    if (_listView) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          sliver: SliverList.separated(
            itemCount: metas.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
            itemBuilder: (_, i) => card(metas[i]),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.all(Spacing.xl),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 300,
            crossAxisSpacing: Spacing.xl,
            mainAxisSpacing: Spacing.xl,
          ),
          itemCount: metas.length,
          itemBuilder: (_, i) => card(metas[i]),
        ),
      ),
    ];
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
}

/// Criterios de ordenación.
enum _SortBy { updatedDesc, updatedAsc, titleAsc, titleDesc }

/// Secciones de la navegación lateral.
enum _Section { all, recent, favorites }

/// Logo + nombre de la app.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InklusLogo(size: 32),
          const SizedBox(width: Spacing.md),
          Text('Inklus', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}

/// Tarjeta de un cuaderno. En cuadrícula: portada grande + título, fecha,
/// etiquetas y estrella de favorito. En lista ([compact]): fila compacta.
class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    required this.meta,
    required this.compact,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSetColor,
    required this.onEditTags,
    required this.onToggleFavorite,
  });

  final NotebookMeta meta;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onSetColor;
  final VoidCallback onEditTags;
  final VoidCallback onToggleFavorite;

  Widget _menu(BuildContext context) => MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: Icon(meta.favorite ? Icons.star : Icons.star_outline),
            onPressed: onToggleFavorite,
            child: Text(meta.favorite ? 'Quitar de favoritos' : 'Añadir a favoritos'),
          ),
          MenuItemButton(leadingIcon: const Icon(Icons.edit_outlined), onPressed: onRename, child: const Text('Renombrar')),
          MenuItemButton(leadingIcon: const Icon(Icons.copy_outlined), onPressed: onDuplicate, child: const Text('Duplicar')),
          MenuItemButton(leadingIcon: const Icon(Icons.palette_outlined), onPressed: onSetColor, child: const Text('Portada y color')),
          MenuItemButton(leadingIcon: const Icon(Icons.label_outline), onPressed: onEditTags, child: const Text('Etiquetas')),
          const Divider(),
          MenuItemButton(
            leadingIcon: Icon(Icons.delete_outline, color: context.inklus.danger),
            onPressed: onDelete,
            child: Text('Mover a la papelera', style: TextStyle(color: context.inklus.danger)),
          ),
        ],
        builder: (context, menu, _) => IconButton(
          tooltip: 'Opciones del cuaderno',
          icon: const Icon(Icons.more_vert),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        ),
      );

  Widget _cover(BuildContext context) => _NotebookCover(
        color: meta.colorValue != null ? Color(meta.colorValue!) : null,
        title: meta.title,
        isDark: context.isDark,
        coverStyle: meta.coverStyle,
        coverImagePath: meta.coverImagePath,
      );

  @override
  Widget build(BuildContext context) {
    final subtitle = date_util.relativeTime(meta.updatedAt);
    if (compact) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
          leading: ClipRRect(
            borderRadius: Radii.smAll,
            child: SizedBox(width: 40, height: 52, child: _cover(context)),
          ),
          title: Text(meta.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text([subtitle, ...meta.tags.take(3)].join(' · ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (meta.favorite) Icon(Icons.star, color: context.inklus.warning),
              _SyncIcon(notebookId: meta.id, syncEnabled: meta.isSyncEnabled),
              _menu(context),
            ],
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Cuaderno ${meta.title}, $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Portada con sombra suave, como un cuaderno físico.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: Radii.mdAll,
                      boxShadow: [
                        BoxShadow(
                          color: context.inklus.shadow,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(borderRadius: Radii.mdAll, child: _cover(context)),
                  ),
                  if (meta.favorite)
                    Positioned(
                      top: Spacing.sm,
                      left: Spacing.sm,
                      child: Icon(Icons.star, color: context.inklus.warning, shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 4),
                      ]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                ),
                _SyncIcon(notebookId: meta.id, syncEnabled: meta.isSyncEnabled),
                SizedBox(width: 36, height: 36, child: _menu(context)),
              ],
            ),
            Text(subtitle, style: context.text.bodySmall),
            if (meta.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Spacing.xs),
                child: Text(
                  meta.tags.take(3).map((t) => '#$t').join('  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(color: context.colors.primary),
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
          errorBuilder: (_, _, _) => CustomPaint(
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

