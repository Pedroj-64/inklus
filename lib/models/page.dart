import 'image_item.dart';
import 'stroke.dart';
import 'template.dart';

/// Una página del cuaderno: conjunto de trazos e imágenes sobre una plantilla.
class Page {
  final String id;
  String name;
  final List<Stroke> strokes;
  final List<ImageItem> images;
  PageTemplate template;

  Page({
    required this.id,
    required this.name,
    required this.strokes,
    required this.images,
    required this.template,
  });

  factory Page.blank({String? id, String? name, PageTemplate? template}) =>
      Page(
        id: id ?? _newId(),
        name: name ?? 'Página 1',
        strokes: [],
        images: [],
        template: template ?? const PageTemplate(),
      );

  static String _newId() =>
      'pg_${DateTime.now().microsecondsSinceEpoch}_${_rand()}';

  static String _rand() => (DateTime.now().microsecondsSinceEpoch % 100000)
      .toString()
      .padLeft(5, '0');

  Page copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    List<ImageItem>? images,
    PageTemplate? template,
  }) =>
      Page(
        id: id ?? this.id,
        name: name ?? this.name,
        strokes: strokes ?? this.strokes,
        images: images ?? this.images,
        template: template ?? this.template,
      );

  factory Page.fromJson(Map<String, dynamic> json) => Page(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Página',
        strokes: (json['strokes'] as List? ?? [])
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        images: (json['images'] as List? ?? [])
            .map((i) => ImageItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        template: PageTemplate.fromJson(
            json['template'] as Map<String, dynamic>? ?? const {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
        'template': template.toJson(),
      };
}
