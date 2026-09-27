// SPDX-License-Identifier: GPL-3.0-or-later
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

  // ---- Formato (texto enriquecido a nivel de caja) ----
  final bool bold;
  final bool italic;
  final bool underline;

  /// Alineación: `left`, `center` o `right`.
  final String align;

  /// Familia: `sans`, `serif` o `mono` (familias genéricas del sistema; no
  /// se empaquetan fuentes).
  final String fontFamily;

  static const alignments = ['left', 'center', 'right'];
  static const families = ['sans', 'serif', 'mono'];

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
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.align = 'left',
    this.fontFamily = 'sans',
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
    bool clearLink = false,
    bool? bold,
    bool? italic,
    bool? underline,
    String? align,
    String? fontFamily,
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
        linkToPageId: clearLink ? null : (linkToPageId ?? this.linkToPageId),
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        align: align ?? this.align,
        fontFamily: fontFamily ?? this.fontFamily,
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
        bold: json['b'] as bool? ?? false,
        italic: json['i'] as bool? ?? false,
        underline: json['u'] as bool? ?? false,
        align: json['align'] as String? ?? 'left',
        fontFamily: json['font'] as String? ?? 'sans',
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
        if (bold) 'b': true,
        if (italic) 'i': true,
        if (underline) 'u': true,
        if (align != 'left') 'align': align,
        if (fontFamily != 'sans') 'font': fontFamily,
      };
}
