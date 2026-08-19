import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/template.dart';

/// Plantilla disponible en el marketplace.
class MarketplaceTemplate {
  final String id;
  final String name;
  final String description;
  final String category;

  /// URL del thumbnail (puede ser una imagen local bundled o remota).
  final String thumbnailUrl;

  /// Tipo de plantilla.
  final TemplateType type;

  /// Si es relleno infinito.
  final bool infiniteFill;

  /// Color de las líneas (hex).
  final String? lineColor;

  /// Espaciado entre líneas.
  final double? spacing;

  const MarketplaceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    this.type = TemplateType.blank,
    this.infiniteFill = true,
    this.lineColor,
    this.spacing,
  });

  factory MarketplaceTemplate.fromJson(Map<String, dynamic> json) =>
      MarketplaceTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['desc'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        thumbnailUrl: json['thumb'] as String? ?? '',
        type: TemplateType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TemplateType.blank,
        ),
        infiniteFill: json['infinite'] as bool? ?? true,
        lineColor: json['lineColor'] as String?,
        spacing: (json['spacing'] as num?)?.toDouble(),
      );

  /// Convierte a PageTemplate para usar en el editor.
  PageTemplate toPageTemplate() => PageTemplate(
        type: type,
        infiniteFill: infiniteFill,
        lineColorValue: lineColor != null ? int.parse('0xFF${lineColor!.substring(1)}') : 0xFF9DB6D9,
        spacing: spacing ?? 52,
      );
}

/// Categorías del marketplace.
class TemplateCategory {
  final String name;
  final String icon;

  const TemplateCategory({required this.name, this.icon = '📁'});

  static const categories = [
    TemplateCategory(name: 'General', icon: '📁'),
    TemplateCategory(name: 'Educación', icon: '📚'),
    TemplateCategory(name: 'Negocios', icon: '💼'),
    TemplateCategory(name: 'Creatividad', icon: '🎨'),
    TemplateCategory(name: 'Productividad', icon: '⚡'),
    TemplateCategory(name: 'Personal', icon: '📝'),
  ];
}

/// Servicio de marketplace de plantillas.
///
/// Mantiene un catálogo de plantillas descargables. El catálogo se puede
/// ampliar añadiendo entradas al JSON bundled o descargando un manifiesto
/// remoto.
class TemplateMarketplaceService {
  static const _catalogFileName = 'marketplace_catalog.json';
  List<MarketplaceTemplate> _catalog = [];

  /// Plantillas pre-bundled con la app.
  static final _bundledTemplates = [
    const MarketplaceTemplate(
      id: 'tpl_blank_inf',
      name: 'Lienzo en blanco',
      description: 'Lienzo infinito sin guías',
      category: 'General',
      thumbnailUrl: '',
      type: TemplateType.blank,
      infiniteFill: true,
    ),
    const MarketplaceTemplate(
      id: 'tpl_ruled_narrow',
      name: 'Rayas finas',
      description: 'Líneas horizontales con espaciado estrecho',
      category: 'Educación',
      thumbnailUrl: '',
      type: TemplateType.ruled,
      infiniteFill: true,
      spacing: 24,
    ),
    const MarketplaceTemplate(
      id: 'tpl_ruled_wide',
      name: 'Rayas anchas',
      description: 'Líneas horizontales con espaciado amplio',
      category: 'Educación',
      thumbnailUrl: '',
      type: TemplateType.ruled,
      infiniteFill: true,
      spacing: 36,
    ),
    const MarketplaceTemplate(
      id: 'tpl_grid_small',
      name: 'Cuadrícula fina',
      description: 'Cuadrícula pequeña para notas detalladas',
      category: 'Educación',
      thumbnailUrl: '',
      type: TemplateType.grid,
      infiniteFill: true,
      spacing: 20,
    ),
    const MarketplaceTemplate(
      id: 'tpl_grid_large',
      name: 'Cuadrícula grande',
      description: 'Cuadrícula grande para diagramas',
      category: 'Creatividad',
      thumbnailUrl: '',
      type: TemplateType.grid,
      infiniteFill: true,
      spacing: 40,
    ),
    const MarketplaceTemplate(
      id: 'tpl_dot',
      name: 'Puntos',
      description: 'Grid de puntos para sketching libre',
      category: 'Creatividad',
      thumbnailUrl: '',
      type: TemplateType.dots,
      infiniteFill: true,
    ),
    const MarketplaceTemplate(
      id: 'tpl_sheet_a4',
      name: 'Hoja A4',
      description: 'Hoja tamaño A4 con margen',
      category: 'General',
      thumbnailUrl: '',
      type: TemplateType.sheet,
      infiniteFill: false,
    ),
    const MarketplaceTemplate(
      id: 'tpl_music',
      name: 'Pentagrama musical',
      description: '5 líneas para escritura musical',
      category: 'Creatividad',
      thumbnailUrl: '',
      type: TemplateType.music,
      infiniteFill: true,
    ),
    const MarketplaceTemplate(
      id: 'tpl_weekly',
      name: 'Agenda semanal',
      description: 'Vista de 7 días para planificación',
      category: 'Productividad',
      thumbnailUrl: '',
      type: TemplateType.planner,
      infiniteFill: true,
    ),
    const MarketplaceTemplate(
      id: 'tpl_habit',
      name: 'Tracker de hábitos',
      description: 'Grid para seguimiento de hábitos diarios',
      category: 'Productividad',
      thumbnailUrl: '',
      type: TemplateType.habit,
      infiniteFill: true,
    ),
    const MarketplaceTemplate(
      id: 'tpl_meeting',
      name: 'Notas de reunión',
      description: 'Plantilla para actas con secciones',
      category: 'Negocios',
      thumbnailUrl: '',
      type: TemplateType.ruled,
      infiniteFill: true,
      spacing: 30,
    ),
    const MarketplaceTemplate(
      id: 'tpl_journal',
      name: 'Diario personal',
      description: 'Página con fecha y espacio para reflexión',
      category: 'Personal',
      thumbnailUrl: '',
      type: TemplateType.ruled,
      infiniteFill: true,
      spacing: 28,
    ),
  ];

  Future<File> _catalogFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inklus/$_catalogFileName');
  }

  /// Carga el catálogo (bundled + descargas del usuario).
  Future<void> load() async {
    try {
      final f = await _catalogFile();
      if (await f.exists()) {
        final raw = await f.readAsString();
        if (raw.trim().isNotEmpty) {
          final list = jsonDecode(raw) as List;
          _catalog = list
              .map((e) =>
                  MarketplaceTemplate.fromJson(e as Map<String, dynamic>))
              .toList();
          return;
        }
      }
    } catch (e) {
      debugPrint('TemplateMarketplaceService.load: $e');
    }
    _catalog = [];
  }

  Future<void> _save() async {
    try {
      final f = await _catalogFile();
      await f.parent.create(recursive: true);
      await f.writeAsString(
        jsonEncode(_catalog.map((t) => {
              'id': t.id,
              'name': t.name,
              'desc': t.description,
              'category': t.category,
              'thumb': t.thumbnailUrl,
              'type': t.type.name,
              'infinite': t.infiniteFill,
              if (t.lineColor != null) 'lineColor': t.lineColor,
              if (t.spacing != null) 'spacing': t.spacing,
            }).toList()),
      );
    } catch (e) {
      debugPrint('TemplateMarketplaceService._save: $e');
    }
  }

  /// Todas las plantillas disponibles (bundled + descargadas).
  List<MarketplaceTemplate> get allTemplates =>
      [..._bundledTemplates, ..._catalog];

  /// Plantillas por categoría.
  List<MarketplaceTemplate> byCategory(String category) =>
      allTemplates.where((t) => t.category == category).toList();

  /// Busca plantillas por nombre.
  List<MarketplaceTemplate> search(String query) {
    final q = query.toLowerCase();
    return allTemplates
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  /// Añade una plantilla personalizada al catálogo del marketplace.
  Future<void> addCustom(MarketplaceTemplate template) async {
    _catalog.add(template);
    await _save();
  }

  /// Elimina una plantilla del catálogo del usuario (no las bundled).
  Future<void> removeCustom(String id) async {
    _catalog.removeWhere((t) => t.id == id);
    await _save();
  }

  // -------------------------------------------------------------------------
  // C10: Marketplace comunitario vía GitHub
  // -------------------------------------------------------------------------

  /// URL del repositorio GitHub que aloja el catálogo comunitario.
  /// El JSON del catálogo debe estar en `templates/catalog.json` en la raíz
  /// del repo. El repo público sirve como "base de datos" del marketplace.
  static const _catalogRepoUrl =
      'https://raw.githubusercontent.com/nicblo/inclus-templates/main/templates/catalog.json';

  /// Tiempo máximo de vida de la caché remota (6 horas).
  static const _cacheMaxAge = Duration(hours: 6);

  DateTime? _lastRemoteFetch;
  List<MarketplaceTemplate> _remoteTemplates = [];

  /// Plantillas remotas descargadas del catálogo comunitario.
  List<MarketplaceTemplate> get remoteTemplates =>
      List.unmodifiable(_remoteTemplates);

  /// Si hay plantillas remotas disponibles.
  bool get hasRemoteTemplates => _remoteTemplates.isNotEmpty;

  /// Descarga el catálogo comunitario desde GitHub.
  ///
  /// El JSON debe tener la misma estructura que el catálogo local:
  /// `[{id, name, desc, category, thumb, type, infinite, ...}]`
  ///
  /// Las plantillas remotas se cachean en memoria y se refrescan cada
  /// [_cacheMaxAge]. Devuelve el número de plantillas descargadas.
  Future<int> fetchRemoteCatalog() async {
    // Usar caché si es reciente.
    if (_lastRemoteFetch != null &&
        DateTime.now().difference(_lastRemoteFetch!) < _cacheMaxAge) {
      return _remoteTemplates.length;
    }

    try {
      final response = await http.get(Uri.parse(_catalogRepoUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        debugPrint('TemplateMarketplace: HTTP ${response.statusCode}');
        return 0;
      }

      final json = jsonDecode(response.body);
      if (json is! List) return 0;

      _remoteTemplates = json
          .map((e) => MarketplaceTemplate.fromJson(e as Map<String, dynamic>))
          .where((t) => !_bundledTemplates.any((b) => b.id == t.id))
          .toList();
      _lastRemoteFetch = DateTime.now();

      debugPrint(
        'TemplateMarketplace: ${_remoteTemplates.length} plantilla(s) '
        'descargada(s) del catálogo comunitario.',
      );
      return _remoteTemplates.length;
    } catch (e) {
      debugPrint('TemplateMarketplace.fetchRemoteCatalog: $e');
      return 0;
    }
  }

  /// Todas las plantillas (bundled + locales + remotas).
  List<MarketplaceTemplate> get allTemplatesIncludingRemote =>
      [..._bundledTemplates, ..._catalog, ..._remoteTemplates];
}
