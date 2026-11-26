// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

/// Versión publicada más nueva que la instalada.
class UpdateInfo {
  final String version; // sin la «v» del tag
  final String downloadUrl; // APK de esta variante, o la página de la release
  const UpdateInfo(this.version, this.downloadUrl);
}

/// Avisa de nuevas versiones consultando la última release de GitHub (la
/// app se distribuye por GitHub Releases). Sin cuenta ni datos: solo un GET
/// público. Se apaga en Configuración o al compilar con
/// `--dart-define=INKLUS_NO_UPDATE_CHECK=true` (tiendas como F-Droid).
abstract final class UpdateService {
  static const _latestUrl = 'https://api.github.com/repos/Pedroj-64/inklus/releases/latest';
  static const _prefEnabled = 'update_check';
  static const _prefLastCheck = 'update_last_check';
  static const _prefDismissed = 'update_dismissed';

  static const bool available = !bool.fromEnvironment('INKLUS_NO_UPDATE_CHECK');

  static Future<bool> isEnabled() async =>
      available && ((await SharedPreferences.getInstance()).getBool(_prefEnabled) ?? true);

  static Future<void> setEnabled(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_prefEnabled, on);

  /// true si [remote] (p. ej. «1.11.0» o «v1.11.0») es posterior a [local].
  static bool isNewer(String remote, String local) {
    List<int> parts(String v) => [
          for (final p in v.replaceFirst(RegExp('^v'), '').split('-').first.split('.'))
            int.tryParse(p) ?? 0,
        ];
    final r = parts(remote), l = parts(local);
    for (var i = 0; i < 3; i++) {
      final a = i < r.length ? r[i] : 0, b = i < l.length ? l[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  /// Archivo de la release que corresponde a esta instalación.
  @visibleForTesting
  static String? assetFor(List<({String name, String url})> assets, {required bool android, required bool lite}) {
    if (!android) return null; // escritorio: página de la release (AppImage/.deb/tar)
    final wanted = lite ? 'inklus-lite-arm64-v8a.apk' : 'app-release.apk';
    for (final a in assets) {
      if (a.name == wanted) return a.url;
    }
    return null;
  }

  /// Consulta GitHub. [force] ignora el límite de una vez al día y la versión
  /// descartada. null = no hay nada nuevo (o no se pudo comprobar).
  static Future<UpdateInfo?> check({bool force = false, http.Client? client}) async {
    if (!available) return null;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force) {
      if (!(prefs.getBool(_prefEnabled) ?? true)) return null;
      final last = prefs.getInt(_prefLastCheck) ?? 0;
      if (now - last < Duration.millisecondsPerDay) return null;
    }
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse(_latestUrl), headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'Inklus',
          })
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      await prefs.setInt(_prefLastCheck, now);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['draft'] == true || json['prerelease'] == true) return null;
      final tag = (json['tag_name'] as String? ?? '').replaceFirst(RegExp('^v'), '');
      if (!isNewer(tag, kAppVersion)) return null;
      if (!force && prefs.getString(_prefDismissed) == tag) return null;
      final assets = [
        for (final a in json['assets'] as List? ?? const [])
          if (a is Map<String, dynamic>)
            (name: a['name'] as String? ?? '', url: a['browser_download_url'] as String? ?? ''),
      ];
      final page = json['html_url'] as String? ?? '$kSourceCodeUrl/releases/latest';
      final url = assetFor(assets, android: Platform.isAndroid, lite: kLiteBuild) ?? page;
      // Solo enlaces de GitHub: la respuesta no debe poder mandar a otro sitio.
      final host = Uri.tryParse(url)?.host ?? '';
      if (host != 'github.com' && !host.endsWith('.github.com')) return null;
      return UpdateInfo(tag, url);
    } catch (e) {
      debugPrint('UpdateService.check: $e');
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// El usuario cerró el aviso de [version]: no se vuelve a mostrar sola.
  static Future<void> dismiss(String version) async =>
      (await SharedPreferences.getInstance()).setString(_prefDismissed, version);
}
