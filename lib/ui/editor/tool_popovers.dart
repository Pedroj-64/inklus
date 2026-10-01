// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../logic/pen_presets.dart';
import '../../models/stroke.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../widgets/custom_color_dialog.dart';
import '../widgets/stroke_options_sheet.dart';
import 'tool_visuals.dart';
import '../../services/marketplace/marketplace_service.dart';
import '../../l10n/l10n.dart';

/// Opciones de una pluma favorita o del resaltador: tipo de pluma, color,
/// grosor y ajustes. Los cambios se aplican al momento y se guardan en la
/// pluma activa (vía [PenPresetsController.syncFrom]).
class PenPopover extends StatelessWidget {
  const PenPopover({super.key, required this.canvas, required this.presets});

  final CanvasController canvas;
  final PenPresetsController presets;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([canvas, presets]),
      builder: (context, _) {
        final isHighlighter = canvas.tool == ToolType.highlighter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHighlighter) ...[
              _SectionTitle(context.l10n.popPenType),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final t in ToolVisuals.penTools)
                    ChoiceChip(
                      avatar: Icon(ToolVisuals.icon(t), size: 18),
                      label: Text(ToolVisuals.label(context, t)),
                      selected: canvas.tool == t,
                      onSelected: (_) {
                        canvas.setTool(t);
                        presets.syncFrom(canvas);
                      },
                    ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
            ],
            _SectionTitle(context.l10n.createColor),
            ColorGrid(canvas: canvas, presets: presets),
            const SizedBox(height: Spacing.lg),
            _SectionTitle(context.l10n.popThickness),
            SizePicker(canvas: canvas, onChanged: () => presets.syncFrom(canvas)),
            SizedBox(height: Spacing.sm),
            SizedBox(height: Spacing.sm),
            _SectionTitle(context.l10n.popStraighten),
            SegmentedButton<ShapeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ShapeMode.off, label: Text(context.l10n.popNo)),
                ButtonSegment(value: ShapeMode.hold, label: Text(context.l10n.popOnHold)),
                ButtonSegment(value: ShapeMode.always, label: Text(context.l10n.popAlways)),
              ],
              selected: {canvas.shapeMode},
              onSelectionChanged: (v) => canvas.setShapeMode(v.first),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              switch (canvas.shapeMode) {
                ShapeMode.off => context.l10n.popShapeOffHint,
                ShapeMode.hold =>
                  context.l10n.popShapeHoldHint,
                ShapeMode.always => context.l10n.popShapeAlwaysHint,
              },
              style: context.text.bodySmall,
            ),
            if (!isHighlighter)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(Icons.tune),
                  label: Text(context.l10n.popAdvanced),
                  onPressed: () {
                    Navigator.pop(context);
                    showStrokeOptionsSheet(context, controller: canvas);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Opciones del borrador: modo y tamaño.
class EraserPopover extends StatelessWidget {
  const EraserPopover({super.key, required this.canvas});

  final CanvasController canvas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: canvas,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(context.l10n.popMode),
          SegmentedButton<EraserMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: EraserMode.partial,
                icon: Icon(Icons.content_cut),
                label: Text(context.l10n.popPartial),
              ),
              ButtonSegment(
                value: EraserMode.stroke,
                icon: Icon(Icons.gesture),
                label: Text(context.l10n.popStroke),
              ),
              ButtonSegment(
                value: EraserMode.highlighterOnly,
                icon: Icon(Icons.border_color),
                label: Text(context.l10n.popHighlighter),
              ),
            ],
            selected: {canvas.eraserMode},
            onSelectionChanged: (s) => canvas.setEraserMode(s.first),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            switch (canvas.eraserMode) {
              EraserMode.partial => context.l10n.popEraseOff,
              EraserMode.stroke => context.l10n.popEraseStroke,
              EraserMode.highlighterOnly => context.l10n.popEraseHighlighter,
            },
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Spacing.lg),
          _SectionTitle(context.l10n.popSize),
          SizePicker(canvas: canvas),
        ],
      ),
    );
  }
}

/// Solo color (texto, rellenar).
class ColorPopover extends StatelessWidget {
  const ColorPopover({super.key, required this.canvas, required this.presets});

  final CanvasController canvas;
  final PenPresetsController presets;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: canvas,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionTitle(context.l10n.createColor),
            ColorGrid(canvas: canvas, presets: presets),
          ],
        ),
      );
}

/// Rejilla de colores: paleta fija, recientes y selector personalizado.
class ColorGrid extends StatelessWidget {
  const ColorGrid({super.key, required this.canvas, required this.presets, this.onPick});

  final CanvasController canvas;
  final PenPresetsController presets;

  /// Si se indica, se llama en vez de cambiar el color del lienzo (p. ej.
  /// para recolorear una selección).
  final ValueChanged<Color>? onPick;

  void _pick(Color c) {
    presets.addRecentColor(c);
    if (onPick != null) {
      onPick!(c);
    } else {
      canvas.setColor(c);
      presets.syncFrom(canvas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = presets.recentColors
        .where((c) => !kDefaultPalette.contains(c))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            for (final c in kDefaultPalette)
              ColorSwatchButton(
                color: c,
                selected: onPick == null && canvas.color == c,
                onTap: () => _pick(c),
              ),
            _CustomColorButton(onTap: () async {
              await showCustomColorDialog(context, canvas);
              presets.addRecentColor(canvas.color);
              if (onPick != null) {
                onPick!(canvas.color);
              } else {
                presets.syncFrom(canvas);
              }
            }),
          ],
        ),
        // Paletas instaladas desde el marketplace.
        FutureBuilder<List<({String name, List<Color> colors})>>(
          future: MarketplaceService.instance.installedPalettes(),
          builder: (context, snap) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final palette in snap.data ?? const <({String name, List<Color> colors})>[]) ...[
                const SizedBox(height: Spacing.sm),
                Text(palette.name, style: context.text.labelSmall),
                const SizedBox(height: Spacing.xs),
                Wrap(
                  spacing: Spacing.xs,
                  children: [
                    for (final c in palette.colors)
                      ColorSwatchButton(
                        color: c,
                        selected: onPick == null && canvas.color == c,
                        onTap: () => _pick(c),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(context.l10n.libNavRecent, style: context.text.labelSmall),
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.xs,
            children: [
              for (final c in recent)
                ColorSwatchButton(
                  color: c,
                  selected: onPick == null && canvas.color == c,
                  onTap: () => _pick(c),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Muestra de color circular con área táctil de 48 dp.
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    // Check en blanco o negro según la luminancia del color.
    final checkColor =
        color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.colorSemantics(color.toARGB32().toRadixString(16).substring(2).toUpperCase()),
      child: InkResponse(
        onTap: onTap,
        radius: Sizes.minTouch / 2,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: AnimatedContainer(
              duration: Motion.fast,
              width: Sizes.swatch,
              height: Sizes.swatch,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected ? Icon(Icons.check, size: 18, color: checkColor) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomColorButton extends StatelessWidget {
  const _CustomColorButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.l10n.colorCustomTitle,
        child: InkResponse(
          onTap: onTap,
          radius: Sizes.minTouch / 2,
          child: SizedBox.square(
            dimension: 40,
            child: Center(
              child: Container(
                width: Sizes.swatch,
                height: Sizes.swatch,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outlineVariant),
                  gradient: const SweepGradient(colors: [
                    Colors.red, Colors.yellow, Colors.green, Colors.cyan,
                    Colors.blue, Colors.purple, Colors.red,
                  ]),
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      );
}

/// Grosor: tres tamaños rápidos + slider fino, con vista previa real.
class SizePicker extends StatelessWidget {
  const SizePicker({super.key, required this.canvas, this.onChanged});

  final CanvasController canvas;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final (min, max) = canvas.sizeRange;
    final quick = [0.12, 0.3, 0.6].map((f) => min + (max - min) * f).toList();
    final isEraser = canvas.tool == ToolType.eraser;
    final dotColor = isEraser ? context.colors.outline : canvas.color;
    void set(double v) {
      canvas.setToolSize(v);
      onChanged?.call();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final q in quick)
              _SizeDot(
                size: q,
                color: dotColor,
                selected: (canvas.toolSize - q).abs() < (max - min) * 0.04,
                onTap: () => set(q),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: canvas.toolSize.clamp(min, max),
                min: min,
                max: max,
                label: canvas.toolSize.toStringAsFixed(1),
                onChanged: set,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                canvas.toolSize.toStringAsFixed(canvas.toolSize < 10 ? 1 : 0),
                textAlign: TextAlign.end,
                style: context.text.labelMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SizeDot extends StatelessWidget {
  const _SizeDot({required this.size, required this.color, required this.selected, required this.onTap});

  final double size;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = size.clamp(4.0, 30.0);
    return InkResponse(
      onTap: onTap,
      radius: Sizes.minTouch / 2,
      child: Container(
        width: Sizes.minTouch,
        height: Sizes.minTouch,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? context.colors.primaryContainer : null,
        ),
        alignment: Alignment.center,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(text, style: context.text.titleSmall),
      );
}
