// SPDX-License-Identifier: GPL-3.0-or-later
// ============================================================================
// Utilidades de formateo de fechas (textos traducidos con AppLocalizations)
// ============================================================================
import '../l10n/l10n.dart';

/// Antigüedad legible de una fecha: "ahora", "hace 5 min", "hace 3 h",
/// "hace 2 d" o "dd/mm/aaaa" (≥ 7 días).
String relativeTime(AppLocalizations l10n, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return _date(time);
}

/// Igual que [relativeTime] pero para elementos de la papelera.
String deletedAgo(AppLocalizations l10n, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return l10n.timeDeletedNow;
  if (diff.inMinutes < 60) return l10n.timeDeletedMin(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeDeletedHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDeletedDays(diff.inDays);
  return l10n.timeDeletedOn(_date(time));
}

String _date(DateTime time) {
  final t = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year}';
}
