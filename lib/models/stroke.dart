// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

/// Herramientas de escritura/dibujo disponibles.
///
/// `eraser` nunca se guarda como trazo: solo se usa en tiempo de ejecución
/// para borrar trazos existentes.
enum ToolType {
  pen, // lapicero: trazo uniforme, filo definido
  pencil, // lápiz: grosor variable según presión
  highlighter, // resaltador: trazo ancho y translúcido
  calligraphy, // caligrafía: grosor variable según ángulo
  brush, // pincel: trazo suave y orgánico
  marker, // marcador: trazo ancho semitransparente, tipo sharpie
  spray, // aerosol: trazo con partículas dispersas
  eraser, // borrador
  select, // mover/redimensionar imágenes (no genera trazos)
  lasso, // selección de trazos con lazo
  bucket, // relleno de áreas
  text, // cajas de texto
}

ToolType toolTypeFromName(String name) =>
    ToolType.values.firstWhere((t) => t.name == name, orElse: () => ToolType.pen);

/// Un punto del trazo en coordenadas de "mundo" (independientes del zoom).
///
/// [pressure] va de 0 a 1 y lo reporta el stylus; se usa para modular el
/// grosor del trazo en tiempo real.
class StrokePoint {
  final double x;
  final double y;
  final double pressure;

  const StrokePoint(this.x, this.y, this.pressure);

  Offset get offset => Offset(x, y);

  factory StrokePoint.fromOffset(Offset o, double pressure) =>
      StrokePoint(o.dx, o.dy, pressure);

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['p'] as num?)?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};
}

/// Un trazo completo confirmado sobre la página.
///
/// Almacenamos los puntos crudos (mundo) y la geometría se genera con
/// `perfect_freehand` en el momento de pintar/exportar. Guardar puntos crudos
/// (en vez del polígono) permite redibujar a cualquier zoom sin pérdida.
class Stroke {
  final String id;
  final List<StrokePoint> points;
  final ToolType tool;
  final int colorValue; // ARGB
  final double size; // diámetro base en unidades de mundo

  /// Si es mayor que 0, el trazo tiene un relleno de color (bucket fill).
  /// El valor es el color ARGB del relleno.
  final int? fillColorValue;

  /// Índice de la capa a la que pertenece este trazo (0 = capa por defecto).
  final int layerIndex;

  /// Tipo de forma detectada (line, arrow, rectangle, circle) o null.
  final String? shapeType;

  /// Ajustes de `perfect_freehand` con los que se dibujó el trazo.
  /// null = valores por defecto de la herramienta (trazos antiguos).
  final double? thinning;
  final double? smoothing;
  final double? streamline;

  Stroke({
    required this.id,
    required this.points,
    required this.tool,
    required this.colorValue,
    required this.size,
    this.fillColorValue,
    this.layerIndex = 0,
    this.shapeType,
    this.thinning,
    this.smoothing,
    this.streamline,
  });

  Color get color => Color(colorValue);

  /// Rectángulo que envuelve los puntos (sin grosor). Se calcula una vez:
  /// un [Stroke] confirmado es inmutable (editar = crear otra instancia).
  late final Rect pointBounds = _computeBounds();

  /// Rectángulo que envuelve el trazo pintado (puntos + grosor). Se usa
  /// para descartar trazos fuera de pantalla (culling) y hit-tests rápidos.
  /// El aerosol dispersa partículas hasta `size` alrededor de cada punto.
  Rect get paintBounds =>
      pointBounds.inflate(tool == ToolType.spray ? size + 4 : size);

  Rect _computeBounds() {
    if (points.isEmpty) return Rect.zero;
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    for (final p in points) {
      if (p.x < left) left = p.x;
      if (p.y < top) top = p.y;
      if (p.x > right) right = p.x;
      if (p.y > bottom) bottom = p.y;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Stroke copyWith({
    String? id,
    List<StrokePoint>? points,
    ToolType? tool,
    int? colorValue,
    double? size,
    int? fillColorValue,
    bool clearFillColor = false,
    int? layerIndex,
    String? shapeType,
    bool clearShapeType = false,
  }) =>
      Stroke(
        id: id ?? this.id,
        points: points ?? this.points,
        tool: tool ?? this.tool,
        colorValue: colorValue ?? this.colorValue,
        size: size ?? this.size,
        fillColorValue: clearFillColor ? null : (fillColorValue ?? this.fillColorValue),
        layerIndex: layerIndex ?? this.layerIndex,
        shapeType: clearShapeType ? null : (shapeType ?? this.shapeType),
        thinning: thinning,
        smoothing: smoothing,
        streamline: streamline,
      );

  /// Copia desplazada [delta] (mismo id y atributos).
  Stroke translated(Offset delta) => copyWith(
        points: [
          for (final p in points)
            StrokePoint(p.x + delta.dx, p.y + delta.dy, p.pressure),
        ],
      );

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        id: json['id'] as String,
        points: (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        tool: toolTypeFromName(json['tool'] as String),
        colorValue: (json['color'] as num).toInt(),
        size: (json['size'] as num).toDouble(),
        fillColorValue: (json['fillColor'] as num?)?.toInt(),
        layerIndex: (json['layer'] as num?)?.toInt() ?? 0,
        shapeType: json['shape'] as String?,
        thinning: (json['th'] as num?)?.toDouble(),
        smoothing: (json['sm'] as num?)?.toDouble(),
        streamline: (json['sl'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'tool': tool.name,
        'color': colorValue,
        'size': size,
        if (fillColorValue != null) 'fillColor': fillColorValue,
        if (layerIndex != 0) 'layer': layerIndex,
        if (shapeType != null) 'shape': shapeType,
        if (thinning != null) 'th': thinning,
        if (smoothing != null) 'sm': smoothing,
        if (streamline != null) 'sl': streamline,
      };
}
