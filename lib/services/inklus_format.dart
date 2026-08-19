import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document.dart';
import '../models/image_item.dart';
import '../models/note.dart';
import '../models/page.dart';

/// Formato propietario **.inklus**: contenedor autocontenido de un cuaderno.
///
/// Es un archivo ZIP con dos partes:
/// - `document.json` — el JSON del documento (trazos, páginas, plantillas),
///   con las rutas de imágenes/plantillas reescritas a
///   `inklus://images/<nombre>` cuando el archivo local existe.
/// - `images/<nombre>` — las imágenes insertadas y plantillas propias
///   embebidas dentro del propio archivo.
///
/// Así el cuaderno viaja en **un único archivo** (como `.goodnotes`/`.sdoc`),
/// sin archivos sueltos: se puede exportar, compartir o subir a Google Drive,
/// y al importarlo se restauran también las imágenes (no hace falta ningún
/// archivo externo).
class InklusFormat {
  InklusFormat._();

  static const _docEntry = 'document.json';
  static const _imagesPrefix = 'images/';
  static const scheme = 'inklus://';

  // -------------------------------------------------------------------------
  // Exportación (documento → bytes .inklus)
  // -------------------------------------------------------------------------

  /// Serializa un cuaderno completo al formato .inklus.
  ///
  /// Lee de disco las imágenes y plantillas de todas las páginas y las
  /// embebe en el contenedor, reescribiendo las rutas del JSON a
  /// `inklus://images/<nombre>` (los archivos que ya no existen se dejan con
  /// su ruta original, sin romper el documento).
  static Future<Uint8List> exportBytes(Document document) async {
    final images = <String, Future<Uint8List>>{};
    final pages = <Page>[];
    for (final page in document.pages) {
      final newImages = <ImageItem>[];
      for (final item in page.images) {
        final file = File(item.localPath);
        if (await file.exists()) {
          final name = _basename(item.localPath);
          images.putIfAbsent(name, () => file.readAsBytes());
          newImages.add(item.copyWith(localPath: _embedKey(name)));
        } else {
          newImages.add(item);
        }
      }

      var template = page.template;
      final templatePath = template.imagePath;
      if (templatePath != null) {
        final file = File(templatePath);
        if (await file.exists()) {
          final name = _basename(templatePath);
          images.putIfAbsent(name, () => file.readAsBytes());
          template = template.copyWith(imagePath: _embedKey(name));
        }
      }
      pages.add(page.copyWith(images: newImages, template: template));
    }

    final outDoc = Document(
      id: document.id,
      title: document.title,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      pages: pages,
    );

    final archive = Archive();
    final docBytes = utf8.encode(jsonEncode(outDoc.toJson()));
    archive.addFile(ArchiveFile(_docEntry, docBytes.length, docBytes));
    for (final entry in images.entries) {
      final bytes = await entry.value;
      archive.addFile(
        ArchiveFile('$_imagesPrefix${entry.key}', bytes.length, bytes),
      );
    }
    return ZipEncoder().encodeBytes(archive);
  }

  // -------------------------------------------------------------------------
  // Importación (bytes .inklus → documento restaurado)
  // -------------------------------------------------------------------------

  /// Lee un archivo .inklus, extrae las imágenes a la carpeta de la app y
  /// devuelve el documento con las rutas re-mapeadas a archivos locales.
  ///
  /// [extractTo] permite fijar el destino de las imágenes (tests); por
  /// defecto se usa `<appSupport>/inklus/restored/<id del documento>/`.
  static Future<Document> importBytes(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    Uint8List? docBytes;
    final entries = <String, Uint8List>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final data = file.readBytes();
      if (data == null) continue;
      if (file.name == _docEntry) {
        docBytes = data;
      } else {
        entries[file.name] = data;
      }
    }
    if (docBytes == null) {
      throw const FormatException('No es un cuaderno .inklus válido');
    }

    final doc = Document.fromJson(
      jsonDecode(utf8.decode(docBytes)) as Map<String, dynamic>,
    );
    final dir =
        extractTo ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/inklus/restored/${doc.id}',
        );
    await dir.create(recursive: true);

    final pages = <Page>[];
    for (final page in doc.pages) {
      final images = <ImageItem>[];
      for (final item in page.images) {
        images.add(
          item.copyWith(localPath: await _materialize(item.localPath, dir, entries)),
        );
      }
      var template = page.template;
      final templatePath = template.imagePath;
      if (templatePath != null) {
        template = template.copyWith(
          imagePath: await _materialize(templatePath, dir, entries),
        );
      }
      pages.add(page.copyWith(images: images, template: template));
    }
    return Document(
      id: doc.id,
      title: doc.title,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      pages: pages,
    );
  }

  /// Convierte una ruta `inklus://images/<nombre>` en un archivo local
  /// extraído; las rutas normales se devuelven tal cual.
  static Future<String> _materialize(
    String path,
    Directory dir,
    Map<String, Uint8List> entries,
  ) async {
    if (!path.startsWith(scheme)) return path;
    final key = path.substring(scheme.length); // 'images/<nombre>'
    final bytes = entries[key];
    if (bytes == null) return path;
    final file = File('${dir.path}/${key.split('/').last}');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static String _basename(String path) => path.split('/').last;

  static String _embedKey(String name) => '$scheme$_imagesPrefix$name';

  // -------------------------------------------------------------------------
  // Variantes para Note (nuevo formato)
  // -------------------------------------------------------------------------

  /// Serializa un Note al formato .inklus (misma lógica que exportBytes).
  static Future<Uint8List> exportNoteBytes(Note note) async {
    // Un Note tiene la misma estructura que un Document, así que reusamos
    // la lógica existente construyendo un Document temporal.
    final doc = Document(
      id: note.id,
      title: note.title,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      pages: note.pages,
    );
    return exportBytes(doc);
  }

  /// Importa un .inklus y devuelve un Note restaurado.
  static Future<Note> importNoteBytes(
    Uint8List bytes, {
    Directory? extractTo,
  }) async {
    final doc = await importBytes(bytes, extractTo: extractTo);
    return Note(
      id: doc.id,
      title: doc.title,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      pages: doc.pages,
    );
  }
}
