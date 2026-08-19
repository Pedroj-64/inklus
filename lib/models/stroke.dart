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

  Stroke({
    required this.id,
    required this.points,
    required this.tool,
    required this.colorValue,
    required this.size,
    this.fillColorValue,
    this.layerIndex = 0,
    this.shapeType,
  });

  Color get color => Color(colorValue);

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
      };
}
