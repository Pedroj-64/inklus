import 'dart:ui';

import '../models/stroke.dart';
import 'stroke_engine.dart';

/// Borrador a nivel de trazo.
///
/// En vez de borrar trazos enteros, elimina los puntos del trazo que caen
/// dentro del círculo del borrador y parte el trazo en fragmentos contiguos
/// (cada fragmento conserva herramienta, color y grosor originales).
/// Esto da un borrado fino, tipo goma de borrar real.
class StrokeEraser {
  const StrokeEraser._();

  /// Devuelve los trazos que sobreviven tras aplicar el borrador.
  ///
  /// Los trazos intactos se devuelven tal cual; los tocados se reemplazan
  /// por sus fragmentos. Es responsabilidad del llamador saber qué trazos
  /// entraron para armar la acción de deshacer.
  static List<Stroke> erase(
    List<Stroke> strokes,
    List<Offset> eraserPath,
    double radius,
  ) {
    if (eraserPath.isEmpty) return strokes;

    final result = <Stroke>[];
    for (final stroke in strokes) {
      // Radio efectivo: el círculo del borrador más medio trazo, para que
      // borrar "encima" de la línea la corte limpiamente.
      final effectiveRadius = radius + stroke.size / 2;
      final kept = <int>[];
      for (var i = 0; i < stroke.points.length; i++) {
        final p = stroke.points[i].offset;
        var erased = false;
        for (final e in eraserPath) {
          if ((p - e).distance <= effectiveRadius) {
            erased = true;
            break;
          }
        }
        if (!erased) kept.add(i);
      }
      if (kept.length == stroke.points.length) {
        result.add(stroke); // intacto
        continue;
      }
      // Invalida la caché del trazo original (fue modificado).
      StrokeEngine.invalidate(stroke.id);
      // Parte los puntos conservados en fragmentos contiguos.
      var runStart = 0;
      while (runStart < kept.length) {
        var runEnd = runStart + 1;
        while (runEnd < kept.length && kept[runEnd] == kept[runEnd - 1] + 1) {
          runEnd++;
        }
        final runPoints = [
          for (var k = runStart; k < runEnd; k++) stroke.points[kept[k]],
        ];
        // Un fragmento de < 2 puntos es un punto suelto: se descarta.
        if (runPoints.length >= 2) {
          result.add(
            stroke.copyWith(
              id: '${stroke.id}_f${result.length}_${_rand()}',
              points: runPoints,
            ),
          );
        }
        runStart = runEnd;
      }
    }
    return result;
  }

  static String _rand() =>
      '${DateTime.now().microsecondsSinceEpoch % 1000000}';
}
