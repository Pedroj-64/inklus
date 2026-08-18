/// Genera un identificador único con prefijo legible.
String newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_rand()}';

String _rand() => (DateTime.now().microsecondsSinceEpoch % 9973)
    .toString()
    .padLeft(5, '0');
