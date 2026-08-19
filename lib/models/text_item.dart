import 'dart:ui';

/// Un cuadro de texto superpuesto sobre el lienzo.
///
/// Almacena el contenido, posición, tamaño y estilo del texto.
/// Se renderiza como un widget de Flutter superpuesto sobre el canvas.
class TextItem {
  final String id;

  /// Centro del item en coordenadas de mundo.
  double x;
  double y;

  /// Ancho del cuadro de texto en unidades de mundo.
  double width;

  /// Contenido del texto.
  String text;

  /// Tamaño de fuente en unidades de mundo.
  double fontSize;

  /// Color del texto (ARGB).
  int colorValue;

  /// Índice de la capa a la que pertenece.
  final int layerIndex;

  /// Id de la página destino si este texto es un enlace interno (backlink).
  final String? linkToPageId;

  TextItem({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.text,
    this.fontSize = 18,
    this.colorValue = 0xFF1A1A1A, // kDefaultStrokeColor.toARGB32()
    this.layerIndex = 0,
    this.linkToPageId,
  });

  Color get color => Color(colorValue);

  /// Altura estimada del cuadro de texto.
  double get height => _estimateHeight();

  Rect get rect => Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
  );

  /// Estima la altura del cuadro de texto basándose en el contenido.
  double _estimateHeight() {
    // Aproximación: cada línea cabe ~width/fontSize caracteres.
    final charsPerLine = (width / (fontSize * 0.6)).ceil().clamp(1, 200);
    final lineCount = (text.length / charsPerLine).ceil().clamp(1, 50);
    return lineCount * fontSize * 1.4 + 16; // margen vertical
  }

  bool contains(Offset worldPoint) => rect.inflate(6).contains(worldPoint);

  TextItem copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    String? text,
    double? fontSize,
    int? colorValue,
    int? layerIndex,
    String? linkToPageId,
  }) =>
      TextItem(
        id: id ?? this.id,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        colorValue: colorValue ?? this.colorValue,
        layerIndex: layerIndex ?? this.layerIndex,
        linkToPageId: linkToPageId ?? this.linkToPageId,
      );

  factory TextItem.fromJson(Map<String, dynamic> json) => TextItem(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['w'] as num).toDouble(),
        text: json['text'] as String? ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
        colorValue: (json['color'] as num?)?.toInt() ?? 0xFF1A1A1A, // kDefaultStrokeColor.toARGB32()
        layerIndex: (json['layer'] as num?)?.toInt() ?? 0,
        linkToPageId: json['linkToPage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'w': width,
        'text': text,
        'fontSize': fontSize,
        'color': colorValue,
        if (layerIndex != 0) 'layer': layerIndex,
        if (linkToPageId != null) 'linkToPage': linkToPageId,
      };
}
