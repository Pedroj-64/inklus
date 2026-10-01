// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../logic/pen_presets.dart';
import '../../models/stroke.dart';
import '../../services/ocr_service.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../widgets/controller_selector.dart';
import '../widgets/dialogs.dart';
import 'anchored_popover.dart';
import 'tool_popovers.dart';
import '../../l10n/l10n.dart';

/// Barra flotante de acciones para la selección del lazo (o para pegar).
///
/// Aparece arriba del lienzo solo cuando hay algo que hacer, en lugar de
/// ocupar una barra fija. Acciones: copiar, duplicar, color, grosor,
/// convertir a texto (Android/iOS) y eliminar.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.canvas,
    required this.presets,
    required this.onMessage,
  });

  final CanvasController canvas;
  final PenPresetsController presets;
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context) {
    return ControllerSelector<CanvasController, (int, int, bool, ToolType)>(
      listenable: canvas,
      selector: (c) =>
          (c.selectionCount, c.selectedStrokes.length, c.hasClipboard, c.tool),
      builder: (context, state) {
        final (count, strokeCount, hasClipboard, tool) = state;
        final pasteOnly =
            count == 0 &&
            hasClipboard &&
            (tool == ToolType.lasso || tool == ToolType.select);
        final visible = count > 0 || pasteOnly;
        return AnimatedSwitcher(
          duration: Motion.normal,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SizeTransition(sizeFactor: a, child: child),
          ),
          child: !visible
              ? const SizedBox.shrink()
              : Material(
                  key: ValueKey(pasteOnly),
                  color: context.colors.surfaceContainerHigh,
                  elevation: 6,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(Radii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: pasteOnly
                          ? [
                              _Action(
                                icon: Icons.content_paste,
                                label: context.l10n.selPaste,
                                onTap: canvas.pasteStrokes,
                              ),
                            ]
                          : _selectionActions(context, count, strokeCount > 0),
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// [hasStrokes]: color, grosor y convertir a texto solo aplican a trazos;
  /// copiar, duplicar, mover, escalar/rotar y eliminar, a toda la selección.
  List<Widget> _selectionActions(
    BuildContext context,
    int count,
    bool hasStrokes,
  ) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Text('$count', style: context.text.labelLarge),
    ),
    _Action(
      icon: Icons.copy,
      label: context.l10n.selCopy,
      onTap: () {
        canvas.copySelectedStrokes();
        onMessage(context.l10n.selCopied);
      },
    ),
    _Action(
      icon: Icons.copy_all_outlined,
      label: context.l10n.libDuplicate,
      onTap: canvas.duplicateSelectedStrokes,
    ),
    if (hasStrokes) ...[
      Builder(
        builder: (anchor) => _Action(
          icon: Icons.palette_outlined,
          label: context.l10n.createColor,
          onTap: () => showAnchoredPopover<void>(
            context: context,
            anchorContext: anchor,
            builder: (_) => ColorGrid(
              canvas: canvas,
              presets: presets,
              onPick: canvas.recolorSelection,
            ),
          ),
        ),
      ),
      _Action(
        icon: Icons.line_weight,
        label: context.l10n.selThinner,
        onTap: () => canvas.scaleSelectionThickness(0.8),
        iconSize: 16,
      ),
      _Action(
        icon: Icons.line_weight,
        label: context.l10n.selThicker,
        onTap: () => canvas.scaleSelectionThickness(1.25),
      ),
      if (OcrService.isSupported)
        _Action(
          icon: Icons.title,
          label: context.l10n.selToText,
          onTap: () => _convertToText(context),
        ),
    ],
    _Action(
      icon: Icons.delete_outline,
      label: context.l10n.libDelete,
      color: context.inklus.danger,
      onTap: canvas.deleteSelectedStrokes,
    ),
    _Action(
      icon: Icons.close,
      label: context.l10n.selDeselect,
      onTap: canvas.clearLassoSelection,
    ),
  ];

  Future<void> _convertToText(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final result = await OcrService.recognizeStrokes(
        canvas.selectedStrokes,
        sheetSize: canvas.sheetSize,
      );
      if (!context.mounted) return;
      if (result.isEmpty) {
        onMessage(context.l10n.selNoText);
        return;
      }
      // Permitir corregir antes de sustituir la escritura.
      final text = await showTextPrompt(
        context,
        title: context.l10n.selToText,
        initialValue: result.text,
        confirmLabel: context.l10n.selConvert,
        multiline: true,
      );
      if (text != null) canvas.convertSelectionToText(text);
    } catch (e) {
      onMessage(l10n.selRecognizeFailed('$e'));
    }
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.iconSize = 22,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onTap,
    icon: Icon(icon, size: iconSize, color: color ?? context.colors.onSurface),
  );
}
