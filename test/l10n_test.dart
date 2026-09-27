// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las traducciones no pueden quedarse atrás: toda clave del español (la
/// fuente) debe existir en inglés, con los mismos marcadores {…}.
void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();

  Set<String> placeholders(String text) =>
      RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

  test('inglés tiene todas las claves del español y ninguna de más', () {
    final es = arb('es'), en = arb('en');
    expect(keys(en), keys(es));
  });

  test('mismos marcadores en cada traducción', () {
    final es = arb('es'), en = arb('en');
    for (final k in keys(es)) {
      expect(placeholders(en[k] as String), placeholders(es[k] as String),
          reason: k);
    }
  });
}
