import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Gestión de imágenes del dispositivo:
/// - copia los archivos elegidos a la carpeta de datos de la app (para que
///   el documento siga siendo válido aunque se mueva el archivo original);
/// - decodifica `ui.Image` para poder pintarlas/medirlas.
class ImageService {
  /// Copia un archivo elegido a `inklus/images/` y devuelve la nueva ruta.
  Future<String> importToApp(String sourcePath) async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/inklus/images');
    if (!await folder.exists()) await folder.create(recursive: true);
    final ext = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'img';
    final dest =
        '${folder.path}/img_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Lee y decodifica una imagen local.
  Future<ui.Image> decode(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Lee las dimensiones (px) de una imagen local sin cachearla.
  Future<ui.Image> decodeDims(String path) => decode(path);

  /// Cache de imágenes decodificadas (clave = ruta local).
  /// El lienzo lo consulta para pintar; aquí se puebla de forma asíncrona.
  final Map<String, ui.Image> cache = {};

  /// Asegura que la imagen de [path] esté decodificada y en cache.
  /// Devuelve true si ya estaba lista, false si hay que esperar.
  Future<void> ensureCached(String path) async {
    if (cache.containsKey(path)) return;
    try {
      cache[path] = await decode(path);
    } catch (e) {
      debugPrint('ImageService.ensureCached: $e');
    }
  }
}
