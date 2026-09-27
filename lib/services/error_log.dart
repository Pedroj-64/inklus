// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants.dart';
import 'app_paths.dart';
import 'file_utils.dart';

/// Registro **local** de errores no capturados.
///
/// Sustituye a un servicio de *crash reporting*: nada sale del dispositivo
/// salvo que el usuario comparta el registro a mano (Configuración →
/// "Registro de errores"). Así se puede diagnosticar un fallo sin analítica
/// ni cuentas de terceros.
abstract final class ErrorLog {
  static const _fileName = 'errors.log';

  /// Tamaño máximo: al superarlo se conserva la mitad más reciente.
  static const maxBytes = 256 * 1024;

  static final SerialQueue _queue = SerialQueue();

  /// Archivo del registro (null en tests, donde se puede sustituir).
  @visibleForTesting
  static Future<File> Function() fileProvider = () => AppPaths.file(_fileName);

  /// Añade un error con su traza. Nunca lanza: un fallo al registrar no
  /// debe provocar otro.
  static Future<void> record(Object error, StackTrace? stack, {String? context}) {
    final entry = StringBuffer()
      ..writeln('=== ${DateTime.now().toIso8601String()} · Inklus $kAppVersion'
          ' · ${Platform.operatingSystem}${context == null ? '' : ' · $context'}')
      ..writeln(error)
      ..writeln(_trim(stack));
    return _queue.run(() async {
      try {
        final file = await fileProvider();
        var text = await file.exists() ? await file.readAsString() : '';
        text += entry.toString();
        if (text.length > maxBytes) {
          // Corta por el inicio de una entrada para no dejar trazas a medias.
          final cut = text.indexOf('=== ', text.length - maxBytes ~/ 2);
          text = cut < 0 ? text.substring(text.length - maxBytes ~/ 2) : text.substring(cut);
        }
        await writeAtomic(file, text);
      } catch (e) {
        debugPrint('ErrorLog.record: $e');
      }
    });
  }

  /// Contenido completo ('' si no hay errores).
  static Future<String> read() async {
    final file = await fileProvider();
    return await file.exists() ? file.readAsString() : '';
  }

  /// Número de errores registrados.
  static Future<int> count() async => '=== '.allMatches(await read()).length;

  static Future<void> clear() => _queue.run(() async {
        final file = await fileProvider();
        if (await file.exists()) await file.delete();
      });

  /// Primeras líneas de la traza (lo útil para diagnosticar).
  static String _trim(StackTrace? stack) {
    if (stack == null) return '';
    final lines = stack.toString().split('\n');
    return lines.take(25).join('\n');
  }
}
