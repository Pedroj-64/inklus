// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/document.dart';
import '../models/image_item.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/page.dart';
import '../models/template.dart';
import 'file_utils.dart';
import 'app_paths.dart';
import 'app_errors.dart';

/// Formato propietario **.inklus v2**: contenedor autocontenido de un cuaderno.
///
/// Estructura ZIP optimizada:
/// ```
/// .inklus
/// ├── format.json          ← version marker {"version":2}
/// ├── notebook.json        ← metadata del cuaderno
/// ├── notes/<note-id>.json  ← un archivo por Note (páginas, trazos, plantillas)
/// └── images/<name>        ← imágenes embebidas
/// ```
///
/// **Ventajas vs v1** (document.json monolítico):
/// - Los Notes se guardan por separado → parseo parcial posible.
/// - La metadata se lee sin cargar el contenido de las páginas.
/// - Las imágenes siguen embebidas (autocontenido).
///
/// Se mantiene compatibilidad con v1 (document.json) para importar
/// archivos antiguos.
class InklusFormat {
  InklusFormat._();

  // Nombres de entrada en el ZIP
  static const _formatEntry = 'format.json';
  static const _docEntry = 'document.json'; // v1 (legacy)
  static const _notebookEntry = 'notebook.json'; // v2
  static const _notesPrefix = 'notes/';
  static const _imagesPrefix = 'images/';
  static const _audioPrefix = 'audio/';
  static const _recordingsEntry = 'recordings.json'; // v1: grabaciones de la nota
  static const _flashcardsEntry = 'flashcards.json'; // v1: tarjetas de estudio
  static const scheme = 'inklus://';

  static const _currentVersion = 2;

  // -------------------------------------------------------------------------
  // Exportación v2 (Notebook → bytes .inklus)
  // -------------------------------------------------------------------------

  /// Serializa un [Notebook] completo al formato .inklus v2.
  ///
  /// Cada [Note] se serializa como un archivo JSON independiente dentro
  /// del ZIP, y las imágenes de todas las páginas se embeben en `images/`.
  static Future<Uint8List> exportNotebookBytes(Notebook notebook) async {
    // 1) Recopilar imágenes de todos los notes.
    final images = <String, Future<Uint8List>>{};
    final audio = <String, Future<Uint8List>>{};

    final notesData = <String, Map<String, dynamic>>{};
    for (final note in notebook.notes) {
      final processedNote = await _processNoteForExport(note, images, audio);
      notesData[note.id] = processedNote;
    }

    // 2) Construir el ZIP.
    final archive = Archive();

    // format.json
    final formatBytes = utf8.encode(jsonEncode({'version': _currentVersion}));
    archive.addFile(ArchiveFile(_formatEntry, formatBytes.length, formatBytes));

    // notebook.json (metadata sin páginas)
    final notebookMeta = {
      'id': notebook.id,
      'title': notebook.title,
      'color': notebook.colorValue,
      'coverStyle': notebook.coverStyle,
      if (notebook.coverImagePath != null) 'coverImagePath': notebook.coverImagePath,
      if (notebook.tags.isNotEmpty) 'tags': notebook.tags,
      'noteIds': notebook.notes.map((n) => n.id).toList(),
    };
    final nbBytes = utf8.encode(jsonEncode(notebookMeta));
    archive.addFile(ArchiveFile(_notebookEntry, nbBytes.length, nbBytes));

    // notes/<id>.json
    for (final entry in notesData.entries) {
      final bytes = utf8.encode(jsonEncode(entry.value));
      archive.addFile(
        ArchiveFile('$_notesPrefix${entry.key}.json', bytes.length, bytes),
      );
    }

    // images/<name>
    for (final entry in images.entries) {
      final bytes = await entry.value;
      archive.addFile(
        ArchiveFile('$_imagesPrefix${entry.key}', bytes.length, bytes),
      );
    }
    await _addAudio(archive, audio);

    return ZipEncoder().encodeBytes(archive);
  }

  // -------------------------------------------------------------------------
  // Importación v2 (bytes .inklus → Notebook)
  // -------------------------------------------------------------------------

  /// Detecta la versión del .inklus y delega al importer correcto.
  ///
  /// Se decide por `notebook.json` (v2), **no** por `format.json`: las
  /// copias de una sola nota (Drive, "copia .inklus" del editor) son v1 y
  /// también llevan `format.json`.
  static Future<Object> importAuto(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.files.any((f) => f.name == _notebookEntry)) {
      return importNotebookBytes(bytes, extractTo: extractTo);
    }
    // v1 legacy → devuelve Document
    return importBytes(bytes, extractTo: extractTo);
  }

  /// Importa un .inklus v2 y devuelve un [Notebook] restaurado.
  static Future<Notebook> importNotebookBytes(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    // Leer todas las entradas.
    Uint8List? notebookBytes;
    final noteEntries = <String, Uint8List>{};
    final imageEntries = <String, Uint8List>{};

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final data = file.readBytes();
      if (data == null) continue;

      if (file.name == _notebookEntry) {
        notebookBytes = data;
      } else if (file.name.startsWith(_notesPrefix)) {
        final noteId = file.name
            .substring(_notesPrefix.length)
            .replaceAll('.json', '');
        noteEntries[noteId] = data;
      } else if (file.name.startsWith(_imagesPrefix) || file.name.startsWith(_audioPrefix)) {
        imageEntries[file.name] = data;
      }
    }

    if (notebookBytes == null) {
      throw const AppError(AppErrorCode.notInklusV2);
    }

    final nbJson = jsonDecode(utf8.decode(notebookBytes)) as Map<String, dynamic>;

    // Crear directorio de extracción.
    final docId = nbJson['id'] as String;
    final dir = extractTo ??
        Directory(
          (await AppPaths.restored(docId)).path,
        );
    await dir.create(recursive: true);

    // Extraer imágenes.
    final extractedImages = <String, String>{};
    for (final entry in imageEntries.entries) {
      final fileName = safeFileName(entry.key);
      if (fileName == null) continue; // nombre inseguro/vacío: se ignora
      final file = File('${dir.path}/$fileName');
      await writeAtomic(file, entry.value);
      extractedImages[entry.key] = file.path;
    }

    // Reconstruir Notes.
    final notes = <Note>[];
    final noteIds = (nbJson['noteIds'] as List?)?.cast<String>() ?? [];
    for (final noteId in noteIds) {
      final noteBytes = noteEntries[noteId];
      if (noteBytes == null) continue;
      final noteJson = jsonDecode(utf8.decode(noteBytes)) as Map<String, dynamic>;
      final note = _rebuildNote(noteJson, extractedImages);
      note.recordings.addAll(_rebuildRecordings(noteJson['recordings'], extractedImages));
      note.flashcards.addAll(Note.fromJson({'id': '', 'flashcards': noteJson['flashcards']}).flashcards);
      notes.add(note);
    }

    return Notebook(
      id: docId,
      title: nbJson['title'] as String? ?? 'Sin título',
      colorValue: (nbJson['color'] as num?)?.toInt(),
      coverStyle: nbJson['coverStyle'] as String? ?? 'simple',
      coverImagePath: nbJson['coverImagePath'] as String?,
      tags: (nbJson['tags'] as List? ?? []).map((t) => t as String).toList(),
      notes: notes,
    );
  }

  // -------------------------------------------------------------------------
  // Exportación v1 legacy (Document → bytes .inklus)
  // -------------------------------------------------------------------------

  static Future<Uint8List> exportBytes(Document document) async {
    final images = <String, Future<Uint8List>>{};
    final pages = <Page>[];
    for (final page in document.pages) {
      final newImages = <ImageItem>[];
      for (final item in page.images) {
        final file = File(item.localPath);
        if (await file.exists()) {
          final name = _basename(item.localPath);
          images.putIfAbsent(name, () => file.readAsBytes());
          newImages.add(item.copyWith(localPath: _embedKey(name)));
        } else {
          newImages.add(item);
        }
      }
      var template = page.template;
      final templatePath = template.imagePath;
      if (templatePath != null) {
        final file = File(templatePath);
        if (await file.exists()) {
          final name = _basename(templatePath);
          images.putIfAbsent(name, () => file.readAsBytes());
          template = template.copyWith(imagePath: _embedKey(name));
        }
      }
      pages.add(page.copyWith(images: newImages, template: template));
    }

    final outDoc = Document(
      id: document.id,
      title: document.title,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      pages: pages,
    );

    final archive = Archive();
    final formatBytes = utf8.encode(jsonEncode({'version': 1}));
    archive.addFile(ArchiveFile(_formatEntry, formatBytes.length, formatBytes));
    final docBytes = utf8.encode(jsonEncode(outDoc.toJson()));
    archive.addFile(ArchiveFile(_docEntry, docBytes.length, docBytes));
    for (final entry in images.entries) {
      final bytes = await entry.value;
      archive.addFile(
        ArchiveFile('$_imagesPrefix${entry.key}', bytes.length, bytes),
      );
    }
    if (document.flashcards.isNotEmpty) {
      final b = utf8.encode(jsonEncode([for (final c in document.flashcards) c.toJson()]));
      archive.addFile(ArchiveFile(_flashcardsEntry, b.length, b));
    }
    if (document.recordings.isNotEmpty) {
      final audio = <String, Future<Uint8List>>{};
      final recBytes = utf8.encode(jsonEncode(await _embedRecordings(document.recordings, audio)));
      archive.addFile(ArchiveFile(_recordingsEntry, recBytes.length, recBytes));
      await _addAudio(archive, audio);
    }
    return ZipEncoder().encodeBytes(archive);
  }

  // -------------------------------------------------------------------------
  // Importación v1 legacy (bytes .inklus → Document)
  // -------------------------------------------------------------------------

  static Future<Document> importBytes(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    Uint8List? docBytes;
    final entries = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final data = file.readBytes();
      if (data == null) continue;
      if (file.name == _docEntry) {
        docBytes = data;
      } else {
        entries[file.name] = data;
      }
    }
    if (docBytes == null) {
      throw const AppError(AppErrorCode.notInklusFile);
    }

    final doc = Document.fromJson(
      jsonDecode(utf8.decode(docBytes)) as Map<String, dynamic>,
    );
    final dir = extractTo ??
        Directory(
          (await AppPaths.restored(doc.id)).path,
        );
    await dir.create(recursive: true);

    final pages = <Page>[];
    for (final page in doc.pages) {
      final images = <ImageItem>[];
      for (final item in page.images) {
        images.add(
          item.copyWith(localPath: await _materialize(item.localPath, dir, entries)),
        );
      }
      var template = page.template;
      final templatePath = template.imagePath;
      if (templatePath != null) {
        template = template.copyWith(
          imagePath: await _materialize(templatePath, dir, entries),
        );
      }
      pages.add(page.copyWith(images: images, template: template));
    }
    final recordings = <AudioRecording>[];
    final recBytes = entries[_recordingsEntry];
    if (recBytes != null) {
      final extracted = <String, String>{};
      for (final e in entries.entries) {
        if (!e.key.startsWith(_audioPrefix)) continue;
        final name = safeFileName(e.key);
        if (name == null) continue;
        final f = File('${dir.path}/$name');
        await writeAtomic(f, e.value);
        extracted[e.key] = f.path;
      }
      recordings.addAll(_rebuildRecordings(jsonDecode(utf8.decode(recBytes)), extracted));
    }
    return Document(
      id: doc.id,
      title: doc.title,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      pages: pages,
      recordings: recordings,
      flashcards: entries[_flashcardsEntry] == null
          ? null
          : Note.fromJson({'id': '', 'flashcards': jsonDecode(utf8.decode(entries[_flashcardsEntry]!))}).flashcards,
    );
  }

  // -------------------------------------------------------------------------
  // Variantes Note (envuelve Document)
  // -------------------------------------------------------------------------

  static Future<Uint8List> exportNoteBytes(Note note) async {
    final doc = Document(
      id: note.id,
      title: note.title,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      pages: note.pages,
      recordings: note.recordings,
      flashcards: note.flashcards,
    );
    return exportBytes(doc);
  }

  static Future<Note> importNoteBytes(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final doc = await importBytes(bytes, extractTo: extractTo);
    return Note(
      id: doc.id,
      title: doc.title,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      pages: doc.pages,
      recordings: doc.recordings,
      flashcards: doc.flashcards,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers internos
  // -------------------------------------------------------------------------

  /// Procesa un Note para exportación: reescribe rutas de imágenes
  /// a `inklus://images/<nombre>` y recopila los bytes de las imágenes.
  static Future<Map<String, dynamic>> _processNoteForExport(
    Note note,
    Map<String, Future<Uint8List>> images,
    Map<String, Future<Uint8List>> audio,
  ) async {
    final pages = <Map<String, dynamic>>[];
    for (final page in note.pages) {
      final newImages = <Map<String, dynamic>>[];
      for (final item in page.images) {
        final file = File(item.localPath);
        if (await file.exists()) {
          final name = _basename(item.localPath);
          images.putIfAbsent(name, () => file.readAsBytes());
          newImages.add(item.copyWith(localPath: _embedKey(name)).toJson());
        } else {
          newImages.add(item.toJson());
        }
      }
      var template = page.template;
      final templatePath = template.imagePath;
      if (templatePath != null) {
        final file = File(templatePath);
        if (await file.exists()) {
          final name = _basename(templatePath);
          images.putIfAbsent(name, () => file.readAsBytes());
          template = template.copyWith(imagePath: _embedKey(name));
        }
      }
      // Desde toJson: conserva todos los campos (marcadores, enlaces…).
      pages.add({
        ...page.toJson(),
        'images': newImages,
        'template': template.toJson(),
      });
    }

    return {
      'id': note.id,
      'title': note.title,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'pages': pages,
      if (note.recordings.isNotEmpty)
        'recordings': await _embedRecordings(note.recordings, audio),
      if (note.flashcards.isNotEmpty)
        'flashcards': [for (final c in note.flashcards) c.toJson()],
    };
  }

  /// Reconstruye un Note desde su JSON + imágenes extraídas.
  static Note _rebuildNote(
    Map<String, dynamic> json,
    Map<String, String> extractedImages,
  ) {
    final pages = (json['pages'] as List? ?? []).map((p) {
      final pageJson = p as Map<String, dynamic>;
      // Reconstruir imágenes con rutas locales.
      final images = (pageJson['images'] as List? ?? []).map((imgJson) {
        final item = ImageItem.fromJson(imgJson as Map<String, dynamic>);
        if (item.localPath.startsWith(scheme)) {
          final key = item.localPath.substring(scheme.length);
          final localPath = extractedImages[key];
          if (localPath != null) {
            return item.copyWith(localPath: localPath);
          }
        }
        return item;
      }).toList();

      // Reconstruir template con ruta de imagen local.
      var template = PageTemplate.fromJson(
        pageJson['template'] as Map<String, dynamic>,
      );
      if (template.imagePath != null && template.imagePath!.startsWith(scheme)) {
        final key = template.imagePath!.substring(scheme.length);
        final localPath = extractedImages[key];
        if (localPath != null) {
          template = template.copyWith(imagePath: localPath);
        }
      }

      // Desde fromJson: conserva todos los campos (marcadores, enlaces…).
      return Page.fromJson(pageJson).copyWith(images: images, template: template);
    }).toList();

    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sin título',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      pages: pages,
    );
  }

  /// Convierte una ruta `inklus://images/<nombre>` en un archivo local.
  static Future<String> _materialize(
    String path,
    Directory dir,
    Map<String, Uint8List> entries,
  ) async {
    if (!path.startsWith(scheme)) return path;
    final key = path.substring(scheme.length);
    final bytes = entries[key];
    if (bytes == null) return path;
    final fileName = safeFileName(key);
    if (fileName == null) return path;
    final file = File('${dir.path}/$fileName');
    await writeAtomic(file, bytes);
    return file.path;
  }

  static String _basename(String path) => path.split('/').last;

  /// Grabaciones con la ruta reescrita a `inklus://audio/<nombre>`; recoge
  /// los bytes de los archivos que existen.
  static Future<List<Map<String, dynamic>>> _embedRecordings(
    List<AudioRecording> recs,
    Map<String, Future<Uint8List>> audio,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final r in recs) {
      final file = File(r.path);
      if (!await file.exists()) continue; // sin archivo no sirve la ficha
      final name = _basename(r.path);
      audio.putIfAbsent(name, file.readAsBytes);
      out.add(r.withPath('$scheme$_audioPrefix$name').toJson());
    }
    return out;
  }

  static Future<void> _addAudio(Archive archive, Map<String, Future<Uint8List>> audio) async {
    for (final e in audio.entries) {
      final bytes = await e.value;
      archive.addFile(ArchiveFile('$_audioPrefix${e.key}', bytes.length, bytes));
    }
  }

  /// Fichas de grabación con la ruta local del audio extraído (las que no
  /// tienen archivo en el paquete se descartan).
  static List<AudioRecording> _rebuildRecordings(Object? json, Map<String, String> extracted) => [
        for (final r in json is List ? json : const [])
          if (r is Map<String, dynamic>)
            if (AudioRecording.fromJson(r) case final rec when rec.path.startsWith(scheme))
              if (extracted[rec.path.substring(scheme.length)] case final local?) rec.withPath(local),
      ];

  static String _embedKey(String name) => '$scheme$_imagesPrefix$name';
}
