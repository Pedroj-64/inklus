// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../logic/pen_presets.dart';
import '../../models/stroke.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../widgets/controller_selector.dart';
import 'anchored_popover.dart';
import 'tool_popovers.dart';
import 'tool_visuals.dart';
import '../../l10n/l10n.dart';
import '../widgets/notebook_covers.dart';

/// Barra superior única del editor (sustituye al riel lateral y a la barra
/// inferior): deja todo el resto de la pantalla al lienzo.
///
/// ```
/// [←] Título · Pág. 2/5 | ✎ ✎ ✎  ▌  ⌫  ◌  T  🖼  📏  ⋯ | ↶ ↷  ▯ ☰  ☁ ⋮
/// ```
///
/// Tocar una herramienta la activa; tocarla **otra vez** abre sus opciones
/// en un popover anclado (color, grosor, modo…).
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.canvas,
    required this.presets,
    required this.onBack,
    required this.onEditTitle,
    required this.onInsertImage,
    required this.onTemplates,
    required this.onInsertSticker,
    required this.pagesOpen,
    required this.onTogglePages,
    required this.layersOpen,
    required this.onToggleLayers,
    required this.trailing,
  });

  final CanvasController canvas;
  final PenPresetsController presets;
  final VoidCallback onBack;
  final VoidCallback onEditTitle;
  final VoidCallback onInsertImage;
  final VoidCallback onTemplates;
  final VoidCallback onInsertSticker;
  final bool pagesOpen;
  final VoidCallback onTogglePages;
  final bool layersOpen;
  final VoidCallback onToggleLayers;

  /// Acciones de la derecha (nube, menú ⋮) que construye la pantalla.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < Breakpoints.expanded;
    return Material(
      color: context.inklus.toolbar,
      child: Container(
        height: Sizes.editorToolbar,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.inklus.toolbarBorder)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            canvas.toolContextNotifier,
            canvas.bottomBarContextNotifier,
            presets,
          ]),
          builder: (context, _) => Row(
            children: [
              IconButton(
                tooltip: context.l10n.tbBackToLibrary,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 140 : 260),
                child: _TitleButton(canvas: canvas, onTap: onEditTitle),
              ),
              const _Divider(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _tools(context)),
                ),
              ),
              const _Divider(),
              _UndoRedo(canvas: canvas),
              _ToolbarButton(
                icon: Icons.view_sidebar_outlined,
                label: pagesOpen ? context.l10n.tbHidePages : context.l10n.tbPages,
                selected: pagesOpen,
                onTap: onTogglePages,
              ),
              _ToolbarButton(
                icon: layersOpen ? Icons.layers : Icons.layers_outlined,
                label: layersOpen ? context.l10n.tbHideLayers : context.l10n.tbLayers,
                selected: layersOpen,
                onTap: onToggleLayers,
              ),
              ...trailing,
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _tools(BuildContext context) {
    final tool = canvas.tool;
    return [
      for (var i = 0; i < PenPresetsController.slotCount; i++)
        _penSlot(context, i, tool),
      _penSlot(context, PenPresetsController.highlighterSlot, tool),
      _toolWithOptions(
        context,
        ToolType.eraser,
        (c) => EraserPopover(canvas: canvas),
      ),
      _ToolbarButton(
        icon: ToolVisuals.icon(ToolType.lasso),
        label: ToolVisuals.label(context, ToolType.lasso),
        selected: tool == ToolType.lasso,
        onTap: () => canvas.setTool(ToolType.lasso),
      ),
      _toolWithOptions(
        context,
        ToolType.text,
        (c) => ColorPopover(canvas: canvas, presets: presets),
      ),
      _ToolbarButton(
        icon: Icons.add_photo_alternate_outlined,
        label: context.l10n.tbInsertImage,
        onTap: onInsertImage,
      ),
      _ToolbarButton(
        icon: canvas.rulerEnabled && canvas.rulerType == RulerType.protractor
            ? Icons.architecture
            : Icons.straighten,
        label: !canvas.rulerEnabled
            ? context.l10n.tbRuler
            : canvas.rulerType == RulerType.straight
                ? context.l10n.tbRulerNext
                : context.l10n.tbProtractorNext,
        selected: canvas.rulerEnabled,
        onTap: canvas.cycleRuler,
      ),
      _MoreToolsButton(
        canvas: canvas,
        presets: presets,
        onTemplates: onTemplates,
        onInsertSticker: onInsertSticker,
      ),
    ];
  }

  /// Ranura de pluma favorita / resaltador.
  Widget _penSlot(BuildContext context, int slot, ToolType currentTool) {
    final preset = presets.presetAt(slot);
    final showing = presets.isShowing(slot, currentTool);
    return Builder(
      builder: (anchor) => _ToolbarButton(
        icon: ToolVisuals.icon(preset.tool),
        label: slot == PenPresetsController.highlighterSlot
            ? context.l10n.popHighlighter
            : context.l10n.tbPenSlot(ToolVisuals.label(context, preset.tool), slot + 1),
        selected: showing,
        inkColor: preset.color,
        onTap: () {
          if (showing) {
            showAnchoredPopover<void>(
              context: context,
              anchorContext: anchor,
              builder: (_) => PenPopover(canvas: canvas, presets: presets),
            );
          } else {
            presets.activate(slot, canvas);
          }
        },
      ),
    );
  }

  /// Herramienta que, si ya está activa, abre su popover al tocarla.
  Widget _toolWithOptions(
    BuildContext context,
    ToolType type,
    WidgetBuilder popover,
  ) {
    final selected = canvas.tool == type;
    return Builder(
      builder: (anchor) => _ToolbarButton(
        icon: ToolVisuals.icon(type),
        label: ToolVisuals.label(context, type),
        selected: selected,
        onTap: () {
          if (selected) {
            showAnchoredPopover<void>(
              context: context,
              anchorContext: anchor,
              builder: popover,
            );
          } else {
            canvas.setTool(type);
          }
        },
      ),
    );
  }
}

/// "Más herramientas": mover, rellenar, lupa, plantillas.
class _MoreToolsButton extends StatelessWidget {
  const _MoreToolsButton({
    required this.canvas,
    required this.presets,
    required this.onTemplates,
    required this.onInsertSticker,
  });

  final CanvasController canvas;
  final PenPresetsController presets;
  final VoidCallback onTemplates;
  final VoidCallback onInsertSticker;

  @override
  Widget build(BuildContext context) {
    final extraSelected = canvas.tool == ToolType.select ||
        canvas.tool == ToolType.bucket ||
        canvas.laserMode ||
        canvas.magnifierEnabled;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(ToolVisuals.icon(ToolType.select)),
          onPressed: () => canvas.setTool(ToolType.select),
          child: Text(context.l10n.tbMoveSelect),
        ),
        MenuItemButton(
          leadingIcon: Icon(ToolVisuals.icon(ToolType.bucket)),
          onPressed: () => canvas.setTool(ToolType.bucket),
          child: Text(context.l10n.tbFill),
        ),
        MenuItemButton(
          leadingIcon: Icon(canvas.magnifierEnabled ? Icons.search_off : Icons.search),
          onPressed: canvas.toggleMagnifier,
          child: Text(canvas.magnifierEnabled ? context.l10n.tbHideMagnifier : context.l10n.tbMagnifier),
        ),
        MenuItemButton(
          leadingIcon: Icon(canvas.laserMode ? Icons.flashlight_off : Icons.flashlight_on),
          onPressed: canvas.toggleLaser,
          child: Text(canvas.laserMode ? context.l10n.tbLaserOff : context.l10n.tbLaser),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.emoji_emotions_outlined),
          onPressed: onInsertSticker,
          child: Text(context.l10n.tbInsertSticker),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.dashboard_customize_outlined),
          onPressed: onTemplates,
          child: Text(context.l10n.tbPageTemplate),
        ),
      ],
      builder: (context, menu, _) => _ToolbarButton(
        icon: Icons.more_horiz,
        label: context.l10n.tbMoreTools,
        selected: extraSelected,
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

class _TitleButton extends StatelessWidget {
  const _TitleButton({required this.canvas, required this.onTap});

  final CanvasController canvas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: Radii.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
          child: ControllerSelector<CanvasController, (String, int, int)>(
            listenable: canvas,
            selector: (c) => (c.note.title, c.pageIndex, c.pageCount),
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle(context.l10n, state.$1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                Text(
                  context.l10n.tbPageOf(state.$2 + 1, state.$3),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
}

class _UndoRedo extends StatelessWidget {
  const _UndoRedo({required this.canvas});

  final CanvasController canvas;

  @override
  Widget build(BuildContext context) =>
      ControllerSelector<CanvasController, (bool, bool)>(
        listenable: canvas,
        selector: (c) => (c.canUndo, c.canRedo),
        builder: (context, state) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.tbUndo,
              icon: const Icon(Icons.undo),
              onPressed: state.$1 ? canvas.undo : null,
            ),
            IconButton(
              tooltip: context.l10n.tbRedo,
              icon: const Icon(Icons.redo),
              onPressed: state.$2 ? canvas.redo : null,
            ),
          ],
        ),
      );
}

/// Botón de la barra: icono con fondo tonal cuando está activo y, para las
/// plumas, una barrita con el color de tinta.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.inkColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? inkColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxs),
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.mdAll,
            child: AnimatedContainer(
              duration: Motion.fast,
              width: Sizes.minTouch,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: Radii.mdAll,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: Sizes.toolIcon, color: fg),
                  if (inkColor != null)
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: inkColor,
                          borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                          border: Border.all(color: scheme.outlineVariant, width: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
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
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        color: context.colors.outlineVariant,
      );
}
