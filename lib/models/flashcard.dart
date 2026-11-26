// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

/// Tarjeta de estudio: una zona de una página es la pregunta y otra
/// (opcional) la respuesta, ambas en coordenadas de mundo.
class Flashcard {
  final String id;
  final String pageId;
  final Rect front;
  final Rect? back;

  // Repetición espaciada (tipo SM-2).
  final int due; // ms desde epoch: cuándo toca repasarla
  final int intervalDays;
  final double ease;
  final int reps; // aciertos seguidos

  const Flashcard({
    required this.id,
    required this.pageId,
    required this.front,
    this.back,
    this.due = 0,
    this.intervalDays = 0,
    this.ease = 2.5,
    this.reps = 0,
  });

  bool isDue(DateTime now) => due <= now.millisecondsSinceEpoch;

  Flashcard copyWith({Rect? back, int? due, int? intervalDays, double? ease, int? reps}) => Flashcard(
        id: id,
        pageId: pageId,
        front: front,
        back: back ?? this.back,
        due: due ?? this.due,
        intervalDays: intervalDays ?? this.intervalDays,
        ease: ease ?? this.ease,
        reps: reps ?? this.reps,
      );

  static Rect _rect(List<dynamic> v) => Rect.fromLTWH(
      (v[0] as num).toDouble(), (v[1] as num).toDouble(), (v[2] as num).toDouble(), (v[3] as num).toDouble());
  static List<double> _list(Rect r) => [r.left, r.top, r.width, r.height];

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'] as String,
        pageId: j['page'] as String,
        front: _rect(j['front'] as List),
        back: j['back'] is List ? _rect(j['back'] as List) : null,
        due: (j['due'] as num?)?.toInt() ?? 0,
        intervalDays: (j['iv'] as num?)?.toInt() ?? 0,
        ease: (j['ease'] as num?)?.toDouble() ?? 2.5,
        reps: (j['reps'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': pageId,
        'front': _list(front),
        if (back != null) 'back': _list(back!),
        'due': due,
        'iv': intervalDays,
        'ease': ease,
        'reps': reps,
      };
}

/// Respuesta del usuario al repasar una tarjeta.
enum ReviewGrade { again, good, easy }

/// Siguiente estado de [card] tras responder [grade] en [now] (SM-2
/// simplificado, como Anki con tres botones). Pura: se prueba sin UI.
Flashcard reviewCard(Flashcard card, ReviewGrade grade, DateTime now) {
  const day = Duration.millisecondsPerDay;
  final t = now.millisecondsSinceEpoch;
  switch (grade) {
    case ReviewGrade.again:
      // Vuelve en 10 minutos y cuesta un poco más la próxima vez.
      return card.copyWith(
          reps: 0, intervalDays: 0, ease: max(1.3, card.ease - 0.2), due: t + 10 * 60 * 1000);
    case ReviewGrade.good:
    case ReviewGrade.easy:
      final easy = grade == ReviewGrade.easy;
      var days = switch (card.reps) {
        0 => 1,
        1 => 3,
        _ => (card.intervalDays * card.ease).round(),
      };
      if (easy) days = (days * 1.3).ceil();
      return card.copyWith(
        reps: card.reps + 1,
        intervalDays: days,
        ease: easy ? card.ease + 0.15 : card.ease,
        due: t + days * day,
      );
  }
}
