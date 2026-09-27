// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

/// Utilidades de E/S compartidas por los servicios de persistencia.

int _tmpCounter = 0;

/// Sufijo aleatorio de los temporales: [writeJsonAtomic] escribe desde
/// isolates nuevos, donde [_tmpCounter] vuelve a empezar en 0.
final Random _tmpRandom = Random();

/// Escribe [data] (String o `List<int>`) en [file] de forma **atómica**:
/// primero en un temporal junto al destino y luego `rename`. Si la app se
/// cierra a mitad de escritura, el archivo original queda intacto (nunca
/// truncado).
Future<void> writeAtomic(File file, Object data) async {
  await file.parent.create(recursive: true);
  final tmp = File(
    '${file.path}.tmp-${DateTime.now().microsecondsSinceEpoch}-'
    '${_tmpCounter++}-${_tmpRandom.nextInt(1 << 32)}',
  );
  try {
    if (data is String) {
      await tmp.writeAsString(data, flush: true);
    } else if (data is List<int>) {
      await tmp.writeAsBytes(data, flush: true);
    } else {
      throw ArgumentError('writeAtomic: tipo no soportado ${data.runtimeType}');
    }
    await tmp.rename(file.path);
  } catch (e) {
    // No dejar temporales huérfanos.
    try {
      if (await tmp.exists()) await tmp.delete();
    } catch (_) {}
    rethrow;
  }
}

/// Une [base] con una ruta relativa [relative] procedente de un archivo
/// externo (p. ej. una entrada de ZIP) **rechazando** rutas absolutas o que
/// escapen de [base] con `..` (protección contra *zip-slip*).
///
/// Devuelve null si la ruta no es segura.
String? safeJoin(String base, String relative) {
  if (relative.isEmpty ||
      relative.startsWith('/') ||
      relative.startsWith('\\') ||
      relative.contains('\\') ||
      RegExp(r'^[a-zA-Z]:').hasMatch(relative)) {
    return null;
  }
  final parts = relative.split('/');
  for (final p in parts) {
    if (p == '..' || p == '.') return null;
  }
  if (parts.last.isEmpty) return null;
  return '$base/$relative';
}

/// Nombre de archivo simple (sin directorios) seguro para escribir dentro de
/// una carpeta propia. Devuelve null para '', '.', '..'.
String? safeFileName(String path) {
  final name = path.split('/').last.split('\\').last;
  if (name.isEmpty || name == '.' || name == '..') return null;
  return name;
}

/// Umbral a partir del cual el JSON se decodifica en otro isolate para no
/// bloquear la UI (notas grandes con miles de trazos).
const int kIsolateJsonThreshold = 128 * 1024;

/// Puntos de trazo a partir de los cuales una nota se guarda en otro isolate
/// (~20k puntos ≈ 600 KB de JSON: por debajo, lanzar el isolate cuesta más
/// de lo que ahorra).
const int kBackgroundSavePoints = 20000;

/// Decodifica JSON; si es grande, lo hace en un isolate aparte. El resultado
/// vuelve con `Isolate.exit` (transferencia sin copia profunda).
Future<Object?> decodeJsonAsync(String raw) async {
  if (raw.length < kIsolateJsonThreshold) return jsonDecode(raw);
  return Isolate.run(() => jsonDecode(raw));
}

/// Serializa [json] (mapas/listas ya construidos, p. ej. `note.toJson()`) y
/// lo escribe con [writeAtomic]. Con [background] la codificación y la
/// escritura ocurren en otro isolate: el hilo de UI solo paga la copia del
/// mapa, no `jsonEncode` (lo caro en notas con miles de trazos).
Future<void> writeJsonAtomic(
  File file,
  Object json, {
  bool background = false,
}) {
  if (!background) return writeAtomic(file, jsonEncode(json));
  final path = file.path;
  return Isolate.run(() => writeAtomic(File(path), jsonEncode(json)));
}

/// Ejecuta tareas asíncronas de una en una (mutex simple basado en Futures).
/// Evita que dos lecturas-modificación-escritura del mismo archivo se pisen.
class SerialQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    // La cola continúa aunque la tarea falle.
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
