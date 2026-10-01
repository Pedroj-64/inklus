// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/document.dart';
import '../models/id.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import 'inklus_format.dart';
import 'storage_service.dart';
import 'app_errors.dart';
import '../l10n/l10n.dart';

/// Qué contiene un archivo que el usuario quiere importar.
enum ImportKind {
  /// `.inklus` v2: un cuaderno completo (format.json + notebook.json).
  notebook,

  /// `.inklus` v1 (document.json): se convierte en un cuaderno con una nota.
  legacyDocument,

  /// Respaldo completo de la biblioteca (backup.json / index.json).
  fullBackup,
}

/// Resultado de una importación, listo para mostrarse al usuario.
class ImportResult {
  const ImportResult(this.kind, {this.title = '', this.count = 0, this.notebookId});

  final ImportKind kind;

  /// Título del cuaderno importado y su número de notas (o de cuadernos en un
  /// respaldo completo): con ellos la UI arma el mensaje traducido.
  final String title;
  final int count;

  String message(AppLocalizations l10n) => switch (kind) {
        ImportKind.fullBackup => l10n.importBackupRestored(count),
        ImportKind.notebook => l10n.importNotebookDone(title, count),
        ImportKind.legacyDocument => l10n.importNotebookSimple(title),
      };

  /// Cuaderno creado (null en un respaldo completo).
  final String? notebookId;
}

/// Punto único de importación: **detecta el tipo por el contenido**, no por
/// la extensión. Así se aceptan `.inklus`, respaldos `.zip` y también los
/// `.inklus` que Android/Drive renombraron a `.zip` o `.inklus.zip` (el
/// contenedor es un ZIP y algunos gestores añaden la extensión).
abstract final class ImportService {
  /// Abre el selector de archivos. En Android/iOS no se filtra por
  /// extensión: `.inklus` no tiene tipo MIME registrado y el filtro
  /// ocultaba los archivos (o solo dejaba ver `.zip`).
  static Future<Uint8List?> pickFile() async =>
      (await pickPlatformFile())?.xFile.readAsBytes();

  /// Como [pickFile], pero conserva el nombre del archivo elegido.
  static Future<PlatformFile?> pickPlatformFile() async {
    final mobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final files = mobile
        ? await FilePicker.pickFiles(type: FileType.any)
        : await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['inklus', 'zip'],
          );
    return files.isEmpty ? null : files.first;
  }

  /// Detecta el tipo de archivo. Lanza [FormatException] si no es de Inklus.
  static Future<ImportKind> detect(Uint8List bytes) async {
    final names = await Isolate.run(() {
      try {
        return ZipDecoder().decodeBytes(bytes).files.map((f) => f.name).toSet();
      } catch (_) {
        return <String>{};
      }
    });
    return kindFor(names);
  }

  /// Regla de detección a partir de los nombres de las entradas del ZIP.
  @visibleForTesting
  static ImportKind kindFor(Set<String> names) {
    if (names.contains('backup.json') || names.contains('index.json')) {
      return ImportKind.fullBackup;
    }
    // Una nota suelta (copia de Drive, "copia .inklus") es v1 aunque lleve
    // format.json: manda la entrada de contenido.
    if (names.contains('notebook.json')) return ImportKind.notebook;
    if (names.contains('document.json')) return ImportKind.legacyDocument;
    throw const AppError(AppErrorCode.notInklus);
  }

  /// Importa [bytes] en la biblioteca y describe lo que se hizo.
  static Future<ImportResult> importBytes(
    Uint8List bytes, {
    StorageService? storage,
    @visibleForTesting Directory? extractTo,
  }) async {
    final s = storage ?? StorageService.instance;
    final kind = await detect(bytes);
    switch (kind) {
      case ImportKind.fullBackup:
        final count = await s.importFullBackup(bytes);
        return ImportResult(kind, count: count);
      case ImportKind.notebook:
      case ImportKind.legacyDocument:
        final result = await InklusFormat.importAuto(bytes, extractTo: extractTo);
        if (result is Notebook) {
          await s.saveNotebook(result);
          return ImportResult(
            kind,
            title: result.title,
            count: result.notes.length,
            notebookId: result.id,
          );
        }
        final doc = result as Document;
        // Id nuevo: la nota original puede seguir en la biblioteca y dos
        // cuadernos no deben compartir `notes/<id>.json`.
        final note = Note(
          id: newId('note'),
          title: doc.title,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          pages: doc.pages,
        );
        final nb = Notebook(id: newId('nb'), title: doc.title, notes: [note]);
        await s.saveNotebook(nb);
        return ImportResult(kind, title: doc.title, notebookId: nb.id);
    }
  }
}
