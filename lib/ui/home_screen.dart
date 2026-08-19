import '../constants.dart';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../logic/canvas_controller.dart';
import '../models/note.dart';
import '../models/template.dart';
import '../models/id.dart';
import '../models/image_item.dart';
import '../models/stroke.dart';
import '../services/drive_sync_service.dart';
import '../services/export_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_import_service.dart';
import '../services/image_service.dart';
import '../services/inklus_format.dart';
import '../services/storage_service.dart';
import '../services/template_library_service.dart';
import '../services/writing_stats_service.dart';
import '../services/reminder_service.dart';
import '../services/search_service.dart';
import 'canvas/drawing_canvas.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/layers_sidebar.dart';
import 'widgets/minimap.dart';
import 'widgets/page_thumbnails.dart';
import 'widgets/stroke_options_sheet.dart';
import 'widgets/template_picker_sheet.dart';
import 'widgets/tool_rail.dart';
import 'writing_stats_screen.dart';
import '../utils/theme_colors.dart';

/// Editor de un cuaderno (pantalla principal de escritura).
///
/// Recibe un [note] ya cargado desde la lista de notas ([NoteListScreen])
/// y crea su [CanvasController] al montarse.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.note,
    required this.notebookId,
  });

  final Note note;
  final String notebookId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService.instance;
  final ImageService _imageService = ImageService();
  final DriveSyncService _syncService = DriveSyncService.instance;
  final TemplateLibraryService _templateLibrary = TemplateLibraryService();
  final WritingStatsService _stats = WritingStatsService();
  final ReminderService _reminders = ReminderService();
  final SearchService _search = SearchService();
  late final CanvasController _controller;
  bool _syncing = false;
  bool _toolRailCollapsed = false;
  bool _layersSidebarOpen = false;
  bool _thumbnailsOpen = true;
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    _templateLibrary.init();
    _stats.load();
    _reminders.load();
    _search.load();
    _sessionStart = DateTime.now();
    _controller = CanvasController(
      _storage,
      initial: widget.note,
      notebookId: widget.notebookId,
    );
    // Replica automática a Drive en cada guardado local (solo si hay sesión
    // y el scope ya está autorizado; nunca muestra UI).
    // A8: ahora se sincroniza cada Note individualmente (no el Document).
    _controller.onRemoteSync = (note) async {
      if (!_syncService.isSignedIn) return;
      // Sync selectiva: solo subir si el notebook lo tiene habilitado.
      final metas = await _storage.loadIndex();
      final meta = metas.where((m) => m.id == widget.notebookId).firstOrNull;
      if (meta != null && !meta.isSyncEnabled) return;
      try {
        await _syncService.backupNote(note);
      } catch (_) {
        // Silencioso: el guardado local ya protege los datos.
      }
    };
    // Notificación de sync completado.
    _syncService.onSyncComplete = (msg) {
      if (mounted) _snack(msg);
    };
    _loadSyncEnabled();
  }

  CanvasController get _c => _controller;

  // -------------------------------------------------------------------------
  // Acciones
  // -------------------------------------------------------------------------

  Future<void> _insertImages() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
        // ignore: deprecated_member_use (multi-selección requiere allowMultiple)
        allowMultiple: true,
      );
      for (final f in files) {
        final path = f.path;
        if (path == null) continue;
        final localPath = await _imageService.importToApp(path);
        final img = await _imageService.decode(localPath);
        _imageService.cache[localPath] = img;
        if (!mounted) return;

        final w = img.width.toDouble();
        final h = img.height.toDouble();
        final fit = w > 520 ? 520 / w : 1.0;
        final center = _c.viewportToWorld(
          Offset(_c.viewportSize.width / 2, _c.viewportSize.height / 2),
          _c.viewportSize,
        );
        _c.addImage(
          ImageItem(
            id: newId('img'),
            localPath: localPath,
            x: center.dx,
            y: center.dy,
            width: w * fit,
            height: h * fit,
          ),
        );
      }
      _c.setTool(ToolType.select);
    } catch (e) {
      _snack('No se pudo insertar la imagen: $e');
    }
  }

  Future<void> _deleteSelectedImage() async {
    final id = _c.selectedImageId;
    if (id == null) return;
    for (final item in _c.page.images) {
      if (item.id == id) {
        _c.removeImage(item);
        return;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Exportación con opciones configurables
  // -------------------------------------------------------------------------

  /// Abre el diálogo de opciones de exportación y luego exporta.
  Future<void> _exportWithOptions(
    Future<Uint8List> Function(ExportOptions) render,
    String defaultName, {
    bool isRegion = false,
    bool showStrokesOnly = false,
  }) async {
    final options = await _showExportOptionsDialog(
      isRegion: isRegion,
      showStrokesOnly: showStrokesOnly,
    );
    if (options == null) return; // cancelado
    _export(() => render(options), defaultName);
  }

  Future<ExportOptions?> _showExportOptionsDialog({
    bool isRegion = false,
    bool showStrokesOnly = false,
  }) async {
    int maxDimension = 2048;
    bool transparentBg = false;
    bool strokesOnly = false;

    return showDialog<ExportOptions>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Opciones de exportación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // DPI / resolución
              DropdownButton<int>(
                value: maxDimension,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1024, child: Text('Baja (1024 px)')),
                  DropdownMenuItem(value: 2048, child: Text('Media (2048 px)')),
                  DropdownMenuItem(value: 4096, child: Text('Alta (4096 px)')),
                  DropdownMenuItem(value: 8192, child: Text('Máxima (8192 px)')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => maxDimension = v);
                },
              ),
              const SizedBox(height: 12),
              // Fondo transparente
              SwitchListTile(
                title: const Text('Fondo transparente'),
                subtitle: const Text('Sin plantilla ni papel'),
                value: transparentBg,
                onChanged: (v) =>
                    setDialogState(() => transparentBg = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              // Solo trazos
              if (showStrokesOnly)
                SwitchListTile(
                  title: const Text('Solo trazos'),
                  subtitle: const Text('Sin imágenes ni plantilla'),
                  value: strokesOnly,
                  onChanged: (v) =>
                      setDialogState(() => strokesOnly = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ExportOptions(
                  maxDimension: maxDimension,
                  transparentBackground: transparentBg,
                  strokesOnly: strokesOnly,
                ),
              ),
              child: const Text('Exportar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPng() => _exportWithOptions(
        (opts) => ExportService.renderPagePng(
          _c.page,
          sheetSize: _c.sheetSize,
          imageCache: _imageService.cache,
          options: opts,
        ),
        'inklus_pagina_${_c.pageIndex + 1}.png',
        showStrokesOnly: true,
      );

  Future<void> _exportPdf() => _exportWithOptions(
        (opts) => ExportService.renderPagePdf(
          _c.page,
          sheetSize: _c.sheetSize,
          imageCache: _imageService.cache,
          options: opts,
        ),
        'inklus_pagina_${_c.pageIndex + 1}.pdf',
        showStrokesOnly: true,
      );

  Future<void> _exportNotebookPdf() => _exportWithOptions(
        (opts) => ExportService.renderNotebookPdf(
          _c.document,
          imageCache: _imageService.cache,
          options: opts,
        ),
        '${_safeName(_c.document.title)}.pdf',
        showStrokesOnly: true,
      );

  Future<void> _exportInklusCopy() => _export(
        () => InklusFormat.exportBytes(_c.document),
        '${_safeName(_c.document.title)}.inklus',
      );

  /// Exporta la página actual a SVG (solo trazos).
  Future<void> _exportSvg() async {
    try {
      final svgString = ExportService.renderPageSvg(_c.page);
      final bytes = Uint8List.fromList(utf8.encode(svgString));
      final name = 'inklus_pagina_${_c.pageIndex + 1}.svg';
      await _saveBytes(bytes, name);
    } catch (e) {
      _snack('Error al exportar SVG: $e');
    }
  }

  /// Reconoce el texto escrito a mano en la página actual (OCR).
  Future<void> _recognizeText() async {
    if (!OcrService.isSupported) {
      _snack('OCR solo está disponible en Android e iOS');
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Reconociendo texto...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    try {
      final result = await OcrService.recognizeText(
        _c.page,
        sheetSize: _c.sheetSize,
        imageCache: _imageService.cache,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (result.isEmpty) {
        _snack('No se reconoció texto en esta página');
        return;
      }

      // Mostrar resultado y permitir copiar.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Texto reconocido'),
          content: SingleChildScrollView(
            child: SelectableText(
              result.text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.text));
                Navigator.pop(context);
                _snack('Texto copiado al portapapeles');
              },
              child: const Text('Copiar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack('Error al reconocer texto: $e');
    }
  }

  /// Nombre de archivo seguro a partir del título del cuaderno.
  String _safeName(String title) {
    final clean = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return clean.isEmpty ? 'inklus_cuaderno' : clean;
  }

  Future<void> _export(
    Future<Uint8List> Function() render,
    String fileName,
  ) async {
    // Previsualización: renderizar primero y mostrar antes de guardar.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await render();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // Mostrar previsualización si es imagen (PNG).
      if (fileName.endsWith('.png')) {
        final shouldSave = await _showPreviewDialog(bytes, fileName);
        if (shouldSave != true) return;
      }

      await _saveBytes(bytes, fileName);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack('Error al exportar: $e');
    }
  }

  /// Diálogo de previsualización para exportaciones de imagen.
  Future<bool?> _showPreviewDialog(Uint8List bytes, String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Previsualización: $fileName'),
        content: SingleChildScrollView(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBytes(Uint8List bytes, String fileName) async {
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Guardar $fileName',
        fileName: fileName,
        bytes: bytes,
      );
      if (saved != null) {
        _snack('Exportado: ${saved.path}');
      }
    } catch (_) {
      // Fallback: carpeta de datos de la app.
      try {
        final dir = await getApplicationSupportDirectory();
        final folder = Directory('${dir.path}/inklus/exports');
        await folder.create(recursive: true);
        final file = File('${folder.path}/$fileName');
        await file.writeAsBytes(bytes);
        _snack('Exportado: ${file.path}');
      } catch (e) {
        _snack('No se pudo guardar el archivo: $e');
      }
    }
  }

  // -------------------------------------------------------------------------
  // Compartir (share_plus)
  // -------------------------------------------------------------------------

  Future<void> _sharePng() async {
    try {
      final bytes = await ExportService.renderPagePng(
        _c.page,
        sheetSize: _c.sheetSize,
        imageCache: _imageService.cache,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inklus_pagina_${_c.pageIndex + 1}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Página de Inklus'));
    } catch (e) {
      _snack('Error al compartir: $e');
    }
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await ExportService.renderPagePdf(
        _c.page,
        sheetSize: _c.sheetSize,
        imageCache: _imageService.cache,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inklus_pagina_${_c.pageIndex + 1}.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Página de Inklus'));
    } catch (e) {
      _snack('Error al compartir: $e');
    }
  }

  Future<void> _shareInklus() async {
    try {
      final bytes = await InklusFormat.exportBytes(_c.document);
      final dir = await getTemporaryDirectory();
      final name = '${_safeName(_c.document.title)}.inklus';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Cuaderno de Inklus'));
    } catch (e) {
      _snack('Error al compartir: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Sync / Drive
  // -------------------------------------------------------------------------

  /// Botón ☁️: inicia sesión o muestra el menú de Drive.
  Future<void> _syncPressed() async {
    if (_syncing) return;

    if (!_syncService.isSignedIn) {
      await _signInAndBackup();
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(_syncService.email ?? 'Cuenta Google'),
              subtitle: const Text('Sincronizado con la nube'),
              dense: true,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Subir ahora'),
              onTap: () => Navigator.pop(context, 'upload'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restaurar desde la nube'),
              subtitle: const Text('Última versión (last-write-wins)'),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ver versiones en Drive'),
              onTap: () => Navigator.pop(context, 'versions'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Subir archivo .inklus'),
              onTap: () => Navigator.pop(context, 'uploadFile'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(_syncEnabledForCurrent
                  ? 'Sync: activada para este cuaderno'
                  : 'Sync: desactivada para este cuaderno'),
              onTap: () => Navigator.pop(context, 'toggleSync'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: const Text('Cambiar de cuenta'),
              onTap: () => Navigator.pop(context, 'switchAccount'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => Navigator.pop(context, 'signout'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'upload':
        await _backupNow();
      case 'restore':
        await _restoreFromCloud();
      case 'versions':
        await _showVersions();
      case 'uploadFile':
        await _uploadInklusFile();
      case 'toggleSync':
        await _toggleSyncForCurrent();
      case 'switchAccount':
        await _switchAccount();
      case 'signout':
        await _syncService.signOut();
        if (mounted) _snack('Sesión cerrada');
    }
  }

  bool _syncEnabledForCurrent = true;

  Future<void> _loadSyncEnabled() async {
    final metas = await _storage.loadIndex();
    // A8: syncEnabled está en el NotebookMeta, no en el Note.
    final meta = metas.where((m) => m.id == widget.notebookId).firstOrNull;
    if (meta != null && mounted) {
      setState(() => _syncEnabledForCurrent = meta.isSyncEnabled);
    }
  }

  Future<void> _toggleSyncForCurrent() async {
    final currentEnabled = _syncEnabledForCurrent;
    // A8: syncEnabled es a nivel de Notebook, no de Note.
    await _storage.setSyncEnabled(widget.notebookId, !currentEnabled);
    await _loadSyncEnabled();
    if (mounted) {
      _snack(currentEnabled
          ? 'Sync desactivada para este cuaderno'
          : 'Sync activada para este cuaderno');
    }
  }

  Future<void> _signInAndBackup() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.signIn();
      if (!ok) return;
      if (mounted) _snack('Conectado como ${_syncService.email}');
      await _backupNow();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _backupNow() async {
    setState(() => _syncing = true);
    try {
      // A8: backup individual por Note (no el Document completo).
      await _syncService.backupNote(
        _c.note,
        promptForConsent: true,
      );
      if (mounted) _snack('Nota sincronizada con Google Drive');
    } catch (e) {
      if (mounted) _snack('Error al subir: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _syncing = true);
    try {
      // Pedir contraseña si el usuario quiere descifrar.
      final password = await _promptPassword(
        titulo: 'Restaurar desde Drive',
        hint: 'Contraseña (dejar vacío si no está cifrado)',
      );
      // A8: restore individual por Note (no el Document completo).
      final restored = await _syncService.restoreNote(
        noteId: _c.note.id,
        password: password?.isEmpty == true ? null : password,
      );
      if (!mounted) return;
      if (restored == null) {
        _snack('Todavía no hay ninguna copia de esta nota en Google Drive');
      } else {
        _c.replaceNote(restored, notebookId: widget.notebookId);
        // Persistir la nota restaurada en disco local.
        await _storage.saveNote(widget.notebookId, restored);
        _snack('Nota restaurada desde Google Drive');
      }
    } catch (e) {
      if (mounted) _snack('Error al restaurar: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Muestra un diálogo de resolución de versiones cuando hay múltiples
  /// copias de una nota en Drive.
  Future<void> _showConflictResolution(List<DriveVersion> versions) async {
    if (!mounted) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Versiones disponibles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se encontraron múltiples copias en Google Drive. '
              'Selecciona la que quieres restaurar:',
            ),
            const SizedBox(height: 12),
            ...versions.map((v) {
              final t = v.modifiedTime.toLocal();
              String two(int n) => n.toString().padLeft(2, '0');
              final dateStr = '${two(t.day)}/${two(t.month)}/${t.year} '
                  '${two(t.hour)}:${two(t.minute)}';
              final sizeKb = (v.sizeBytes / 1024).round();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(v.name),
                  subtitle: Text('$dateStr · $sizeKb KB'),
                  onTap: () => Navigator.pop(context, v.fileId),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (chosen != null && mounted) {
      final password = await _promptPassword(
        titulo: 'Descifrar versión',
        hint: 'Contraseña (dejar vacío si no está cifrado)',
      );
      final doc = await _syncService.downloadVersion(
        chosen,
        password: password?.isEmpty == true ? null : password,
      );
      if (doc != null && mounted) {
        _c.replaceNote(
          Note(
            id: doc.id,
            title: doc.title,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt,
            pages: doc.pages,
          ),
          notebookId: widget.notebookId,
        );
        _snack('Versión restaurada');
      }
    }
  }

  /// Muestra la lista de versiones de la nota actual en Drive y deja elegir.
  Future<void> _showVersions() async {
    setState(() => _syncing = true);
    try {
      // A8: filtrar versiones por el id de la nota actual.
      final versions = await _syncService.listVersions(noteId: _c.note.id);
      if (!mounted) return;
      if (versions.isEmpty) {
        _snack('No hay versiones de esta nota en Google Drive');
        return;
      }
      if (versions.length == 1) {
        // Solo una versión: restaurar directamente.
        final password = await _promptPassword(
          titulo: 'Descifrar versión',
          hint: 'Contraseña (dejar vacío si no está cifrado)',
        );
        final doc = await _syncService.downloadVersion(
          versions.first.fileId,
          password: password?.isEmpty == true ? null : password,
        );
        if (!mounted) return;
        if (doc == null) {
          _snack('No se pudo leer esa versión');
        } else {
          _c.replaceNote(
            Note(
              id: doc.id,
              title: doc.title,
              createdAt: doc.createdAt,
              updatedAt: doc.updatedAt,
              pages: doc.pages,
            ),
            notebookId: widget.notebookId,
          );
          _snack('Versión restaurada');
        }
      } else {
        // Múltiples versiones: mostrar diálogo de selección.
        await _showConflictResolution(versions);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Sube un archivo .inklus manual a Drive.
  Future<void> _uploadInklusFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['inklus'],
      );
      if (files.isEmpty) return;
      final filePath = files.first.path!;
      final bytes = await File(filePath).readAsBytes();
      final name = files.first.name;
      setState(() => _syncing = true);
      await _syncService.uploadInklusFile(bytes, name, promptForConsent: true);
      if (mounted) _snack('Archivo "$name" subido a Google Drive');
    } catch (e) {
      if (mounted) _snack('Error al subir: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _switchAccount() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.switchAccount();
      if (ok && mounted) {
        _snack('Conectado como ${_syncService.email}');
      }
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Pide una contraseña al usuario (para cifrado/descifrado).
  Future<String?> _promptPassword({
    required String titulo,
    required String hint,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Sin contraseña'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _c.document.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Título del cuaderno'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      _c.setTitle(result.trim());
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onMenuAction(String v) {
    switch (v) {
      case 'png':
        _exportPng();
      case 'pdf':
        _exportPdf();
      case 'pdfAll':
        _exportNotebookPdf();
      case 'pptx':
        _exportPptx();
      case 'inklus':
        _exportInklusCopy();
      case 'svg':
        _exportSvg();
      case 'ocr':
        _recognizeText();
      case 'sharePng':
        _sharePng();
      case 'sharePdf':
        _sharePdf();
      case 'shareInklus':
        _shareInklus();
      case 'clear':
        _confirmClearPage();
      case 'backup':
        _exportFullBackup();
      case 'restoreBackup':
        _importFullBackup();
      case 'haptics':
        _c.setHapticEnabled(!_c.hapticEnabled);
        HapticFeedback.mediumImpact();
      case 'present':
        _c.togglePresentationMode();
      case 'nightMode':
        _toggleNightMode();
      case 'importPdf':
        _importPdfAsBackground();
      case 'versions':
        _showVersionHistory();
      case 'reminder':
        _createReminder();
      case 'stats':
        _openStats();
      case 'searchContent':
        _searchContent();
    }
  }

  // --- Modo nocturno de escritura ---
  bool _nightMode = false;

  void _toggleNightMode() {
    setState(() => _nightMode = !_nightMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_nightMode ? 'Modo nocturno activado' : 'Modo nocturno desactivado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // --- Importar PDF como fondo (C7) ---
  Future<void> _importPdfAsBackground() async {
    if (!PdfImportService.isSupported) {
      _snack('Importación de PDF solo disponible en Android/iOS');
      return;
    }
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.path == null) return;

      // Renderizar la primera página del PDF como imagen.
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final pngBytes = await PdfImportService.renderFirstPage(result.path!);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (pngBytes == null) {
        _snack('No se pudo renderizar el PDF');
        return;
      }

      // Guardar la imagen renderizada en la carpeta de la app.
      final localPath = await PdfImportService.saveRenderedPage(
        pngBytes,
        name: 'pdf_bg_${_c.note.id}.png',
      );
      if (localPath == null) {
        _snack('Error al guardar la imagen del PDF');
        return;
      }

      // Cachear la imagen y usarla como plantilla custom con relleno infinito.
      final image = await _imageService.decode(localPath);
      _imageService.cache[localPath] = image;

      final w = image.width.toDouble();
      final h = image.height.toDouble();
      _c.setTemplate(PageTemplate(
        type: TemplateType.custom,
        imagePath: localPath,
        infiniteFill: true,
        customWidth: w,
        customHeight: h,
      ));
      _c.fitView(_c.viewportSize);
      _snack('PDF importado como plantilla de fondo');
    } catch (e) {
      if (mounted) {
        _snack('Error al importar PDF: $e');
      }
    }
  }

  // --- Historial de versiones local ---
  void _showVersionHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial de versiones: próximamente')),
    );
  }

  // --- Exportar a PowerPoint (.pptx) ---
  Future<void> _exportPptx() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await ExportService.renderNotebookPptx(
        _c.document,
        imageCache: _imageService.cache,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _saveBytes(bytes, '${_safeName(_c.document.title)}.pptx');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack('Error al exportar PowerPoint: $e');
    }
  }

  // --- Recordatorio ---
  Future<void> _createReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    final dateTime = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    await _reminders.create(
      documentId: _c.document.id,
      documentTitle: _c.document.title,
      dateTime: dateTime,
    );
    _snack('Recordatorio creado para ${date.day}/${date.month} a las ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  // --- Estadísticas ---
  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WritingStatsScreen()),
    );
  }

  // --- Búsqueda en contenido ---
  Future<void> _searchContent() async {
    // Indexar el documento actual.
    await _search.indexTextItems(_c.document);
    if (!mounted) return;
    final controller = TextEditingController();
    final results = await showDialog<List<SearchResult>>(
      context: context,
      builder: (context) => _SearchDialog(
        searchService: _search,
        controller: controller,
      ),
    );
    if (results != null && results.isNotEmpty) {
      _snack('${results.length} resultado(s) encontrado(s)');
    }
  }

  // --- Respaldo local completo ---

  Future<void> _exportFullBackup() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await _storage.exportFullBackup();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _saveBytes(bytes, 'inklus_respaldo_completo.zip');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack('Error al exportar respaldo: $e');
    }
  }

  Future<void> _importFullBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (files.isEmpty) return;
      final filePath = files.first.path!;
      final bytes = await File(filePath).readAsBytes();
      final count = await _storage.importFullBackup(bytes);
      if (!mounted) return;
      _snack('Respaldo importado: $count cuaderno(s)');
    } catch (e) {
      if (mounted) _snack('Error al importar respaldo: $e');
    }
  }

  // -------------------------------------------------------------------------
  // UI
  @override
  void dispose() {
    // Guardar estadísticas de sesión.
    if (_sessionStart != null) {
      final minutes = DateTime.now().difference(_sessionStart!).inMinutes;
      if (minutes > 0) _stats.recordActivity(minutes: minutes);
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final presentMode = controller.presentationMode;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1A1B1E) : const Color(0xFFEFEDE8),
          body: SafeArea(
            child: Column(
              children: [
                if (!presentMode) _buildTopBar(context),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!presentMode)
                        ToolRail(
                          controller: controller,
                          collapsed: _toolRailCollapsed,
                          onToggleCollapsed: () => setState(() => _toolRailCollapsed = !_toolRailCollapsed),
                          onInsertImage: _insertImages,
                          onTemplates: () => showTemplatePicker(
                            context,
                            controller: controller,
                            imageService: _imageService,
                            templateLibrary: _templateLibrary,
                          ),
                          onLayers: () => setState(() {
                            _layersSidebarOpen = !_layersSidebarOpen;
                          }),
                          layersSidebarOpen: _layersSidebarOpen,
                        ),
                      if (_layersSidebarOpen && !presentMode)
                        LayersSidebar(
                          controller: controller,
                          onClose: () => setState(() => _layersSidebarOpen = false),
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DrawingCanvas(
                                controller: controller,
                                imageService: _imageService,
                              ),
                            ),
                            if (controller.selectedImageId != null &&
                                !presentMode)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: FloatingActionButton.small(
                                  heroTag: 'deleteImage',
                                  backgroundColor: Colors.white,
                                  onPressed: _deleteSelectedImage,
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ),
                            if (!presentMode)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: _ZoomControls(controller: controller),
                              ),
                            if (!presentMode && !controller.sheetSize.isEmpty)
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: MinimapWidget(controller: controller),
                              ),
                            if (presentMode)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: GestureDetector(
                                  onTap: controller.togglePresentationMode,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_exit,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!presentMode && _thumbnailsOpen)
                  PageThumbnailsStrip(
                    controller: controller,
                    imageService: _imageService,
                    onToggle: () => setState(() => _thumbnailsOpen = !_thumbnailsOpen),
                  ),
                if (!presentMode && !_thumbnailsOpen)
                  GestureDetector(
                    onTap: () => setState(() => _thumbnailsOpen = true),
                    child: Container(
                      height: 28,
                      color: isDark ? kSurfaceDark : Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_arrow_up, size: 18, color: isDark ? Colors.white54 : ThemeColors.of(context).iconTertiary),
                          Text('Páginas', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : ThemeColors.of(context).iconTertiary)),
                        ],
                      ),
                    ),
                  ),
                if (!presentMode)
                  BottomBar(
                    controller: controller,
                    onStrokeOptions: () => showStrokeOptionsSheet(
                      context,
                      controller: controller,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final controller = _c;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, _syncService]),
      builder: (context, _) {
        // Icono de sync según el estado del cuaderno actual.
        final syncStatus = _syncService.statusFor(controller.document.id);
        IconData cloudIcon;
        Color? cloudColor;
        String syncTooltip;

        if (_syncing) {
          cloudIcon = Icons.sync;
          cloudColor = null;
          syncTooltip = 'Sincronizando...';
        } else if (!_syncService.isSignedIn) {
          cloudIcon = Icons.cloud_upload_outlined;
          cloudColor = null;
          syncTooltip = 'Sincronizar con Google';
        } else {
          switch (syncStatus) {
            case SyncStatus.synced:
              cloudIcon = Icons.cloud_done;
              cloudColor = kAccentColor;
              syncTooltip = 'Sincronizado con Google';
            case SyncStatus.syncing:
              cloudIcon = Icons.sync;
              cloudColor = null;
              syncTooltip = 'Sincronizando...';
            case SyncStatus.error:
              cloudIcon = Icons.cloud_off;
              cloudColor = const Color(0xFFE53935);
              syncTooltip = 'Error de sincronización';
            case SyncStatus.disabled:
              cloudIcon = Icons.cloud_queue;
              cloudColor = ThemeColors.of(context).iconTertiary;
              syncTooltip = 'Sync desactivada para este cuaderno';
            case SyncStatus.pending:
              cloudIcon = Icons.cloud_upload_outlined;
              cloudColor = null;
              syncTooltip = 'Sincronizar con Google';
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: isDark ? kSurfaceDark : Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Volver a la biblioteca',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
                const Icon(Icons.edit, color: kAccentColor),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _editTitle,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      controller.document.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Página anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: controller.pageIndex > 0
                      ? () => controller.goToPage(controller.pageIndex - 1)
                      : null,
                ),
                Text(
                  '${controller.pageIndex + 1} / ${controller.pageCount}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  tooltip: 'Página siguiente',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: controller.pageIndex < controller.pageCount - 1
                      ? () => controller.goToPage(controller.pageIndex + 1)
                      : null,
                ),
                IconButton(
                  tooltip: 'Nueva página',
                  icon: const Icon(Icons.add),
                  onPressed: controller.addPage,
                ),
                IconButton(
                  tooltip: 'Eliminar página',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: controller.pageCount > 1
                      ? () => _confirmDeletePage()
                      : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Deshacer',
                  icon: const Icon(Icons.undo),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                IconButton(
                  tooltip: 'Rehacer',
                  icon: const Icon(Icons.redo),
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                IconButton(
                  tooltip: syncTooltip,
                  icon: _syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(cloudIcon, color: cloudColor),
                  onPressed: _syncing ? null : _syncPressed,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: _onMenuAction,
                  itemBuilder: (context) => [
                    // --- Exportar ---
                    const PopupMenuItem(
                      value: 'png',
                      child: ListTile(
                        leading: Icon(Icons.image_outlined),
                        title: Text('Exportar página (PNG)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf_outlined),
                        title: Text('Exportar página (PDF)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pdfAll',
                      child: ListTile(
                        leading: Icon(Icons.menu_book_outlined),
                        title: Text('Exportar cuaderno (PDF)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'inklus',
                      child: ListTile(
                        leading: Icon(Icons.save_alt),
                        title: Text('Guardar copia (.inklus)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'svg',
                      child: ListTile(
                        leading: Icon(Icons.code_outlined),
                        title: Text('Exportar trazos (SVG)'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'ocr',
                      enabled: OcrService.isSupported,
                      child: ListTile(
                        leading: Icon(Icons.text_snippet_outlined),
                        title: Text(OcrService.isSupported
                            ? 'Reconocer texto (OCR)'
                            : 'OCR (solo Android/iOS)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    // --- Compartir ---
                    const PopupMenuItem(
                      value: 'sharePng',
                      child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Compartir página (PNG)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sharePdf',
                      child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Compartir página (PDF)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'shareInklus',
                      child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Compartir cuaderno (.inklus)'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                        leading: Icon(Icons.cleaning_services_outlined),
                        title: Text('Limpiar página'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'backup',
                      child: ListTile(
                        leading: Icon(Icons.backup_outlined),
                        title: Text('Exportar respaldo completo'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restoreBackup',
                      child: ListTile(
                        leading: Icon(Icons.restore_outlined),
                        title: Text('Importar respaldo completo'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'haptics',
                      child: ListTile(
                        leading: Icon(_c.hapticEnabled
                            ? Icons.vibration
                            : Icons.vibration_outlined),
                        title: Text(_c.hapticEnabled
                            ? 'Vibración: activada'
                            : 'Vibración: desactivada'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'present',
                      child: ListTile(
                        leading: Icon(_c.presentationMode
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen),
                        title: Text(_c.presentationMode
                            ? 'Salir de presentación'
                            : 'Modo presentación'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'nightMode',
                      child: ListTile(
                        leading: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Modo nocturno de escritura'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'importPdf',
                      child: const ListTile(
                        leading: Icon(Icons.picture_as_pdf_outlined),
                        title: Text('Importar PDF como fondo'),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'versions',
                      child: const ListTile(
                        leading: Icon(Icons.history),
                        title: Text('Historial de versiones'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    // --- Herramientas de calidad de vida ---
                    const PopupMenuItem(
                      value: 'pptx',
                      child: ListTile(
                        leading: Icon(Icons.slideshow_outlined),
                        title: Text('Exportar como PowerPoint'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reminder',
                      child: ListTile(
                        leading: Icon(Icons.alarm_add_outlined),
                        title: Text('Crear recordatorio'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: ListTile(
                        leading: Icon(Icons.analytics_outlined),
                        title: Text('Estadísticas de escritura'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'searchContent',
                      child: ListTile(
                        leading: Icon(Icons.search),
                        title: Text('Buscar en contenido'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Guarda el último cambio pendiente y vuelve a la biblioteca.
  Future<void> _goBack() async {
    await _controller.saveNow();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _confirmDeletePage() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar página'),
        content: const Text(
          'Se borrarán todos los trazos e imágenes de esta página. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) _c.deleteCurrentPage();
  }

  Future<void> _confirmClearPage() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar página'),
        content: const Text('Se borrará todo el contenido de la página.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (ok == true) _c.clearPage();
  }
}

/// Controles flotantes de zoom sobre el lienzo.
class _ZoomControls extends StatelessWidget {
  final CanvasController controller;

  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final center = Offset(
          controller.viewportSize.width / 2,
          controller.viewportSize.height / 2,
        );
        return Material(
          color: isDark ? kSurfaceDark : Colors.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Acercar',
                  icon: const Icon(Icons.add),
                  onPressed: () => controller.zoomAt(
                      1.25, center, controller.viewportSize),
                ),
                Text(
                  '${(controller.scale * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : ThemeColors.of(context).textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Alejar',
                  icon: const Icon(Icons.remove),
                  onPressed: () => controller.zoomAt(
                      0.8, center, controller.viewportSize),
                ),
                const Divider(height: 4),
                IconButton(
                  tooltip: 'Ajustar a la vista',
                  icon: const Icon(Icons.fit_screen_outlined),
                  onPressed: () =>
                      controller.fitView(controller.viewportSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Diálogo de búsqueda en contenido del cuaderno.
class _SearchDialog extends StatefulWidget {
  final SearchService searchService;
  final TextEditingController controller;

  const _SearchDialog({
    required this.searchService,
    required this.controller,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_search);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_search);
    super.dispose();
  }

  void _search() {
    setState(() {
      _results = widget.searchService.search(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar en contenido'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: widget.controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar texto...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_results.length} resultado(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        widget.controller.text.isEmpty
                            ? 'Escribe para buscar...'
                            : 'Sin resultados',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              r.documentTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...r.matches.map((m) => Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Pág. ${m.pageIndex + 1}: ${m.matchedText}',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
