import '../../constants.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';

import '../../logic/canvas_controller.dart';
import '../../models/page.dart';
import '../../services/export_service.dart';
import '../../services/image_service.dart';

/// Franja horizontal de miniaturas de páginas en la parte inferior del editor.
///
/// Muestra una miniatura renderizada de cada página, permite navegar entre
/// ellas, duplicar, eliminar y reordenar con drag & drop.
class PageThumbnailsStrip extends StatefulWidget {
  final CanvasController controller;
  final ImageService imageService;
  final VoidCallback? onToggle;

  const PageThumbnailsStrip({
    super.key,
    required this.controller,
    required this.imageService,
    this.onToggle,
  });

  @override
  State<PageThumbnailsStrip> createState() => _PageThumbnailsStripState();
}

class _PageThumbnailsStripState extends State<PageThumbnailsStrip> {
  /// Cache de miniaturas por id de página.
  final Map<String, Future<Uint8List>> _thumbs = {};

  final ScrollController _scrollController = ScrollController();

  CanvasController get _c => widget.controller;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Renderiza la miniatura de una página concreta.
  Future<Uint8List> _renderThumb(Page page) async {
    for (final item in page.images) {
      await widget.imageService.ensureCached(item.localPath);
    }
    final templatePath = page.template.imagePath;
    if (templatePath != null) {
      await widget.imageService.ensureCached(templatePath);
    }
    return ExportService.renderPagePng(
      page,
      sheetSize: page.template.sheetSize,
      imageCache: widget.imageService.cache,
      options: const ExportOptions(maxDimension: 240),
    );
  }

  Future<Uint8List> _thumbFor(Page page) {
    return _thumbs.putIfAbsent(page.id, () => _renderThumb(page));
  }

  /// Invalida la caché de miniaturas y fuerza rebuild de la página actual.
  void _invalidateThumb(Page page) {
    _thumbs.remove(page.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final pages = _c.pages;
        final current = _c.pageIndex;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 110,
          color: isDark ? kSurfaceDark : Colors.white,
          child: Row(
            children: [
              // Botón colapsar
              GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  width: 28,
                  margin: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.keyboard_arrow_down, size: 18,
                      color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
              // Botón duplicar página
              _ActionChip(
                icon: Icons.copy_outlined,
                tooltip: 'Duplicar página',
                onPressed: () {
                  _c.duplicatePage();
                  _invalidateThumb(_c.page);
                  _scrollToCurrent();
                },
              ),
              // Lista de miniaturas reordenables
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        final t = animation.value;
                        return Transform.scale(
                          scale: 1.0 + 0.05 * (1.0 - t),
                          child: Opacity(
                            opacity: 0.5 + 0.5 * t,
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  // ignore: deprecated_member_use (onReorderItem no existe aún)
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.mediumImpact();
                    _c.reorderPage(oldIndex, newIndex);
                    // Invalidar todas las miniaturas tras reordenar.
                    _thumbs.clear();
                    if (mounted) setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isCurrent = index == current;
                    return GestureDetector(
                      key: ValueKey(page.id),
                      onTap: () => _c.goToPage(index),
                      child: _PageThumb(
                        page: page,
                        index: index,
                        isCurrent: isCurrent,
                        thumb: _thumbFor(page),
                        onDelete: pages.length > 1
                            ? () => _deletePage(index)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              // Botón nueva página
              _ActionChip(
                icon: Icons.add,
                tooltip: 'Nueva página',
                onPressed: () {
                  _c.addPage();
                  _scrollToCurrent();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = (_c.pageIndex * 92.0).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deletePage(int index) async {
    if (_c.pages.length <= 1) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar página'),
        content: Text(
          'Se eliminará la página ${index + 1} con todo su contenido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final targetIndex = index < _c.pageIndex
          ? index
          : (index == _c.pageIndex ? index : index);
      _c.goToPage(targetIndex);
      _c.deleteCurrentPage();
      _thumbs.clear();
      if (mounted) setState(() {});
    }
  }
}

/// Miniatura de una página individual con número e indicador de selección.
class _PageThumb extends StatelessWidget {
  final Page page;
  final int index;
  final bool isCurrent;
  final Future<Uint8List> thumb;
  final VoidCallback? onDelete;

  const _PageThumb({
    required this.page,
    required this.index,
    required this.isCurrent,
    required this.thumb,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCurrent
                        ? kAccentColor
                        : Colors.black12,
                    width: isCurrent ? 2.5 : 1,
                  ),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF333333)
                      : const Color(0xFFF1F0EC),
                  boxShadow: [
                    if (isCurrent)
                      BoxShadow(
                        color: kAccentColor.withAlpha(40),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: FutureBuilder<Uint8List>(
                    future: thumb,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        );
                      }
                      if (snapshot.hasError) {
                        return Icon(
                          Icons.broken_image_outlined,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                          size: 24,
                        );
                      }
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Número de página
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? kAccentColor
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // Botón eliminar (esquina superior derecha)
              if (onDelete != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón de acción pequeño para la franja de miniaturas.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
        ),
      ),
    );
  }
}
