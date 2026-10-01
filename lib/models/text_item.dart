// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'text_layout.dart';

/// Formato de un tramo del texto de una caja. `null` = hereda el de la caja.
///
/// Los tramos se guardan ordenados y sin solaparse (ver [applyRunStyle]).
class TextRun {
  const TextRun(
    this.start,
    this.end, {
    this.bold,
    this.italic,
    this.underline,
    this.strike,
    this.color,
    this.highlight,
    this.font,
  });

  /// Rango `[start, end)` en unidades UTF-16 (como `TextSelection`).
  final int start;
  final int end;
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final bool? strike;

  /// Color del texto (ARGB) y color de resaltado (ARGB).
  final int? color;
  final int? highlight;
  final String? font;

  bool get isBlank =>
      bold == null &&
      italic == null &&
      underline == null &&
      strike == null &&
      color == null &&
      highlight == null &&
      font == null;

  /// Mismo formato (ignora el rango).
  bool sameStyle(TextRun o) =>
      bold == o.bold &&
      italic == o.italic &&
      underline == o.underline &&
      strike == o.strike &&
      color == o.color &&
      highlight == o.highlight &&
      font == o.font;

  TextRun withRange(int s, int e) => TextRun(s, e,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      color: color,
      highlight: highlight,
      font: font);

  /// [clearColor]/[clearHighlight]/[clearFont] devuelven el campo a "heredar".
  TextRun copyStyle({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    int? color,
    int? highlight,
    String? font,
    bool clearColor = false,
    bool clearHighlight = false,
    bool clearFont = false,
  }) =>
      TextRun(start, end,
          bold: bold ?? this.bold,
          italic: italic ?? this.italic,
          underline: underline ?? this.underline,
          strike: strike ?? this.strike,
          color: clearColor ? null : (color ?? this.color),
          highlight: clearHighlight ? null : (highlight ?? this.highlight),
          font: clearFont ? null : (font ?? this.font));

  Map<String, dynamic> toJson() => {
        's': start,
        'e': end,
        if (bold != null) 'b': bold,
        if (italic != null) 'i': italic,
        if (underline != null) 'u': underline,
        if (strike != null) 'k': strike,
        if (color != null) 'c': color,
        if (highlight != null) 'h': highlight,
        if (font != null) 'f': font,
      };

  factory TextRun.fromJson(Map<String, dynamic> j) => TextRun(
        (j['s'] as num).toInt(),
        (j['e'] as num).toInt(),
        bold: j['b'] as bool?,
        italic: j['i'] as bool?,
        underline: j['u'] as bool?,
        strike: j['k'] as bool?,
        color: (j['c'] as num?)?.toInt(),
        highlight: (j['h'] as num?)?.toInt(),
        font: j['f'] as String?,
      );
}

/// Aplica [change] al formato del rango `[start, end)` y devuelve los tramos
/// resultantes (ordenados, sin huecos en blanco ni tramos contiguos iguales).
List<TextRun> applyRunStyle(
  List<TextRun> runs,
  int start,
  int end,
  TextRun Function(TextRun) change,
) {
  if (end <= start) return runs;
  final cuts = <int>{start, end};
  for (final r in runs) {
    cuts..add(r.start)..add(r.end);
  }
  final points = cuts.toList()..sort();
  final out = <TextRun>[];
  for (var i = 0; i + 1 < points.length; i++) {
    final a = points[i], b = points[i + 1];
    var seg = TextRun(a, b);
    for (final r in runs) {
      if (r.start <= a && r.end >= b) {
        seg = r.withRange(a, b);
        break;
      }
    }
    if (a >= start && b <= end) seg = change(seg).withRange(a, b);
    if (seg.isBlank) continue;
    if (out.isNotEmpty && out.last.end == a && out.last.sameStyle(seg)) {
      out[out.length - 1] = out.last.withRange(out.last.start, b);
    } else {
      out.add(seg);
    }
  }
  return out;
}

/// Formato del carácter en [index] (o un tramo en blanco).
TextRun runAt(List<TextRun> runs, int index) {
  for (final r in runs) {
    if (r.start <= index && index < r.end) return r;
  }
  return TextRun(index, index + 1);
}

/// Reajusta los tramos tras editar el texto de [oldText] a [newText]: los
/// tramos posteriores se desplazan; lo que se teclea al final de un tramo
/// hereda su formato (como en Word/Docs).
List<TextRun> adjustRunsForEdit(
    List<TextRun> runs, String oldText, String newText) {
  if (runs.isEmpty || oldText == newText) return runs;
  final minLen = oldText.length < newText.length ? oldText.length : newText.length;
  var p = 0;
  while (p < minLen && oldText.codeUnitAt(p) == newText.codeUnitAt(p)) {
    p++;
  }
  var s = 0;
  while (s < minLen - p &&
      oldText.codeUnitAt(oldText.length - 1 - s) ==
          newText.codeUnitAt(newText.length - 1 - s)) {
    s++;
  }
  final oldEnd = oldText.length - s;
  final ins = newText.length - p - s;
  final delta = ins - (oldEnd - p);
  final out = <TextRun>[];
  for (final r in runs) {
    int a, b;
    if (r.end <= p) {
      a = r.start;
      b = (r.end == p && ins > 0) ? r.end + ins : r.end;
    } else if (r.start >= oldEnd) {
      a = r.start + delta;
      b = r.end + delta;
    } else if (r.start < p && r.end > oldEnd) {
      a = r.start;
      b = r.end + delta;
    } else if (r.start < p) {
      a = r.start;
      b = p + ins;
    } else if (r.end > oldEnd) {
      a = p + ins;
      b = r.end + delta;
    } else {
      continue; // tramo dentro de lo borrado
    }
    if (b > a) out.add(r.withRange(a, b));
  }
  return out;
}

/// Un cuadro de texto superpuesto sobre el lienzo.
///
/// Almacena el contenido, posición, tamaño y estilo del texto. El formato de
/// la caja ([bold], [fontFamily]…) es el de partida; [runs] lo sobrescribe
/// por tramos (subrayar o colorear solo una parte).
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

  // ---- Formato de la caja ----
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  /// Alineación: `left`, `center` o `right`.
  final String align;

  /// Una de [families].
  final String fontFamily;

  /// Interlineado (multiplicador del tamaño de letra).
  final double lineHeight;

  /// Formato por tramos (inmutable: para cambiar, crear otra lista).
  final List<TextRun> runs;

  static const alignments = ['left', 'center', 'right'];

  /// Familias disponibles. `sans`/`serif`/`mono` son las del sistema; el
  /// resto van empaquetadas (`assets/fonts`, licencia OFL).
  static const families = [
    'sans',
    'lato',
    'serif',
    'lora',
    'playfair',
    'oswald',
    'mono',
    'sourcecode',
    'caveat',
    'indie',
    'pacifico',
  ];

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
    this.strike = false,
    this.align = 'left',
    this.fontFamily = 'sans',
    this.lineHeight = 1.3,
    this.runs = const [],
  });

  Color get color => Color(colorValue);

  /// Altura real del texto ya maquetado (medida con el mismo estilo que el
  /// lienzo y el editor, así que coincide con lo que se ve).
  double get height => measureTextItemHeight(this);

  Rect get rect => Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );

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
    bool? strike,
    String? align,
    String? fontFamily,
    double? lineHeight,
    List<TextRun>? runs,
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
        strike: strike ?? this.strike,
        align: align ?? this.align,
        fontFamily: fontFamily ?? this.fontFamily,
        lineHeight: lineHeight ?? this.lineHeight,
        runs: runs ?? this.runs,
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
        strike: json['k'] as bool? ?? false,
        align: json['align'] as String? ?? 'left',
        fontFamily: json['font'] as String? ?? 'sans',
        lineHeight: (json['lh'] as num?)?.toDouble() ?? 1.3,
        runs: [
          for (final r in json['runs'] as List? ?? const [])
            TextRun.fromJson(r as Map<String, dynamic>),
        ],
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
        if (strike) 'k': true,
        if (align != 'left') 'align': align,
        if (fontFamily != 'sans') 'font': fontFamily,
        if (lineHeight != 1.3) 'lh': lineHeight,
        if (runs.isNotEmpty) 'runs': [for (final r in runs) r.toJson()],
      };
}
