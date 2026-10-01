// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../models/template.dart';
import '../services/marketplace/marketplace_models.dart';
import '../services/marketplace/marketplace_service.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import '../l10n/l10n.dart';

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
    final l10n = context.l10n;
    try {
      if (_service.isInstalled(pack.id)) {
        await _service.uninstall(pack.id);
        _snack(l10n.marketUninstalled(_packName(l10n, pack)));
      } else {
        await _service.install(pack);
        _snack(l10n.marketInstalled(_packName(l10n, pack), _whereToFind(pack.type)));
      }
    } catch (e) {
      _snack(l10n.marketInstallFailed(_packName(l10n, pack), '$e'));
    } finally {
      if (mounted) setState(() => _busy.remove(pack.id));
    }
  }

  String _whereToFind(PackType t) => switch (t) {
        PackType.template => context.l10n.marketWhereTemplate,
        PackType.palette => context.l10n.marketWherePalette,
        PackType.stickers => context.l10n.marketWhereStickers,
      };

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  /// Cabecera con degradado de marca y el buscador integrado.
  Widget _hero(BuildContext context) {
    final scheme = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.sm, Spacing.xl, 0),
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        borderRadius: Radii.xlAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, Color.lerp(scheme.primary, scheme.onSurface, 0.4)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, color: scheme.onPrimary, size: 28),
              const SizedBox(width: Spacing.md),
              Text(context.l10n.marketHeroTitle,
                  style: context.text.headlineSmall?.copyWith(
                      color: scheme.onPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            context.l10n.marketHeroSubtitle,
            style: context.text.bodyMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: Spacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SearchBar(
              hintText: context.l10n.marketSearch,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surface),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: Text(context.l10n.marketTitle)),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.lg, Spacing.xl, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_loading && _service.source != CatalogSource.network)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off, size: 16, color: context.colors.onSurfaceVariant),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                _service.source == CatalogSource.cache
                                    ? context.l10n.marketOfflineCache
                                    : context.l10n.marketOfflineBundled,
                                style: context.text.labelMedium
                                    ?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final (label, icon, type) in [
                          (context.l10n.marketAll, Icons.apps, null),
                          (context.l10n.marketTemplates, Icons.dashboard_customize_outlined, PackType.template),
                          (context.l10n.marketPalettes, Icons.palette_outlined, PackType.palette),
                          (context.l10n.marketStickers, Icons.emoji_emotions_outlined, PackType.stickers),
                        ])
                          ChoiceChip(
                            avatar: Icon(icon, size: 18),
                            label: Text(
                                '$label · ${_service.catalog.where((p) => type == null || p.type == type).length}'),
                            selected: _filter == type,
                            showCheckmark: false,
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
              SliverFillRemaining(child: Center(child: Text(context.l10n.marketNoResults)))
            else
              SliverPadding(
                padding: const EdgeInsets.all(Spacing.xl),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 292,
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

/// Nombre/descripción traducidos de los paquetes incluidos en la app; los del
/// catálogo remoto se muestran tal como se publicaron.
String _packName(AppLocalizations l10n, MarketplacePack p) => switch (p.id) {
      'cuadernos-clasicos' => l10n.packClassicName,
      'papel-tecnico' => l10n.packTechName,
      'paleta-estudio' => l10n.packStudyName,
      'paleta-pastel' => l10n.packPastelName,
      'paleta-tierra' => l10n.packEarthName,
      _ => p.name,
    };

String _packDescription(AppLocalizations l10n, MarketplacePack p) => switch (p.id) {
      'cuadernos-clasicos' => l10n.packClassicDesc,
      'papel-tecnico' => l10n.packTechDesc,
      'paleta-estudio' => l10n.packStudyDesc,
      'paleta-pastel' => l10n.packPastelDesc,
      'paleta-tierra' => l10n.packEarthDesc,
      _ => p.description,
    };

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

  (IconData, String) _typeInfo(BuildContext context, PackType t) => switch (t) {
        PackType.template => (Icons.dashboard_customize_outlined, context.l10n.marketTemplates),
        PackType.palette => (Icons.palette_outlined, context.l10n.marketPalette),
        PackType.stickers => (Icons.emoji_emotions_outlined, context.l10n.marketStickers),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, typeLabel) = _typeInfo(context, pack.type);
    final scheme = context.colors;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: installed ? scheme.primary : scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _preview(context),
                Positioned(
                  left: Spacing.sm,
                  top: Spacing.sm,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 14, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(typeLabel, style: context.text.labelSmall),
                      ]),
                    ),
                  ),
                ),
                if (installed)
                  Positioned(
                    right: Spacing.sm,
                    top: Spacing.sm,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.primary,
                      child: Icon(Icons.check, size: 16, color: scheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
            child: Text(_packName(context.l10n, pack),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
            child: Text(_packDescription(context.l10n, pack),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text('${pack.author} · ${pack.license}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelSmall),
                ),
                const SizedBox(width: Spacing.sm),
                busy
                    ? const SizedBox.square(
                        dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : installed
                        ? OutlinedButton(onPressed: onToggle, child: Text(context.l10n.marketRemove))
                        : FilledButton.icon(
                            onPressed: onToggle,
                            icon: const Icon(Icons.download, size: 18),
                            label: Text(context.l10n.marketInstall),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vista previa: imagen del paquete, o una generada (plantilla real /
  /// colores / icono).
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
    final t = pack.templates.map((t) => t.toPageTemplate()).whereType<PageTemplate>().firstOrNull;
    if (t != null) {
      return ColoredBox(
        color: context.inklus.paper,
        child: CustomPaint(painter: _TemplatePreview(t)),
      );
    }
    return ColoredBox(
      color: context.colors.secondaryContainer,
      child: Center(
        child: Icon(Icons.emoji_emotions_outlined,
            size: 48, color: context.colors.onSecondaryContainer),
      ),
    );
  }
}

/// Vista previa de una plantilla con su tipo y color de línea reales.
class _TemplatePreview extends CustomPainter {
  _TemplatePreview(this.t);

  final PageTemplate t;

  @override
  void paint(Canvas canvas, Size size) {
    final color = Color(t.lineColorValue);
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    // El espaciado real (≈50) se reduce para que se vea el patrón entero.
    final gap = (t.spacing / 3.4).clamp(9.0, 26.0);
    switch (t.type) {
      case TemplateType.grid:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = gap; x < size.width; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
      case TemplateType.dots:
        final dot = Paint()..color = color;
        for (var y = gap; y < size.height; y += gap) {
          for (var x = gap; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 1.4, dot);
          }
        }
      case TemplateType.music:
        for (var g = 0; g < 3; g++) {
          for (var l = 0; l < 5; l++) {
            final y = 16 + g * 40 + l * 5.0;
            canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
          }
        }
      case TemplateType.planner:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = size.width / 4; x < size.width; x += size.width / 4) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
      case TemplateType.habit:
        final box = Paint()
          ..color = color
          ..style = PaintingStyle.stroke;
        for (var y = gap; y < size.height - gap / 2; y += gap) {
          for (var x = gap; x < size.width - gap / 2; x += gap) {
            canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: gap * 0.6, height: gap * 0.6), box);
          }
        }
      default: // ruled, sheet, blank, custom
        if (t.type != TemplateType.blank) {
          for (var y = gap; y < size.height; y += gap) {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_TemplatePreview old) => old.t != t;
}
