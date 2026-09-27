// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';

/// Pantalla secundaria con el lenguaje visual de la biblioteca: barra
/// superior mínima (atrás + acciones), **título grande** con subtítulo y
/// contenido centrado con ancho máximo legible en tablet.
///
/// El contenido se pasa como slivers para poder mezclar listas y rejillas
/// largas sin anidar scrolls.
class InklusPage extends StatelessWidget {
  const InklusPage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.headerTrailing,
    this.floatingActionButton,
    this.maxWidth = 960,
    required this.slivers,
  });

  final String title;
  final String? subtitle;

  /// Icono de sección junto al título (en una insignia tonal).
  final IconData? icon;

  /// Acciones de la barra superior (iconos).
  final List<Widget> actions;

  /// Widget a la derecha del título (p. ej. un botón "Vaciar").
  final Widget? headerTrailing;

  final Widget? floatingActionButton;

  /// Ancho máximo del contenido; `double.infinity` para rejillas.
  final double maxWidth;

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [...actions, const SizedBox(width: Spacing.sm)]),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            _constrained(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.xl, 0, Spacing.xl, Spacing.xl),
                  child: PageHeader(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    trailing: headerTrailing,
                  ),
                ),
              ),
            ),
            for (final s in slivers) _constrained(s),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _constrained(Widget sliver) => maxWidth.isInfinite
      ? sliver
      : SliverLayoutBuilder(
          builder: (context, c) {
            final extra = (c.crossAxisExtent - maxWidth) / 2;
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: extra > 0 ? extra : 0),
              sliver: sliver,
            );
          },
        );
}

/// Título grande + subtítulo (el mismo que "Mis cuadernos").
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconBadge(icon: icon!, size: 52),
          const SizedBox(width: Spacing.lg),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: context.text.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  subtitle!,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Icono en un cuadrado redondeado tonal (encabezados, filas de ajustes).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.color,
  });

  final IconData icon;
  final double size;

  /// Color de acento; por defecto el primario de la marca.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: accent, size: size * 0.5),
    );
  }
}

/// Título de un grupo de ajustes o de una sección de la pantalla.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.xs, Spacing.xl, Spacing.xs, Spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.text.titleSmall
                    ?.copyWith(color: context.colors.primary),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Tarjeta que agrupa filas (ajustes, listas cortas) con separadores finos.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Divider(indent: Spacing.lg, endIndent: Spacing.lg));
      rows.add(children[i]);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}

/// Fila de ajustes: insignia + título + descripción + control a la derecha.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accent,
    this.showChevron,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accent;

  /// Muestra "›" (por defecto: si hay [onTap] y no hay [trailing]).
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
      leading: IconBadge(icon: icon, color: accent),
      title: Text(title, style: context.text.titleMedium),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
      trailing: trailing ??
          (chevron
              ? Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant)
              : null),
      onTap: onTap,
    );
  }
}

/// Estado vacío común: ilustración tonal + título + texto + acciones.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer
                      .withValues(alpha: context.isDark ? 0.35 : 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: context.colors.primary),
              ),
              const SizedBox(height: Spacing.xl),
              Text(title,
                  style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyLarge
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Spacing.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Spacing.md,
                  runSpacing: Spacing.md,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de hoja inferior: insignia + título + subtítulo + acción.
/// (El asa de arrastre la pone el tema: `showDragHandle`.)
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.xl, 0, Spacing.lg, Spacing.lg),
        child: Row(
          children: [
            IconBadge(icon: icon),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.text.titleLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.text.bodyMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
}
