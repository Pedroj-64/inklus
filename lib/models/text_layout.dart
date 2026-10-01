// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/painting.dart';

import 'text_item.dart';

/// Familia de fuente de Flutter para el id guardado en el modelo.
String? textFontFamily(String id) => switch (id) {
      'serif' => 'serif',
      'mono' => 'monospace',
      'lato' => 'Lato',
      'lora' => 'Lora',
      'playfair' => 'PlayfairDisplay',
      'oswald' => 'Oswald',
      'sourcecode' => 'SourceCodePro',
      'caveat' => 'Caveat',
      'indie' => 'IndieFlower',
      'pacifico' => 'Pacifico',
      _ => null, // fuente por defecto del sistema
    };

/// Nombre que ve el usuario para cada familia.
String textFontLabel(String id) => switch (id) {
      'sans' => 'Sans',
      'lato' => 'Lato',
      'serif' => 'Serif',
      'lora' => 'Lora',
      'playfair' => 'Playfair',
      'oswald' => 'Oswald',
      'mono' => 'Mono',
      'sourcecode' => 'Source Code',
      'caveat' => 'Caveat',
      'indie' => 'Indie Flower',
      'pacifico' => 'Pacifico',
      _ => id,
    };

/// Estilo de una caja de texto. **Única fuente** para el lienzo, la
/// exportación y el campo de edición (lo que editas es lo que se pinta).
/// [scale] convierte el tamaño de mundo a pantalla (1 en el mundo).
TextStyle textItemStyle(TextItem item, {double scale = 1}) => TextStyle(
      color: item.color,
      fontSize: item.fontSize * scale,
      height: item.lineHeight,
      fontWeight: item.bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
      decoration: _decoration(item.underline, item.strike),
      decorationColor: item.color,
      fontFamily: textFontFamily(item.fontFamily),
    );

TextDecoration _decoration(bool underline, bool strike) => TextDecoration.combine([
      if (underline) TextDecoration.underline,
      if (strike) TextDecoration.lineThrough,
    ]);

TextAlign textItemAlign(TextItem item) => switch (item.align) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

/// Construye el árbol de tramos de [text] sobre el estilo base [base]
/// (ya con el zoom aplicado). [extraCuts] parte el texto en más puntos
/// (p. ej. la región de composición del teclado).
TextSpan buildTextItemSpan(
  TextItem item,
  String text,
  List<TextRun> runs,
  TextStyle base, {
  TextRange composing = TextRange.empty,
  bool markComposing = false,
}) {
  final cuts = <int>{0, text.length};
  for (final r in runs) {
    if (r.start < text.length) cuts.add(r.start);
    if (r.end < text.length) cuts.add(r.end);
  }
  final hasComposing = markComposing && composing.isValid && !composing.isCollapsed;
  if (hasComposing) {
    cuts..add(composing.start.clamp(0, text.length))..add(composing.end.clamp(0, text.length));
  }
  final points = cuts.where((c) => c >= 0 && c <= text.length).toList()..sort();
  final children = <InlineSpan>[];
  for (var i = 0; i + 1 < points.length; i++) {
    final a = points[i], b = points[i + 1];
    var style = base;
    final r = runAt(runs, a);
    if (!r.isBlank) {
      final bold = r.bold ?? item.bold;
      final italic = r.italic ?? item.italic;
      final under = (r.underline ?? item.underline) ||
          (hasComposing && a >= composing.start && b <= composing.end);
      final strike = r.strike ?? item.strike;
      final color = r.color != null ? Color(r.color!) : item.color;
      style = base.copyWith(
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        decoration: _decoration(under, strike),
        decorationColor: color,
        backgroundColor: r.highlight != null ? Color(r.highlight!) : null,
        fontFamily: r.font != null ? textFontFamily(r.font!) : base.fontFamily,
      );
    } else if (hasComposing && a >= composing.start && b <= composing.end) {
      style = base.copyWith(
          decoration: _decoration(true, item.strike), decorationColor: item.color);
    }
    children.add(TextSpan(text: text.substring(a, b), style: style));
  }
  return TextSpan(style: base, children: children);
}

/// Altura del texto de [item] maquetado a su ancho. Cachea el último
/// resultado por instancia (el pintado la pide en cada frame).
double measureTextItemHeight(TextItem item) {
  final key = Object.hash(item.text, item.width, item.fontSize, item.bold,
      item.italic, item.fontFamily, item.lineHeight, Object.hashAll(item.runs.map((r) => Object.hash(r.start, r.end, r.bold, r.italic, r.font))));
  final cached = _heightCache[item];
  if (cached != null && cached.$1 == key) return cached.$2;
  final painter = TextPainter(
    text: buildTextItemSpan(item, item.text, item.runs, textItemStyle(item)),
    textAlign: textItemAlign(item),
    textDirection: TextDirection.ltr,
  )..layout(minWidth: item.width, maxWidth: item.width);
  // Una caja vacía ocupa una línea (si no, desaparece de la selección).
  final h = painter.height < item.fontSize * item.lineHeight
      ? item.fontSize * item.lineHeight
      : painter.height;
  painter.dispose();
  _heightCache[item] = (key, h);
  return h;
}

final Expando<(int, double)> _heightCache = Expando('textItemHeight');
