import '../constants.dart';
import 'package:flutter/material.dart';

import '../services/writing_stats_service.dart';

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
    final maxStrokes = _last30.fold<int>(
      0,
      (max, d) => d.strokeCount > max ? d.strokeCount : max,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: totals == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- Resumen rápido ---
                _SummaryRow(
                  items: [
                    _SummaryItem(
                      icon: Icons.draw,
                      label: 'Trazos',
                      value: '${totals.totalStrokes}',
                    ),
                    _SummaryItem(
                      icon: Icons.description_outlined,
                      label: 'Páginas',
                      value: '${totals.totalPagesCreated}',
                    ),
                    _SummaryItem(
                      icon: Icons.timer_outlined,
                      label: 'Minutos',
                      value: '${totals.totalMinutesActive}',
                    ),
                    _SummaryItem(
                      icon: Icons.event_available,
                      label: 'Días activos',
                      value: '${totals.totalDaysActive}',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Rachas ---
                _SectionTitle(title: 'Rachas'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StreakCard(
                      label: 'Racha actual',
                      days: totals.currentStreak,
                      color: const Color(0xFF10B981),
                      isFire: true,
                    ),
                    const SizedBox(width: 12),
                    _StreakCard(
                      label: 'Récord',
                      days: totals.longestStreak,
                      color: const Color(0xFFF59E0B),
                      isFire: false,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Actividad últimos 30 días ---
                _SectionTitle(title: 'Actividad — últimos 30 días'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: _ActivityChart(
                    data: _last30,
                    maxValue: maxStrokes > 0 ? maxStrokes : 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Leyenda.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: kAccentColor, label: 'Trazos'),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: const Color(0xFF10B981),
                      label: 'Páginas',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Fila de resumen con totales.
class _SummaryRow extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(60),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(item.icon, size: 22, color: kAccentColor),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// Tarjeta de racha.
class _StreakCard extends StatelessWidget {
  final String label;
  final int days;
  final Color color;
  final bool isFire;

  const _StreakCard({
    required this.label,
    required this.days,
    required this.color,
    required this.isFire,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isFire && days > 0) const Text('🔥', style: TextStyle(fontSize: 18)),
                if (isFire && days > 0) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withAlpha(180),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$days días',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de sección.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

/// Gráfico de barras simple de actividad.
class _ActivityChart extends StatelessWidget {
  final List<DayStats> data;
  final int maxValue;

  const _ActivityChart({required this.data, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final barWidth = (MediaQuery.of(context).size.width - 80) /
        (data.isEmpty ? 1 : data.length);

    return Column(
      children: [
        // Barras.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((day) {
              final strokesHeight = maxValue > 0
                  ? (day.strokeCount / maxValue)
                  : 0.0;
              final pagesHeight = maxValue > 0
                  ? (day.pagesCreated / maxValue)
                  : 0.0;
              return Container(
                width: barWidth.clamp(2.0, 12.0),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.pagesCreated > 0)
                      Container(
                        height: (pagesHeight * 100).clamp(2.0, 100.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                    if (day.strokeCount > 0)
                      Container(
                        height: (strokesHeight * 100).clamp(2.0, 100.0),
                        decoration: BoxDecoration(
                          color: kAccentColor,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                    if (day.strokeCount == 0 && day.pagesCreated == 0)
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Etiquetas de fechas.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (data.isNotEmpty)
              Text(
                _formatDate(data.first.date),
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
            if (data.length > 1)
              Text(
                _formatDate(data.last.date),
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}';
  }
}
