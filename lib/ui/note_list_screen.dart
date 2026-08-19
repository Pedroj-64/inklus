import '../constants.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/notebook.dart';
import '../models/template.dart';
import '../services/export_service.dart';
import '../services/image_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

/// Pantalla que muestra la lista de apuntes (notes) dentro de un cuaderno.
///
/// Permite crear, renombrar, eliminar, duplicar y reordenar notas.
/// Al tocar una nota se navega al editor ([HomeScreen]).
class NoteListScreen extends StatefulWidget {
  final Notebook notebook;

  const NoteListScreen({super.key, required this.notebook});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final StorageService _storage = StorageService.instance;
  final ImageService _imageService = ImageService();
  late Notebook _notebook;
  final Map<String, Future<Uint8List>> _thumbs = {};

  @override
  void initState() {
    super.initState();
    _notebook = widget.notebook;
  }

  Future<Uint8List> _thumbFor(Note note) =>
      _thumbs.putIfAbsent(note.id, () => _renderThumb(note));

  Future<Uint8List> _renderThumb(Note note) async {
    if (note.pages.isEmpty) throw StateError('Sin páginas');
    final page = note.pages.first;
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
      options: const ExportOptions(maxDimension: 320),
    );
  }

  Future<void> _reload() async {
    final nb = await _storage.loadNotebook(_notebook.id);
    if (nb != null && mounted) {
      setState(() => _notebook = nb);
    }
  }

  // ------------------------------------------------------------------------- CRUD

  Future<void> _createNote() async {
    final result = await _showCreateNoteDialog();
    if (result == null) return;
    final note = await _storage.createNote(
      _notebook.id,
      title: result.name,
      template: result.template,
    );
    if (!mounted) return;
    await _reload();
    // Abrir la nota recién creada
    await _openNote(note);
  }

  Future<void> _openNote(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(
          note: note,
          notebookId: _notebook.id,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _renameNote(Note note) async {
    final name = await _promptText(
      titulo: 'Renombrar nota',
      hint: 'Nombre',
      prefilled: note.title,
    );
    if (name == null) return;
    await _storage.renameNote(_notebook.id, note.id, name);
    await _reload();
  }

  Future<void> _duplicateNote(Note note) async {
    await _storage.duplicateNote(_notebook.id, note.id);
    await _reload();
  }

  Future<void> _deleteNote(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text(
          'Se eliminará "${note.title}" de este cuaderno.',
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
    await _storage.deleteNote(_notebook.id, note.id);
    await _reload();
  }

  Future<void> _renameNotebook() async {
    final name = await _promptText(
      titulo: 'Renombrar cuaderno',
      hint: 'Nombre',
      prefilled: _notebook.title,
    );
    if (name == null) return;
    await _storage.renameNotebook(_notebook.id, name);
    await _reload();
  }

  // ------------------------------------------------------------------------- Diálogos

  Future<_CreateNoteResult?> _showCreateNoteDialog() async {
    final nameController = TextEditingController(
      text: 'Nota ${_notebook.notes.length + 1}',
    );
    var selectedTemplate = const PageTemplate();

    return showDialog<_CreateNoteResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Mi nota',
                  ),
                  onSubmitted: (_) {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(
                        context,
                        _CreateNoteResult(
                          name: nameController.text.trim(),
                          template: selectedTemplate,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Plantilla',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _CompactTemplateGrid(
                  selected: selectedTemplate.type,
                  onSelect: (t) => setDialogState(() {
                    selectedTemplate = selectedTemplate.copyWith(type: t);
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  _CreateNoteResult(name: name, template: selectedTemplate),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
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

  // ------------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _notebook.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Renombrar cuaderno',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _renameNotebook,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva nota',
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
      body: _notebook.notes.isEmpty
          ? _buildEmptyState()
          : _buildNoteList(isDark),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kAccentColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note_add_outlined,
                size: 40,
                color: kAccentColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin notas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea tu primera nota para empezar a escribir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _createNote,
              icon: const Icon(Icons.add),
              label: const Text('Crear nota'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteList(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _notebook.notes.length,
      itemBuilder: (context, index) {
        final note = _notebook.notes[index];
        final pageCount = note.pages.length;
        final timeAgo = _relativeTime(note.updatedAt);
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _openNote(note),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miniatura de la primera página
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFF1F0EC),
                        child: FutureBuilder<Uint8List>(
                          future: _thumbFor(note),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              );
                            }
                            if (snapshot.hasError) {
                              return Icon(
                                Icons.description_outlined,
                                color: isDark ? Colors.white30 : Colors.black26,
                                size: 36,
                              );
                            }
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      // Menú contextual flotante
                      Positioned(
                        top: 4,
                        right: 4,
                        child: PopupMenuButton<String>(
                          tooltip: 'Opciones',
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_vert, size: 18, color: Colors.white),
                          ),
                          onSelected: (v) {
                            switch (v) {
                              case 'rename':
                                _renameNote(note);
                              case 'duplicate':
                                _duplicateNote(note);
                              case 'delete':
                                _deleteNote(note);
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
                            PopupMenuDivider(),
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
                // Info de la nota
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pageCount página${pageCount == 1 ? '' : 's'} · $timeAgo',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Helpers ---

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  final t = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year}';
}

/// Resultado del diálogo de creación de nota.
class _CreateNoteResult {
  final String name;
  final PageTemplate template;
  _CreateNoteResult({required this.name, required this.template});
}

/// Grid compacto de selección de plantillas.
class _CompactTemplateGrid extends StatelessWidget {
  final TemplateType selected;
  final ValueChanged<TemplateType> onSelect;

  const _CompactTemplateGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = <(TemplateType, IconData, String)>[
      (TemplateType.blank, Icons.landscape, 'Infinito'),
      (TemplateType.ruled, Icons.format_list_bulleted, 'Rayas'),
      (TemplateType.grid, Icons.grid_on, 'Cuadrícula'),
      (TemplateType.dots, Icons.grain, 'Puntos'),
      (TemplateType.sheet, Icons.description, 'Hoja fija'),
      (TemplateType.music, Icons.music_note, 'Pentagrama'),
      (TemplateType.planner, Icons.calendar_today, 'Planificador'),
      (TemplateType.habit, Icons.checklist, 'Hábitos'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final (type, icon, label) = templates[index];
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? kAccentColor.withAlpha(20)
                  : (isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.grey.withAlpha(25)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? kAccentColor
                    : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? kAccentColor
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? kAccentColor
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
