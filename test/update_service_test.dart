// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isNewer compara versiones (con o sin «v», con sufijos)', () {
    expect(UpdateService.isNewer('v1.11.0', '1.10.1'), isTrue);
    expect(UpdateService.isNewer('2.0.0', '1.10.9'), isTrue);
    expect(UpdateService.isNewer('1.10.1', '1.10.1'), isFalse);
    expect(UpdateService.isNewer('1.9.9', '1.10.0'), isFalse, reason: 'numérico, no texto');
    expect(UpdateService.isNewer('1.11', '1.10.5'), isTrue);
    expect(UpdateService.isNewer('2.0.0-beta', '1.10.1'), isTrue);
  });

  test('elige el APK de la variante; en escritorio, la página', () {
    final assets = [
      (name: 'app-release.apk', url: 'https://github.com/x/app-release.apk'),
      (name: 'inklus-lite-arm64-v8a.apk', url: 'https://github.com/x/lite.apk'),
    ];
    expect(UpdateService.assetFor(assets, android: true, lite: false), 'https://github.com/x/app-release.apk');
    expect(UpdateService.assetFor(assets, android: true, lite: true), 'https://github.com/x/lite.apk');
    expect(UpdateService.assetFor(assets, android: false, lite: false), isNull);
  });

  http.Client fake(String tag, {String host = 'github.com'}) => MockClient((req) async => http.Response(
      jsonEncode({
        'tag_name': tag,
        'html_url': 'https://$host/Pedroj-64/inklus/releases/tag/$tag',
        'assets': [],
      }),
      200));

  test('check: avisa de una versión nueva, una vez al día y respeta «descartar»', () async {
    final info = await UpdateService.check(client: fake('v99.0.0'));
    expect(info?.version, '99.0.0');
    expect(await UpdateService.check(client: fake('v99.0.0')), isNull, reason: 'ya se miró hoy');
    await UpdateService.dismiss('99.0.0');
    expect(await UpdateService.check(force: true, client: fake('v99.0.0')), isNotNull, reason: 'a mano sí');
    SharedPreferences.setMockInitialValues({'update_dismissed': '99.0.0'});
    expect(await UpdateService.check(client: fake('v99.0.0')), isNull);
  });

  test('check: misma versión, apagado o enlace fuera de GitHub → nada', () async {
    expect(await UpdateService.check(client: fake('v$kAppVersion')), isNull);
    expect(await UpdateService.check(force: true, client: fake('v99.0.0', host: 'evil.example')), isNull);
    SharedPreferences.setMockInitialValues({'update_check': false});
    expect(await UpdateService.check(client: fake('v99.0.0')), isNull);
  });
}
