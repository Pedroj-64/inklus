// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../services/writing_stats_service.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/page_scaffold.dart';
import '../l10n/l10n.dart';

/// Pantalla de estadísticas de escritura.
///
/// Muestra totales acumulados, gráfico de actividad de los últimos 30 días
/// y detalles de rachas.
class WritingStatsScreen extends StatefulWidget {
  const WritingStatsScreen({super.key});

  @override
  State<WritingStatsScreen> createState() => _WritingStatsScreenState();
}

class _WritingStatsScreenState extends State<WritingStatsScreen> {
  final _stats = WritingStatsService();
  TotalStats? _totals;
  List<DayStats> _last30 = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _stats.load();
    if (!mounted) return;
    setState(() {
      _totals = _stats.totals();
      _last30 = _stats.lastNDays(30);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    return InklusPage(
      title: context.l10n.statsTitle,
      subtitle: context.l10n.statsSubtitle,
      icon: Icons.insights_outlined,
      maxWidth: 820,
      slivers: [
        if (totals == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (totals.totalStrokes == 0 && totals.totalMinutesActive == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.analytics_outlined,
              title: context.l10n.statsEmptyTitle,
              message: context.l10n.statsEmptyBody,
            ),
          )
        else
          SliverList.list(
            children: [
              _SummaryGrid(items: [
                (Icons.draw_outlined, context.l10n.statsStrokes, totals.totalStrokes),
                (Icons.description_outlined, context.l10n.tbPages, totals.totalPagesCreated),
                (Icons.timer_outlined, context.l10n.statsMinutes, totals.totalMinutesActive),
                (Icons.event_available_outlined, context.l10n.statsActiveDays, totals.totalDaysActive),
              ]),
              SectionLabel(context.l10n.statsStreaks),
              Row(
                children: [
                  Expanded(
                    child: _StreakCard(
                      label: context.l10n.statsCurrentStreak,
                      days: totals.currentStreak,
                      color: context.inklus.success,
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _StreakCard(
                      label: context.l10n.statsRecord,
                      days: totals.longestStreak,
                      color: context.inklus.warning,
                      icon: Icons.emoji_events_outlined,
                    ),
                  ),
                ],
              ),
              SectionLabel(context.l10n.statsActivity),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    children: [
                      SizedBox(height: 160, child: _ActivityChart(data: _last30)),
                      const SizedBox(height: Spacing.md),
                      Wrap(
                        spacing: Spacing.lg,
                        children: [
                          _LegendDot(color: context.colors.primary, label: context.l10n.statsStrokes),
                          _LegendDot(
                              color: context.inklus.success,
                              label: context.l10n.statsDaysWithPages),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Totales en una rejilla (4 columnas en tablet, 2 en teléfono).
class _SummaryGrid extends StatelessWidget {
  final List<(IconData, String, int)> items;
  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth < Breakpoints.compact ? 2 : 4;
      final width = (c.maxWidth - Spacing.md * (columns - 1)) / columns;
      return Wrap(
        spacing: Spacing.md,
        runSpacing: Spacing.md,
        children: [
          for (final (icon, label, value) in items)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: icon, size: 40),
                      const SizedBox(height: Spacing.md),
                      Text('$value', style: context.text.headlineSmall),
                      Text(
                        label,
                        style: context.text.bodyMedium
                            ?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// Tarjeta de racha.
class _StreakCard extends StatelessWidget {
  final String label;
  final int days;
  final Color color;
  final IconData icon;

  const _StreakCard({
    required this.label,
    required this.days,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: context.isDark ? 0.16 : 0.1),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: Spacing.xs),
                Text(label, style: context.text.labelLarge?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              context.l10n.statsDays(days),
              style: context.text.headlineMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leyenda del gráfico.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          label,
          style: context.text.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Barras de trazos por día (altura relativa al día con más trazos) y un
/// punto verde encima de los días en que se crearon páginas.
class _ActivityChart extends StatelessWidget {
  final List<DayStats> data;

  const _ActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxStrokes =
        data.fold<int>(1, (m, d) => d.strokeCount > m ? d.strokeCount : m);
    final muted = context.colors.outlineVariant;
    final dateStyle = context.text.bodySmall
        ?.copyWith(color: context.colors.onSurfaceVariant);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            const dot = 8.0;
            final barMax = c.maxHeight - dot - Spacing.xs;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in data)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Tooltip(
                        message: context.l10n.statsDayTooltip(_formatDate(day.date), day.strokeCount, day.pagesCreated),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (day.pagesCreated > 0)
                              Container(
                                width: dot,
                                height: dot,
                                margin: const EdgeInsets.only(bottom: Spacing.xs),
                                decoration: BoxDecoration(
                                  color: context.inklus.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Container(
                              height: day.strokeCount == 0
                                  ? 2
                                  : (day.strokeCount / maxStrokes * barMax)
                                      .clamp(3.0, barMax),
                              decoration: BoxDecoration(
                                color: day.strokeCount == 0
                                    ? muted
                                    : context.colors.primary,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (data.isNotEmpty) Text(_formatDate(data.first.date), style: dateStyle),
            if (data.length > 1) Text(_formatDate(data.last.date), style: dateStyle),
          ],
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}';
}
