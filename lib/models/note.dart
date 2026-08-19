import 'page.dart';

/// Un apunte (note) dentro de un cuaderno.
///
/// Equivale al modelo `Document` original. Contiene las páginas, metadatos
/// y estado de edición. Se serializa como JSON individual en
/// `<appSupport>/inklus/notes/<id>.json`.
class Note {
  final String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  final List<Page> pages;

  Note({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
  });

  factory Note.newBlank({String? id, String? title}) => Note(
        id: id ?? 'note_${DateTime.now().microsecondsSinceEpoch}',
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
      );

  /// Crea un Note a partir de un Document legacy (formato antiguo).
  ///
  /// Se usa durante la migración de A3: toma el contenido intacto del
  /// Document plano y lo convierte en un Note.
  factory Note.fromLegacyDocument(Map<String, dynamic> docJson) =>
      Note.fromJson(docJson);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  /// Marca el updatedAt como ahora.
  void touch() => updatedAt = DateTime.now();
}
