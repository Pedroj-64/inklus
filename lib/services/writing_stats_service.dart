import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Estadísticas de escritura de un día.
class DayStats {
  final DateTime date;

  /// Número de trazos creados.
  final int strokeCount;

  /// Número de páginas creadas.
  final int pagesCreated;

  /// Minutos de actividad de escritura (aproximado por sesiones activas).
  final int minutesActive;

  /// Número de documentos tocados.
  final int documentsTouched;

  const DayStats({
    required this.date,
    this.strokeCount = 0,
    this.pagesCreated = 0,
    this.minutesActive = 0,
    this.documentsTouched = 0,
  });

  factory DayStats.fromJson(Map<String, dynamic> json) => DayStats(
        date: DateTime.parse(json['date'] as String),
        strokeCount: json['strokes'] as int? ?? 0,
        pagesCreated: json['pages'] as int? ?? 0,
        minutesActive: json['minutes'] as int? ?? 0,
        documentsTouched: json['docs'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'strokes': strokeCount,
        'pages': pagesCreated,
        'minutes': minutesActive,
        'docs': documentsTouched,
      };

  /// Crea una copia con valores incrementados.
  DayStats copyWith({
    int? addStrokes,
    int? addPages,
    int? addMinutes,
    int? addDocs,
  }) =>
      DayStats(
        date: date,
        strokeCount: strokeCount + (addStrokes ?? 0),
        pagesCreated: pagesCreated + (addPages ?? 0),
        minutesActive: minutesActive + (addMinutes ?? 0),
        documentsTouched: documentsTouched + (addDocs ?? 0),
      );
}

/// Estadísticas acumuladas (resumen total).
class TotalStats {
  final int totalStrokes;
  final int totalPagesCreated;
  final int totalMinutesActive;
  final int totalDocuments;
  final int totalDaysActive;
  final int currentStreak;
  final int longestStreak;

  const TotalStats({
    required this.totalStrokes,
    required this.totalPagesCreated,
    required this.totalMinutesActive,
    required this.totalDocuments,
    required this.totalDaysActive,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// Servicio de estadísticas de escritura.
///
/// Persiste datos en `inklus/stats.json` como un mapa de fechas.
/// Se actualiza en cada acción de escritura (trazo, página nueva).
class WritingStatsService {
  static const _fileName = 'stats.json';

  Map<String, DayStats> _days = {};

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inklus/$_fileName');
  }

  /// Carga las estadísticas desde disco.
  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _days = {
        for (final e in json.entries)
          e.key: DayStats.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (e) {
      debugPrint('WritingStatsService.load: $e');
    }
  }

  /// Guarda las estadísticas a disco.
  Future<void> _save() async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      final map = <String, dynamic>{};
      for (final e in _days.entries) {
        map[e.key] = e.value.toJson();
      }
      await f.writeAsString(jsonEncode(map));
    } catch (e) {
      debugPrint('WritingStatsService._save: $e');
    }
  }

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DayStats _today() {
    final key = _key(DateTime.now());
    return _days[key] ?? DayStats(date: DateTime.now());
  }

  /// Registra trazos creados.
  Future<void> recordStrokes(int count, {String? docId}) async {
    final docTouched = docId != null ? 1 : 0;
    _days[_key(DateTime.now())] = _today().copyWith(
      addStrokes: count,
      addDocs: docTouched,
    );
    await _save();
  }

  /// Registra una página creada.
  Future<void> recordPageCreated({String? docId}) async {
    _days[_key(DateTime.now())] = _today().copyWith(
      addPages: 1,
      addDocs: docId != null ? 1 : 0,
    );
    await _save();
  }

  /// Registra minutos de actividad (llamar periódicamente o al guardar).
  Future<void> recordActivity({int minutes = 1}) async {
    _days[_key(DateTime.now())] = _today().copyWith(
      addMinutes: minutes,
    );
    await _save();
  }

  /// Estadísticas de un día específico.
  DayStats? statsFor(DateTime date) => _days[_key(date)];

  /// Estadísticas de los últimos N días (para gráficos).
  List<DayStats> lastNDays(int n) {
    final result = <DayStats>[];
    final now = DateTime.now();
    for (var i = n - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      result.add(_days[_key(date)] ?? DayStats(date: date));
    }
    return result;
  }

  /// Estadísticas acumuladas de toda la vida.
  TotalStats totals() {
    var totalStrokes = 0;
    var totalPages = 0;
    var totalMinutes = 0;
    final docIds = <String>{};
    var daysActive = 0;

    for (final day in _days.values) {
      totalStrokes += day.strokeCount;
      totalPages += day.pagesCreated;
      totalMinutes += day.minutesActive;
      if (day.strokeCount > 0 || day.pagesCreated > 0) daysActive++;
    }

    // Calcular rachas.
    final now = DateTime.now();
    var currentStreak = 0;
    var longestStreak = 0;
    var streak = 0;
    DateTime? prev;

    for (var i = 0; i < 365; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final key = _key(date);
      final day = _days[key];
      if (day != null && (day.strokeCount > 0 || day.pagesCreated > 0)) {
        streak++;
        if (i == 0 || (prev != null && date.difference(prev).inDays == 1)) {
          if (i == 0 || currentStreak == streak - 1) {
            currentStreak = streak;
          }
        }
        if (streak > longestStreak) longestStreak = streak;
        prev = date;
      } else {
        if (i == 0) currentStreak = 0;
        streak = 0;
      }
    }

    return TotalStats(
      totalStrokes: totalStrokes,
      totalPagesCreated: totalPages,
      totalMinutesActive: totalMinutes,
      totalDocuments: docIds.length,
      totalDaysActive: daysActive,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }
}
