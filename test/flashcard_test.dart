// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/flashcard.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  const day = Duration.millisecondsPerDay;
  const card = Flashcard(id: 'c', pageId: 'p', front: Rect.fromLTWH(0, 0, 10, 10));

  test('una tarjeta nueva toca ya', () => expect(card.isDue(now), isTrue));

  test('«Bien» sigue 1 → 3 → intervalo × facilidad', () {
    var c = reviewCard(card, ReviewGrade.good, now);
    expect(c.intervalDays, 1);
    expect(c.due, now.millisecondsSinceEpoch + day);
    expect(c.isDue(now), isFalse);
    c = reviewCard(c, ReviewGrade.good, now);
    expect(c.intervalDays, 3);
    c = reviewCard(c, ReviewGrade.good, now);
    expect(c.intervalDays, (3 * 2.5).round());
  });

  test('«Otra vez» reinicia, baja la facilidad (mín. 1,3) y vuelve en 10 min', () {
    var c = reviewCard(reviewCard(card, ReviewGrade.good, now), ReviewGrade.again, now);
    expect(c.reps, 0);
    expect(c.ease, closeTo(2.3, 1e-9));
    expect(c.due, now.millisecondsSinceEpoch + 600000);
    for (var i = 0; i < 20; i++) {
      c = reviewCard(c, ReviewGrade.again, now);
    }
    expect(c.ease, 1.3);
  });

  test('«Fácil» alarga el intervalo y sube la facilidad', () {
    final c = reviewCard(card, ReviewGrade.easy, now);
    expect(c.intervalDays, 2);
    expect(c.ease, closeTo(2.65, 1e-9));
  });

  test('JSON de ida y vuelta', () {
    final c = reviewCard(card.copyWith(back: const Rect.fromLTWH(0, 20, 10, 5)), ReviewGrade.good, now);
    final back = Flashcard.fromJson(c.toJson());
    expect(back.back, c.back);
    expect(back.due, c.due);
    expect(back.ease, c.ease);
    expect(Flashcard.fromJson(card.toJson()).back, isNull);
  });
}
