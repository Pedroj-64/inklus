// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';
import 'id.dart';
import 'image_item.dart';
import 'stroke.dart';
import 'template.dart';
import 'text_item.dart';

/// Metadatos de una capa dentro de una página.
class Layer {
  String name;
  bool visible;
  bool locked;

  /// Opacidad de la capa (0.0 = transparente, 1.0 = opaca).
  double opacity;

  Layer({
    required this.name,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
  });

  Layer copyWith({
    String? name,
    bool? visible,
    bool? locked,
    double? opacity,
  }) =>
      Layer(
        name: name ?? this.name,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        opacity: opacity ?? this.opacity,
      );

  factory Layer.fromJson(Map<String, dynamic> json) => Layer(
        name: json['name'] as String? ?? 'Capa',
        visible: json['visible'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'visible': visible,
        'locked': locked,
        if (opacity < 1.0) 'opacity': opacity,
      };
}

/// Una página del cuaderno: conjunto de trazos e imágenes sobre una plantilla.
///
/// Soporta capas: cada trazo e imagen puede pertenecer a una capa diferente.
/// Zona de la página que lleva a otra página del mismo cuaderno (planners).
class PageLink {
  final Rect rect; // coordenadas de mundo
  final String toPageId;
  const PageLink(this.rect, this.toPageId);

  factory PageLink.fromJson(Map<String, dynamic> j) => PageLink(
        Rect.fromLTWH((j['x'] as num).toDouble(), (j['y'] as num).toDouble(),
            (j['w'] as num).toDouble(), (j['h'] as num).toDouble()),
        j['to'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'x': rect.left, 'y': rect.top, 'w': rect.width, 'h': rect.height, 'to': toPageId};
}

/// La capa por defecto es la 0 (siempre existe). Si el JSON no tiene capas,
/// se crea una capa "Capa 1" por defecto para compatibilidad.
class Page {
  final String id;
  String name;
  final List<Stroke> strokes;
  final List<ImageItem> images;
  final List<TextItem> textItems;
  PageTemplate template;

  /// Lista de capas de esta página. Siempre hay al menos una.
  List<Layer> layers;

  /// Página marcada (aparece destacada y filtrable en el panel de páginas).
  bool bookmarked;

  /// Enlaces a otras páginas (un toque con el dedo salta a la página).
  final List<PageLink> links;

  Page({
    required this.id,
    required this.name,
    required this.strokes,
    required this.images,
    required this.template,
    List<Layer>? layers,
    List<TextItem>? textItems,
    this.bookmarked = false,
    List<PageLink>? links,
  })  : layers = layers ?? [Layer(name: 'Capa 1')],
        textItems = textItems ?? [],
        links = links ?? [];

  /// true si [name] lo puso el usuario (no es «Página 3», «PDF 2»…).
  bool get hasCustomName => !RegExp(r'^(Página|PDF) \d+( \(copia\))*$').hasMatch(name);

  factory Page.blank({String? id, String? name, PageTemplate? template}) =>
      Page(
        id: id ?? _newId(),
        name: name ?? 'Página 1',
        strokes: [],
        images: [],
        template: template ?? const PageTemplate(),
      );

  /// Hoja fija con una imagen (página de PDF, foto…) de fondo, del ancho
  /// estándar de hoja y la proporción de la imagen ([width]×[height] px).
  factory Page.background({
    required String name,
    required String path,
    required int width,
    required int height,
  }) {
    const w = PageTemplate.sheetWidth;
    return Page.blank(
      name: name,
      template: PageTemplate(
        type: TemplateType.custom,
        imagePath: path,
        infiniteFill: false,
        customWidth: w,
        customHeight: width == 0 ? PageTemplate.sheetHeight : w * height / width,
      ),
    );
  }

  static String _newId() => newId('pg');

  Page copyWith({
    String? id,
    String? name,
    List<Stroke>? strokes,
    List<ImageItem>? images,
    PageTemplate? template,
    List<Layer>? layers,
    List<TextItem>? textItems,
  }) =>
      Page(
        id: id ?? this.id,
        name: name ?? this.name,
        strokes: strokes ?? this.strokes,
        images: images ?? this.images,
        template: template ?? this.template,
        layers: layers ?? this.layers,
        textItems: textItems ?? this.textItems,
        bookmarked: bookmarked,
        links: List.of(links),
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
        layers: (json['layers'] as List?)
            ?.map((l) => Layer.fromJson(l as Map<String, dynamic>))
            .toList(),
        textItems: (json['textItems'] as List? ?? [])
            .map((t) => TextItem.fromJson(t as Map<String, dynamic>))
            .toList(),
        bookmarked: json['bookmarked'] as bool? ?? false,
        links: [
          for (final l in json['links'] as List? ?? const [])
            if (l is Map<String, dynamic>) PageLink.fromJson(l),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'images': images.map((i) => i.toJson()).toList(),
        'template': template.toJson(),
        'layers': layers.map((l) => l.toJson()).toList(),
        'textItems': textItems.map((t) => t.toJson()).toList(),
        if (bookmarked) 'bookmarked': true,
        if (links.isNotEmpty) 'links': [for (final l in links) l.toJson()],
      };
}
