// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    final data = Uint8List.fromList(utf8.encode('{"hola":"mundo"}'));

    test('cifra y descifra (contraseña ASCII)', () async {
      final enc = await BackupCrypto.encrypt(data, 'secreto');
      expect(enc, isNot(equals(data)));
      expect(await BackupCrypto.decrypt(enc, 'secreto'), data);
    });

    test('contraseña con ñ y emoji descifra correctamente', () async {
      const pwd = 'contraseña🔒';
      final enc = await BackupCrypto.encrypt(data, pwd);
      expect(await BackupCrypto.decrypt(enc, pwd), data);
    });

    test('contraseña incorrecta falla', () async {
      final enc = await BackupCrypto.encrypt(data, 'a');
      expect(BackupCrypto.decrypt(enc, 'b'), throwsA(anything));
    });

    test('backups legacy (clave derivada de codeUnits) siguen abriendo',
        () async {
      // Reproduce el cifrado anterior: SecretKey(password.codeUnits).
      const pwd = 'año';
      final salt = List<int>.filled(BackupCrypto.saltLength, 3);
      final nonce = List<int>.filled(BackupCrypto.nonceLength, 5);
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: BackupCrypto.pbkdf2Iterations,
        bits: 256,
      ).deriveKey(secretKey: SecretKey(pwd.codeUnits), nonce: salt);
      final box = await AesGcm.with256bits()
          .encrypt(data, secretKey: key, nonce: nonce);
      final legacy = Uint8List.fromList(
          [...salt, ...nonce, ...box.cipherText, ...box.mac.bytes]);

      expect(await BackupCrypto.decrypt(legacy, pwd), data);
    });
  });
}
