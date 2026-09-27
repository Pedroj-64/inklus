// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'file_utils.dart';
import 'storage_service.dart';

/// Una versión guardada de una nota.
class NoteVersion {
  final String noteId;
  final DateTime savedAt;
  final int sizeBytes;
  final String path;

  const NoteVersion({
    required this.noteId,
    required this.savedAt,
    required this.sizeBytes,
    required this.path,
  });
}

/// Historial de versiones **local** (offline, sin cuenta).
///
/// Guarda instantáneas comprimidas de cada nota en
/// `<appSupport>/inklus/versions/<noteId>/<millis>.json.gz` y conserva las
/// [maxVersions] más recientes. Complementa (no sustituye) las revisiones de
/// Google Drive.
class VersionHistoryService {
  VersionHistoryService({
    StorageService? storage,
    this.maxVersions = 20,
    this.minInterval = const Duration(minutes: 10),
  }) : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  /// Número máximo de versiones por nota (las más antiguas se borran).
  final int maxVersions;

  /// Separación mínima entre instantáneas automáticas.
  final Duration minInterval;

  Future<Directory> _dirFor(String noteId) async {
    final base = await _storage.baseDirectory();
    // El id viene de nuestros propios modelos, pero se sanea igualmente.
    final safe = noteId.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return Directory('${base.path}/versions/$safe');
  }

  /// Lista las versiones de una nota, de la más reciente a la más antigua.
  Future<List<NoteVersion>> list(String noteId) async {
    final dir = await _dirFor(noteId);
    if (!await dir.exists()) return [];
    final versions = <NoteVersion>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json.gz')) continue;
      final name = entity.uri.pathSegments.last;
      final millis = int.tryParse(name.split('.').first);
      if (millis == null) continue;
      versions.add(NoteVersion(
        noteId: noteId,
        savedAt: DateTime.fromMillisecondsSinceEpoch(millis),
        sizeBytes: await entity.length(),
        path: entity.path,
      ));
    }
    versions.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return versions;
  }

  /// Guarda una instantánea de [note].
  ///
  /// Si [force] es false, se omite cuando la última versión es más reciente
  /// que [minInterval]. Devuelve true si se escribió una versión nueva.
  Future<bool> snapshot(Note note, {bool force = false}) async {
    try {
      final existing = await list(note.id);
      if (!force &&
          existing.isNotEmpty &&
          DateTime.now().difference(existing.first.savedAt) < minInterval) {
        return false;
      }
      final json = jsonEncode(note.toJson());
      final bytes = gzip.encode(utf8.encode(json));
      final dir = await _dirFor(note.id);
      var millis = DateTime.now().millisecondsSinceEpoch;
      // Evita colisiones si se guardan dos versiones en el mismo ms.
      if (existing.isNotEmpty &&
          existing.first.savedAt.millisecondsSinceEpoch >= millis) {
        millis = existing.first.savedAt.millisecondsSinceEpoch + 1;
      }
      await writeAtomic(File('${dir.path}/$millis.json.gz'), bytes);
      await _prune(note.id);
      return true;
    } catch (e) {
      debugPrint('VersionHistoryService.snapshot: $e');
      return false;
    }
  }

  /// Carga el contenido de una versión.
  Future<Note> load(NoteVersion version) async {
    final raw = utf8.decode(gzip.decode(await File(version.path).readAsBytes()));
    return Note.fromJson(await decodeJsonAsync(raw) as Map<String, dynamic>);
  }

  /// Borra las versiones que exceden [maxVersions].
  Future<void> _prune(String noteId) async {
    final versions = await list(noteId);
    for (final v in versions.skip(maxVersions)) {
      try {
        await File(v.path).delete();
      } catch (e) {
        debugPrint('VersionHistoryService._prune: $e');
      }
    }
  }
}
