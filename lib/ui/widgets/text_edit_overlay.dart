// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../models/text_item.dart';
import '../../models/text_layout.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../../l10n/l10n.dart';

/// Resaltados del texto (colores suaves, como el marcador de Docs).
const List<Color> _kHighlights = [
  Color(0xFFFFF176),
  Color(0xFFA5D6A7),
  Color(0xFF90CAF9),
  Color(0xFFF48FB1),
  Color(0xFFFFCC80),
  Color(0xFFCE93D8),
];

const List<double> _kLineHeights = [1.0, 1.15, 1.3, 1.5, 2.0];

/// Controlador de texto que pinta los tramos con formato mientras se edita
/// y reajusta sus rangos cuando cambia el texto (teclear, pegar, cortar…).
class RichTextController extends TextEditingController {
  RichTextController();

  TextItem? item;
  List<TextRun> runs = const [];
  bool _loading = false;

  /// `true` mientras [load] vuelca una caja (se llama durante `build`).
  bool get loading => _loading;

  /// Carga una caja sin tratar el cambio de texto como una edición.
  void load(TextItem it) {
    _loading = true;
    item = it;
    runs = it.runs;
    value = TextEditingValue(
      text: it.text,
      selection: TextSelection.collapsed(offset: it.text.length),
    );
    _loading = false;
  }

  @override
  set value(TextEditingValue newValue) {
    if (!_loading && newValue.text != text) {
      runs = adjustRunsForEdit(runs, text, newValue.text);
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final it = item;
    if (it == null) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    return buildTextItemSpan(it, text, runs, style ?? const TextStyle(),
        composing: value.composing, markComposing: withComposing);
  }
}

enum _Panel { none, font, color, highlight, spacing }

/// Edición en el lienzo de una caja de texto, tipo Docs/Word.
///
/// Es un campo de texto real (cursor, selección, cortar/copiar/pegar con el
/// lápiz, dedo o ratón) con una barra de formato que actúa sobre la
/// **selección** (o sobre toda la caja si no hay selección). Se puede mover
/// y ensanchar la caja con sus asas.
///
/// Vive FUERA del `Listener` del lienzo (ver `DrawingCanvas`): así tocar la
/// barra o el campo no llega a la página.
class TextEditOverlay extends StatefulWidget {
  const TextEditOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  State<TextEditOverlay> createState() => _TextEditOverlayState();
}

class _TextEditOverlayState extends State<TextEditOverlay> {
  static const double _pad = 6;

  final RichTextController _tc = RichTextController();
  final FocusNode _focus = FocusNode();
  String? _editingId;
  _Panel _panel = _Panel.none;

  /// Borde superior de la caja (mundo). Fijo mientras se teclea: la caja
  /// crece hacia abajo en vez de "bailar" alrededor de su centro.
  double _topWorld = 0;

  CanvasController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _tc.removeListener(_onTextChanged);
    _tc.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Cambia la selección → la barra refleja el formato de lo seleccionado.
  void _onTextChanged() {
    if (mounted && !_tc.loading && _editingId != null) setState(() {});
  }

  TextItem? _currentItem() {
    final id = _c.editingTextId;
    if (id == null) return null;
    for (final t in _c.page.textItems) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Publica la caja con el texto/tramos actuales, manteniendo fijo su borde
  /// superior.
  void _push(TextItem next) {
    next = next.copyWith(text: _tc.text, runs: _tc.runs);
    next.y = _topWorld + next.height / 2;
    _tc.item = next;
    _c.updateTextItem(next);
  }

  /// Rango al que afecta el formato: la selección, o todo el texto.
  (int, int, bool) get _range {
    final sel = _tc.selection;
    if (sel.isValid && !sel.isCollapsed) return (sel.start, sel.end, false);
    return (0, _tc.text.length, true);
  }

  /// Cambia el formato del rango. [run] actúa sobre los tramos; [whole]
  /// (solo si no hay selección) también sobre el formato de la caja.
  void _format(TextRun Function(TextRun) run, [TextItem Function(TextItem)? whole]) {
    final item = _currentItem();
    if (item == null) return;
    final (a, b, all) = _range;
    _tc.runs = applyRunStyle(_tc.runs, a, b, run);
    _push(all && whole != null ? whole(item) : item);
    _focus.requestFocus();
  }

  /// `true` si TODO el rango cumple [test] (para alternar negrita, etc.).
  bool _all(TextItem item, bool Function(TextRun) test) {
    final (a, b, _) = _range;
    if (a >= b) return test(const TextRun(0, 0));
    var pos = a;
    while (pos < b) {
      final r = runAt(_tc.runs, pos);
      if (!test(r)) return false;
      pos = r.isBlank ? pos + 1 : r.end.clamp(pos + 1, b);
    }
    return true;
  }

  void _toggle(
    bool Function(TextItem) itemValue,
    bool? Function(TextRun) runValue,
    TextRun Function(TextRun, bool) setRun,
    TextItem Function(TextItem, bool) setItem,
  ) {
    final item = _currentItem();
    if (item == null) return;
    final on = _all(item, (r) => runValue(r) ?? itemValue(item));
    _format((r) => setRun(r, !on), (t) => setItem(t, !on));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final item = _currentItem();
        if (item == null) {
          _editingId = null;
          _panel = _Panel.none;
          return const SizedBox.shrink();
        }
        if (_editingId != item.id) {
          _editingId = item.id;
          _panel = _Panel.none;
          _topWorld = item.y - item.height / 2;
          _tc.load(item);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _focus.requestFocus();
          });
        }
        _tc.item = item;

        final scale = _c.scale;
        final topLeft = _c.worldToViewport(
          Offset(item.x - item.width / 2, _topWorld),
          _c.viewportSize,
        );
        final width = item.width * scale;
        final boxHeight = item.height * scale;
        final viewport = _c.viewportSize;
        // La barra va encima de la caja; si no cabe, debajo.
        final above = topLeft.dy > 120;
        final style = textItemStyle(item, scale: scale)
            .copyWith(inherit: false, letterSpacing: 0, textBaseline: TextBaseline.alphabetic);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ---- Barra de formato (+ panel desplegable) ----
            Positioned(
              left: Spacing.sm,
              right: Spacing.sm,
              top: above ? null : topLeft.dy + boxHeight + Spacing.md + _pad,
              bottom: above ? viewport.height - topLeft.dy + Spacing.md + _pad : null,
              child: Align(
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: Offset(
                    (topLeft.dx - Spacing.sm).clamp(
                      0.0,
                      (viewport.width - 2 * Spacing.sm - 360).clamp(0.0, double.infinity),
                    ),
                    0,
                  ),
                  // Misma "región" que el campo: tocar la barra no cuenta como
                  // tocar fuera (si no, pulsar Negrita cerraría la edición).
                  child: TextFieldTapRegion(
                    child: ExcludeFocus(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (above && _panel != _Panel.none) ...[
                            _buildPanel(item),
                            const SizedBox(height: Spacing.xs),
                          ],
                          _buildBar(item, viewport.width - 2 * Spacing.sm),
                          if (!above && _panel != _Panel.none) ...[
                            const SizedBox(height: Spacing.xs),
                            _buildPanel(item),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ---- Marco + campo ----
            Positioned(
              left: topLeft.dx - _pad,
              top: topLeft.dy - _pad,
              width: width + 2 * _pad,
              child: Material(
                color: context.inklus.paper.withValues(alpha: 0.94),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: Radii.smAll,
                  side: BorderSide(color: context.colors.primary, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_pad),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                    child: TextField(
                    controller: _tc,
                    focusNode: _focus,
                    style: style,
                    textAlign: textItemAlign(item),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autofocus: true,
                    cursorColor: context.colors.primary,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: context.l10n.textEditHint,
                      hintStyle: style.copyWith(color: Colors.black38),
                    ),
                    onChanged: (_) {
                      final cur = _currentItem();
                      if (cur != null) _push(cur);
                    },
                    onTapOutside: (_) => _c.commitEditingText(),
                  )),
                ),
              ),
            ),
            // ---- Asas: mover (esquina) y ensanchar (borde derecho) ----
            Positioned(
              left: topLeft.dx - _pad - 22,
              top: topLeft.dy - _pad - 22,
              child: TextFieldTapRegion(
                child: _Handle(
                  icon: Icons.open_with,
                  tooltip: context.l10n.textEditMove,
                  onDrag: (d) {
                    final cur = _currentItem();
                    if (cur == null) return;
                    _topWorld += d.dy / scale;
                    _push(cur.copyWith(x: cur.x + d.dx / scale));
                  },
                ),
              ),
            ),
            Positioned(
              left: topLeft.dx + width + _pad - 22,
              top: topLeft.dy + boxHeight / 2 - 22,
              child: TextFieldTapRegion(
                child: _Handle(
                  icon: Icons.swap_horiz,
                  tooltip: context.l10n.textEditWidth,
                  onDrag: (d) {
                    final cur = _currentItem();
                    if (cur == null) return;
                    final w = (cur.width + d.dx / scale).clamp(60.0, 4000.0);
                    // El borde izquierdo no se mueve: solo crece hacia la derecha.
                    _push(cur.copyWith(x: cur.x + (w - cur.width) / 2, width: w));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Barra
  // -------------------------------------------------------------------------

  Widget _buildBar(TextItem item, double maxWidth) {
    final scheme = context.colors;
    final bold = _all(item, (r) => r.bold ?? item.bold);
    final italic = _all(item, (r) => r.italic ?? item.italic);
    final under = _all(item, (r) => r.underline ?? item.underline);
    final strike = _all(item, (r) => r.strike ?? item.strike);
    final (a, _, _) = _range;
    final at = runAt(_tc.runs, a);
    final fontId = at.font ?? item.fontFamily;
    final textColor = at.color != null ? Color(at.color!) : item.color;
    final sel = _tc.selection;
    final hasSel = sel.isValid && !sel.isCollapsed;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 6,
        borderRadius: Radii.xlAll,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fuente
              TextButton(
                onPressed: () => _togglePanel(_Panel.font),
                child: Text(
                  textFontLabel(fontId),
                  style: TextStyle(fontFamily: textFontFamily(fontId), fontSize: 15),
                ),
              ),
              const _Divider(),
              // Tamaño
              _barButton(Icons.remove, context.l10n.textEditSmaller, false,
                  () => _setSize(item, item.fontSize - 2)),
              SizedBox(
                width: 32,
                child: Text('${item.fontSize.round()}',
                    textAlign: TextAlign.center, style: context.text.labelLarge),
              ),
              _barButton(Icons.add, context.l10n.textEditLarger, false,
                  () => _setSize(item, item.fontSize + 2)),
              const _Divider(),
              // B I U S
              _barButton(Icons.format_bold, context.l10n.textEditBold, bold,
                  () => _toggle((t) => t.bold, (r) => r.bold,
                      (r, v) => r.copyStyle(bold: v), (t, v) => t.copyWith(bold: v))),
              _barButton(Icons.format_italic, context.l10n.textEditItalic, italic,
                  () => _toggle((t) => t.italic, (r) => r.italic,
                      (r, v) => r.copyStyle(italic: v), (t, v) => t.copyWith(italic: v))),
              _barButton(Icons.format_underlined, context.l10n.textEditUnderline, under,
                  () => _toggle((t) => t.underline, (r) => r.underline,
                      (r, v) => r.copyStyle(underline: v), (t, v) => t.copyWith(underline: v))),
              _barButton(Icons.strikethrough_s, context.l10n.textEditStrike, strike,
                  () => _toggle((t) => t.strike, (r) => r.strike,
                      (r, v) => r.copyStyle(strike: v), (t, v) => t.copyWith(strike: v))),
              const _Divider(),
              // Colores
              _colorButton(Icons.format_color_text, context.l10n.textEditColor, textColor,
                  _panel == _Panel.color, () => _togglePanel(_Panel.color)),
              _colorButton(
                  Icons.border_color,
                  context.l10n.textEditHighlight,
                  at.highlight != null ? Color(at.highlight!) : _kHighlights.first,
                  _panel == _Panel.highlight,
                  () => _togglePanel(_Panel.highlight)),
              const _Divider(),
              // Párrafo
              _barButton(
                switch (item.align) {
                  'center' => Icons.format_align_center,
                  'right' => Icons.format_align_right,
                  _ => Icons.format_align_left,
                },
                context.l10n.textEditAlign,
                false,
                () {
                  final next = TextItem.alignments[
                      (TextItem.alignments.indexOf(item.align) + 1) %
                          TextItem.alignments.length];
                  _push(item.copyWith(align: next));
                },
              ),
              _barButton(Icons.format_line_spacing, context.l10n.textEditSpacing, _panel == _Panel.spacing,
                  () => _togglePanel(_Panel.spacing)),
              const _Divider(),
              _barButton(
                  Icons.link,
                  item.linkToPageId != null ? context.l10n.textEditLinkActive : context.l10n.textEditLink,
                  item.linkToPageId != null,
                  () => _showLinkPicker(item)),
              _barButton(Icons.delete_outline, context.l10n.textEditDelete, false,
                  () => _c.removeTextItem(item),
                  color: context.inklus.danger),
              _barButton(Icons.check, context.l10n.textEditDone, false, _c.commitEditingText,
                  color: scheme.primary),
              if (!hasSel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Text(context.l10n.textEditWholeBox, style: context.text.labelSmall),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePanel(_Panel p) => setState(() => _panel = _panel == p ? _Panel.none : p);

  void _setSize(TextItem item, double size) {
    _push(item.copyWith(fontSize: size.clamp(8.0, 200.0)));
    _focus.requestFocus();
  }

  Widget _barButton(IconData icon, String tooltip, bool on, VoidCallback onTap,
      {Color? color}) {
    return IconButton(
      tooltip: tooltip,
      isSelected: on,
      style: on
          ? IconButton.styleFrom(backgroundColor: context.colors.primaryContainer)
          : null,
      icon: Icon(icon, color: color),
      onPressed: onTap,
    );
  }

  /// Botón con una barrita del color actual debajo del icono (como Docs).
  Widget _colorButton(
      IconData icon, String tooltip, Color color, bool open, VoidCallback onTap) {
    return IconButton(
      tooltip: tooltip,
      isSelected: open,
      style: open
          ? IconButton.styleFrom(backgroundColor: context.colors.primaryContainer)
          : null,
      onPressed: onTap,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: context.colors.outlineVariant, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Paneles desplegables
  // -------------------------------------------------------------------------

  Widget _buildPanel(TextItem item) {
    final scheme = context.colors;
    final child = switch (_panel) {
      _Panel.font => _fontList(item),
      _Panel.color => _swatches(
          colors: kDefaultPalette,
          onPick: (c) => _format(
              (r) => r.copyStyle(color: c.toARGB32()),
              (t) => t.copyWith(colorValue: c.toARGB32())),
          onClear: null,
        ),
      _Panel.highlight => _swatches(
          colors: _kHighlights,
          onPick: (c) => _format((r) => r.copyStyle(highlight: c.toARGB32())),
          onClear: () => _format((r) => r.copyStyle(clearHighlight: true)),
          clearLabel: context.l10n.textEditNoHighlight,
        ),
      _Panel.spacing => Wrap(
          spacing: Spacing.sm,
          children: [
            for (final h in _kLineHeights)
              ChoiceChip(
                label: Text(h.toString()),
                selected: (item.lineHeight - h).abs() < 0.01,
                onSelected: (_) {
                  _push(item.copyWith(lineHeight: h));
                  setState(() => _panel = _Panel.none);
                },
              ),
          ],
        ),
      _Panel.none => const SizedBox.shrink(),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 280),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 6,
        borderRadius: Radii.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: child,
        ),
      ),
    );
  }

  Widget _fontList(TextItem item) {
    final (a, _, _) = _range;
    final current = runAt(_tc.runs, a).font ?? item.fontFamily;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in TextItem.families)
            ListTile(
              dense: true,
              selected: id == current,
              selectedTileColor: context.colors.primaryContainer,
              shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
              title: Text(textFontLabel(id),
                  style: TextStyle(fontFamily: textFontFamily(id), fontSize: 18)),
              trailing: id == current ? const Icon(Icons.check, size: 18) : null,
              onTap: () {
                _format((r) => r.copyStyle(font: id), (t) => t.copyWith(fontFamily: id));
                setState(() => _panel = _Panel.none);
              },
            ),
        ],
      ),
    );
  }

  Widget _swatches({
    required List<Color> colors,
    required void Function(Color) onPick,
    required VoidCallback? onClear,
    String clearLabel = '',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final c in colors)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  onPick(c);
                  setState(() => _panel = _Panel.none);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                ),
              ),
          ],
        ),
        if (onClear != null)
          TextButton.icon(
            onPressed: () {
              onClear();
              setState(() => _panel = _Panel.none);
            },
            icon: const Icon(Icons.format_color_reset, size: 18),
            label: Text(clearLabel),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Enlace a página
  // -------------------------------------------------------------------------

  /// Selector de página para convertir la caja en un enlace interno.
  void _showLinkPicker(TextItem item) {
    final pages = _c.pages;
    showModalBottomSheet<void>(
      context: context,
      // Misma región que el campo: tocar la hoja no debe cerrar la edición.
      builder: (context) => TextFieldTapRegion(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.l10n.textEditLink, style: context.text.titleMedium),
              ),
              if (item.linkToPageId != null)
                ListTile(
                  leading: Icon(Icons.link_off, color: context.inklus.danger),
                  title: Text(context.l10n.textEditUnlink),
                  onTap: () {
                    Navigator.pop(context);
                    _push(item.copyWith(clearLink: true));
                  },
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final linked = item.linkToPageId == page.id;
                    return ListTile(
                      leading: Icon(linked ? Icons.link : Icons.description_outlined),
                      title: Text(page.name),
                      subtitle: Text(context.l10n.commonPageN(index + 1)),
                      selected: linked,
                      onTap: () {
                        Navigator.pop(context);
                        _push(item.copyWith(linkToPageId: page.id));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asa redonda que se arrastra (mover / ensanchar la caja).
class _Handle extends StatelessWidget {
  const _Handle({required this.icon, required this.tooltip, required this.onDrag});

  final IconData icon;
  final String tooltip;
  final void Function(Offset delta) onDrag;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => onDrag(d.delta),
        // Zona táctil amplia (≥ 44 dp alrededor del círculo visible).
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: Icon(icon, size: 16, color: context.colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 24,
        child: VerticalDivider(width: Spacing.md, color: context.colors.outlineVariant),
      );
}
