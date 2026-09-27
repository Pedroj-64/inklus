// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:http/http.dart' as http;

import '../../models/template.dart';
import '../file_utils.dart';
import '../storage_service.dart';
import '../template_library_service.dart';
import 'marketplace_models.dart';

/// Marketplace de Inklus: catálogo público de paquetes gratuitos
/// (plantillas, paletas, stickers) alojado en un repositorio de GitHub y
/// servido por CDN. Ver `marketplace/README.md` para publicar paquetes.
///
/// Seguridad: solo se descargan archivos listados en el catálogo, con ruta
/// relativa bajo `packs/`, tamaño limitado y **sha256 verificado** antes de
/// guardarlos. Nunca se ejecuta nada descargado.
class MarketplaceService extends ChangeNotifier {
  MarketplaceService({
    http.Client? client,
    StorageService? storage,
    this.templateLibrary,
    this.baseUrl = defaultBaseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? StorageService.instance;

  /// Repositorio oficial (servido por jsDelivr, CDN gratuito con caché).
  /// Instancia compartida por toda la app (catálogo e instalados).
  static final MarketplaceService instance =
      MarketplaceService(templateLibrary: TemplateLibraryService());

  static const defaultBaseUrl =
      'https://cdn.jsdelivr.net/gh/Pedroj-64/inklus-marketplace@main/';

  static const catalogFile = 'catalog.json';
  static const schemaVersion = 2;
  static const maxFileBytes = 5 * 1024 * 1024;
  static const maxPackBytes = 20 * 1024 * 1024;
  static const maxCatalogBytes = 2 * 1024 * 1024;

  final String baseUrl;
  final http.Client _client;
  final StorageService _storage;
  /// Dónde se registran las plantillas con imagen ("Mis plantillas").
  final TemplateLibraryService? templateLibrary;

  List<MarketplacePack> _catalog = [];
  final Map<String, InstalledPack> _installed = {};
  bool _installedLoaded = false;

  /// De dónde salió el catálogo mostrado.
  CatalogSource source = CatalogSource.builtIn;

  List<MarketplacePack> get catalog => List.unmodifiable(_catalog);
  List<InstalledPack> get installed => _installed.values.toList();
  bool isInstalled(String id) => _installed.containsKey(id);

  Future<Directory> _dir() async {
    final base = await _storage.baseDirectory();
    return Directory('${base.path}/marketplace');
  }

  // -------------------------------------------------------------------------
  // Catálogo
  // -------------------------------------------------------------------------

  /// Descarga el catálogo; si falla usa la copia guardada y, si no hay,
  /// el catálogo inicial incluido en la app. Nunca lanza.
  Future<void> loadCatalog() async {
    await _loadInstalled();
    final dir = await _dir();
    final cache = File('${dir.path}/$catalogFile');
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl$catalogFile'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      if (res.bodyBytes.length > maxCatalogBytes) throw const FormatException('Catálogo demasiado grande');
      _catalog = parseCatalog(utf8.decode(res.bodyBytes));
      await writeAtomic(cache, res.bodyBytes);
      source = CatalogSource.network;
    } catch (e) {
      debugPrint('MarketplaceService: sin red o catálogo inválido ($e)');
      try {
        _catalog = parseCatalog(await cache.readAsString());
        source = CatalogSource.cache;
      } catch (_) {
        _catalog = builtInCatalog;
        source = CatalogSource.builtIn;
      }
    }
    notifyListeners();
  }

  /// Parsea y valida un catálogo: los paquetes inválidos se descartan.
  static List<MarketplacePack> parseCatalog(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schema'] != schemaVersion) {
      throw FormatException('Versión de catálogo no soportada: ${json['schema']}');
    }
    final packs = <MarketplacePack>[];
    for (final p in json['packs'] as List? ?? []) {
      try {
        final pack = MarketplacePack.fromJson(p as Map<String, dynamic>);
        final errors = validatePack(pack);
        if (errors.isEmpty) {
          packs.add(pack);
        } else {
          debugPrint('Paquete descartado ${pack.id}: ${errors.join('; ')}');
        }
      } catch (e) {
        debugPrint('Paquete ilegible: $e');
      }
    }
    return packs;
  }

  /// Reglas que debe cumplir un paquete (las mismas que valida la CI del
  /// repositorio del marketplace). Devuelve la lista de errores.
  static List<String> validatePack(MarketplacePack p) {
    final errors = <String>[];
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,63}$').hasMatch(p.id)) {
      errors.add('id inválido (a-z, 0-9, guiones; 3-64)');
    }
    if (p.name.trim().isEmpty) errors.add('falta el nombre');
    if (p.license.trim().isEmpty) errors.add('falta la licencia');
    final paths = <String>{};
    for (final f in p.files) {
      if (safeJoin('/', f.path) == null || !f.path.startsWith('packs/${p.id}/')) {
        errors.add('ruta insegura o fuera del paquete: ${f.path}');
      }
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(f.sha256)) errors.add('sha256 inválido: ${f.path}');
      if (f.size <= 0 || f.size > maxFileBytes) errors.add('tamaño no permitido: ${f.path}');
      if (!RegExp(r'\.(png|jpg|jpeg|webp)$').hasMatch(f.path.toLowerCase())) {
        errors.add('tipo de archivo no permitido: ${f.path}');
      }
      paths.add(f.path);
    }
    if (p.totalSize > maxPackBytes) errors.add('paquete demasiado grande');
    for (final ref in [
      ...p.stickers,
      ...p.templates.map((t) => t.image).whereType<String>(),
    ]) {
      if (!paths.contains(ref)) errors.add('archivo referenciado no listado: $ref');
    }
    switch (p.type) {
      case PackType.template:
        if (p.templates.isEmpty) errors.add('un paquete de plantillas necesita "templates"');
      case PackType.palette:
        if (p.palette.length < 2) errors.add('una paleta necesita al menos 2 colores');
      case PackType.stickers:
        if (p.stickers.isEmpty) errors.add('un paquete de stickers necesita "stickers"');
    }
    return errors;
  }

  // -------------------------------------------------------------------------
  // Instalación
  // -------------------------------------------------------------------------

  Future<void> _loadInstalled() async {
    if (_installedLoaded) return;
    _installedLoaded = true;
    final dir = Directory('${(await _dir()).path}/installed');
    if (!await dir.exists()) return;
    await for (final f in dir.list()) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      try {
        final ip = InstalledPack.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
        _installed[ip.pack.id] = ip;
      } catch (e) {
        debugPrint('MarketplaceService: manifiesto ilegible ${f.path}: $e');
      }
    }
  }

  /// Instala un paquete: descarga y verifica cada archivo; registra sus
  /// plantillas con imagen en "Mis plantillas". Lanza si algo no cuadra
  /// (y no deja nada a medias).
  Future<void> install(MarketplacePack pack) async {
    await _loadInstalled();
    final errors = validatePack(pack);
    if (errors.isNotEmpty) throw StateError(errors.join('; '));
    final root = await _dir();
    final packDir = Directory('${root.path}/packs/${pack.id}');
    final localFiles = <String, String>{};
    try {
      for (final f in pack.files) {
        final bytes = await _download(f);
        final local = File('${packDir.path}/${safeFileName(f.path)}');
        await writeAtomic(local, bytes);
        localFiles[f.path] = local.path;
      }
      final libraryIds = <String>[];
      final library = templateLibrary;
      if (library != null) {
        for (final t in pack.templates.where((t) => t.image != null)) {
          final entry = await library.save(
            name: t.name,
            sourceImagePath: localFiles[t.image]!,
            infiniteFill: t.infinite,
          );
          libraryIds.add(entry.id);
        }
      }
      final ip = InstalledPack(pack: pack, localFiles: localFiles, libraryTemplateIds: libraryIds);
      await writeAtomic(
        File('${root.path}/installed/${pack.id}.json'),
        jsonEncode(ip.toJson()),
      );
      _installed[pack.id] = ip;
      notifyListeners();
    } catch (_) {
      if (await packDir.exists()) await packDir.delete(recursive: true);
      rethrow;
    }
  }

  Future<Uint8List> _download(PackFile f) async {
    final res = await _client
        .get(Uri.parse('$baseUrl${f.path}'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode} en ${f.path}');
    final bytes = res.bodyBytes;
    if (bytes.length != f.size) throw StateError('Tamaño inesperado en ${f.path}');
    final hash = await sha256Hex(bytes);
    if (hash != f.sha256) throw StateError('Huella sha256 incorrecta en ${f.path}');
    return bytes;
  }

  /// sha256 en hexadecimal (minúsculas).
  static Future<String> sha256Hex(List<int> bytes) async {
    final h = await Sha256().hash(bytes);
    return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> uninstall(String id) async {
    await _loadInstalled();
    final ip = _installed.remove(id);
    if (ip == null) return;
    final root = await _dir();
    final packDir = Directory('${root.path}/packs/$id');
    if (await packDir.exists()) await packDir.delete(recursive: true);
    final manifest = File('${root.path}/installed/$id.json');
    if (await manifest.exists()) await manifest.delete();
    final library = templateLibrary;
    if (library != null) {
      for (final tid in ip.libraryTemplateIds) {
        try {
          await library.delete(tid);
        } catch (e) {
          debugPrint('MarketplaceService.uninstall: $e');
        }
      }
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Contenido instalado (lo consume el resto de la app)
  // -------------------------------------------------------------------------

  Future<List<({String name, PageTemplate template})>> installedTemplates() async {
    await _loadInstalled();
    return [
      for (final ip in _installed.values)
        for (final t in ip.pack.templates)
          if (t.toPageTemplate() case final tpl?) (name: t.name, template: tpl),
    ];
  }

  Future<List<({String name, List<Color> colors})>> installedPalettes() async {
    await _loadInstalled();
    return [
      for (final ip in _installed.values)
        if (ip.pack.palette.isNotEmpty) (name: ip.pack.name, colors: ip.pack.palette),
    ];
  }

  Future<List<String>> installedStickers() async {
    await _loadInstalled();
    return [
      for (final ip in _installed.values)
        for (final s in ip.pack.stickers) ?ip.localFiles[s],
    ];
  }

  // -------------------------------------------------------------------------
  // Catálogo inicial (sin red, sin archivos: solo parámetros y colores)
  // -------------------------------------------------------------------------

  static final List<MarketplacePack> builtInCatalog = [
    MarketplacePack(
      id: 'cuadernos-clasicos',
      name: 'Cuadernos clásicos',
      description: 'Rayado ancho y estrecho, cuadrícula de 5 mm, puntos y pentagrama.',
      type: PackType.template,
      author: 'Inklus',
      license: 'CC0-1.0',
      version: '1.0.0',
      tags: ['estudio', 'básicos'],
      templates: const [
        PackTemplate(name: 'Rayado ancho', params: {'type': 'ruled', 'spacing': 64}),
        PackTemplate(name: 'Rayado estrecho', params: {'type': 'ruled', 'spacing': 40}),
        PackTemplate(name: 'Cuadrícula 5 mm', params: {'type': 'grid', 'spacing': 28}),
        PackTemplate(name: 'Puntos', params: {'type': 'dots', 'spacing': 30}),
        PackTemplate(name: 'Pentagrama', params: {'type': 'music', 'spacing': 60}),
      ],
    ),
    MarketplacePack(
      id: 'papel-tecnico',
      name: 'Papel técnico',
      description: 'Cuadrícula fina tipo milimetrado y agenda por columnas, en tonos suaves.',
      type: PackType.template,
      author: 'Inklus',
      license: 'CC0-1.0',
      version: '1.0.0',
      tags: ['ingeniería'],
      templates: const [
        PackTemplate(name: 'Milimetrado', params: {'type': 'grid', 'spacing': 12, 'lineColor': '#C8D8E8'}),
        PackTemplate(name: 'Agenda por columnas', params: {'type': 'planner', 'spacing': 44}),
      ],
    ),
    MarketplacePack(
      id: 'paleta-estudio',
      name: 'Paleta Estudio',
      description: 'Tinta azul y negra, rojo de corrección, verde y naranja para destacar.',
      type: PackType.palette,
      author: 'Inklus',
      license: 'CC0-1.0',
      version: '1.0.0',
      palette: [
        parseHexColor('#1E3A8A')!, parseHexColor('#111827')!, parseHexColor('#DC2626')!,
        parseHexColor('#15803D')!, parseHexColor('#EA580C')!,
      ],
    ),
    MarketplacePack(
      id: 'paleta-pastel',
      name: 'Paleta Pastel',
      description: 'Tonos suaves para apuntes bonitos y diagramas.',
      type: PackType.palette,
      author: 'Inklus',
      license: 'CC0-1.0',
      version: '1.0.0',
      palette: [
        parseHexColor('#F9A8D4')!, parseHexColor('#A5B4FC')!, parseHexColor('#86EFAC')!,
        parseHexColor('#FDE68A')!, parseHexColor('#FDBA74')!, parseHexColor('#67E8F9')!,
      ],
    ),
    MarketplacePack(
      id: 'paleta-tierra',
      name: 'Paleta Tierra',
      description: 'Ocres, oliva y terracota, con buen contraste sobre papel.',
      type: PackType.palette,
      author: 'Inklus',
      license: 'CC0-1.0',
      version: '1.0.0',
      palette: [
        parseHexColor('#7C2D12')!, parseHexColor('#A16207')!, parseHexColor('#3F6212')!,
        parseHexColor('#78716C')!, parseHexColor('#B45309')!,
      ],
    ),
  ];
}

/// Origen del catálogo que se está mostrando.
enum CatalogSource { network, cache, builtIn }
