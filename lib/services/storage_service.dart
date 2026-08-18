import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document.dart';
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

  const NotebookMeta({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.colorValue,
    this.syncEnabled,
  });

  /// Por defecto la sincronización está activa.
  bool get isSyncEnabled => syncEnabled ?? true;

  NotebookMeta copyWith({
    String? title,
    DateTime? updatedAt,
    int? colorValue,
    bool? syncEnabled,
  }) =>
      NotebookMeta(
        id: id,
        title: title ?? this.title,
        updatedAt: updatedAt ?? this.updatedAt,
        colorValue: colorValue ?? this.colorValue,
        syncEnabled: syncEnabled ?? this.syncEnabled,
      );

  factory NotebookMeta.fromJson(Map<String, dynamic> json) => NotebookMeta(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Sin título',
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        colorValue: (json['color'] as num?)?.toInt(),
        syncEnabled: json['syncEnabled'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        if (colorValue != null) 'color': colorValue,
        if (syncEnabled != null) 'syncEnabled': syncEnabled,
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
  static const _legacyFileName = 'current_document.json';

  /// Directorio base opcional (para tests); si es null se usa el soporte de
  /// datos de la app (`getApplicationSupportDirectory`).
  final Directory? _baseDirOverride;

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

  Future<File> _indexFile(Directory base) async =>
      File('${base.path}/$_indexName');

  Future<File> _docFile(Directory base, String id) async {
    final docs = await _docsDir(base);
    return File('${docs.path}/$id.json');
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
      'documents': metas.map((m) => m.toJson()).toList(),
    }));
  }

  /// Lista los cuadernos guardados, ordenados por `updatedAt` descendente.
  ///
  /// En la primera ejecución migra el antiguo `current_document.json` al
  /// nuevo formato si aún no existe el índice.
  Future<List<NotebookMeta>> loadIndex() async {
    final base = await _baseDir();
    var metas = await _readIndex(base);
    if (metas.isEmpty) {
      final migrated = await _migrateLegacy(base);
      if (migrated != null) metas = [migrated];
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
      final meta = await save(doc);
      // El documento ya está en documents/<id>.json; eliminamos el legacy
      // para que la migración no se repita en cada arranque.
      await legacy.delete();
      return meta;
    } catch (e) {
      debugPrint('StorageService._migrateLegacy: $e');
      return null;
    }
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
    ));
    await _writeIndex(base, metas);
    return NotebookMeta(
      id: document.id,
      title: document.title,
      updatedAt: document.updatedAt,
      colorValue: document.colorValue,
    );
  }

  /// Crea un cuaderno nuevo en blanco y lo guarda.
  Future<Document> create({String? title}) async {
    final doc = Document.newBlank(title: title);
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
  // Papelera
  // -------------------------------------------------------------------------

  /// Lista los cuadernos en la papelera, ordenados por fecha de eliminación
  /// (el más reciente primero).
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
        final doc = Document.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        metas.add(NotebookMeta(
          id: doc.id,
          title: doc.title,
          updatedAt: doc.updatedAt,
          colorValue: doc.colorValue,
        ));
      } catch (_) {
        // Archivo corrupto, ignorar.
      }
    }
    metas.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return metas;
  }

  /// Restaura un cuaderno desde la papelera al índice.
  Future<void> restoreFromTrash(String id) async {
    final base = await _baseDir();
    final trashFile = File('${base.path}/trash/$id.json');
    if (!await trashFile.exists()) return;
    final docs = await _docsDir(base);
    final docFile = File('${docs.path}/$id.json');
    await trashFile.copy(docFile.path);
    await trashFile.delete();
    // Reconstruir el índice leyendo el documento restaurado.
    final doc = await load(id);
    if (doc != null) await save(doc);
  }

  /// Carga un documento completo desde la papelera.
  Future<Document?> loadFromTrash(String id) async {
    final base = await _baseDir();
    final trashFile = File('${base.path}/trash/$id.json');
    try {
      if (!await trashFile.exists()) return null;
      final raw = await trashFile.readAsString();
      if (raw.trim().isEmpty) return null;
      return Document.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
  }

  /// Vacía toda la papelera (elimina definitivamente todo).
  Future<void> emptyTrash() async {
    final base = await _baseDir();
    final trashDir = Directory('${base.path}/trash');
    if (await trashDir.exists()) await trashDir.delete(recursive: true);
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
}
