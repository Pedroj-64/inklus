// SPDX-License-Identifier: GPL-3.0-or-later
// ============================================================================
// Utilidades de formateo de fechas
//
// Extraídas de duplicados en notebook_library.dart y trash_screen.dart.
// ============================================================================

/// Devuelve una representación legible de la "antigüedad" de una fecha.
///
/// - "ahora mismo" (< 1 min)
/// - "hace 5 min" (< 1 hora)
/// - "hace 3 h" (< 24 horas)
/// - "hace 2 d" (< 7 días)
/// - "dd/mm/aaaa" (≥ 7 días)
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'ahora mismo';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  final t = time.toLocal();
  return '${_two(t.day)}/${_two(t.month)}/${t.year}';
}

/// Devuelve una representación de "hace X tiempo" para elementos de papelera.
///
/// Igual que [relativeTime] pero con prefijo "eliminado".
String deletedAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'eliminado ahora';
  if (diff.inMinutes < 60) return 'eliminado hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'eliminado hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'eliminado hace ${diff.inDays} días';
  final t = time.toLocal();
  return 'eliminado ${_two(t.day)}/${_two(t.month)}/${t.year}';
}

String _two(int n) => n.toString().padLeft(2, '0');
