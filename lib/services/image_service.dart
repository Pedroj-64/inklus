// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/id.dart';

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
    final dest = '${folder.path}/${newId('img')}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Lee y decodifica una imagen local.
  Future<ui.Image> decode(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Cache de imágenes decodificadas (clave = ruta local), acotada por
  /// memoria con desalojo LRU. El lienzo lo consulta para pintar; aquí se
  /// puebla de forma asíncrona.
  final BoundedImageCache cache = BoundedImageCache();

  /// Rutas en decodificación (evita decodificar la misma imagen dos veces
  /// cuando varias llamadas llegan antes de terminar la primera).
  final Map<String, Future<void>> _pending = {};

  /// Asegura que la imagen de [path] esté decodificada y en cache.
  Future<void> ensureCached(String path) {
    if (cache.containsKey(path)) return Future.value();
    return _pending.putIfAbsent(path, () async {
      try {
        cache[path] = await decode(path);
      } catch (e) {
        debugPrint('ImageService.ensureCached: $e');
      } finally {
        _pending.remove(path);
      }
    });
  }
}

/// Map de imágenes con presupuesto de memoria (bytes de píxeles RGBA).
///
/// Al superar [maxBytes] se desalojan las menos usadas recientemente. Las
/// imágenes desalojadas no se `dispose()`an explícitamente (podrían estar
/// en uso por un frame o una exportación en curso); las libera el GC.
class BoundedImageCache extends MapBase<String, ui.Image> {
  BoundedImageCache({this.maxBytes = 192 * 1024 * 1024});

  final int maxBytes;
  // ignore: prefer_collection_literals
  final LinkedHashMap<String, ui.Image> _map = LinkedHashMap();
  int _bytes = 0;

  int get currentBytes => _bytes;

  /// Aumenta con cada imagen añadida: los painters lo comparan para saber
  /// si deben repintar (la instancia del Map es siempre la misma).
  int get version => _version;
  int _version = 0;

  static int _sizeOf(ui.Image img) => img.width * img.height * 4;

  @override
  ui.Image? operator [](Object? key) {
    final img = _map.remove(key);
    if (img == null) return null;
    _map[key as String] = img; // marca como usada recientemente
    return img;
  }

  @override
  void operator []=(String key, ui.Image value) {
    final old = _map.remove(key);
    if (old != null) _bytes -= _sizeOf(old);
    _map[key] = value;
    _bytes += _sizeOf(value);
    _version++;
    // Desaloja las más antiguas, pero nunca la recién insertada.
    while (_bytes > maxBytes && _map.length > 1) {
      final oldestKey = _map.keys.first;
      final evicted = _map.remove(oldestKey)!;
      _bytes -= _sizeOf(evicted);
    }
  }

  @override
  void clear() {
    _map.clear();
    _bytes = 0;
  }

  @override
  Iterable<String> get keys => _map.keys;

  @override
  ui.Image? remove(Object? key) {
    final img = _map.remove(key);
    if (img != null) _bytes -= _sizeOf(img);
    return img;
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);
}
