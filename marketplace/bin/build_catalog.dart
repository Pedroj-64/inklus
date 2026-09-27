// SPDX-License-Identifier: GPL-3.0-or-later
//
// Genera `catalog.json` a partir de `packs/*/manifest.json`.
//
//   dart run bin/build_catalog.dart           # valida y escribe catalog.json
//   dart run bin/build_catalog.dart --check   # solo valida (para PRs)
//
// Las reglas son las MISMAS que aplica la app
// (`MarketplaceService.validatePack` en el repo de Inklus): si cambias una,
// cambia la otra.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const schemaVersion = 2;
const maxFileBytes = 5 * 1024 * 1024;
const maxPackBytes = 20 * 1024 * 1024;
final idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{2,63}$');
final allowedExt = RegExp(r'\.(png|jpg|jpeg|webp)$');
const types = {'template', 'palette', 'stickers'};

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  final packsDir = Directory('packs');
  if (!packsDir.existsSync()) {
    stderr.writeln('No existe la carpeta packs/');
    exit(1);
  }
  final packs = <Map<String, dynamic>>[];
  final errors = <String>[];

  final dirs = packsDir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final dir in dirs) {
    final id = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final manifestFile = File('${dir.path}/manifest.json');
    if (!manifestFile.existsSync()) {
      errors.add('$id: falta manifest.json');
      continue;
    }
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      errors.add('$id: manifest.json no es JSON válido ($e)');
      continue;
    }
    final packErrors = <String>[];
    if (m['id'] != id) packErrors.add('el id debe coincidir con la carpeta ("$id")');
    if (!idPattern.hasMatch(id)) packErrors.add('id inválido');
    for (final field in ['name', 'description', 'author', 'license', 'version', 'type']) {
      if ((m[field] as String?)?.trim().isEmpty ?? true) packErrors.add('falta "$field"');
    }
    if (!types.contains(m['type'])) packErrors.add('type debe ser uno de $types');

    // Archivos referenciados: stickers, imágenes de plantilla y preview.
    final refs = <String>{
      ...(m['stickers'] as List? ?? []).cast<String>(),
      for (final t in (m['templates'] as List? ?? []).cast<Map<String, dynamic>>())
        if (t['image'] is String) t['image'] as String,
    };
    final files = <Map<String, dynamic>>[];
    var total = 0;
    for (final ref in refs) {
      if (!ref.startsWith('packs/$id/') || ref.contains('..') || !allowedExt.hasMatch(ref.toLowerCase())) {
        packErrors.add('ruta no permitida: $ref');
        continue;
      }
      final f = File(ref);
      if (!f.existsSync()) {
        packErrors.add('no existe el archivo $ref');
        continue;
      }
      final bytes = f.readAsBytesSync();
      if (bytes.length > maxFileBytes) packErrors.add('$ref supera 5 MB');
      total += bytes.length;
      files.add({'path': ref, 'sha256': sha256.convert(bytes).toString(), 'size': bytes.length});
    }
    if (total > maxPackBytes) packErrors.add('el paquete supera 20 MB');
    switch (m['type']) {
      case 'template':
        if ((m['templates'] as List? ?? []).isEmpty) packErrors.add('faltan "templates"');
      case 'palette':
        if ((m['palette'] as List? ?? []).length < 2) packErrors.add('la paleta necesita 2+ colores');
      case 'stickers':
        if ((m['stickers'] as List? ?? []).isEmpty) packErrors.add('faltan "stickers"');
    }
    if (m['preview'] is String && !File(m['preview'] as String).existsSync()) {
      packErrors.add('no existe la vista previa ${m['preview']}');
    }

    if (packErrors.isEmpty) {
      packs.add({...m, if (files.isNotEmpty) 'files': files});
      stdout.writeln('✔ $id');
    } else {
      errors.addAll(packErrors.map((e) => '$id: $e'));
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('\n${errors.length} error(es):');
    for (final e in errors) {
      stderr.writeln('  ✘ $e');
    }
    exit(1);
  }
  if (checkOnly) {
    stdout.writeln('\n${packs.length} paquete(s) válidos.');
    return;
  }
  File('catalog.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'schema': schemaVersion,
    'updated': DateTime.now().toUtc().toIso8601String(),
    'packs': packs,
  }));
  stdout.writeln('\ncatalog.json generado con ${packs.length} paquete(s).');
}
