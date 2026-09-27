// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../services/marketplace/marketplace_models.dart';
import '../services/marketplace/marketplace_service.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';

/// Marketplace: paquetes gratuitos de la comunidad (plantillas, paletas y
/// stickers). Todo el contenido es libre (licencias CC) y se verifica antes
/// de instalarse.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, this.service});

  /// Para tests; por defecto la instancia compartida.
  final MarketplaceService? service;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final MarketplaceService _service = widget.service ?? MarketplaceService.instance;
  bool _loading = true;
  PackType? _filter;
  String _query = '';
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _service.loadCatalog().whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _toggleInstall(MarketplacePack pack) async {
    setState(() => _busy.add(pack.id));
    try {
      if (_service.isInstalled(pack.id)) {
        await _service.uninstall(pack.id);
        _snack('«${pack.name}» desinstalado');
      } else {
        await _service.install(pack);
        _snack('«${pack.name}» instalado: ${_whereToFind(pack.type)}');
      }
    } catch (e) {
      _snack('No se pudo instalar «${pack.name}»: $e');
    } finally {
      if (mounted) setState(() => _busy.remove(pack.id));
    }
  }

  String _whereToFind(PackType t) => switch (t) {
        PackType.template => 'en Plantilla de la página',
        PackType.palette => 'en los colores de cada pluma',
        PackType.stickers => 'en Más herramientas → Insertar sticker',
      };

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final packs = _service.catalog
        .where((p) => _filter == null || p.type == _filter)
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.sm, Spacing.xl, Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plantillas, paletas y stickers creados por la comunidad. '
                      'Todo es gratis y de licencia libre.',
                      style: context.text.bodyMedium,
                    ),
                    if (!_loading && _service.source != CatalogSource.network)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.md),
                        child: Material(
                          color: context.colors.secondaryContainer,
                          borderRadius: Radii.mdAll,
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off),
                            title: Text(_service.source == CatalogSource.cache
                                ? 'Sin conexión: mostrando el último catálogo descargado'
                                : 'Sin conexión: mostrando los paquetes incluidos en la app'),
                          ),
                        ),
                      ),
                    const SizedBox(height: Spacing.md),
                    SearchBar(
                      hintText: 'Buscar paquetes',
                      leading: const Icon(Icons.search),
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(context.colors.surfaceContainerHigh),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: Spacing.md),
                    Wrap(
                      spacing: Spacing.sm,
                      children: [
                        for (final (label, type) in [
                          ('Todo', null),
                          ('Plantillas', PackType.template),
                          ('Paletas', PackType.palette),
                          ('Stickers', PackType.stickers),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _filter == type,
                            onSelected: (_) => setState(() => _filter = type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (packs.isEmpty)
              const SliverFillRemaining(child: Center(child: Text('No hay paquetes que coincidan')))
            else
              SliverPadding(
                padding: const EdgeInsets.all(Spacing.xl),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 250,
                    crossAxisSpacing: Spacing.lg,
                    mainAxisSpacing: Spacing.lg,
                  ),
                  itemCount: packs.length,
                  itemBuilder: (_, i) {
                    final pack = packs[i];
                    return _PackCard(
                      pack: pack,
                      baseUrl: _service.baseUrl,
                      installed: _service.isInstalled(pack.id),
                      busy: _busy.contains(pack.id),
                      onToggle: () => _toggleInstall(pack),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.baseUrl,
    required this.installed,
    required this.busy,
    required this.onToggle,
  });

  final MarketplacePack pack;
  final String baseUrl;
  final bool installed;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 90, width: double.infinity, child: _preview(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 0),
            child: Row(
              children: [
                Icon(switch (pack.type) {
                  PackType.template => Icons.dashboard_customize_outlined,
                  PackType.palette => Icons.palette_outlined,
                  PackType.stickers => Icons.emoji_emotions_outlined,
                }, size: 18, color: context.colors.primary),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(pack.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
            child: Text(pack.description,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.sm, Spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text('${pack.author} · ${pack.license}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
                ),
                busy
                    ? const SizedBox.square(
                        dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : installed
                        ? OutlinedButton(onPressed: onToggle, child: const Text('Quitar'))
                        : FilledButton.tonal(onPressed: onToggle, child: const Text('Instalar')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vista previa: imagen del paquete, o una generada (colores / icono).
  Widget _preview(BuildContext context) {
    if (pack.preview != null) {
      return Image.network(
        '$baseUrl${pack.preview}',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(context),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    if (pack.palette.isNotEmpty) {
      return Row(
        children: [
          for (final c in pack.palette)
            Expanded(child: ColoredBox(color: c, child: const SizedBox.expand())),
        ],
      );
    }
    return ColoredBox(
      color: context.inklus.paper,
      child: CustomPaint(painter: _LinesPreview(color: context.colors.primary.withValues(alpha: 0.35))),
    );
  }
}

/// Rayado genérico para la vista previa de paquetes de plantillas.
class _LinesPreview extends CustomPainter {
  _LinesPreview({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 14.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LinesPreview old) => old.color != color;
}
