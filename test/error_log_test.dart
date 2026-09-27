// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/error_log.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_errlog_');
    ErrorLog.fileProvider = () async => File('${tmp.path}/errors.log');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('registra, cuenta y borra', () async {
    await ErrorLog.record(StateError('uno'), StackTrace.current);
    await ErrorLog.record(ArgumentError('dos'), null, context: 'prueba');
    expect(await ErrorLog.count(), 2);
    final text = await ErrorLog.read();
    expect(text, contains('Bad state: uno'));
    expect(text, contains('prueba'));
    await ErrorLog.clear();
    expect(await ErrorLog.count(), 0);
  });

  test('no crece sin límite y conserva lo más reciente', () async {
    final big = 'x' * 5000;
    for (var i = 0; i < 120; i++) {
      await ErrorLog.record('error $i $big', null);
    }
    final text = await ErrorLog.read();
    expect(text.length, lessThanOrEqualTo(ErrorLog.maxBytes));
    expect(text, contains('error 119'));
    expect(text, isNot(contains('error 0 ')));
    expect(text.startsWith('=== '), isTrue, reason: 'corta por entradas completas');
  });
}
