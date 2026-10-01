// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Page;

import '../../logic/canvas_controller.dart';
import '../../models/page.dart';
import '../../services/export_service.dart';
import '../../services/image_service.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../../l10n/l10n.dart';

/// Panel lateral con las páginas de la nota (vertical, como GoodNotes).
///
/// - Tocar una miniatura abre la página; arrastrar la reordena.
/// - Menú por página: duplicar / eliminar (eliminar se puede deshacer).
/// - La miniatura de la página actual se regenera con un pequeño retraso
///   tras editar (no en cada trazo).
class PagesPanel extends StatefulWidget {
  const PagesPanel({
    super.key,
    required this.canvas,
    required this.imageService,
    required this.onClose,
  });

  final CanvasController canvas;
  final ImageService imageService;
  final VoidCallback onClose;

  @override
  State<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends State<PagesPanel> {
  /// Miniatura por página, con la versión de contenido con la que se hizo.
  final Map<String, ({int version, Future<Uint8List> png})> _thumbs = {};
  Timer? _refresh;
  int _seenVersion = -1;

  /// Mostrar solo las páginas marcadas.
  bool _onlyBookmarked = false;

  CanvasController get _c => widget.canvas;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onCanvasChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onCanvasChanged);
    _refresh?.cancel();
    super.dispose();
  }

  void _onCanvasChanged() {
    if (_c.contentVersion == _seenVersion) {
      // Cambio de página/selección: solo repintar la lista.
      if (mounted) setState(() {});
      return;
    }
    _seenVersion = _c.contentVersion;
    _refresh?.cancel();
    _refresh = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      // Solo la página actual cambia al escribir.
      _thumbs.remove(_c.page.id);
      setState(() {});
    });
  }

  Future<Uint8List> _render(Page page) async {
    for (final item in page.images) {
      await widget.imageService.ensureCached(item.localPath);
    }
    final tpl = page.template.imagePath;
    if (tpl != null) await widget.imageService.ensureCached(tpl);
    return ExportService.renderPagePng(
      page,
      sheetSize: page.template.sheetSize,
      imageCache: widget.imageService.cache,
      options: const ExportOptions(maxDimension: 320),
    );
  }

  Future<Uint8List> _thumbFor(Page page) {
    final cached = _thumbs[page.id];
    if (cached != null) return cached.png;
    final png = _render(page);
    _thumbs[page.id] = (version: _c.contentVersion, png: png);
    return png;
  }

  Future<void> _pageMenu(BuildContext context, int index, Offset position) async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'bookmark',
          child: Text(_c.pages[index].bookmarked ? context.l10n.pgUnbookmark : context.l10n.pgBookmark),
        ),
        PopupMenuItem(value: 'duplicate', child: Text(context.l10n.pgDuplicate)),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.pgDelete)),
      ],
    );
    if (choice == null) return;
    _c.goToPage(index);
    switch (choice) {
      case 'bookmark':
        _c.toggleBookmark();
      case 'duplicate':
        _c.duplicatePage();
      case 'delete':
        _c.deleteCurrentPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _c.pages;
    final scheme = context.colors;
    return Container(
      width: Sizes.pagesPanel,
      decoration: BoxDecoration(
        color: context.inklus.toolbar,
        border: Border(left: BorderSide(color: context.inklus.toolbarBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.xs, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(context.l10n.pgPagesCount(pages.length), style: context.text.titleSmall),
                ),
                IconButton(
                  tooltip: _onlyBookmarked ? context.l10n.pgShowAll : context.l10n.pgOnlyBookmarked,
                  isSelected: _onlyBookmarked,
                  icon: const Icon(Icons.bookmark_border),
                  selectedIcon: const Icon(Icons.bookmark),
                  onPressed: () => setState(() => _onlyBookmarked = !_onlyBookmarked),
                ),
                IconButton(
                  tooltip: context.l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              buildDefaultDragHandles: false,
              itemCount: pages.length,
              // onReorderItem ya ajusta el índice destino tras quitar el origen.
              onReorderItem: _c.reorderPage,
              itemBuilder: (context, i) {
                final page = pages[i];
                final selected = i == _c.pageIndex;
                if (_onlyBookmarked && !page.bookmarked) {
                  return SizedBox.shrink(key: ValueKey(page.id));
                }
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(page.id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: GestureDetector(
                      onTap: () => _c.goToPage(i),
                      onSecondaryTapDown: (d) => _pageMenu(context, i, d.globalPosition),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: page.template.isFinite
                                ? page.template.sheetSize.aspectRatio
                                : 0.75,
                            child: AnimatedContainer(
                              duration: Motion.fast,
                              decoration: BoxDecoration(
                                color: context.inklus.paper,
                                borderRadius: Radii.smAll,
                                border: Border.all(
                                  color: selected ? scheme.primary : scheme.outlineVariant,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FutureBuilder<Uint8List>(
                                future: _thumbFor(page),
                                builder: (context, snap) => snap.hasData
                                    ? Image.memory(snap.data!, fit: BoxFit.contain, gaplessPlayback: true)
                                    : const SizedBox.expand(),
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (page.bookmarked)
                                Icon(Icons.bookmark, size: 14, color: scheme.primary),
                              Text('${i + 1}',
                                  style: context.text.labelMedium?.copyWith(
                                    color: selected ? scheme.primary : null,
                                  )),
                              Builder(
                                builder: (btn) => IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: context.l10n.pgOptions,
                                  icon: const Icon(Icons.more_horiz, size: 18),
                                  onPressed: () {
                                    final box = btn.findRenderObject() as RenderBox;
                                    _pageMenu(context, i, box.localToGlobal(Offset.zero));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: Text(context.l10n.pgNew),
                onPressed: _c.addPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
