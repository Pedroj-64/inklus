import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../logic/canvas_controller.dart';
import '../models/document.dart';
import '../models/id.dart';
import '../models/image_item.dart';
import '../models/stroke.dart';
import '../services/drive_sync_service.dart';
import '../services/export_service.dart';
import '../services/image_service.dart';
import '../services/inklus_format.dart';
import '../services/storage_service.dart';
import 'canvas/drawing_canvas.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/minimap.dart';
import 'widgets/page_thumbnails.dart';
import 'widgets/template_picker_sheet.dart';
import 'widgets/tool_rail.dart';

/// Editor de un cuaderno (pantalla principal de escritura).
///
/// Recibe el [document] ya cargado desde la biblioteca ([NotebookLibraryScreen])
/// y crea su [CanvasController] al montarse.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.document});

  final Document document;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ImageService _imageService = ImageService();
  final DriveSyncService _syncService = DriveSyncService.instance;
  late final CanvasController _controller;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(_storage, initial: widget.document);
    // Replica automática a Drive en cada guardado local (solo si hay sesión
    // y el scope ya está autorizado; nunca muestra UI).
    _controller.onRemoteSync = (document) async {
      if (!_syncService.isSignedIn) return;
      try {
        await _syncService.backupDocument(document);
      } catch (_) {
        // Silencioso: el guardado local ya protege los datos.
      }
    };
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
        // Ancho máximo razonable para empezar (se puede redimensionar).
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
      // Cambia a la herramienta de selección para poder moverlas.
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

  Future<void> _exportPng() => _export(() => ExportService.renderPagePng(
        _c.page,
        sheetSize: _c.sheetSize,
        imageCache: _imageService.cache,
      ), 'inklus_pagina_${_c.pageIndex + 1}.png');

  Future<void> _exportPdf() => _export(() => ExportService.renderPagePdf(
        _c.page,
        sheetSize: _c.sheetSize,
        imageCache: _imageService.cache,
      ), 'inklus_pagina_${_c.pageIndex + 1}.pdf');

  /// Exporta todas las páginas del cuaderno a un único PDF.
  Future<void> _exportNotebookPdf() => _export(
        () => ExportService.renderNotebookPdf(
          _c.document,
          imageCache: _imageService.cache,
        ),
        '${_safeName(_c.document.title)}.pdf',
      );

  /// Guarda una copia del cuaderno en formato propio .inklus (autocontenido:
  /// documento + imágenes embebidas; se puede reimportar o subir a Drive).
  Future<void> _exportInklusCopy() => _export(
        () => InklusFormat.exportBytes(_c.document),
        '${_safeName(_c.document.title)}.inklus',
      );

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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await render();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _saveBytes(bytes, fileName);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack('Error al exportar: $e');
    }
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
              onTap: () => Navigator.pop(context, 'restore'),
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
      case 'signout':
        await _syncService.signOut();
        if (mounted) _snack('Sesión cerrada');
    }
  }

  Future<void> _signInAndBackup() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.signIn();
      if (!ok) return; // usuario canceló el diálogo de Google
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
      // Acción explícita del usuario: fuerza el consentimiento si hace falta.
      await _syncService.backupDocument(
        _c.document,
        promptForConsent: true,
      );
      if (mounted) _snack('Cuaderno subido a Google Drive');
    } catch (e) {
      if (mounted) _snack('Error al subir: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _syncing = true);
    try {
      final doc = await _syncService.restoreDocument();
      if (!mounted) return;
      if (doc == null) {
        _snack('Todavía no hay ninguna copia en Google Drive');
      } else {
        _c.replaceDocument(doc);
        _snack('Cuaderno restaurado desde Google Drive');
      }
    } catch (e) {
      if (mounted) _snack('Error al restaurar: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
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
      case 'inklus':
        _exportInklusCopy();
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
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final presentMode = controller.presentationMode;
        return Scaffold(
          backgroundColor: const Color(0xFFEFEDE8),
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
                          onInsertImage: _insertImages,
                          onTemplates: () => showTemplatePicker(
                            context,
                            controller: controller,
                            imageService: _imageService,
                          ),
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
                            if (controller.selectedImageId != null && !presentMode)
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
                            // Minimapa en lienzos infinitos
                            if (!presentMode && !controller.sheetSize.isEmpty)
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: MinimapWidget(controller: controller),
                              ),
                            // Botón salir de presentación
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
                if (!presentMode)
                  PageThumbnailsStrip(
                    controller: controller,
                    imageService: _imageService,
                  ),
                if (!presentMode) BottomBar(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final controller = _c;
    // Escucha al controlador (título, páginas…) y al servicio de sync
    // (icono ☁️ cambia al iniciar/cerrar sesión).
    return ListenableBuilder(
      listenable: Listenable.merge([controller, _syncService]),
      builder: (context, _) {
        return Material(
          color: Colors.white,
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
                const Icon(Icons.edit, color: Color(0xFF3B82F6)),
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
                  tooltip: _syncService.isSignedIn
                      ? 'Sincronizado con Google (${_syncService.email})'
                      : 'Sincronizar con Google',
                  icon: _syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _syncService.isSignedIn
                              ? Icons.cloud_done
                              : Icons.cloud_upload_outlined,
                          color: _syncService.isSignedIn
                              ? const Color(0xFF3B82F6)
                              : null,
                        ),
                  onPressed: _syncing ? null : _syncPressed,
                ),                  PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: _onMenuAction,
                  itemBuilder: (context) => [
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
        final center = Offset(
          controller.viewportSize.width / 2,
          controller.viewportSize.height / 2,
        );
        return Material(
          color: Colors.white,
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
                  onPressed: () => controller.zoomAt(1.25, center, controller.viewportSize),
                ),
                Text(
                  '${(controller.scale * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Alejar',
                  icon: const Icon(Icons.remove),
                  onPressed: () => controller.zoomAt(0.8, center, controller.viewportSize),
                ),
                const Divider(height: 4),
                IconButton(
                  tooltip: 'Ajustar a la vista',
                  icon: const Icon(Icons.fit_screen_outlined),
                  onPressed: () => controller.fitView(controller.viewportSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
