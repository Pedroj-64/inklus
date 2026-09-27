// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';


import '../models/template.dart';
import 'file_utils.dart';
import '../models/id.dart';
import 'app_paths.dart';

/// Entrada de la biblioteca de plantillas propias.
class CustomTemplateEntry {
  final String id;
  final String name;
  final String imagePath; // ruta local de la imagen
  final bool infiniteFill;
  final double? customWidth;
  final double? customHeight;

  const CustomTemplateEntry({
    required this.id,
    required this.name,
    required this.imagePath,
    this.infiniteFill = false,
    this.customWidth,
    this.customHeight,
  });

  /// Convierte a [PageTemplate] para usar en el controlador.
  PageTemplate toPageTemplate() => PageTemplate(
        type: TemplateType.custom,
        imagePath: imagePath,
        infiniteFill: infiniteFill,
        customWidth: customWidth,
        customHeight: customHeight,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'infiniteFill': infiniteFill,
        if (customWidth != null) 'customW': customWidth,
        if (customHeight != null) 'customH': customHeight,
      };

  factory CustomTemplateEntry.fromJson(Map<String, dynamic> json) =>
      CustomTemplateEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        infiniteFill: json['infiniteFill'] as bool? ?? false,
        customWidth: (json['customW'] as num?)?.toDouble(),
        customHeight: (json['customH'] as num?)?.toDouble(),
      );
}

/// Servicio para guardar y cargar plantillas custom reutilizables.
///
/// Las plantillas se guardan en `<appSupport>/inklus/templates/` con un
/// archivo `index.json` que lista las entradas y las imágenes correspondientes.
class TemplateLibraryService {
  Directory? _dir;
  List<CustomTemplateEntry> _entries = [];

  List<CustomTemplateEntry> get entries => List.unmodifiable(_entries);

  /// Inicializa el servicio y carga las plantillas existentes.
  Future<void> init() async {
    _dir = await AppPaths.templates();
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    await _loadIndex();
  }

  /// Guarda una nueva plantilla en la biblioteca.
  Future<CustomTemplateEntry> save({
    required String name,
    required String sourceImagePath,
    required bool infiniteFill,
    double? customWidth,
    double? customHeight,
  }) async {
    if (_dir == null) await init();

    final id = newId('tpl');
    final ext = sourceImagePath.split('.').last;
    final destPath = '${_dir!.path}/$id.$ext';

    // Copia la imagen a la carpeta de templates.
    await File(sourceImagePath).copy(destPath);

    final entry = CustomTemplateEntry(
      id: id,
      name: name,
      imagePath: destPath,
      infiniteFill: infiniteFill,
      customWidth: customWidth,
      customHeight: customHeight,
    );

    _entries.add(entry);
    await _saveIndex();
    return entry;
  }

  /// Elimina una plantilla de la biblioteca.
  Future<void> delete(String id) async {
    final entry = _entries.firstWhere((e) => e.id == id, orElse: () => throw StateError('Template not found'));
    final file = File(entry.imagePath);
    if (await file.exists()) await file.delete();
    _entries.removeWhere((e) => e.id == id);
    await _saveIndex();
  }

  Future<void> _loadIndex() async {
    final indexFile = File('${_dir!.path}/index.json');
    if (!await indexFile.exists()) {
      _entries = [];
      return;
    }
    try {
      final json = jsonDecode(await indexFile.readAsString()) as List;
      _entries = json
          .map((e) => CustomTemplateEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _entries = [];
    }
  }

  Future<void> _saveIndex() async {
    final indexFile = File('${_dir!.path}/index.json');
    await writeAtomic(indexFile, 
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
