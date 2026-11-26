// SPDX-License-Identifier: GPL-3.0-or-later
import 'flashcard.dart';
import 'page.dart';
import 'id.dart';

/// Grabación de audio de una nota. [path] es absoluto, como
/// `ImageItem.localPath` (el respaldo completo lo re-mapea igual); las
/// grabaciones nuevas van a `AppPaths.audio(noteId)`.
class AudioRecording {
  final String id;
  final String path;
  final int startedAt; // ms desde epoch (casa con `Stroke.ts`)
  final int durationMs;

  const AudioRecording({
    required this.id,
    required this.path,
    required this.startedAt,
    required this.durationMs,
  });

  factory AudioRecording.fromJson(Map<String, dynamic> j) => AudioRecording(
        id: j['id'] as String,
        path: j['path'] as String,
        startedAt: (j['startedAt'] as num).toInt(),
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'path': path, 'startedAt': startedAt, 'durationMs': durationMs};

  AudioRecording withPath(String p) =>
      AudioRecording(id: id, path: p, startedAt: startedAt, durationMs: durationMs);
}

/// Un apunte (note) dentro de un cuaderno.
///
/// Equivale al modelo `Document` original. Contiene las páginas, metadatos
/// y estado de edición. Se serializa como JSON individual en
/// `<appSupport>/inklus/notes/<id>.json`.
class Note {
  /// Versión del esquema de la nota en disco. Subirla al cambiar el JSON de
  /// forma incompatible y migrar en [Note.fromJson] según `schemaVersion`.
  static const currentSchema = 1;

  final String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  final List<Page> pages;

  /// Grabaciones de audio sincronizadas con la escritura.
  final List<AudioRecording> recordings;

  /// Tarjetas de estudio hechas con zonas de sus páginas.
  final List<Flashcard> flashcards;

  Note({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    List<AudioRecording>? recordings,
    List<Flashcard>? flashcards,
  })  : recordings = recordings ?? [],
        flashcards = flashcards ?? [];

  factory Note.newBlank({String? id, String? title}) => Note(
        id: id ?? newId('note'),
        title: title ?? 'Sin título',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: [Page.blank()],
      );

  /// Crea un Note a partir de un JSON (formato de archivo individual).
  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Sin título',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.now(),
        pages: (json['pages'] as List? ?? [])
            .map((p) => Page.fromJson(p as Map<String, dynamic>))
            .toList(),
        recordings: [
          for (final r in json['recordings'] as List? ?? const [])
            if (r is Map<String, dynamic>) AudioRecording.fromJson(r),
        ],
        flashcards: [
          for (final c in json['flashcards'] as List? ?? const [])
            if (c is Map<String, dynamic>) Flashcard.fromJson(c),
        ],
      );

  /// Crea un Note a partir de un Document legacy (formato antiguo).
  ///
  /// Se usa durante la migración de A3: toma el contenido intacto del
  /// Document plano y lo convierte en un Note.
  factory Note.fromLegacyDocument(Map<String, dynamic> docJson) =>
      Note.fromJson(docJson);

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchema,
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
        if (recordings.isNotEmpty) 'recordings': [for (final r in recordings) r.toJson()],
        if (flashcards.isNotEmpty) 'flashcards': [for (final c in flashcards) c.toJson()],
      };

  /// Marca el updatedAt como ahora.
  void touch() => updatedAt = DateTime.now();
}
