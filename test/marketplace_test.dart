// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inklus/services/marketplace/marketplace_models.dart';
import 'package:inklus/services/marketplace/marketplace_service.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('inklus_mkt_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  final sticker = List<int>.generate(100, (i) => i);

  Future<Map<String, dynamic>> catalogJson({String? sha}) async => {
        'schema': 2,
        'packs': [
          {
            'id': 'estrellas',
            'name': 'Estrellas',
            'type': 'stickers',
            'license': 'CC0-1.0',
            'stickers': ['packs/estrellas/star.png'],
            'files': [
              {
                'path': 'packs/estrellas/star.png',
                'sha256': sha ?? await MarketplaceService.sha256Hex(sticker),
                'size': sticker.length,
              },
            ],
          },
          {'id': 'MAL ID', 'name': 'x', 'type': 'palette', 'license': 'CC0-1.0'},
        ],
      };

  MarketplaceService service(Map<String, dynamic> catalog, {bool offline = false}) {
    final client = MockClient((req) async {
      if (offline) throw const SocketException('sin red');
      if (req.url.path.endsWith('catalog.json')) {
        return http.Response(jsonEncode(catalog), 200);
      }
      if (req.url.path.endsWith('star.png')) return http.Response.bytes(sticker, 200);
      return http.Response('no', 404);
    });
    return MarketplaceService(
      client: client,
      storage: StorageService(baseDir: tmp),
      baseUrl: 'https://example.test/',
    );
  }

  test('descarta paquetes inválidos del catálogo', () async {
    final s = service(await catalogJson());
    await s.loadCatalog();
    expect(s.source, CatalogSource.network);
    expect(s.catalog.map((p) => p.id), ['estrellas']);
  });

  test('instala verificando sha256 y expone los stickers', () async {
    final s = service(await catalogJson());
    await s.loadCatalog();
    await s.install(s.catalog.single);
    final stickers = await s.installedStickers();
    expect(File(stickers.single).readAsBytesSync(), sticker);
    await s.uninstall('estrellas');
    expect(await s.installedStickers(), isEmpty);
  });

  test('sha256 incorrecto: no instala nada', () async {
    final s = service(await catalogJson(sha: 'a' * 64));
    await s.loadCatalog();
    await expectLater(s.install(s.catalog.single), throwsStateError);
    expect(s.isInstalled('estrellas'), isFalse);
    expect(Directory('${tmp.path}/marketplace/packs/estrellas').existsSync(), isFalse);
  });

  test('sin red: usa la caché y, si no hay, el catálogo incluido', () async {
    final offline = service({}, offline: true);
    await offline.loadCatalog();
    expect(offline.source, CatalogSource.builtIn);
    expect(offline.catalog, isNotEmpty);

    final online = service(await catalogJson());
    await online.loadCatalog(); // deja caché
    final offline2 = service({}, offline: true);
    await offline2.loadCatalog();
    expect(offline2.source, CatalogSource.cache);
  });

  test('el catálogo incluido es válido y sus plantillas se convierten', () async {
    for (final p in MarketplaceService.builtInCatalog) {
      expect(MarketplaceService.validatePack(p), isEmpty, reason: p.id);
    }
    final s = service({}, offline: true);
    await s.loadCatalog();
    await s.install(s.catalog.first);
    final templates = await s.installedTemplates();
    expect(templates.first.template.spacing, 64);
  });

  test('rutas fuera del paquete son rechazadas', () {
    final p = MarketplacePack.fromJson({
      'id': 'malo',
      'name': 'Malo',
      'type': 'stickers',
      'license': 'CC0-1.0',
      'stickers': ['packs/otro/../../x.png'],
      'files': [
        {'path': 'packs/otro/../../x.png', 'sha256': 'a' * 64, 'size': 10},
      ],
    });
    expect(MarketplaceService.validatePack(p), isNotEmpty);
  });
}
