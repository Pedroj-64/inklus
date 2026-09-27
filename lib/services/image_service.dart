// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../models/id.dart';
import '../models/page.dart';
import 'app_paths.dart';

/// Lado mayor (px) con que se decodifican las imágenes para el **lienzo**.
/// Una foto de 12 MP a tamaño completo ocupa ~48 MB en memoria; a 2560 px
/// ~20 MB (y la mayoría, bastante menos). En pantalla no se nota: la imagen
/// ocupa una parte de la hoja y la hoja rara vez supera ese ancho en píxeles.
const int kCanvasImageMaxSide = 2560;

/// Resuelve las imágenes que necesita una página al exportarla.
typedef ExportImageResolver = Future<Map<String, ui.Image>> Function(Page page);

/// Gestión de imágenes del dispositivo:
/// - copia los archivos elegidos a la carpeta de datos de la app (para que
///   el documento siga siendo válido aunque se mueva el archivo original);
/// - decodifica `ui.Image` para poder pintarlas/medirlas.
class ImageService {
  /// Copia un archivo elegido a `inklus/images/` y devuelve la nueva ruta.
  Future<String> importToApp(String sourcePath) async {
    final folder = await AppPaths.images();
    final ext = sourcePath.contains('.')
        ? sourcePath.split('.').last.toLowerCase()
        : 'img';
    final dest = '${folder.path}/${newId('img')}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Lee y decodifica una imagen local. Si su lado mayor supera [maxSide]
  /// se decodifica ya reducida (conservando la proporción); `null` = tamaño
  /// original.
  Future<ui.Image> decode(String path, {int? maxSide = kCanvasImageMaxSide}) async {
    final bytes = await File(path).readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final size = fitWithin(descriptor.width, descriptor.height, maxSide);
    final codec = await descriptor.instantiateCodec(
      targetWidth: size?.$1,
      targetHeight: size?.$2,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  /// Tamaño reducido para que el lado mayor de [width]×[height] no pase de
  /// [maxSide], o null si ya cabe (o no hay límite).
  @visibleForTesting
  static (int, int)? fitWithin(int width, int height, int? maxSide) {
    final longest = width > height ? width : height;
    if (maxSide == null || longest <= maxSide) return null;
    final f = maxSide / longest;
    return ((width * f).round().clamp(1, maxSide), (height * f).round().clamp(1, maxSide));
  }

  /// Imágenes (fotos y plantilla) de [pages] para exportar a [maxDimension]
  /// px. Hasta la resolución del lienzo se reutiliza la caché; por encima se
  /// decodifican a la resolución de la exportación para que no pierdan
  /// nitidez. El mapa devuelto retiene sus imágenes aunque la caché las
  /// desaloje durante la exportación.
  Future<Map<String, ui.Image>> imagesForExport(
    Iterable<Page> pages, {
    int maxDimension = kCanvasImageMaxSide,
  }) async {
    final paths = <String>{
      for (final page in pages) ...[
        for (final item in page.images) item.localPath,
        if (page.template.imagePath != null) page.template.imagePath!,
      ],
    };
    final result = <String, ui.Image>{};
    for (final path in paths) {
      if (maxDimension <= kCanvasImageMaxSide) {
        await ensureCached(path);
        final img = cache[path];
        if (img != null) result[path] = img;
      } else {
        try {
          result[path] = await decode(path, maxSide: maxDimension);
        } catch (e) {
          debugPrint('ImageService.imagesForExport: $e');
        }
      }
    }
    return result;
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
