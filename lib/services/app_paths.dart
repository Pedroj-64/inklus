// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Rutas de datos de la app. **Única fuente** de `<appSupport>/inklus` y de
/// sus subcarpetas: ningún servicio vuelve a construirlas a mano.
///
/// ```
/// inklus/
///   index.json · notebooks/ · notes/ · trash/        (StorageService)
///   images/ · restored/<id>/ · pdf_imports/          (imágenes)
///   templates/ · marketplace/ · versions/ · exports/
///   stats.json · reminders.json · calendar.json …
/// ```
abstract final class AppPaths {
  static Directory? _rootOverride;

  /// Carpeta raíz para tests (null = la real).
  @visibleForTesting
  static set rootOverride(Directory? dir) => _rootOverride = dir;

  /// `<appSupport>/inklus`, creada si no existe.
  static Future<Directory> root() async {
    final override = _rootOverride;
    if (override != null) return override;
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/inklus');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Subcarpeta [relative] de la raíz, creada si no existe.
  static Future<Directory> dir(String relative) async {
    final dir = Directory('${(await root()).path}/$relative');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Archivo [name] en la raíz (no lo crea).
  static Future<File> file(String name) async => File('${(await root()).path}/$name');

  static Future<Directory> images() => dir('images');
  static Future<Directory> pdfImports() => dir('pdf_imports');
  static Future<Directory> templates() => dir('templates');
  static Future<Directory> exports() => dir('exports');

  /// Imágenes extraídas de un `.inklus` importado o restaurado.
  static Future<Directory> restored(String id) => dir('restored/$id');
}
