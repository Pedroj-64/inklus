// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import '../models/id.dart';
import '../models/stroke.dart';

/// Borrador a nivel de trazo.
///
/// En vez de borrar trazos enteros, elimina los puntos del trazo que caen
/// dentro del círculo del borrador y parte el trazo en fragmentos contiguos
/// (cada fragmento conserva herramienta, color, grosor, capa y ajustes).
/// Esto da un borrado fino, tipo goma de borrar real.
class StrokeEraser {
  const StrokeEraser._();

  /// Devuelve los trazos que sobreviven tras aplicar el borrador, en el
  /// **mismo orden** que la entrada (los fragmentos ocupan el lugar del
  /// trazo original). Los trazos intactos se devuelven tal cual.
  static List<Stroke> erase(
    List<Stroke> strokes,
    List<Offset> eraserPath,
    double radius,
  ) {
    if (eraserPath.isEmpty) return strokes;
    final pathBounds = _bounds(eraserPath);
    final result = <Stroke>[];
    for (final stroke in strokes) {
      final fragments = eraseStroke(stroke, eraserPath, radius, pathBounds: pathBounds);
      if (fragments == null) {
        result.add(stroke);
      } else {
        result.addAll(fragments);
      }
    }
    return result;
  }

  /// Aplica el borrador a un solo trazo.
  ///
  /// Devuelve null si el trazo no se tocó, o la lista (posiblemente vacía)
  /// de fragmentos que lo reemplazan.
  static List<Stroke>? eraseStroke(
    Stroke stroke,
    List<Offset> eraserPath,
    double radius, {
    Rect? pathBounds,
  }) {
    if (eraserPath.isEmpty || stroke.points.isEmpty) return null;
    // Radio efectivo: el círculo del borrador más medio trazo, para que
    // borrar "encima" de la línea la corte limpiamente.
    final effectiveRadius = radius + stroke.size / 2;
    // Descarte rápido: si los rectángulos no se tocan, no hay nada que hacer.
    final pb = pathBounds ?? _bounds(eraserPath);
    if (!stroke.pointBounds.overlaps(pb.inflate(effectiveRadius))) return null;

    final r2 = effectiveRadius * effectiveRadius;
    final kept = <int>[];
    for (var i = 0; i < stroke.points.length; i++) {
      final p = stroke.points[i];
      var erased = false;
      for (final e in eraserPath) {
        final dx = p.x - e.dx;
        final dy = p.y - e.dy;
        if (dx * dx + dy * dy <= r2) {
          erased = true;
          break;
        }
      }
      if (!erased) kept.add(i);
    }
    if (kept.length == stroke.points.length) return null; // intacto

    // Parte los puntos conservados en fragmentos contiguos.
    final fragments = <Stroke>[];
    var runStart = 0;
    while (runStart < kept.length) {
      var runEnd = runStart + 1;
      while (runEnd < kept.length && kept[runEnd] == kept[runEnd - 1] + 1) {
        runEnd++;
      }
      // Un fragmento de < 2 puntos es un punto suelto: se descarta.
      if (runEnd - runStart >= 2) {
        fragments.add(
          stroke.copyWith(
            id: newId('st'),
            points: [
              for (var k = runStart; k < runEnd; k++) stroke.points[kept[k]],
            ],
            clearShapeType: true, // un fragmento ya no es la figura completa
          ),
        );
      }
      runStart = runEnd;
    }
    return fragments;
  }

  static Rect _bounds(List<Offset> pts) {
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < left) left = p.dx;
      if (p.dy < top) top = p.dy;
      if (p.dx > right) right = p.dx;
      if (p.dy > bottom) bottom = p.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
