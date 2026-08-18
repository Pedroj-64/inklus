import 'page.dart';

/// Cuaderno completo: metadatos + lista de páginas.
///
/// Es la unidad que se serializa a JSON para el guardado local y, si el
/// usuario inicia sesión, para la copia de seguridad en Google Drive.
class Document {
  final String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  final List<Page> pages;

  /// Color de portada del cuaderno (ARGB). null = sin color asignado.
  int? colorValue;

  Document({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    this.colorValue,
  });

  factory Document.newBlank({String? id, String? title}) => Document(
        id: id ?? 'doc_${DateTime.now().microsecondsSinceEpoch}',
        title: title ?? 'Mi cuaderno',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: [Page.blank()],
        colorValue: null,
      );

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Mi cuaderno',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.now(),
        pages: (json['pages'] as List? ?? [])
            .map((p) => Page.fromJson(p as Map<String, dynamic>))
            .toList(),
        colorValue: (json['color'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
        if (colorValue != null) 'color': colorValue,
      };
}
