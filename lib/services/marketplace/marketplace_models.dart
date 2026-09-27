// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui' show Color;

import '../../models/template.dart';

/// Tipos de paquete del marketplace (v1).
enum PackType {
  /// Plantillas de página: paramétricas (rayado, cuadrícula…) o con imagen.
  template,

  /// Paleta de colores para las plumas.
  palette,

  /// Stickers PNG para insertar en la página.
  stickers,
}

/// Archivo descargable de un paquete, con su huella para verificarlo.
class PackFile {
  const PackFile({required this.path, required this.sha256, required this.size});

  /// Ruta relativa en el repositorio del marketplace (`packs/<id>/…`).
  final String path;
  final String sha256;
  final int size;

  factory PackFile.fromJson(Map<String, dynamic> j) => PackFile(
        path: j['path'] as String,
        sha256: (j['sha256'] as String).toLowerCase(),
        size: (j['size'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {'path': path, 'sha256': sha256, 'size': size};
}

/// Una plantilla dentro de un paquete: paramétrica ([params]) o con imagen.
class PackTemplate {
  const PackTemplate({required this.name, this.params, this.image, this.infinite = false});

  final String name;
  final Map<String, dynamic>? params;
  final String? image;
  final bool infinite;

  factory PackTemplate.fromJson(Map<String, dynamic> j) => PackTemplate(
        name: j['name'] as String? ?? 'Plantilla',
        params: j['params'] as Map<String, dynamic>?,
        image: j['image'] as String?,
        infinite: j['infinite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (params != null) 'params': params,
        if (image != null) 'image': image,
        if (infinite) 'infinite': true,
      };

  /// Plantilla de página a partir de los parámetros (tipos integrados).
  PageTemplate? toPageTemplate() {
    final p = params;
    if (p == null) return null;
    final type = templateTypeFromName(p['type'] as String? ?? 'ruled');
    return PageTemplate(
      type: type,
      spacing: ((p['spacing'] as num?)?.toDouble() ?? 52).clamp(8, 400).toDouble(),
      lineColorValue: parseHexColor(p['lineColor'] as String?)?.toARGB32() ?? 0xFF9DB6D9,
      infiniteFill: p['infinite'] as bool? ?? true,
    );
  }
}

/// Paquete publicado en el catálogo.
class MarketplacePack {
  const MarketplacePack({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.author,
    required this.license,
    required this.version,
    this.tags = const [],
    this.preview,
    this.templates = const [],
    this.palette = const [],
    this.stickers = const [],
    this.files = const [],
  });

  final String id;
  final String name;
  final String description;
  final PackType type;
  final String author;

  /// Licencia SPDX del contenido (p. ej. CC0-1.0, CC-BY-4.0).
  final String license;
  final String version;
  final List<String> tags;

  /// Imagen de vista previa (ruta relativa; opcional).
  final String? preview;
  final List<PackTemplate> templates;
  final List<Color> palette;

  /// Rutas relativas de los stickers (deben estar también en [files]).
  final List<String> stickers;
  final List<PackFile> files;

  int get totalSize => files.fold(0, (n, f) => n + f.size);

  factory MarketplacePack.fromJson(Map<String, dynamic> j) => MarketplacePack(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        type: PackType.values.byName(j['type'] as String),
        author: j['author'] as String? ?? 'Anónimo',
        license: j['license'] as String? ?? 'CC0-1.0',
        version: j['version'] as String? ?? '1.0.0',
        tags: (j['tags'] as List? ?? []).map((e) => e as String).toList(),
        preview: j['preview'] as String?,
        templates: (j['templates'] as List? ?? [])
            .map((e) => PackTemplate.fromJson(e as Map<String, dynamic>))
            .toList(),
        palette: (j['palette'] as List? ?? [])
            .map((e) => parseHexColor(e as String))
            .whereType<Color>()
            .toList(),
        stickers: (j['stickers'] as List? ?? []).map((e) => e as String).toList(),
        files: (j['files'] as List? ?? [])
            .map((e) => PackFile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'author': author,
        'license': license,
        'version': version,
        if (tags.isNotEmpty) 'tags': tags,
        if (preview != null) 'preview': preview,
        if (templates.isNotEmpty) 'templates': [for (final t in templates) t.toJson()],
        if (palette.isNotEmpty)
          'palette': [for (final c in palette) toHexColor(c)],
        if (stickers.isNotEmpty) 'stickers': stickers,
        if (files.isNotEmpty) 'files': [for (final f in files) f.toJson()],
      };
}

/// Paquete instalado: el paquete + dónde quedaron sus archivos.
class InstalledPack {
  const InstalledPack({
    required this.pack,
    required this.localFiles,
    this.libraryTemplateIds = const [],
  });

  final MarketplacePack pack;

  /// Ruta relativa del catálogo → ruta local.
  final Map<String, String> localFiles;

  /// Plantillas con imagen añadidas a "Mis plantillas" (para quitarlas al
  /// desinstalar).
  final List<String> libraryTemplateIds;

  factory InstalledPack.fromJson(Map<String, dynamic> j) => InstalledPack(
        pack: MarketplacePack.fromJson(j['pack'] as Map<String, dynamic>),
        localFiles: (j['files'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
        libraryTemplateIds:
            (j['libraryTemplates'] as List? ?? []).map((e) => e as String).toList(),
      );

  Map<String, dynamic> toJson() => {
        'pack': pack.toJson(),
        'files': localFiles,
        'libraryTemplates': libraryTemplateIds,
      };
}

/// `#RRGGBB` / `#AARRGGBB` → Color (null si no es válido).
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final h = hex.replaceFirst('#', '');
  if (!RegExp(r'^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(h)) return null;
  final v = int.parse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return Color(v);
}

String toHexColor(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
