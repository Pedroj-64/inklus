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
              const _SectionTitle('Tipo de pluma'),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final t in ToolVisuals.penTools)
                    ChoiceChip(
                      avatar: Icon(ToolVisuals.icon(t), size: 18),
                      label: Text(ToolVisuals.label(t)),
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
            const _SectionTitle('Color'),
            ColorGrid(canvas: canvas, presets: presets),
            const SizedBox(height: Spacing.lg),
            const _SectionTitle('Grosor'),
            SizePicker(canvas: canvas, onChanged: () => presets.syncFrom(canvas)),
            const SizedBox(height: Spacing.sm),
            const SizedBox(height: Spacing.sm),
            const _SectionTitle('Enderezar figuras'),
            SegmentedButton<ShapeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ShapeMode.off, label: Text('No')),
                ButtonSegment(value: ShapeMode.hold, label: Text('Al mantener')),
                ButtonSegment(value: ShapeMode.always, label: Text('Siempre')),
              ],
              selected: {canvas.shapeMode},
              onSelectionChanged: (v) => canvas.setShapeMode(v.first),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              switch (canvas.shapeMode) {
                ShapeMode.off => 'Los trazos quedan tal cual.',
                ShapeMode.hold =>
                  'Deja el lápiz quieto medio segundo al terminar una línea, círculo, triángulo o rectángulo.',
                ShapeMode.always => 'Toda figura reconocible se endereza al soltar.',
              },
              style: context.text.bodySmall,
            ),
            if (!isHighlighter)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.tune),
                  label: const Text('Ajustes avanzados del trazo'),
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
          const _SectionTitle('Modo'),
          SegmentedButton<EraserMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: EraserMode.partial,
                icon: Icon(Icons.content_cut),
                label: Text('Parcial'),
              ),
              ButtonSegment(
                value: EraserMode.stroke,
                icon: Icon(Icons.gesture),
                label: Text('Trazo'),
              ),
              ButtonSegment(
                value: EraserMode.highlighterOnly,
                icon: Icon(Icons.border_color),
                label: Text('Resaltador'),
              ),
            ],
            selected: {canvas.eraserMode},
            onSelectionChanged: (s) => canvas.setEraserMode(s.first),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            switch (canvas.eraserMode) {
              EraserMode.partial => 'Borra solo lo que tocas, como una goma.',
              EraserMode.stroke => 'Borra el trazo entero al tocarlo.',
              EraserMode.highlighterOnly => 'Solo borra resaltador; la tinta no se toca.',
            },
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Spacing.lg),
          const _SectionTitle('Tamaño'),
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
            const _SectionTitle('Color'),
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
          Text('Recientes', style: context.text.labelSmall),
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
      label: 'Color #${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
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
        message: 'Color personalizado',
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
