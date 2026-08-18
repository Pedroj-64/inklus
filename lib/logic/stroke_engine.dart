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

  /// Opciones de `perfect_freehand` para una herramienta dada.
  static StrokeOptions optionsFor(ToolType tool, double size) {
    switch (tool) {
      case ToolType.pen:
        return StrokeOptions(
          size: size,
          thinning: 0,
          smoothing: 0.5,
          streamline: 0.45,
          simulatePressure: false,
        );
      case ToolType.pencil:
        return StrokeOptions(
          size: size,
          thinning: 0.55,
          smoothing: 0.5,
          streamline: 0.5,
          simulatePressure: false,
          // Puntas afiladas, estilo lápiz de grafito.
          start: StrokeEndOptions.start(taperEnabled: true, customTaper: 0.35),
          end: StrokeEndOptions.end(taperEnabled: true, customTaper: 0.35),
        );
      case ToolType.highlighter:
        return StrokeOptions(
          size: size,
          thinning: 0,
          smoothing: 0.6,
          streamline: 0.75,
          simulatePressure: false,
          isComplete: true,
        );
      case ToolType.eraser:
      case ToolType.select:
        // El borrador no se renderiza con getStroke (se usa cursor), pero
        // devolvemos algo válido por si acaso.
        return StrokeOptions(size: size, thinning: 0, simulatePressure: false);
    }
  }

  /// Polígono (lista de puntos) que envuelve el trazo, listo para rellenar.
  static List<Offset> outlineFor(Stroke stroke) {
    final points = stroke.points
        .map((p) => PointVector(p.x, p.y, p.pressure))
        .toList();
    return getStroke(
      points,
      options: optionsFor(stroke.tool, stroke.size),
    );
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
    return stroke.color;
  }
}
