// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/logic/palm_rejection.dart';

void main() {
  late DateTime now;
  late PalmRejection palm;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    palm = PalmRejection(clock: () => now);
  });

  test('sin lápiz, un dedo normal se acepta', () {
    expect(palm.rejectTouch(), isFalse);
  });

  test('con el lápiz apoyado, todo toque se descarta', () {
    palm.stylusDownEvent(1);
    expect(palm.rejectTouch(), isTrue);
  });

  test('justo después de levantar el lápiz se sigue descartando', () {
    palm.stylusDownEvent(1);
    palm.stylusUpEvent(1);
    now = now.add(const Duration(milliseconds: 200));
    expect(palm.rejectTouch(), isTrue);
    now = now.add(const Duration(milliseconds: 400));
    expect(palm.rejectTouch(), isFalse);
  });

  test('el hover del lápiz protege antes de tocar', () {
    palm.stylusHoverEvent();
    expect(palm.rejectTouch(), isTrue);
    now = now.add(const Duration(milliseconds: 500));
    expect(palm.rejectTouch(), isFalse);
  });

  test('un contacto grande es palma', () {
    expect(palm.rejectTouch(radiusMajor: 40), isTrue);
    expect(palm.rejectTouch(radiusMajor: 8), isFalse);
  });

  test('isStylusKind', () {
    expect(PalmRejection.isStylusKind(PointerDeviceKind.stylus), isTrue);
    expect(PalmRejection.isStylusKind(PointerDeviceKind.invertedStylus), isTrue);
    expect(PalmRejection.isStylusKind(PointerDeviceKind.touch), isFalse);
  });
}
