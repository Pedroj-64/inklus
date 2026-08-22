import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/template.dart';
import '../models/id.dart';

/// Metadatos de un cuaderno para el índice (sin páginas/trazos).
class NotebookMeta {
  final String id;
  final String title;
  final DateTime updatedAt;

  /// Color de portada del cuaderno (ARGB). null = sin color.
  final int? colorValue;

  /// Si está activo, el cuaderno se sincroniza con Google Drive.
  /// null = true por defecto (para compatibilidad con índices antiguos).
  final bool? syncEnabled;

  /// Etiquetas del cuaderno.
  final List<String> tags;

  /// Estilo de portada (simple, circle, waves, dots, lines, custom).
  final String coverStyle;

  /// Ruta de imagen personalizada para la portada (estilo 'custom').
  final String? coverImagePath;

  const NotebookMeta({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.colorValue,
    this.syncEnabled,
    this.coverStyle = 'simple',
    this.coverImagePath,
    List<String>? tags,
  })  : tags = tags ?? const [];

  /// Por defecto la sincronización está activa.
  bool get isSyncEnabled => syncEnabled ?? true;

  NotebookMeta copyWith({
    String? title,
    DateTime? updatedAt,
    int? colorValue,
    bool? syncEnabled,
    String? coverStyle,
    String? coverImagePath,
    bool clearCoverImage = false,
    List<String>? tags,
  }) =>
      NotebookMeta(
        id: id,
        title: title ?? this.title,
        updatedAt: updatedAt ?? this.updatedAt,
        colorValue: colorValue ?? this.colorValue,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        coverStyle: coverStyle ?? this.coverStyle,
        coverImagePath: clearCoverImage ? null : (coverImagePath ?? this.coverImagePath),
        tags: tags ?? this.tags,
      );

  factory NotebookMeta.fromJson(Map<String, dynamic> json) => NotebookMeta(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Sin título',
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        colorValue: (json['color'] as num?)?.toInt(),
        syncEnabled: json['syncEnabled'] as bool?,
        coverStyle: json['coverStyle'] as String? ?? 'simple',
        coverImagePath: json['coverImagePath'] as String?,
        tags: (json['tags'] as List? ?? [])
            .map((t) => t as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        if (colorValue != null) 'color': colorValue,
        if (syncEnabled != null) 'syncEnabled': syncEnabled,
        if (coverStyle != 'simple') 'coverStyle': coverStyle,
        if (coverImagePath != null) 'coverImagePath': coverImagePath,
        if (tags.isNotEmpty) 'tags': tags,
      };
}

/// Persistencia local de cuadernos (JSON en la carpeta de datos de la app).
///
/// Estructura bajo `<appSupport>/inklus/`:
/// - `index.json` — lista de metadatos de todos los cuadernos (ordenados por
///   `updatedAt` descendente). Es lo que muestra la biblioteca.
/// - `documents/<id>.json` — el documento completo (trazos, páginas, etc.).
///
/// Es el buffer principal de guardado: ante cierres inesperados o pérdida de
/// conexión, los trazos nunca se pierden. Este mismo JSON es el que se
/// replica a Google Drive cuando hay sesión iniciada.
class StorageService {
  static const _indexName = 'index.json';
  static const _documentsFolder = 'documents';
  static const _notebooksFolder = 'notebooks';
  static const _notesFolder = 'notes';
  static const _legacyFileName = 'current_document.json';
  static const _formatVersion = 2;

  /// Instancia singleton para producción. Todos los widgets comparten la
  /// misma instancia para que el índice se mantenga sincronizado.
  static final StorageService instance = StorageService._();

  StorageService._() : _baseDirOverride = null;

  /// Directorio base opcional (para tests); si es null se usa el soporte de
  /// datos de la app (`getApplicationSupportDirectory`).
  final Directory? _baseDirOverride;

  /// Constructor para tests: permite inyectar un directorio temporal.
  StorageService({Directory? baseDir}) : _baseDirOverride = baseDir;

  Future<Directory> _baseDir() async {
    if (_baseDirOverride != null) return _baseDirOverride;
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/inklus');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<Directory> _docsDir(Directory base) async {
    final folder = Directory('${base.path}/$_documentsFolder');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<Directory> _notebooksDir(Directory base) async {
    final folder = Directory('${base.path}/$_notebooksFolder');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<Directory> _notesDir(Directory base) async {
    final folder = Directory('${base.path}/$_notesFolder');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<File> _indexFile(Directory base) async =>
      File('${base.path}/$_indexName');

  Future<File> _docFile(Directory base, String id) async {
    final docs = await _docsDir(base);
    return File('${docs.path}/$id.json');
  }

  Future<File> _notebookFile(Directory base, String id) async {
    final nbs = await _notebooksDir(base);
    return File('${nbs.path}/$id.json');
  }

  Future<File> _noteFile(Directory base, String id) async {
    final notes = await _notesDir(base);
    return File('${notes.path}/$id.json');
  }

  /// Ruta del antiguo documento único (solo para migración).
  Future<File> _legacyFile(Directory base) async =>
      File('${base.path}/$_legacyFileName');

  // -------------------------------------------------------------------------
  // Índice
  // -------------------------------------------------------------------------

  Future<List<NotebookMeta>> _readIndex(Directory base) async {
    final file = await _indexFile(base);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Intentar formato nuevo (v2) primero
      if (json['formatVersion'] == _formatVersion) {
        return (json['notebooks'] as List? ?? [])
            .map((m) => NotebookMeta.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      // Formato antiguo: key 'documents'
      return (json['documents'] as List? ?? [])
          .map((m) => NotebookMeta.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('StorageService._readIndex: $e');
      return [];
    }
  }

  Future<void> _writeIndex(Directory base, List<NotebookMeta> metas) async {
    final file = await _indexFile(base);
    await file.writeAsString(jsonEncode({
      'formatVersion': _formatVersion,
      'notebooks': metas.map((m) => m.toJson()).toList(),
    }));
  }

  /// Lista los cuadernos guardados, ordenados por `updatedAt` descendente.
  ///
  /// En la primera ejecución migra el antiguo `current_document.json` al
  /// nuevo formato si aún no existe el índice.
  Future<List<NotebookMeta>> loadIndex() async {
    final base = await _baseDir();
    var metas = await _readIndex(base);

    // Si el índice está vacío, intentar migrar el legacy (current_document.json)
    if (metas.isEmpty) {
      final migrated = await _migrateLegacy(base);
      if (migrated != null) metas = [migrated];
    }

    // Detectar formato antiguo (sin formatVersion o con key 'documents')
    // y migrar al nuevo formato (Notebook + Note, key 'notebooks')
    if (metas.isNotEmpty) {
      final file = await _indexFile(base);
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          if (json['formatVersion'] != _formatVersion) {
            debugPrint('StorageService: detectado formato antiguo, migrando...');
            metas = await _migrateToNotebookFormat(base);
          }
        }
      }
    }

    metas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return metas;
  }

  /// Convierte el antiguo `current_document.json` (documento único) en un
  /// cuaderno indexado. Devuelve el meta migrado o null si no había nada.
  Future<NotebookMeta?> _migrateLegacy(Directory base) async {
    final legacy = await _legacyFile(base);
    if (!await legacy.exists()) return null;
    try {
      final raw = await legacy.readAsString();
      if (raw.trim().isEmpty) return null;
      final doc = Document.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final meta = await _migrateDocumentToNotebook(base, doc);
      // Eliminamos el legacy para que la migración no se repita.
      await legacy.delete();
      return meta;
    } catch (e) {
      debugPrint('StorageService._migrateLegacy: $e');
      return null;
    }
  }

  /// Migra un Document plano al nuevo formato Notebook + Note.
  ///
  /// **Mapeo explícito** (documentado en A3 del ROADMAP):
  /// - `Document.colorValue` → `Notebook.colorValue`
  /// - `Document.tags` → `Notebook.tags`
  /// - El resto del Document (pages, title, dates) pasa intacto a la Note.
  ///
  /// Crea:
  /// - `notebooks/<id>.json` — Notebook con metadatos + lista de noteIds
  /// - `notes/<noteId>.json` — Note con el contenido del Document
  Future<NotebookMeta> _migrateDocumentToNotebook(
    Directory base,
    Document doc,
  ) async {
    final notesDir = await _notesDir(base);
    final notebooksDir = await _notebooksDir(base);

    // 1. Crear Note a partir del Document (contenido intacto)
    final noteId = 'note_${doc.id}';
    final note = Note(
      id: noteId,
      title: doc.title,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      pages: doc.pages,
    );
    final noteFile = File('${notesDir.path}/$noteId.json');
    await noteFile.writeAsString(jsonEncode(note.toJson()));

    // 2. Crear Notebook con colorValue y tags del Document
    final notebook = Notebook(
      id: doc.id,
      title: doc.title,
      colorValue: doc.colorValue,
      tags: List<String>.from(doc.tags),
      notes: [note],
    );
    final nbFile = File('${notebooksDir.path}/${notebook.id}.json');
    await nbFile.writeAsString(jsonEncode(notebook.toJson()));

    // 3. Devolver meta para el índice
    return NotebookMeta(
      id: notebook.id,
      title: notebook.title,
      updatedAt: notebook.updatedAt,
      colorValue: notebook.colorValue,
      tags: notebook.tags,
    );
  }

  /// Migra todos los Documents del formato antiguo (key 'documents')
  /// al nuevo formato (Notebook + Note, key 'notebooks').
  ///
  /// Se ejecuta una sola vez cuando se detecta un index.json sin
  /// formatVersion o con formatVersion < 2.
  Future<List<NotebookMeta>> _migrateToNotebookFormat(
    Directory base,
  ) async {
    // 1. Leer el índice antiguo (key 'documents')
    final file = await _indexFile(base);
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final oldDocs = json['documents'] as List? ?? [];
    if (oldDocs.isEmpty) return [];

    debugPrint(
      'StorageService: migrando ${oldDocs.length} documento(s) '
      'al formato Notebook+Note...',
    );

    // 2. Para cada Document, crear Notebook + Note
    final newMetas = <NotebookMeta>[];
    final docsDir = await _docsDir(base);

    for (final metaJson in oldDocs) {
      final meta = NotebookMeta.fromJson(metaJson as Map<String, dynamic>);
      final docFile = File('${docsDir.path}/${meta.id}.json');
      if (!await docFile.exists()) continue;

      try {
        final docRaw = await docFile.readAsString();
        if (docRaw.trim().isEmpty) continue;
        final doc = Document.fromJson(
          jsonDecode(docRaw) as Map<String, dynamic>,
        );
        final newMeta = await _migrateDocumentToNotebook(base, doc);
        newMetas.add(newMeta);
      } catch (e) {
        debugPrint('StorageService._migrateToNotebookFormat: $e');
      }
    }

    // 3. Reescribir el índice en formato nuevo
    await _writeIndex(base, newMetas);

    debugPrint(
      'StorageService: migración completada. '
      '${newMetas.length} notebook(s) creado(s).',
    );

    return newMetas;
  }

  // -------------------------------------------------------------------------
  // CRUD de documentos
  // -------------------------------------------------------------------------

  /// Carga un documento completo por id, o null si no existe.
  Future<Document?> load(String id) async {
    final base = await _baseDir();
    final file = await _docFile(base, id);
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return Document.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Nunca dejamos que un JSON corrupto rompa la app.
      debugPrint('StorageService.load: $e');
      return null;
    }
  }

  /// Guarda (o actualiza) un documento: escribe `documents/<id>.json` y
  /// refresca el índice. Devuelve el meta del índice actualizado.
  Future<NotebookMeta> save(Document document) async {
    final base = await _baseDir();
    final file = await _docFile(base, document.id);
    await file.writeAsString(jsonEncode(document.toJson()));

    final metas = await _readIndex(base);
    metas.removeWhere((m) => m.id == document.id);
    metas.add(NotebookMeta(
      id: document.id,
      title: document.title,
      updatedAt: document.updatedAt,
      colorValue: document.colorValue,
      tags: document.tags,
    ));
    await _writeIndex(base, metas);
    return NotebookMeta(
      id: document.id,
      title: document.title,
      updatedAt: document.updatedAt,
      colorValue: document.colorValue,
      tags: document.tags,
    );
  }

  /// Crea un cuaderno nuevo en blanco y lo guarda.
  /// Si se proporciona [template], la primera página usa esa plantilla.
  Future<Document> create({String? title, PageTemplate? template}) async {
    final doc = Document.newBlank(title: title);
    if (template != null && doc.pages.isNotEmpty) {
      doc.pages.first.template = template;
    }
    await save(doc);
    return doc;
  }

  /// Renombra un cuaderno (actualiza el documento y el índice).
  Future<void> rename(String id, String title) async {
    final doc = await load(id);
    if (doc == null) return;
    if (title.trim().isEmpty || title.trim() == doc.title) return;
    doc.title = title.trim();
    doc.updatedAt = DateTime.now();
    await save(doc);
  }

  /// Asigna un color de portada a un cuaderno.
  Future<void> setColor(String id, int? colorValue) async {
    final doc = await load(id);
    if (doc == null) return;
    doc.colorValue = colorValue;
    doc.updatedAt = DateTime.now();
    await save(doc);
  }

  /// Establece las etiquetas de un cuaderno.
  Future<void> setTags(String id, List<String> tags) async {
    final doc = await load(id);
    if (doc == null) return;
    doc.tags = tags;
    doc.updatedAt = DateTime.now();
    await save(doc);
  }

  /// Añade una etiqueta a un cuaderno (sin duplicar).
  Future<void> addTag(String id, String tag) async {
    final doc = await load(id);
    if (doc == null) return;
    if (!doc.tags.contains(tag)) {
      doc.tags.add(tag);
      doc.updatedAt = DateTime.now();
      await save(doc);
    }
  }

  /// Elimina una etiqueta de un cuaderno.
  Future<void> removeTag(String id, String tag) async {
    final doc = await load(id);
    if (doc == null) return;
    if (doc.tags.remove(tag)) {
      doc.updatedAt = DateTime.now();
      await save(doc);
    }
  }

  /// Devuelve todas las etiquetas únicas usadas en todos los cuadernos.
  Future<List<String>> allTags() async {
    final metas = await loadIndex();
    final tags = <String>{};
    for (final m in metas) {
      tags.addAll(m.tags);
    }
    return tags.toList()..sort();
  }

  /// Activa o desactiva la sincronización de un cuaderno con Google Drive.
  Future<void> setSyncEnabled(String id, bool enabled) async {
    final base = await _baseDir();
    final metas = await _readIndex(base);
    final idx = metas.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    metas[idx] = metas[idx].copyWith(
      updatedAt: metas[idx].updatedAt,
      syncEnabled: enabled,
    );
    await _writeIndex(base, metas);
  }

  /// Duplica un cuaderno con un id nuevo y título "... (copia)".
  Future<Document> duplicate(String id) async {
    final doc = await load(id);
    if (doc == null) throw StateError('Cuaderno no encontrado: $id');
    // Roundtrip JSON = copia profunda (trazos, páginas, plantillas).
    final copy = Document(
      id: newId('doc'),
      title: '${doc.title} (copia)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: Document.fromJson(doc.toJson()).pages,
      colorValue: doc.colorValue,
    );
    await save(copy);
    return copy;
  }

  /// Elimina un cuaderno moviéndolo a la papelera.
  Future<void> delete(String id) async {
    final base = await _baseDir();
    final file = await _docFile(base, id);
    if (!await file.exists()) {
      // Solo estaba en el índice; quitar.
      final metas = await _readIndex(base);
      metas.removeWhere((m) => m.id == id);
      await _writeIndex(base, metas);
      return;
    }
    // Mover a carpeta trash/ para poder recuperar.
    final trashDir = Directory('${base.path}/trash');
    if (!await trashDir.exists()) await trashDir.create(recursive: true);
    final trashFile = File('${trashDir.path}/$id.json');
    await file.copy(trashFile.path);
    await file.delete();
    final metas = await _readIndex(base);
    metas.removeWhere((m) => m.id == id);
    await _writeIndex(base, metas);
  }

  // -------------------------------------------------------------------------
  // CRUD de Notebooks (nuevo formato v2)
  // -------------------------------------------------------------------------

  /// Carga un Notebook completo por id, incluyendo sus Notes.
  Future<Notebook?> loadNotebook(String id) async {
    final base = await _baseDir();
    final file = await _notebookFile(base, id);
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Cargar los Notes referenciados por noteIds
      final noteIds = (json['noteIds'] as List? ?? [])
          .map((e) => e as String)
          .toList();
      final notes = <Note>[];
      for (final nid in noteIds) {
        final note = await loadNote(nid);
        if (note != null) notes.add(note);
      }

      return Notebook.fromJson(json, loadedNotes: notes);
    } catch (e) {
      debugPrint('StorageService.loadNotebook: $e');
      return null;
    }
  }

  /// Guarda un Notebook: escribe `notebooks/<id>.json` + cada Note individual.
  Future<void> saveNotebook(Notebook notebook) async {
    final base = await _baseDir();

    // Guardar cada Note
    for (final note in notebook.notes) {
      await _saveNoteRaw(base, note);
    }

    // Guardar el Notebook (solo IDs, no contenido de notes)
    final file = await _notebookFile(base, notebook.id);
    await file.writeAsString(jsonEncode(notebook.toJson()));

    // Actualizar índice
    final metas = await _readIndex(base);
    metas.removeWhere((m) => m.id == notebook.id);
    metas.add(NotebookMeta(
      id: notebook.id,
      title: notebook.title,
      updatedAt: notebook.updatedAt,
      colorValue: notebook.colorValue,
      coverStyle: notebook.coverStyle,
      coverImagePath: notebook.coverImagePath,
      tags: notebook.tags,
    ));
    await _writeIndex(base, metas);
  }

  /// Guarda solo un Note (sin tocar el Notebook ni el índice).
  Future<void> _saveNoteRaw(Directory base, Note note) async {
    final file = await _noteFile(base, note.id);
    await file.writeAsString(jsonEncode(note.toJson()));
  }

  /// Crea un Notebook nuevo con un Note en blanco.
  Future<Notebook> createNotebook({
    String? title,
    int? colorValue,
    String coverStyle = 'simple',
    String? coverImagePath,
    List<String>? tags,
    PageTemplate? template,
  }) async {
    final note = Note.newBlank();
    if (template != null && note.pages.isNotEmpty) {
      note.pages.first.template = template;
    }
    final notebook = Notebook(
      id: newId('nb'),
      title: title ?? 'Mi cuaderno',
      colorValue: colorValue,
      coverStyle: coverStyle,
      coverImagePath: coverImagePath,
      tags: tags,
      notes: [note],
    );
    await saveNotebook(notebook);
    return notebook;
  }

  /// Renombra un Notebook.
  Future<void> renameNotebook(String id, String title) async {
    if (title.trim().isEmpty) return;
    final nb = await loadNotebook(id);
    if (nb == null) return;
    nb.title = title.trim();
    await saveNotebook(nb);
  }

  /// Asigna un color de portada a un Notebook.
  Future<void> setNotebookColor(String id, int? colorValue) async {
    final nb = await loadNotebook(id);
    if (nb == null) return;
    nb.colorValue = colorValue;
    await saveNotebook(nb);
  }

  /// Establece las etiquetas de un Notebook.
  Future<void> setNotebookTags(String id, List<String> tags) async {
    final nb = await loadNotebook(id);
    if (nb == null) return;
    nb.tags = tags;
    await saveNotebook(nb);
  }

  /// Duplica un Notebook con id nuevo, título "... (copia)" y copia profunda
  /// de todos sus Notes.
  Future<Notebook> duplicateNotebook(String id) async {
    final nb = await loadNotebook(id);
    if (nb == null) throw StateError('Notebook no encontrado: $id');

    // Copia profunda de cada Note vía roundtrip JSON
    final newNotes = <Note>[];
    for (final note in nb.notes) {
      final copy = Note.fromJson(
        jsonDecode(jsonEncode(note.toJson())) as Map<String, dynamic>,
      );
      // Asignar IDs nuevos para evitar colisiones
      final newNote = Note(
        id: newId('note'),
        title: copy.title,
        createdAt: copy.createdAt,
        updatedAt: copy.updatedAt,
        pages: copy.pages,
      );
      newNotes.add(newNote);
    }

    final newNb = Notebook(
      id: newId('nb'),
      title: '${nb.title} (copia)',
      colorValue: nb.colorValue,
      tags: List<String>.from(nb.tags),
      notes: newNotes,
    );
    await saveNotebook(newNb);
    return newNb;
  }

  /// Elimina un Notebook y todos sus Notes (moviendo a la papelera).
  Future<void> deleteNotebook(String id) async {
    final base = await _baseDir();
    final nbFile = await _notebookFile(base, id);

    // Recopilar noteIds antes de eliminar
    List<String> noteIds = [];
    if (await nbFile.exists()) {
      try {
        final raw = await nbFile.readAsString();
        if (raw.trim().isNotEmpty) {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          noteIds = (json['noteIds'] as List? ?? [])
              .map((e) => e as String)
              .toList();
        }
      } catch (_) {}
    }

    // Mover notebook a papelera
    final trashDir = Directory('${base.path}/trash');
    if (!await trashDir.exists()) await trashDir.create(recursive: true);
    if (await nbFile.exists()) {
      await nbFile.copy('${trashDir.path}/$id.json');
      await nbFile.delete();
    }

    // Mover cada Note a papelera
    for (final nid in noteIds) {
      final noteFile = await _noteFile(base, nid);
      if (await noteFile.exists()) {
        await noteFile.copy('${trashDir.path}/$nid.json');
        await noteFile.delete();
      }
    }

    // Quitar del índice
    final metas = await _readIndex(base);
    metas.removeWhere((m) => m.id == id);
    await _writeIndex(base, metas);

    // Limpiar imágenes huérfanas en background (no bloquea el retorno).
    collectOrphanedImages();
  }

  // -------------------------------------------------------------------------
  // CRUD de Notes (dentro de un Notebook)
  // -------------------------------------------------------------------------

  /// Carga un Note individual por id, o null si no existe.
  Future<Note?> loadNote(String id) async {
    final base = await _baseDir();
    final file = await _noteFile(base, id);
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return Note.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('StorageService.loadNote: $e');
      return null;
    }
  }

  /// Guarda un Note (actualiza su archivo + el updatedAt del Notebook padre).
  Future<void> saveNote(String notebookId, Note note) async {
    final base = await _baseDir();
    await _saveNoteRaw(base, note);

    // Actualizar el updatedAt del Notebook en el índice
    note.touch();
    final metas = await _readIndex(base);
    final idx = metas.indexWhere((m) => m.id == notebookId);
    if (idx >= 0) {
      metas[idx] = metas[idx].copyWith(updatedAt: DateTime.now());
      await _writeIndex(base, metas);
    }
  }

  /// Crea un Note nuevo dentro de un Notebook.
  Future<Note> createNote(
    String notebookId, {
    String? title,
    PageTemplate? template,
  }) async {
    final nb = await loadNotebook(notebookId);
    if (nb == null) throw StateError('Notebook no encontrado: $notebookId');

    final note = Note.newBlank(title: title);
    if (template != null && note.pages.isNotEmpty) {
      note.pages.first.template = template;
    }

    nb.notes.add(note);
    await saveNotebook(nb);
    return note;
  }

  /// Renombra un Note.
  Future<void> renameNote(
    String notebookId,
    String noteId,
    String title,
  ) async {
    if (title.trim().isEmpty) return;
    final note = await loadNote(noteId);
    if (note == null) return;
    note.title = title.trim();
    await saveNote(notebookId, note);
  }

  /// Elimina un Note de un Notebook (a la papelera).
  Future<void> deleteNote(String notebookId, String noteId) async {
    final base = await _baseDir();
    final nb = await loadNotebook(notebookId);
    if (nb == null) return;

    // No permitir eliminar el último note
    if (nb.notes.length <= 1) return;

    // Quitar de la lista
    nb.notes.removeWhere((n) => n.id == noteId);

    // Mover archivo a papelera
    final trashDir = Directory('${base.path}/trash');
    if (!await trashDir.exists()) await trashDir.create(recursive: true);
    final noteFile = await _noteFile(base, noteId);
    if (await noteFile.exists()) {
      await noteFile.copy('${trashDir.path}/$noteId.json');
      await noteFile.delete();
    }

    await saveNotebook(nb);

    // Limpiar imágenes huérfanas en background.
    collectOrphanedImages();
  }

  /// Duplica un Note dentro del mismo Notebook.
  Future<Note> duplicateNote(
    String notebookId,
    String noteId,
  ) async {
    final nb = await loadNotebook(notebookId);
    if (nb == null) throw StateError('Notebook no encontrado: $notebookId');

    final original = nb.notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => throw StateError('Note no encontrado: $noteId'),
    );

    // Copia profunda vía roundtrip JSON
    final copy = Note.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final newNote = Note(
      id: newId('note'),
      title: '${copy.title} (copia)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pages: copy.pages,
    );

    // Insertar después del original
    final idx = nb.notes.indexWhere((n) => n.id == noteId);
    nb.notes.insert(idx + 1, newNote);

    await saveNotebook(nb);
    return newNote;
  }

  // -------------------------------------------------------------------------
  // Papelera
  // -------------------------------------------------------------------------

  /// Lista los cuadernos en la papelera, ordenados por fecha de eliminación
  /// (el más reciente primero). Soporta formato legacy (Document) y
  /// formato actual (Notebook + Note).
  Future<List<NotebookMeta>> loadTrash() async {
    final base = await _baseDir();
    final trashDir = Directory('${base.path}/trash');
    if (!await trashDir.exists()) return [];
    final metas = <NotebookMeta>[];
    await for (final entity in trashDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final raw = await entity.readAsString();
        if (raw.trim().isEmpty) continue;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        // Detectar formato: si tiene 'noteIds' es Notebook; si tiene 'pages' es Document.
        if (json.containsKey('noteIds')) {
          // Formato Notebook (v2)
          metas.add(NotebookMeta.fromJson(json));
        } else {
          // Formato Document legacy
          final doc = Document.fromJson(json);
          metas.add(NotebookMeta(
            id: doc.id,
            title: doc.title,
            updatedAt: doc.updatedAt,
            colorValue: doc.colorValue,
          ));
        }
      } catch (_) {
        // Archivo corrupto, ignorar.
      }
    }
    metas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return metas;
  }

  /// Restaura un cuaderno desde la papelera al índice.
  /// Soporta formato legacy (Document) y formato actual (Notebook + Note).
  Future<void> restoreFromTrash(String id) async {
    final base = await _baseDir();
    final trashFile = File('${base.path}/trash/$id.json');
    if (!await trashFile.exists()) return;

    final raw = await trashFile.readAsString();
    if (raw.trim().isEmpty) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;

    if (json.containsKey('noteIds')) {
      // ---- Formato Notebook (v2) ----
      // Restaurar el notebook y cada note asociado.
      final noteIds = (json['noteIds'] as List? ?? [])
          .map((e) => e as String)
          .toList();
      for (final nid in noteIds) {
        final noteTrash = File('${base.path}/trash/$nid.json');
        if (await noteTrash.exists()) {
          final notesDir = await _notesDir(base);
          await noteTrash.copy('${notesDir.path}/$nid.json');
          await noteTrash.delete();
        }
      }
      // Mover el notebook a su carpeta.
      final notebooksDir = await _notebooksDir(base);
      await trashFile.copy('${notebooksDir.path}/$id.json');
      await trashFile.delete();
      // Reconstruir el índice.
      final nb = await loadNotebook(id);
      if (nb != null) {
        final metas = await _readIndex(base);
        metas.add(NotebookMeta(
          id: nb.id,
          title: nb.title,
          updatedAt: nb.updatedAt,
          colorValue: nb.colorValue,
          coverStyle: nb.coverStyle,
          coverImagePath: nb.coverImagePath,
          tags: nb.tags,
        ));
        await _writeIndex(base, metas);
      }
    } else {
      // ---- Formato Document legacy ----
      final docs = await _docsDir(base);
      final docFile = File('${docs.path}/$id.json');
      await trashFile.copy(docFile.path);
      await trashFile.delete();
      // Reconstruir el índice leyendo el documento restaurado.
      final doc = await load(id);
      if (doc != null) await save(doc);
    }
  }

  /// Carga un documento completo desde la papelera.
  Future<Document?> loadFromTrash(String id) async {
    final base = await _baseDir();
    final trashFile = File('${base.path}/trash/$id.json');
    try {
      if (!await trashFile.exists()) return null;
      final raw = await trashFile.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json.containsKey('noteIds')) {
        // Notebook format: reconstruct a Document for backward compatibility.
        final nb = await loadNotebook(id);
        if (nb == null) return null;
        return Document(
          id: nb.id,
          title: nb.title,
          createdAt: nb.createdAt,
          updatedAt: nb.updatedAt,
          pages: nb.notes.expand((n) => n.pages).toList(),
          colorValue: nb.colorValue,
          tags: nb.tags,
        );
      }
      return Document.fromJson(json);
    } catch (e) {
      debugPrint('StorageService.loadFromTrash: $e');
      return null;
    }
  }

  /// Elimina definitivamente un cuaderno de la papelera.
  Future<void> purgeFromTrash(String id) async {
    final base = await _baseDir();
    final trashFile = File('${base.path}/trash/$id.json');
    if (await trashFile.exists()) await trashFile.delete();
    // Limpiar imágenes huérfanas.
    collectOrphanedImages();
  }

  /// Vacía toda la papelera (elimina definitivamente todo).
  Future<void> emptyTrash() async {
    final base = await _baseDir();
    final trashDir = Directory('${base.path}/trash');
    if (await trashDir.exists()) await trashDir.delete(recursive: true);
    // Limpiar imágenes huérfanas.
    collectOrphanedImages();
  }

  // -------------------------------------------------------------------------
  // Respaldo local completo (todos los cuadernos en un ZIP)
  // -------------------------------------------------------------------------

  /// Exporta todos los cuadernos + imágenes en un único ZIP.
  ///
  /// Estructura del ZIP:
  /// - `index.json` — índice de todos los cuadernos.
  /// - `documents/<id>.json` — cada documento.
  /// - `images/<path>` — imágenes compartidas.
  Future<Uint8List> exportFullBackup() async {
    final base = await _baseDir();
    final archive = Archive();

    // Copiar index.json
    final indexFile = await _indexFile(base);
    if (await indexFile.exists()) {
      final bytes = await indexFile.readAsBytes();
      archive.addFile(ArchiveFile('index.json', bytes.length, bytes));
    }

    // Copiar todos los documentos
    final docsDir = await _docsDir(base);
    if (await docsDir.exists()) {
      await for (final entity in docsDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final name = 'documents/${entity.uri.pathSegments.last}';
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }
    }

    // Copiar imágenes
    final imagesDir = Directory('${base.path}/images');
    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          final relative = entity.path.substring(base.path.length + 1);
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(relative, bytes.length, bytes));
        }
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Importa un backup completo (ZIP exportado por [exportFullBackup]).
  Future<int> importFullBackup(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final base = await _baseDir();
    var count = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      final data = file.content as List<int>;
      final outPath = '${base.path}/${file.name}';

      if (file.name.startsWith('documents/')) {
        // Guardar documento y contar.
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
        count++;
      } else if (file.name.startsWith('images/')) {
        // Restaurar imagen.
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else if (file.name == 'index.json') {
        // Restaurar índice.
        final outFile = File(outPath);
        await outFile.writeAsBytes(data);
      }
    }

    return count;
  }

  // -------------------------------------------------------------------------
  // Limpieza de imágenes huérfanas
  // -------------------------------------------------------------------------

  /// Recopila todas las rutas de imágenes referenciadas por algún Note activo.
  Future<Set<String>> _collectReferencedImagePaths() async {
    final base = await _baseDir();
    final referenced = <String>{};

    // 1. Recorrer todos los notebooks del índice y cargar sus notes.
    final metas = await _readIndex(base);
    for (final meta in metas) {
      final nbFile = await _notebookFile(base, meta.id);
      if (!await nbFile.exists()) continue;
      try {
        final raw = await nbFile.readAsString();
        if (raw.trim().isEmpty) continue;
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final noteIds = (json['noteIds'] as List? ?? [])
            .map((e) => e as String)
            .toList();
        for (final nid in noteIds) {
          final note = await loadNote(nid);
          if (note == null) continue;
          _extractImagePaths(note, referenced);
        }
      } catch (_) {}
    }

    // 2. También considerar images en la papelera (no borrar si podrían restaurarse).
    final trashDir = Directory('${base.path}/trash');
    if (await trashDir.exists()) {
      await for (final entity in trashDir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final raw = await entity.readAsString();
          if (raw.trim().isEmpty) continue;
          // Intentar como Note
          final noteJson = jsonDecode(raw);
          if (noteJson is Map<String, dynamic> && noteJson.containsKey('pages')) {
            final note = Note.fromJson(noteJson);
            _extractImagePaths(note, referenced);
          }
        } catch (_) {}
      }
    }

    return referenced;
  }

  /// Extrae todas las rutas de imágenes de un Note (images + templates custom).
  void _extractImagePaths(Note note, Set<String> referenced) {
    for (final page in note.pages) {
      for (final img in page.images) {
        referenced.add(img.localPath);
      }
      final tplPath = page.template.imagePath;
      if (tplPath != null) referenced.add(tplPath);
    }
  }

  /// Elimina imágenes de `inklus/images/` que no están referenciadas por
  /// ningún Note (activo o en papelera). Ejecuta en background.
  Future<void> collectOrphanedImages() async {
    try {
      final base = await _baseDir();
      final imagesDir = Directory('${base.path}/images');
      if (!await imagesDir.exists()) return;

      final referenced = await _collectReferencedImagePaths();
      var deleted = 0;

      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is! File) continue;
        if (!referenced.contains(entity.path)) {
          try {
            await entity.delete();
            deleted++;
          } catch (_) {}
        }
      }

      if (deleted > 0) {
        debugPrint('StorageService: $deleted imagen(es) huérfana(s) eliminada(s).');
      }
    } catch (e) {
      debugPrint('StorageService.collectOrphanedImages: $e');
    }
  }
}
