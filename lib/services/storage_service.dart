// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../models/document.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/template.dart';
import '../models/id.dart';
import 'file_utils.dart';
import 'app_paths.dart';

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

  /// Marcado como favorito (aparece en la sección Favoritos).
  final bool favorite;

  const NotebookMeta({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.colorValue,
    this.syncEnabled,
    this.coverStyle = 'simple',
    this.coverImagePath,
    this.favorite = false,
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
    bool? favorite,
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
        favorite: favorite ?? this.favorite,
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
        favorite: json['fav'] as bool? ?? false,
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
        if (favorite) 'fav': true,
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
    return AppPaths.root();
  }

  /// Carpeta raíz de datos (`<appSupport>/inklus`, o la de tests).
  Future<Directory> baseDirectory() => _baseDir();

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

  /// Serializa todas las lecturas-modificación-escritura del índice para que
  /// guardados concurrentes (autoguardado, saveNow, biblioteca) no se pisen.
  final SerialQueue _indexQueue = SerialQueue();

  /// Serializa las lecturas-modificación-escritura de `notebooks/<id>.json`
  /// (ver [_editNotebook]).
  final SerialQueue _notebookQueue = SerialQueue();

  Future<List<NotebookMeta>> _readIndex(Directory base) async {
    final file = await _indexFile(base);
    if (!await file.exists()) return [];
    String raw;
    try {
      raw = await file.readAsString();
    } catch (e) {
      debugPrint('StorageService._readIndex (lectura): $e');
      return [];
    }
    if (raw.trim().isEmpty) return _recoverIndex(base, file);
    try {
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
      debugPrint('StorageService._readIndex: índice corrupto ($e)');
      return _recoverIndex(base, file);
    }
  }

  /// El índice está vacío o corrupto: se aparta (`index.json.corrupt-<ts>`)
  /// y se reconstruye a partir de `notebooks/*.json` para que la biblioteca
  /// no aparezca vacía (y el siguiente guardado no pise el resto).
  Future<List<NotebookMeta>> _recoverIndex(Directory base, File file) async {
    final nbDir = Directory('${base.path}/$_notebooksFolder');
    if (!await nbDir.exists()) return [];
    final metas = <NotebookMeta>[];
    await for (final entity in nbDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        var meta = NotebookMeta.fromJson(json);
        if (!json.containsKey('updatedAt')) {
          meta = meta.copyWith(updatedAt: await entity.lastModified());
        }
        metas.add(meta);
      } catch (e) {
        debugPrint('StorageService._recoverIndex: ${entity.path}: $e');
      }
    }
    if (metas.isEmpty) return [];
    debugPrint(
      'StorageService: índice reconstruido con ${metas.length} cuaderno(s).',
    );
    try {
      await file.rename(
        '${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (_) {}
    await _writeIndex(base, metas);
    return metas;
  }

  Future<void> _writeIndex(Directory base, List<NotebookMeta> metas) async {
    final file = await _indexFile(base);
    await writeAtomic(
      file,
      jsonEncode({
        'formatVersion': _formatVersion,
        'notebooks': metas.map((m) => m.toJson()).toList(),
      }),
    );
  }

  /// Lee, modifica y reescribe el índice de forma serializada.
  Future<void> _updateIndex(
    Directory base,
    void Function(List<NotebookMeta> metas) mutate,
  ) {
    return _indexQueue.run(() async {
      final metas = await _readIndex(base);
      mutate(metas);
      await _writeIndex(base, metas);
    });
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
    await writeAtomic(noteFile, jsonEncode(note.toJson()));

    // 2. Crear Notebook con colorValue y tags del Document
    final notebook = Notebook(
      id: doc.id,
      title: doc.title,
      colorValue: doc.colorValue,
      tags: List<String>.from(doc.tags),
      notes: [note],
    );
    final nbFile = File('${notebooksDir.path}/${notebook.id}.json');
    await writeAtomic(nbFile, jsonEncode(notebook.toJson()));

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
    await writeAtomic(file, jsonEncode(document.toJson()));

    final meta = NotebookMeta(
      id: document.id,
      title: document.title,
      updatedAt: document.updatedAt,
      colorValue: document.colorValue,
      tags: document.tags,
    );
    await _updateIndex(base, (metas) {
      metas.removeWhere((m) => m.id == document.id);
      metas.add(meta);
    });
    return meta;
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
    await _updateIndex(base, (metas) {
      final idx = metas.indexWhere((m) => m.id == id);
      if (idx < 0) return;
      metas[idx] = metas[idx].copyWith(syncEnabled: enabled);
    });
  }

  /// Marca / desmarca un cuaderno como favorito (solo toca el índice).
  Future<void> setFavorite(String id, bool favorite) async {
    final base = await _baseDir();
    await _updateIndex(base, (metas) {
      final idx = metas.indexWhere((m) => m.id == id);
      if (idx >= 0) metas[idx] = metas[idx].copyWith(favorite: favorite);
    });
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
      await _updateIndex(base, (metas) => metas.removeWhere((m) => m.id == id));
      return;
    }
    // Mover a carpeta trash/ para poder recuperar.
    final trashDir = Directory('${base.path}/trash');
    if (!await trashDir.exists()) await trashDir.create(recursive: true);
    final trashFile = File('${trashDir.path}/$id.json');
    await file.copy(trashFile.path);
    await file.delete();
    await _updateIndex(base, (metas) => metas.removeWhere((m) => m.id == id));
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

    // Guardar el Notebook (solo IDs, no contenido de notes); en la misma
    // cola que [_editNotebook] para no pisar una edición en curso.
    final file = await _notebookFile(base, notebook.id);
    await _notebookQueue.run(
      () => writeAtomic(file, jsonEncode(notebook.toJson())),
    );

    // Actualizar índice (conserva syncEnabled del meta anterior).
    await _updateIndex(base, (metas) {
      final prev = metas.where((m) => m.id == notebook.id).firstOrNull;
      metas.removeWhere((m) => m.id == notebook.id);
      metas.add(NotebookMeta(
        id: notebook.id,
        title: notebook.title,
        updatedAt: notebook.updatedAt,
        colorValue: notebook.colorValue,
        syncEnabled: prev?.syncEnabled,
        favorite: prev?.favorite ?? false,
        coverStyle: notebook.coverStyle,
        coverImagePath: notebook.coverImagePath,
        tags: notebook.tags,
      ));
    });
  }

  /// Guarda solo un Note (sin tocar el Notebook ni el índice). Las notas
  /// grandes se codifican en otro isolate (ver [writeJsonAtomic]).
  Future<void> _saveNoteRaw(Directory base, Note note) async {
    final file = await _noteFile(base, note.id);
    // toJson() aquí: instantánea coherente aunque el lienzo siga mutando la
    // página mientras se escribe.
    await writeJsonAtomic(
      file,
      note.toJson(),
      background: _pointCount(note) > kBackgroundSavePoints,
    );
  }

  /// Puntos de trazo de una nota (aproxima el tamaño de su JSON sin
  /// codificarlo).
  static int _pointCount(Note note) {
    var n = 0;
    for (final page in note.pages) {
      for (final s in page.strokes) {
        n += s.points.length;
      }
    }
    return n;
  }

  /// Modifica solo `notebooks/<id>.json` (título, color, etiquetas o
  /// `noteIds`) y su entrada del índice, **sin leer ni reescribir las
  /// notas**: renombrar o añadir una nota no cuesta O(tamaño del cuaderno).
  ///
  /// [mutate] recibe el JSON del cuaderno; si devuelve false no se escribe
  /// nada. Con [touch] la fecha del cuaderno en el índice pasa a "ahora".
  /// Devuelve false si el cuaderno no existe o [mutate] canceló.
  Future<bool> _editNotebook(
    String id,
    bool Function(Map<String, dynamic> json) mutate, {
    bool touch = false,
  }) async {
    final base = await _baseDir();
    final file = await _notebookFile(base, id);
    final changed = await _notebookQueue.run(() async {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!mutate(json)) return null;
      await writeAtomic(file, jsonEncode(json));
      return json;
    });
    if (changed == null) return false;
    await _updateIndex(base, (metas) {
      final idx = metas.indexWhere((m) => m.id == id);
      if (idx < 0) return;
      final prev = metas[idx];
      metas[idx] = NotebookMeta(
        id: id,
        title: changed['title'] as String? ?? prev.title,
        updatedAt: touch ? DateTime.now() : prev.updatedAt,
        colorValue: (changed['color'] as num?)?.toInt(),
        syncEnabled: prev.syncEnabled,
        favorite: prev.favorite,
        coverStyle: prev.coverStyle,
        coverImagePath: prev.coverImagePath,
        tags: (changed['tags'] as List? ?? const [])
            .map((t) => t as String)
            .toList(),
      );
    });
    return true;
  }

  static List<String> _noteIdsOf(Map<String, dynamic> json) =>
      (json['noteIds'] as List? ?? const []).map((e) => e as String).toList();

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
    await _editNotebook(id, (json) {
      json['title'] = title.trim();
      return true;
    });
  }

  /// Asigna un color de portada a un Notebook.
  Future<void> setNotebookColor(String id, int? colorValue) async {
    await _editNotebook(id, (json) {
      if (colorValue == null) {
        json.remove('color');
      } else {
        json['color'] = colorValue;
      }
      return true;
    });
  }

  /// Establece las etiquetas de un Notebook.
  Future<void> setNotebookTags(String id, List<String> tags) async {
    await _editNotebook(id, (json) {
      if (tags.isEmpty) {
        json.remove('tags');
      } else {
        json['tags'] = List<String>.from(tags);
      }
      return true;
    });
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
      } catch (e) {
        debugPrint('StorageService.deleteNotebook: $e');
      }
    }

    // Mover cada Note y luego el notebook (con la fecha de borrado) a la
    // papelera. Las notas no llevan marca: pertenecen al cuaderno.
    for (final nid in noteIds) {
      await _moveToTrash(base, await _noteFile(base, nid), nid);
    }
    await _moveToTrash(base, nbFile, id, marker: const {});

    // Quitar del índice
    await _updateIndex(base, (metas) => metas.removeWhere((m) => m.id == id));

    // Limpiar imágenes huérfanas en background (no bloquea el retorno).
    unawaited(collectOrphanedImages());
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
      return Note.fromJson(await decodeJsonAsync(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('StorageService.loadNote: $e');
      return null;
    }
  }

  /// Guarda un Note (actualiza su archivo + el updatedAt del Notebook padre).
  ///
  /// Con [touch] (edición local) la nota pasa a fecha "ahora"; sin él se
  /// conserva la suya (copias restauradas de Drive: si no, parecerían más
  /// nuevas que el original y ganarían el last-write-wins).
  Future<void> saveNote(String notebookId, Note note, {bool touch = true}) async {
    final base = await _baseDir();
    // touch() ANTES de escribir: el archivo debe llevar la fecha de este
    // guardado (last-write-wins de Drive y "Recientes" la leen de disco).
    if (touch) note.touch();
    await _saveNoteRaw(base, note);

    // Actualizar el updatedAt del Notebook en el índice
    await _updateIndex(base, (metas) {
      final idx = metas.indexWhere((m) => m.id == notebookId);
      if (idx >= 0) {
        metas[idx] = metas[idx].copyWith(updatedAt: DateTime.now());
      }
    });
  }

  /// Crea un Note nuevo dentro de un Notebook.
  Future<Note> createNote(
    String notebookId, {
    String? title,
    PageTemplate? template,
  }) async {
    final note = Note.newBlank(title: title);
    if (template != null && note.pages.isNotEmpty) {
      note.pages.first.template = template;
    }
    await _saveNoteRaw(await _baseDir(), note);
    final ok = await _editNotebook(notebookId, (json) {
      json['noteIds'] = [..._noteIdsOf(json), note.id];
      return true;
    }, touch: true);
    if (!ok) {
      await _deleteNoteFile(note.id);
      throw StateError('Notebook no encontrado: $notebookId');
    }
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
    // Quitar de la lista (nunca el último note).
    String? notebookTitle;
    final removed = await _editNotebook(notebookId, (json) {
      final ids = _noteIdsOf(json);
      if (ids.length <= 1 || !ids.remove(noteId)) return false;
      json['noteIds'] = ids;
      notebookTitle = json['title'] as String?;
      return true;
    }, touch: true);
    if (!removed) return;

    // A la papelera recordando de qué cuaderno venía (para devolverla).
    await _moveToTrash(base, await _noteFile(base, noteId), noteId, marker: {
      'notebookId': notebookId,
      'notebookTitle': ?notebookTitle,
    });

    // Limpiar imágenes huérfanas en background.
    unawaited(collectOrphanedImages());
  }

  /// Duplica un Note dentro del mismo Notebook.
  Future<Note> duplicateNote(
    String notebookId,
    String noteId,
  ) async {
    final original = await loadNote(noteId);
    if (original == null) throw StateError('Note no encontrado: $noteId');

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

    await _saveNoteRaw(await _baseDir(), newNote);
    // Insertar después del original
    final ok = await _editNotebook(notebookId, (json) {
      final ids = _noteIdsOf(json);
      final idx = ids.indexOf(noteId);
      ids.insert(idx < 0 ? ids.length : idx + 1, newNote.id);
      json['noteIds'] = ids;
      return true;
    }, touch: true);
    if (!ok) {
      await _deleteNoteFile(newNote.id);
      throw StateError('Notebook no encontrado: $notebookId');
    }
    return newNote;
  }

  /// Borra `notes/<id>.json` (deshace una nota recién creada si su cuaderno
  /// no existe).
  Future<void> _deleteNoteFile(String id) async {
    final file = await _noteFile(await _baseDir(), id);
    if (await file.exists()) await file.delete();
  }

  // -------------------------------------------------------------------------
  // Papelera
  // -------------------------------------------------------------------------

  /// Clave con los metadatos de borrado dentro de un JSON de la papelera
  /// (`deletedAt` y, en notas sueltas, `notebookId`/`notebookTitle`).
  static const _trashKey = '_trash';

  /// Días que un elemento pasa en la papelera antes de borrarse solo.
  static const trashRetention = Duration(days: 30);

  Directory _trashDir(Directory base) => Directory('${base.path}/trash');

  /// Mueve [src] a `trash/<id>.json`. Con [marker] se añaden los metadatos
  /// de borrado (+ `deletedAt`) al JSON; sin él se mueve tal cual.
  Future<void> _moveToTrash(
    Directory base,
    File src,
    String id, {
    Map<String, dynamic>? marker,
  }) async {
    if (!await src.exists()) return;
    final dest = File('${_trashDir(base).path}/$id.json');
    if (marker == null) {
      await dest.parent.create(recursive: true);
      await src.copy(dest.path);
    } else {
      final json = jsonDecode(await src.readAsString()) as Map<String, dynamic>;
      json[_trashKey] = {
        ...marker,
        'deletedAt': DateTime.now().toIso8601String(),
      };
      await writeAtomic(dest, jsonEncode(json));
    }
    await src.delete();
  }

  /// JSON de cada archivo de la papelera (id → contenido). Los ilegibles se
  /// omiten.
  Future<Map<String, (File, Map<String, dynamic>)>> _readTrash(Directory base) async {
    final dir = _trashDir(base);
    final result = <String, (File, Map<String, dynamic>)>{};
    if (!await dir.exists()) return result;
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final raw = await entity.readAsString();
        if (raw.trim().isEmpty) continue;
        final id = entity.uri.pathSegments.last.replaceAll('.json', '');
        result[id] = (entity, jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('StorageService._readTrash: ${entity.path}: $e');
      }
    }
    return result;
  }

  /// Lista la papelera (lo borrado más reciente primero): cuadernos, notas
  /// sueltas y documentos legacy. Las notas de un cuaderno borrado van
  /// dentro de su entrada, no sueltas. Lo que lleva más de
  /// [trashRetention] se borra definitivamente al listar.
  Future<List<TrashEntry>> loadTrash() async {
    final base = await _baseDir();
    final files = await _readTrash(base);
    final owned = <String>{
      for (final (_, json) in files.values)
        if (json.containsKey('noteIds')) ..._noteIdsOf(json),
    };
    final entries = <TrashEntry>[];
    final expired = <String>[];
    final now = DateTime.now();
    for (final MapEntry(key: id, value: (file, json)) in files.entries) {
      if (owned.contains(id)) continue;
      final marker = json[_trashKey] as Map<String, dynamic>?;
      final deletedAt =
          DateTime.tryParse(marker?['deletedAt'] as String? ?? '') ??
              await file.lastModified();
      if (now.difference(deletedAt) > trashRetention) {
        expired.add(id);
        continue;
      }
      if (json.containsKey('noteIds')) {
        entries.add(TrashEntry(
          id: id,
          kind: TrashKind.notebook,
          title: json['title'] as String? ?? 'Cuaderno',
          deletedAt: deletedAt,
          colorValue: (json['color'] as num?)?.toInt(),
          noteCount: _noteIdsOf(json).length,
        ));
      } else if (marker?['notebookId'] != null || id.startsWith('note')) {
        entries.add(TrashEntry(
          id: id,
          kind: TrashKind.note,
          title: json['title'] as String? ?? 'Nota',
          deletedAt: deletedAt,
          notebookId: marker?['notebookId'] as String?,
          notebookTitle: marker?['notebookTitle'] as String?,
        ));
      } else {
        final doc = Document.fromJson(json);
        entries.add(TrashEntry(
          id: id,
          kind: TrashKind.legacyDocument,
          title: doc.title,
          deletedAt: deletedAt,
          colorValue: doc.colorValue,
        ));
      }
    }
    for (final id in expired) {
      await _purgeTrashFiles(base, files, id);
    }
    if (expired.isNotEmpty) unawaited(collectOrphanedImages());
    entries.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entries;
  }

  /// Restaura un elemento de la papelera:
  /// - **cuaderno**: vuelve con todas sus notas;
  /// - **nota suelta**: vuelve a su cuaderno si aún existe; si no, a un
  ///   cuaderno nuevo con el nombre del original;
  /// - **documento legacy**: como antes (formato antiguo).
  Future<void> restoreFromTrash(String id) async {
    final base = await _baseDir();
    final files = await _readTrash(base);
    final hit = files[id];
    if (hit == null) return;
    final (trashFile, json) = hit;
    final marker = json.remove(_trashKey) as Map<String, dynamic>?;

    if (json.containsKey('noteIds')) {
      final notesDir = await _notesDir(base);
      for (final nid in _noteIdsOf(json)) {
        final noteTrash = files[nid]?.$1;
        if (noteTrash == null) continue;
        await noteTrash.copy('${notesDir.path}/$nid.json');
        await noteTrash.delete();
      }
      await writeAtomic(await _notebookFile(base, id), jsonEncode(json));
      await trashFile.delete();
      final nb = await loadNotebook(id);
      if (nb != null) {
        await _updateIndex(base, (metas) {
          metas.removeWhere((m) => m.id == nb.id);
          metas.add(NotebookMeta(
            id: nb.id,
            title: nb.title,
            updatedAt: nb.updatedAt,
            colorValue: nb.colorValue,
            coverStyle: nb.coverStyle,
            coverImagePath: nb.coverImagePath,
            tags: nb.tags,
          ));
        });
      }
    } else if (marker?['notebookId'] != null || id.startsWith('note')) {
      final note = Note.fromJson(json);
      final notebookId = marker?['notebookId'] as String?;
      var restored = false;
      if (notebookId != null) {
        await _saveNoteRaw(base, note);
        restored = await _editNotebook(notebookId, (nb) {
          nb['noteIds'] = [..._noteIdsOf(nb), note.id];
          return true;
        }, touch: true);
        if (!restored) await _deleteNoteFile(note.id);
      }
      if (!restored) {
        await saveNotebook(Notebook(
          id: newId('nb'),
          title: marker?['notebookTitle'] as String? ?? 'Notas recuperadas',
          notes: [note],
        ));
      }
      await trashFile.delete();
    } else {
      // ---- Formato Document legacy ----
      final docs = await _docsDir(base);
      await writeAtomic(File('${docs.path}/$id.json'), jsonEncode(json));
      await trashFile.delete();
      final doc = await load(id);
      if (doc != null) await save(doc);
    }
  }

  /// Elimina definitivamente un elemento de la papelera (un cuaderno, con
  /// sus notas).
  Future<void> purgeFromTrash(String id) async {
    final base = await _baseDir();
    await _purgeTrashFiles(base, await _readTrash(base), id);
    unawaited(collectOrphanedImages());
  }

  Future<void> _purgeTrashFiles(
    Directory base,
    Map<String, (File, Map<String, dynamic>)> files,
    String id,
  ) async {
    final hit = files[id];
    if (hit == null) return;
    final (file, json) = hit;
    for (final nid in _noteIdsOf(json)) {
      final noteFile = files[nid]?.$1;
      if (noteFile != null && await noteFile.exists()) await noteFile.delete();
    }
    if (await file.exists()) await file.delete();
  }

  /// Vacía toda la papelera (elimina definitivamente todo).
  Future<void> emptyTrash() async {
    final base = await _baseDir();
    final trashDir = _trashDir(base);
    if (await trashDir.exists()) await trashDir.delete(recursive: true);
    // Limpiar imágenes huérfanas.
    unawaited(collectOrphanedImages());
  }

  // -------------------------------------------------------------------------
  // Respaldo local completo (todos los cuadernos en un ZIP)
  // -------------------------------------------------------------------------

  static const _backupManifest = 'backup.json';
  static const _backupVersion = 2;

  /// Carpetas incluidas en el respaldo completo.
  static const _backupFolders = [
    _notebooksFolder,
    _notesFolder,
    _documentsFolder,
    'images',
    'restored', // imágenes extraídas de .inklus / Drive
    'pdf_imports',
    'templates',
    'trash',
  ];

  /// Archivos sueltos de datos del usuario incluidos en el respaldo
  /// (el índice de búsqueda no: se regenera).
  static const _backupRootFiles = [
    'reminders.json',
    'stats.json',
    'calendar_links.json',
  ];

  /// Exporta todos los cuadernos + imágenes en un único ZIP.
  ///
  /// Estructura del ZIP:
  /// - `backup.json` — manifiesto (versión + ruta base original, para
  ///   re-mapear rutas absolutas de imágenes al restaurar en otro equipo).
  /// - `index.json` — índice de todos los cuadernos.
  /// - `notebooks/<id>.json`, `notes/<id>.json` — contenido actual.
  /// - `documents/<id>.json` — formato legacy (si queda alguno).
  /// - `images/<path>` — imágenes compartidas.
  /// - `trash/<id>.json` — papelera.
  Future<Uint8List> exportFullBackup() async {
    final base = await _baseDir();
    final files = <String, Uint8List>{};

    final manifest = utf8.encode(jsonEncode({
      'backupVersion': _backupVersion,
      'basePath': base.path,
      'createdAt': DateTime.now().toIso8601String(),
    }));
    files[_backupManifest] = Uint8List.fromList(manifest);

    final indexFile = await _indexFile(base);
    if (await indexFile.exists()) {
      files[_indexName] = await indexFile.readAsBytes();
    }

    for (final name in _backupRootFiles) {
      final f = File('${base.path}/$name');
      if (await f.exists()) files[name] = await f.readAsBytes();
    }

    for (final folder in _backupFolders) {
      final dir = Directory('${base.path}/$folder');
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File || entity.path.contains('.tmp-')) continue;
        final relative = entity.path.substring(base.path.length + 1);
        files[relative] = await entity.readAsBytes();
      }
    }

    // La compresión ZIP es CPU pura: fuera del hilo de UI.
    return Isolate.run(() {
      final archive = Archive();
      files.forEach((name, bytes) {
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      });
      return Uint8List.fromList(ZipEncoder().encode(archive));
    });
  }

  /// Importa un backup completo (ZIP exportado por [exportFullBackup]).
  ///
  /// **Fusiona** con lo existente: los cuadernos del backup se añaden o
  /// reemplazan a los locales con el mismo id; los demás cuadernos locales se
  /// conservan. Las entradas con rutas inseguras (`..`, absolutas) se ignoran.
  ///
  /// Devuelve el número de cuadernos restaurados.
  Future<int> importFullBackup(Uint8List zipBytes) async {
    final entries = await Isolate.run(() {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      return {
        for (final f in archive)
          if (f.isFile) f.name: Uint8List.fromList(f.content as List<int>),
      };
    });
    final base = await _baseDir();

    // Ruta base del equipo de origen (para re-mapear rutas de imágenes).
    String? oldBase;
    final manifestBytes = entries[_backupManifest];
    if (manifestBytes != null) {
      try {
        final m = jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
        oldBase = m['basePath'] as String?;
      } catch (e) {
        debugPrint('StorageService.importFullBackup: manifiesto inválido: $e');
      }
    }

    Uint8List remap(Uint8List data) {
      if (oldBase == null || oldBase == base.path) return data;
      // Las rutas se guardan como strings JSON: se reemplaza el prefijo
      // tanto en su forma literal como escapada (`\/`).
      final text = utf8
          .decode(data)
          .replaceAll(oldBase, base.path)
          .replaceAll(
            oldBase.replaceAll('/', r'\/'),
            base.path.replaceAll('/', r'\/'),
          );
      return Uint8List.fromList(utf8.encode(text));
    }

    final legacyDocIds = <String>[];
    for (final entry in entries.entries) {
      final name = entry.key;
      if (name == _backupManifest || name == _indexName) continue;
      final top = name.split('/').first;
      if (!_backupFolders.contains(top) && !_backupRootFiles.contains(name)) {
        continue;
      }
      final outPath = safeJoin(base.path, name);
      if (outPath == null) {
        debugPrint('StorageService.importFullBackup: ruta insegura ignorada: $name');
        continue;
      }
      final isJson = name.endsWith('.json') &&
          top != 'images' &&
          top != 'restored' &&
          top != 'pdf_imports';
      await writeAtomic(File(outPath), isJson ? remap(entry.value) : entry.value);
      if (top == _documentsFolder && name.endsWith('.json')) {
        legacyDocIds.add(name.split('/').last.replaceAll('.json', ''));
      }
    }

    // Reconstruir los metas a partir del índice del backup.
    final restored = <NotebookMeta>[];
    final indexBytes = entries[_indexName];
    var isLegacyIndex = indexBytes == null;
    if (indexBytes != null) {
      try {
        final json = jsonDecode(utf8.decode(remap(indexBytes)))
            as Map<String, dynamic>;
        if (json['formatVersion'] == _formatVersion) {
          restored.addAll((json['notebooks'] as List? ?? [])
              .map((m) => NotebookMeta.fromJson(m as Map<String, dynamic>)));
        } else {
          isLegacyIndex = true;
        }
      } catch (e) {
        debugPrint('StorageService.importFullBackup: índice inválido: $e');
        isLegacyIndex = true;
      }
    }

    // Backup antiguo (solo documents/): migrar cada Document a Notebook+Note.
    if (isLegacyIndex) {
      for (final id in legacyDocIds) {
        final doc = await load(id);
        if (doc == null) continue;
        restored.add(await _migrateDocumentToNotebook(base, doc));
      }
    }

    await _updateIndex(base, (metas) {
      for (final m in restored) {
        metas.removeWhere((e) => e.id == m.id);
        metas.add(m);
      }
    });
    return restored.length;
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
      } catch (e) {
        debugPrint('StorageService._collectReferencedImagePaths: $e');
      }
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
        } catch (e) {
          debugPrint('StorageService._collectReferencedImagePaths: $e');
        }
      }
    }

    // 3. Versiones locales (historial): restaurarlas no debe dejar huecos.
    final versionsDir = Directory('${base.path}/versions');
    if (await versionsDir.exists()) {
      await for (final entity in versionsDir.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.json.gz')) continue;
        try {
          final raw = utf8.decode(gzip.decode(await entity.readAsBytes()));
          final json = jsonDecode(raw);
          if (json is Map<String, dynamic>) {
            _extractImagePaths(Note.fromJson(json), referenced);
          }
        } catch (e) {
          debugPrint('StorageService._collectReferencedImagePaths: $e');
        }
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

  bool _collectingOrphans = false;

  /// Elimina imágenes de `inklus/images/` que no están referenciadas por
  /// ningún Note (activo o en papelera). Ejecuta en background.
  ///
  /// Las imágenes modificadas hace menos de [minAge] se respetan: pueden
  /// pertenecer a una nota cuyo autoguardado aún no se ha escrito.
  Future<void> collectOrphanedImages({
    Duration minAge = const Duration(minutes: 10),
  }) async {
    if (_collectingOrphans) return;
    _collectingOrphans = true;
    try {
      final base = await _baseDir();
      final imagesDir = Directory('${base.path}/images');
      if (!await imagesDir.exists()) return;

      final referenced = await _collectReferencedImagePaths();
      final now = DateTime.now();
      var deleted = 0;

      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is! File) continue;
        if (referenced.contains(entity.path)) continue;
        try {
          if (now.difference(await entity.lastModified()) < minAge) continue;
          await entity.delete();
          deleted++;
        } catch (e) {
          debugPrint('StorageService.collectOrphanedImages: ${entity.path}: $e');
        }
      }

      if (deleted > 0) {
        debugPrint('StorageService: $deleted imagen(es) huérfana(s) eliminada(s).');
      }
    } catch (e) {
      debugPrint('StorageService.collectOrphanedImages: $e');
    } finally {
      _collectingOrphans = false;
    }
  }
}

/// Tipo de elemento de la papelera.
enum TrashKind {
  /// Cuaderno completo (con sus notas).
  notebook,

  /// Nota borrada de un cuaderno que sigue existiendo.
  note,

  /// Documento del formato antiguo.
  legacyDocument,
}

/// Elemento de la papelera, listo para mostrarse.
class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.deletedAt,
    this.colorValue,
    this.noteCount = 0,
    this.notebookId,
    this.notebookTitle,
  });

  final String id;
  final TrashKind kind;
  final String title;
  final DateTime deletedAt;
  final int? colorValue;

  /// Notas del cuaderno ([TrashKind.notebook]).
  final int noteCount;

  /// Cuaderno del que venía una nota ([TrashKind.note]).
  final String? notebookId;
  final String? notebookTitle;

  /// Días que le quedan antes del borrado automático.
  int get daysLeft {
    final left = StorageService.trashRetention -
        DateTime.now().difference(deletedAt);
    return left.isNegative ? 0 : (left.inMinutes / Duration.minutesPerDay).ceil();
  }
}
