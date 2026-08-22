import 'dart:ui';

import 'package:perfect_freehand/perfect_freehand.dart'
    hide StrokePoint; // evita colisión con nuestro modelo StrokePoint

import '../models/stroke.dart';

/// Motor de trazado: usa `perfect_freehand` para convertir los puntos crudos
/// de un trazo en un polígono suavizado, con grosor variable según presión.
///
/// Cada herramienta tiene su propia "personalidad":
/// - lapicero: trazo uniforme (thinning 0), filo definido.
/// - lápiz: grosor variable con la presión (thinning alto) y puntas afiladas.
/// - resaltador: trazo ancho, sin variación de grosor, muy "streamlined".
class StrokeEngine {
  const StrokeEngine._();

  // Caché de polígonos calculados para trazos confirmados.
  // Clave = stroke.id, valor = polígono (lista de Offset).
  static final Map<String, List<Offset>> _outlineCache = {};

  /// Invalida la caché de un trazo (llamar al editar/eliminar).
  static void invalidate(String strokeId) => _outlineCache.remove(strokeId);

  /// Invalida toda la caché.
  static void invalidateAll() => _outlineCache.clear();

  /// Opciones de `perfect_freehand` para una herramienta dada.
  ///
  /// Si se proporcionan [thinning], [smoothing] o [streamline], se usan
  /// como overrides de los valores por defecto de cada herramienta.
  static StrokeOptions optionsFor(
    ToolType tool,
    double size, {
    double? thinning,
    double? smoothing,
    double? streamline,
  }) {
    switch (tool) {
      case ToolType.pen:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0,
          smoothing: smoothing ?? 0.5,
          streamline: streamline ?? 0.45,
          simulatePressure: false,
        );
      case ToolType.pencil:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0.55,
          smoothing: smoothing ?? 0.5,
          streamline: streamline ?? 0.5,
          simulatePressure: false,
          // Puntas afiladas, estilo lápiz de grafito.
          start: StrokeEndOptions.start(taperEnabled: true, customTaper: 0.35),
          end: StrokeEndOptions.end(taperEnabled: true, customTaper: 0.35),
        );
      case ToolType.highlighter:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0,
          smoothing: smoothing ?? 0.6,
          streamline: streamline ?? 0.75,
          simulatePressure: false,
          isComplete: true,
        );
      case ToolType.calligraphy:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0.3,
          smoothing: smoothing ?? 0.4,
          streamline: streamline ?? 0.35,
          simulatePressure: true,
          start: StrokeEndOptions.start(taperEnabled: true, customTaper: 0.2),
          end: StrokeEndOptions.end(taperEnabled: true, customTaper: 0.15),
        );
      case ToolType.marker:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0,
          smoothing: smoothing ?? 0.65,
          streamline: streamline ?? 0.7,
          simulatePressure: false,
        );
      case ToolType.spray:
        return StrokeOptions(
          size: size * 1.8,
          thinning: thinning ?? 0,
          smoothing: smoothing ?? 0.4,
          streamline: streamline ?? 0.3,
          simulatePressure: false,
          isComplete: true,
        );
      case ToolType.brush:
        return StrokeOptions(
          size: size,
          thinning: thinning ?? 0.4,
          smoothing: smoothing ?? 0.55,
          streamline: streamline ?? 0.6,
          simulatePressure: true,
          start: StrokeEndOptions.start(taperEnabled: true, customTaper: 0.3),
          end: StrokeEndOptions.end(taperEnabled: true, customTaper: 0.25),
        );
      case ToolType.eraser:
      case ToolType.select:
      case ToolType.lasso:
      case ToolType.bucket:
      case ToolType.text:
        // Herramientas que no generan trazos con getStroke.
        return StrokeOptions(size: size, thinning: 0, simulatePressure: false);
    }
  }

  /// Polígono (lista de puntos) que envuelve el trazo, listo para rellenar.
  /// Usa caché para trazos confirmados (misma ID, mismos puntos).
  static List<Offset> outlineFor(Stroke stroke) {
    final cached = _outlineCache[stroke.id];
    if (cached != null) return cached;
    final points = stroke.points
        .map((p) => PointVector(p.x, p.y, p.pressure))
        .toList();
    final outline = getStroke(
      points,
      options: optionsFor(stroke.tool, stroke.size),
    );
    _outlineCache[stroke.id] = outline;
    return outline;
  }

  /// Polígono del trazo en progreso (aún sin confirmar).
  static List<Offset> outlineForPoints(
    List<StrokePoint> points,
    ToolType tool,
    double size,
  ) {
    return getStroke(
      points.map((p) => PointVector(p.x, p.y, p.pressure)).toList(),
      options: optionsFor(tool, size),
    );
  }

  /// Color con el que se pinta cada herramienta. El resaltador se dibuja
  /// translúcido para que el texto/líneas de la plantilla se vean debajo.
  static Color paintColor(Stroke stroke) {
    if (stroke.tool == ToolType.highlighter) {
      return stroke.color.withValues(alpha: 0.38);
    }
    if (stroke.tool == ToolType.marker) {
      return stroke.color.withValues(alpha: 0.55);
    }
    if (stroke.tool == ToolType.spray) {
      return stroke.color.withValues(alpha: 0.25);
    }
    return stroke.color;
  }

  // ------------------------------------------------------------------
  // Hit-test de trazos (herramienta select)
  // ------------------------------------------------------------------

  /// Distancia mínima desde [worldPoint] hasta el trazo [stroke].
  ///
  /// Itera los segmentos entre puntos consecutivos y calcula la distancia
  /// perpendicular al segmento (o la distancia a los extremos). El resultado
  /// se usa como hit-test: si la distancia es menor que `stroke.size / 2`,
  /// el punto está "sobre" el trazo.
  static double distanceToStroke(Offset worldPoint, Stroke stroke) {
    if (stroke.points.isEmpty) return double.infinity;
    var minDist = double.infinity;
    for (var i = 0; i < stroke.points.length - 1; i++) {
      final a = stroke.points[i].offset;
      final b = stroke.points[i + 1].offset;
      final dist = _pointToSegmentDistance(worldPoint, a, b);
      if (dist < minDist) minDist = dist;
    }
    // También check el primer y último punto.
    final first = stroke.points.first.offset;
    final last = stroke.points.last.offset;
    final dFirst = (worldPoint - first).distance;
    final dLast = (worldPoint - last).distance;
    if (dFirst < minDist) minDist = dFirst;
    if (dLast < minDist) minDist = dLast;
    return minDist;
  }

  /// Encuentra el trazo más cercano a [worldPoint] en [strokes].
  ///
  /// Devuelve el trazo cuyo borde está más cerca del punto, o null si
  /// ningún trazo está dentro de [maxDistance].
  static Stroke? findStrokeAt(
    Offset worldPoint,
    List<Stroke> strokes, {
    double maxDistance = 20.0,
  }) {
    Stroke? closest;
    var closestDist = double.infinity;
    for (final stroke in strokes) {
      final dist = distanceToStroke(worldPoint, stroke);
      if (dist < closestDist) {
        closestDist = dist;
        closest = stroke;
      }
    }
    if (closestDist <= maxDistance) return closest;
    return null;
  }

  /// Distancia desde un punto [p] al segmento [a]-[b].
  static double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.distanceSquared;
    if (abLenSq < 1e-10) return (p - a).distance;
    final t = (ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq;
    final tClamped = t.clamp(0.0, 1.0);
    final closest = a + ab * tClamped;
    return (p - closest).distance;
  }
}
