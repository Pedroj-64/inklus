// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Cifrado de respaldos: AES-256-GCM con clave derivada por PBKDF2
/// (HMAC-SHA256, 100k iteraciones).
///
/// Formato: `[salt (16)] [nonce (12)] [ciphertext] [tag (16)]`.
///
/// PBKDF2 en Dart puro tarda cientos de ms: todo se ejecuta en un isolate
/// aparte para no congelar la UI.
class BackupCrypto {
  BackupCrypto._();

  static const saltLength = 16;
  static const nonceLength = 12;
  static const tagLength = 16;
  static const pbkdf2Iterations = 100000;

  /// Cifra [data] con [password].
  static Future<Uint8List> encrypt(Uint8List data, String password) {
    return Isolate.run(() => _encrypt(data, password));
  }

  /// Descifra [data] con [password].
  ///
  /// La clave se deriva de los bytes UTF-8 de la contraseña. Versiones
  /// anteriores usaban `password.codeUnits` (incorrecto para caracteres
  /// fuera de Latin-1); si el descifrado falla y la contraseña tiene
  /// caracteres no ASCII, se reintenta con esa derivación legacy.
  static Future<Uint8List> decrypt(Uint8List data, String password) {
    return Isolate.run(() async {
      try {
        return await _decrypt(data, utf8.encode(password));
      } on SecretBoxAuthenticationError {
        final legacy = password.codeUnits;
        if (_sameBytes(legacy, utf8.encode(password))) rethrow;
        return _decrypt(data, legacy);
      }
    });
  }

  static Future<SecretKey> _deriveKey(List<int> passwordBytes, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(secretKey: SecretKey(passwordBytes), nonce: salt);
  }

  static Future<Uint8List> _encrypt(Uint8List data, String password) async {
    final salt = _randomBytes(saltLength);
    final nonce = _randomBytes(nonceLength);
    final secretKey = await _deriveKey(utf8.encode(password), salt);
    final box = await AesGcm.with256bits().encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );
    return Uint8List.fromList([
      ...salt,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  static Future<Uint8List> _decrypt(Uint8List data, List<int> passwordBytes) async {
    if (data.length < saltLength + nonceLength + tagLength) {
      throw const FormatException('Datos cifrados demasiado cortos');
    }
    final salt = data.sublist(0, saltLength);
    final nonce = data.sublist(saltLength, saltLength + nonceLength);
    final tag = data.sublist(data.length - tagLength);
    final cipherText =
        data.sublist(saltLength + nonceLength, data.length - tagLength);

    final secretKey = await _deriveKey(passwordBytes, salt);
    final result = await AesGcm.with256bits().decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
      secretKey: secretKey,
    );
    return Uint8List.fromList(result);
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
