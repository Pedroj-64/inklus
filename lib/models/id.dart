// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

final Random _random = Random();
int _counter = 0;

/// Genera un identificador único con prefijo legible.
///
/// Combina reloj (µs), un contador monótono y un sufijo aleatorio: dos ids
/// creados en el mismo microsegundo (p. ej. en un bucle) nunca coinciden.
String newId(String prefix) {
  _counter = (_counter + 1) & 0xFFFFF;
  final rand = _random.nextInt(1 << 20).toRadixString(36).padLeft(4, '0');
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_counter.toRadixString(36)}$rand';
}
