// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/backup_crypto.dart';
import 'package:inklus/services/import_service.dart';
import 'package:inklus/services/inklus_format.dart';
import 'package:inklus/services/storage_service.dart';

/// Entradas hostiles/corruptas: nunca deben escribir fuera de la carpeta ni
/// lanzar `Error`s no controlados (RangeError, TypeError…), solo excepciones.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('inklus_host_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Uint8List zip(Map<String, List<int>> files) {
    final a = Archive();
    files.forEach((n, b) => a.addFile(ArchiveFile(n, b.length, b)));
    return Uint8List.fromList(ZipEncoder().encode(a));
  }

  Future<Object?> outcome(Future<Object?> Function() f) async {
    try {
      await f();
      return null;
    } catch (e) {
      return e;
    }
  }

  test('zip-slip: imágenes con ../ no escapan de la carpeta de extracción',
      () async {
    final extract = Directory('${tmp.path}/a/b')..createSync(recursive: true);
    final nb = utf8.encode(jsonEncode({'id': 'nb', 'title': 't', 'noteIds': []}));
    final bytes = zip({
      'notebook.json': nb,
      'images/../../../evil.png': [1, 2, 3],
      'images/..\\..\\evil2.png': [1, 2, 3],
      'images//abs/evil3.png': [1, 2, 3],
    });
    await InklusFormat.importAuto(bytes, extractTo: extract);
    final escaped = tmp
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !f.path.startsWith(extract.path))
        .toList();
    expect(escaped, isEmpty, reason: 'archivos fuera: $escaped');
  });

  test('basura aleatoria y zips truncados solo lanzan Exception', () async {
    final r = Random(5);
    final valid = zip({
      'notebook.json':
          utf8.encode(jsonEncode({'id': 'nb', 'title': 't', 'noteIds': []})),
    });
    final inputs = <Uint8List>[
      Uint8List(0),
      for (var i = 0; i < 40; i++)
        Uint8List.fromList(List.generate(r.nextInt(500), (_) => r.nextInt(256))),
      for (var i = 1; i < valid.length; i += 7) valid.sublist(0, i),
      for (var i = 0; i < 40; i++)
        (Uint8List.fromList(valid)..[r.nextInt(valid.length)] = r.nextInt(256)),
    ];
    final bad = <String>[];
    for (final b in inputs) {
      final e = await outcome(() => ImportService.importBytes(b,
          storage: StorageService(baseDir: tmp), extractTo: Directory('${tmp.path}/x')));
      if (e is Error) bad.add('${e.runtimeType} (${b.length} B)');
      final k = await outcome(() => ImportService.detect(b));
      if (k is Error) bad.add('detect ${k.runtimeType} (${b.length} B)');
    }
    expect(bad, isEmpty, reason: bad.take(5).join('; '));
  });

  test('JSON con tipos incorrectos no revienta con Error', () async {
    final cases = <Map<String, Object?>>[
      {'title': 't', 'noteIds': []}, // sin id
      {'id': 5, 'title': 't', 'noteIds': []},
      {'id': 'x', 'title': 't', 'noteIds': [1, 2]},
      {'id': 'x', 'title': 't', 'noteIds': 'no'},
      {'id': 'x', 'title': 3, 'noteIds': []},
      {'id': 'x', 'tags': [1, 2], 'noteIds': []},
    ];
    final bad = <String>[];
    for (final c in cases) {
      final e = await outcome(() => ImportService.importBytes(
          zip({'notebook.json': utf8.encode(jsonEncode(c))}),
          storage: StorageService(baseDir: tmp), extractTo: Directory('${tmp.path}/y')));
      if (e is Error) bad.add('$c → ${e.runtimeType}');
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  group('BackupCrypto', () {
    test('cualquier byte alterado o truncado hace fallar el descifrado',
        () async {
      final plain = Uint8List.fromList(utf8.encode('contenido secreto ñ 🔐' * 5));
      final enc = await BackupCrypto.encrypt(plain, 'clave');
      for (final i in [0, 15, 16, 27, 28, enc.length ~/ 2, enc.length - 17,
          enc.length - 16, enc.length - 1]) {
        final t = Uint8List.fromList(enc)..[i] ^= 0x01;
        final e = await outcome(() => BackupCrypto.decrypt(t, 'clave'));
        expect(e, isNotNull, reason: 'byte $i alterado se aceptó');
      }
      for (final n in [0, 10, 43, enc.length - 1]) {
        final e = await outcome(
            () => BackupCrypto.decrypt(enc.sublist(0, n), 'clave'));
        expect(e, isNotNull, reason: 'truncado a $n se aceptó');
      }
    });

    test('cifrar dos veces da salidas distintas (sal/nonce aleatorios)',
        () async {
      final p = Uint8List.fromList([1, 2, 3]);
      final a = await BackupCrypto.encrypt(p, 'k');
      final b = await BackupCrypto.encrypt(p, 'k');
      expect(a, isNot(b));
    });
  });
}
