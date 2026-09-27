// SPDX-License-Identifier: GPL-3.0-or-later
import 'note.dart';
import 'id.dart';

/// Un cuaderno que contiene uno o más apuntes (notes).
///
/// Es el nivel superior de la jerarquía de datos:
/// `Notebook` → `Note` → `Page` → `Stroke/ImageItem/TextItem`.
///
/// Se serializa como JSON en `<appSupport>/inklus/notebooks/<id>.json`.
/// Los notes se guardan como archivos individuales en `notes/<id>.json`.
class Notebook {
  final String id;
  String title;

  /// Color de portada del cuaderno (ARGB). null = sin color asignado.
  int? colorValue;

  /// Estilo de portada (simple, circle, waves, dots, lines, custom).
  String coverStyle;

  /// Ruta de imagen personalizada para portada (estilo 'custom').
  String? coverImagePath;

  /// Etiquetas del cuaderno (para organización y filtrado).
  List<String> tags;

  /// Lista de apuntes que contiene este cuaderno.
  final List<Note> notes;

  Notebook({
    required this.id,
    required this.title,
    this.colorValue,
    this.coverStyle = 'simple',
    this.coverImagePath,
    List<String>? tags,
    List<Note>? notes,
  })  : tags = tags ?? [],
        notes = notes ?? [];

  /// Crea un cuaderno vacío con un note en blanco.
  factory Notebook.newBlank({String? id, String? title}) => Notebook(
        id: id ?? newId('nb'),
        title: title ?? 'Mi cuaderno',
        notes: [Note.newBlank()],
      );

  /// Primer note del cuaderno (el que se abre por defecto).
  Note? get firstNote => notes.isEmpty ? null : notes.first;

  /// Fecha de última actualización basada en el note más reciente.
  DateTime get updatedAt {
    if (notes.isEmpty) return DateTime(2020);
    return notes
        .map((n) => n.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Fecha de creación del cuaderno (el note más antiguo).
  DateTime get createdAt {
    if (notes.isEmpty) return DateTime(2020);
    return notes
        .map((n) => n.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Crea un Notebook a partir de un JSON (formato de archivo individual).
  ///
  /// [loadedNotes] son los Note ya cargados desde sus archivos individuales.
  /// Si no se proveen, se crea una lista vacía (el caller debe cargarlos).
  factory Notebook.fromJson(
    Map<String, dynamic> json, {
    List<Note>? loadedNotes,
  }) =>
      Notebook(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Mi cuaderno',
        colorValue: (json['color'] as num?)?.toInt(),
        coverStyle: json['coverStyle'] as String? ?? 'simple',
        coverImagePath: json['coverImagePath'] as String?,
        tags: (json['tags'] as List? ?? [])
            .map((t) => t as String)
            .toList(),
        notes: loadedNotes ?? [],
      );

  /// Serializa el Notebook a JSON.
  ///
  /// **No incluye los Notes completos** — solo los IDs. Los Notes se
  /// guardan como archivos individuales para minimizar el tamaño del
  /// archivo del notebook y permitir sync selectiva por note.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'noteIds': notes.map((n) => n.id).toList(),
        if (colorValue != null) 'color': colorValue,
        if (coverStyle != 'simple') 'coverStyle': coverStyle,
        if (coverImagePath != null) 'coverImagePath': coverImagePath,
        if (tags.isNotEmpty) 'tags': tags,
      };

  /// Serializa el Notebook con los metadatos básicos de cada note
  /// (para el índice, sin cargar todo el contenido).
  Map<String, dynamic> toIndexJson() => {
        'id': id,
        'title': title,
        'color': colorValue,
        'tags': tags,
        'noteCount': notes.length,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
