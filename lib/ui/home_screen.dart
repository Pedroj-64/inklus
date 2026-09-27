// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/canvas_controller.dart';
import '../models/note.dart';
import '../models/id.dart';
import '../models/image_item.dart';
import '../models/stroke.dart';
import '../services/drive_sync_service.dart';
import '../services/export_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_import_service.dart';
import '../models/page.dart' as model show Page;
import '../services/image_service.dart';
import '../services/import_service.dart';
import '../services/inklus_format.dart';
import '../services/storage_service.dart';
import '../services/template_library_service.dart';
import '../services/writing_stats_service.dart';
import '../services/reminder_service.dart';
import '../services/search_service.dart';
import '../services/version_history_service.dart';
import '../logic/pen_presets.dart';
import 'canvas/drawing_canvas.dart';
import 'editor/version_history_sheet.dart';
import 'editor/editor_toolbar.dart';
import 'editor/pages_panel.dart';
import 'editor/selection_bar.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/controller_selector.dart';
import 'widgets/dialogs.dart';
import 'widgets/layers_sidebar.dart';
import 'widgets/search_sheet.dart';
import 'widgets/template_picker_sheet.dart';
import 'settings_screen.dart';
import 'writing_stats_screen.dart';
import '../services/marketplace/marketplace_service.dart';
import 'marketplace_screen.dart';
import '../services/app_paths.dart';

/// Editor de un cuaderno (pantalla principal de escritura).
///
/// Recibe un [note] ya cargado desde la lista de notas ([NoteListScreen])
/// y crea su [CanvasController] al montarse.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.note,
    required this.notebookId,
    this.initialPage = 0,
  });

  final Note note;
  final String notebookId;

  /// Página a mostrar al abrir (p. ej. desde un resultado de búsqueda).
  final int initialPage;

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
  final SearchService _search = SearchService.instance;
  final VersionHistoryService _versions = VersionHistoryService();
  late final CanvasController _controller;
  /// Plumas favoritas (color y grosor propios por pluma, persistentes).
  final PenPresetsController _presets = PenPresetsController();
  bool _syncing = false;
  bool _layersSidebarOpen = false;

  /// Panel lateral de páginas: cerrado por defecto (más lienzo); se recuerda.
  bool _pagesOpen = false;
  static const _prefPagesPanel = 'pages_panel_open';

  Future<void> _loadPagesPanelPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_prefPagesPanel) ?? false;
      if (mounted && v != _pagesOpen) setState(() => _pagesOpen = v);
    } catch (_) {}
  }

  void _setPagesOpen(bool open) {
    setState(() => _pagesOpen = open);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_prefPagesPanel, open))
        .catchError((_) => false);
  }

  /// Lleva al preset activo los cambios de color/grosor/pluma del lienzo.
  void _syncPresets() => _presets.syncFrom(_controller);
  DateTime? _sessionStart;
  /// `updatedAt` al abrir (el Note se muta en sitio: hay que copiarlo ya).
  late final DateTime _openedAt;

  @override
  void initState() {
    super.initState();
    _templateLibrary.init();
    _stats.load();
    _reminders.load();
    // Índice de búsqueda: al abrir se indexa el texto actual de la nota.
    _search.indexNote(widget.notebookId, widget.note);
    _sessionStart = DateTime.now();
    _openedAt = widget.note.updatedAt;
    _controller = CanvasController(
      _storage,
      initial: widget.note,
      notebookId: widget.notebookId,
    );
    // Replica automática a Drive en cada guardado local (solo si hay sesión
    // y el scope ya está autorizado; nunca muestra UI).
    // A8: ahora se sincroniza cada Note individualmente (no el Document).
    _controller.onNotice = (msg) {
      if (mounted) _snack(msg);
    };
    _controller.onUndoableNotice = (msg, undo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          action: SnackBarAction(label: 'Deshacer', onPressed: undo),
        ));
    };
    _controller.onLayerBlocked = () {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Capa bloqueada — desbloquea para editar'),
              duration: Duration(milliseconds: 1500),
            ),
          );
      }
    };
    // El guardado local ocurre cada ~600 ms; subir a Drive con esa
    // frecuencia es tráfico inútil. Se agrupa: como mucho una subida cada
    // [_remoteSyncDelay], y otra al salir del editor si quedó algo pendiente.
    _controller.onRemoteSync = (_) async {
      _remoteSyncPending = true;
      _remoteSyncTimer ??= Timer(_remoteSyncDelay, _runRemoteSync);
    };
    // Notificación de sync completado.
    _syncService.onSyncComplete = _onSyncComplete;
    _topBarListenable = Listenable.merge([_controller, _syncService]);
    _loadSyncEnabled();
    _loadNightMode();
    _loadPagesPanelPref();
    if (widget.initialPage > 0) _controller.goToPage(widget.initialPage);
    // Plumas favoritas: al cargar, aplicar la activa al lienzo y desde ahí
    // mantenerlas sincronizadas con lo que el usuario cambie.
    _presets.load().then((_) {
      if (!mounted) return;
      _presets.activate(_presets.activeSlot, _controller);
      _controller.bottomBarContextNotifier.addListener(_syncPresets);
    });
    // Historial local: instantánea del estado al abrir (así siempre se puede
    // volver a como estaba antes de esta sesión).
    unawaited(_versions.snapshot(widget.note));
  }

  static const _remoteSyncDelay = Duration(seconds: 20);
  Timer? _remoteSyncTimer;
  bool _remoteSyncPending = false;
  late final Listenable _topBarListenable;

  void _onSyncComplete(String msg) {
    if (mounted) _snack(msg);
  }

  /// Sube la nota a Drive si hay sesión y el cuaderno tiene sync activa.
  /// Silencioso: el guardado local ya protege los datos.
  Future<void> _runRemoteSync() async {
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = null;
    if (!_remoteSyncPending) return;
    _remoteSyncPending = false;
    if (!_syncService.isSignedIn) return;
    try {
      // Sync selectiva: solo subir si el notebook lo tiene habilitado.
      final metas = await _storage.loadIndex();
      final meta = metas.where((m) => m.id == widget.notebookId).firstOrNull;
      if (meta != null && !meta.isSyncEnabled) return;
      await _syncService.backupNote(_controller.note);
    } catch (e) {
      debugPrint('HomeScreen: sync automático falló: $e');
    }
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

  /// Imágenes de [page] a la resolución de la exportación (ver
  /// [ImageService.imagesForExport]).
  Future<Map<String, ui.Image>> _exportImages(
    model.Page page, [
    int maxDimension = kCanvasImageMaxSide,
  ]) =>
      _imageService.imagesForExport([page], maxDimension: maxDimension);

  Future<void> _exportPng() => _exportWithOptions(
        (opts) async => ExportService.renderPagePng(
          _c.page,
          sheetSize: _c.sheetSize,
          imageCache: await _exportImages(_c.page, opts.maxDimension),
          options: opts,
        ),
        'inklus_pagina_${_c.pageIndex + 1}.png',
        showStrokesOnly: true,
      );

  Future<void> _exportPdf() => _exportWithOptions(
        (opts) async => ExportService.renderPagePdf(
          _c.page,
          sheetSize: _c.sheetSize,
          imageCache: await _exportImages(_c.page, opts.maxDimension),
          options: opts,
        ),
        'inklus_pagina_${_c.pageIndex + 1}.pdf',
        showStrokesOnly: true,
      );

  Future<void> _exportNotebookPdf() => _exportWithOptions(
        (opts) => ExportService.renderNotebookPdf(
          _c.note,
          imageCache: _imageService.cache,
          imagesFor: (page) => _exportImages(page, opts.maxDimension),
          options: opts,
        ),
        '${_safeName(_c.note.title)}.pdf',
        showStrokesOnly: true,
      );

  Future<void> _exportInklusCopy() => _export(
        () async {
          final nb = await _storage.loadNotebook(widget.notebookId);
          if (nb != null) return InklusFormat.exportNotebookBytes(nb);
          // Fallback: exportar solo el note actual.
          return InklusFormat.exportNoteBytes(_c.note);
        },
        '${_safeName(_c.note.title)}.inklus',
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
  ///
  /// Usa digital ink recognition (trazos vectoriales) como estrategia
  /// principal, con fallback a bitmap si no hay trazos.
  Future<void> _recognizeText() async {
    if (!OcrService.isSupported) {
      _snack('OCR solo está disponible en Android e iOS');
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: Spacing.lg),
                Text('Reconociendo texto…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final result = await OcrService.recognizeSmart(
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
      // Lo reconocido queda buscable.
      unawaited(_search.setHandwriting(_c.note.id, _c.page.id, result.text));

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
    try {
      final bytes = await runWithLoading(context, render);
      if (!mounted) return;

      // Mostrar previsualización si es imagen (PNG).
      if (fileName.endsWith('.png')) {
        final shouldSave = await _showPreviewDialog(bytes, fileName);
        if (shouldSave != true) return;
      }

      await _saveBytes(bytes, fileName);
    } catch (e) {
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
        final folder = await AppPaths.exports();
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
        imageCache: await _exportImages(_c.page),
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
        imageCache: await _exportImages(_c.page),
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
      final bytes = await InklusFormat.exportNoteBytes(_c.note);
      final dir = await getTemporaryDirectory();
      final name = '${_safeName(_c.note.title)}.inklus';
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
        await _showVersionHistory();
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
        await _storage.saveNote(widget.notebookId, restored, touch: false);
        _snack('Nota restaurada desde Google Drive');
      }
    } catch (e) {
      if (mounted) _snack('Error al restaurar: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Sube un archivo .inklus manual a Drive.
  Future<void> _uploadInklusFile() async {
    try {
      final file = await ImportService.pickPlatformFile();
      if (file == null) return;
      final bytes = await file.xFile.readAsBytes();
      if (await ImportService.detect(bytes) == ImportKind.fullBackup) {
        _snack('Ese archivo es un respaldo completo, no un cuaderno .inklus');
        return;
      }
      // Android puede haberlo renombrado a .zip: en Drive siempre .inklus.
      final name = file.name.replaceFirst(RegExp(r'(\.inklus)?\.zip$'), '.inklus');
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
  }) {
    return showTextPrompt(
      context,
      title: titulo,
      hint: hint,
      obscure: true,
      secondaryLabel: 'Sin contraseña',
      secondaryValue: '',
    );
  }

  Future<void> _editTitle() async {
    final result = await showTextPrompt(
      context,
      title: 'Título del cuaderno',
      hint: 'Nombre',
      initialValue: _c.note.title,
      confirmLabel: 'Guardar',
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
      case 'indexInk':
        _indexHandwriting();
      case 'settings':
        _openSettings();
    }
  }

  // --- Modo nocturno de escritura ---
  // Solo afecta a cómo se VE el lienzo (filtro de color); los colores
  // guardados y la exportación no cambian. Se recuerda entre sesiones.
  static const _nightModePref = 'night_writing_mode';
  bool _nightMode = false;

  Future<void> _loadNightMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_nightModePref) ?? false;
      if (mounted && value != _nightMode) setState(() => _nightMode = value);
    } catch (_) {}
  }

  Future<void> _toggleNightMode() async {
    setState(() => _nightMode = !_nightMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_nightModePref, _nightMode);
    } catch (_) {}
  }

  // --- Importar PDF para anotar ---
  /// Cada página del PDF se convierte en una página de la nota (hoja fija
  /// con el PDF de fondo), como en GoodNotes/Notability.
  Future<void> _importPdfAsBackground() async {
    if (!PdfImportService.isSupported) {
      _snack('Importar PDF por ahora solo está disponible en Android/iOS');
      return;
    }
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.path == null || !mounted) return;

      final pages = await runWithLoading(context, () async {
        final list = <({String path, int width, int height})>[];
        await for (final p in PdfImportService.importPages(result.path!)) {
          list.add((path: p.path, width: p.widthPx, height: p.heightPx));
        }
        return list;
      });
      if (!mounted) return;
      if (pages.isEmpty) {
        _snack('No se pudo leer el PDF');
        return;
      }
      _c.insertPdfPages(pages);
      _c.fitView(_c.viewportSize);
      _snack('PDF importado: ${pages.length} página(s) para anotar');
    } catch (e) {
      _snack('Error al importar PDF: $e');
    }
  }

  // --- Historial de versiones (local + revisiones de Google Drive) ---
  Future<void> _showVersionHistory() async {
    await _controller.flush();
    final local = await _versions.list(_c.note.id);
    if (!mounted) return;
    final chosen = await showVersionHistorySheet(
      context,
      local: local,
      driveRevisions: _syncService.isSignedIn
          ? _syncService.listRevisions(_c.note.id)
          : null,
    );
    if (chosen == null || !mounted) return;
    final date = switch (chosen) {
      NoteVersion v => v.savedAt,
      DriveRevision r => r.modifiedTime,
      _ => DateTime.now(),
    };
    final ok = await showConfirmDialog(
      context,
      title: 'Restaurar versión',
      message: 'La nota volverá a como estaba el ${formatVersionDate(date)}.\n\n'
          'El estado actual se guarda antes como una versión local, así que '
          'puedes deshacer la restauración desde este mismo historial.',
      confirmLabel: 'Restaurar',
    );
    if (!ok || !mounted) return;
    try {
      final restored = await runWithLoading(context, () async {
        await _versions.snapshot(_c.note, force: true);
        return switch (chosen) {
          NoteVersion v => _versions.load(v),
          DriveRevision r => _downloadRevision(r),
          _ => throw StateError('versión desconocida'),
        };
      });
      if (restored == null || !mounted) return;
      _c.replaceNote(restored, notebookId: widget.notebookId);
      await _controller.flush();
      _snack('Versión restaurada');
    } catch (e) {
      if (mounted) _snack('No se pudo restaurar la versión: $e');
    }
  }

  /// Descarga una revisión de Drive; si está cifrada pide la contraseña
  /// (null si el usuario cancela).
  Future<Note?> _downloadRevision(DriveRevision r) async {
    try {
      return await _syncService.downloadRevision(r);
    } on EncryptedBackupException {
      if (!mounted) return null;
      final password = await showTextPrompt(
        context,
        title: 'Copia cifrada',
        hint: 'Contraseña de la copia',
        obscure: true,
        confirmLabel: 'Descifrar',
      );
      if (password == null || password.isEmpty) return null;
      return _syncService.downloadRevision(r, password: password);
    }
  }

  // --- Exportar a PowerPoint (.pptx) ---
  Future<void> _exportPptx() async {
    try {
      final bytes = await runWithLoading(
        context,
        () => ExportService.renderNotebookPptx(
          _c.note,
          imageCache: _imageService.cache,
          imagesFor: _exportImages,
        ),
      );
      if (!mounted) return;
      await _saveBytes(bytes, '${_safeName(_c.note.title)}.pptx');
    } catch (e) {
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
      // Mismo id que los recordatorios creados desde la pantalla de
      // recordatorios: el del cuaderno.
      documentId: widget.notebookId,
      documentTitle: _c.note.title,
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // --- Búsqueda en contenido ---
  Future<void> _searchContent() async {
    await _search.indexNote(widget.notebookId, _c.note);
    if (!mounted) return;
    await showSearchSheet(
      context,
      onlyNoteId: _c.note.id,
      onOpen: (_, match) {
        if (match.pageIndex >= 0) _c.goToPage(match.pageIndex);
      },
    );
  }

  /// Reconoce la escritura de todas las páginas y la guarda en el índice
  /// de búsqueda (Android/iOS, ML Kit en el dispositivo).
  Future<void> _indexHandwriting() async {
    if (!OcrService.isSupported) {
      _snack('Reconocer escritura solo está disponible en Android e iOS');
      return;
    }
    try {
      final count = await runWithLoading(context, () async {
        await _search.indexNote(widget.notebookId, _c.note);
        var n = 0;
        for (final page in _c.pages) {
          if (page.strokes.isEmpty) continue;
          final result = await OcrService.recognizeStrokes(
            page.strokes,
            sheetSize: page.template.sheetSize,
          );
          await _search.setHandwriting(_c.note.id, page.id, result.text);
          n++;
        }
        return n;
      });
      _snack('Escritura indexada en $count página(s): ya puedes buscarla');
    } catch (e) {
      _snack('No se pudo reconocer la escritura: $e');
    }
  }

  // --- Respaldo local completo ---

  Future<void> _exportFullBackup() async {
    try {
      // Asegura que la nota abierta esté en disco antes de empaquetar.
      await _controller.flush();
      if (!mounted) return;
      final bytes = await runWithLoading(context, _storage.exportFullBackup);
      if (!mounted) return;
      await _saveBytes(bytes, 'inklus_respaldo_completo.zip');
    } catch (e) {
      _snack('Error al exportar respaldo: $e');
    }
  }

  /// Importa un cuaderno `.inklus` o un respaldo completo (detectado por el
  /// contenido, ver [ImportService]).
  Future<void> _importFullBackup() async {
    try {
      final bytes = await ImportService.pickFile();
      if (bytes == null || !mounted) return;
      final result =
          await runWithLoading(context, () => ImportService.importBytes(bytes));
      if (!mounted) return;
      _snack('${result.message}. Ábrelo desde la biblioteca.');
    } catch (e) {
      if (mounted) {
        _snack(e is FormatException ? e.message : 'Error al importar: $e');
      }
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
    // Subida pendiente a Drive (se completa en segundo plano).
    if (_remoteSyncPending) unawaited(_runRemoteSync());
    _remoteSyncTimer?.cancel();
    // El servicio es un singleton: no dejarle una referencia a este State.
    if (_syncService.onSyncComplete == _onSyncComplete) {
      _syncService.onSyncComplete = null;
    }
    _controller.bottomBarContextNotifier.removeListener(_syncPresets);
    _presets.dispose();
    // dispose() del controlador guarda lo pendiente si _goBack no lo hizo.
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Solo se reconstruye la estructura cuando cambia lo que la afecta (no en
    // cada punto del trazo). Cada barra escucha lo suyo por separado.
    final screen = ControllerSelector<CanvasController, (bool, bool)>(
      listenable: controller,
      selector: (c) => (c.presentationMode, c.selectedImageId != null),
      builder: (context, state) {
        final (presentMode, hasSelectedImage) = state;
        return Scaffold(
          backgroundColor: context.inklus.desk,
          body: SafeArea(
            child: Column(
              children: [
                if (!presentMode)
                  EditorToolbar(
                    canvas: controller,
                    presets: _presets,
                    onBack: _goBack,
                    onEditTitle: _editTitle,
                    onInsertImage: _insertImages,
                    onTemplates: _openTemplates,
                    onInsertSticker: _insertSticker,
                    pagesOpen: _pagesOpen,
                    onTogglePages: () => _setPagesOpen(!_pagesOpen),
                    layersOpen: _layersSidebarOpen,
                    onToggleLayers: () =>
                        setState(() => _layersSidebarOpen = !_layersSidebarOpen),
                    trailing: [
                      _buildCloudButton(),
                      // El menú muestra estados (marcador, vibración): se
                      // reconstruye solo cuando cambian.
                      ControllerSelector<CanvasController, (bool, bool)>(
                        listenable: controller,
                        selector: (c) => (c.page.bookmarked, c.hapticEnabled),
                        builder: (context, _) => _buildMenuButton(),
                      ),
                    ],
                  ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                nightMode: _nightMode,
                                onGoToPage: _goToPageDialog,
                              ),
                            ),
                            if (!presentMode)
                              Positioned(
                                top: Spacing.md,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SelectionBar(
                                    canvas: controller,
                                    presets: _presets,
                                    onMessage: _snack,
                                  ),
                                ),
                              ),
                            if (hasSelectedImage && !presentMode)
                              Positioned(
                                top: Spacing.md,
                                right: Spacing.md,
                                child: FloatingActionButton.small(
                                  heroTag: 'deleteImage',
                                  tooltip: 'Eliminar imagen',
                                  backgroundColor: context.colors.errorContainer,
                                  foregroundColor: context.colors.onErrorContainer,
                                  onPressed: _deleteSelectedImage,
                                  child: const Icon(Icons.delete_outline),
                                ),
                              ),
                            if (!presentMode)
                              Positioned(
                                right: Spacing.lg,
                                bottom: Spacing.lg,
                                child: _ZoomPill(controller: controller),
                              ),
                            if (!presentMode)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: Spacing.lg,
                                child: Center(
                                  child: _PageNavPill(
                                    controller: controller,
                                    onGoToPage: _goToPageDialog,
                                  ),
                                ),
                              ),
                            if (presentMode)
                              Positioned(
                                top: Spacing.md,
                                left: Spacing.md,
                                child: Row(
                                  children: [
                                    IconButton.filledTonal(
                                      tooltip: 'Salir de presentación',
                                      onPressed: controller.togglePresentationMode,
                                      icon: const Icon(Icons.fullscreen_exit),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    ControllerSelector<CanvasController, bool>(
                                      listenable: controller,
                                      selector: (c) => c.laserMode,
                                      builder: (context, on) => IconButton.filledTonal(
                                        tooltip: on ? 'Desactivar láser' : 'Puntero láser',
                                        isSelected: on,
                                        onPressed: controller.toggleLaser,
                                        icon: const Icon(Icons.flashlight_on),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_pagesOpen && !presentMode)
                        PagesPanel(
                          canvas: controller,
                          imageService: _imageService,
                          onClose: () => _setPagesOpen(false),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // Botón/gesto "atrás" del sistema: guardar antes de salir para que la
    // biblioteca muestre la miniatura y fecha actualizadas.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: screen,
    );
  }

  /// "Ir a página N".
  Future<void> _goToPageDialog() async {
    final value = await showTextPrompt(
      context,
      title: 'Ir a página',
      hint: '1 – ${_c.pageCount}',
      confirmLabel: 'Ir',
      keyboardType: TextInputType.number,
    );
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return;
    if (n < 1 || n > _c.pageCount) {
      _snack('La nota tiene ${_c.pageCount} página(s)');
      return;
    }
    _c.goToPage(n - 1);
  }

  /// Inserta un sticker de los paquetes instalados del marketplace.
  Future<void> _insertSticker() async {
    final stickers = await MarketplaceService.instance.installedStickers();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: stickers.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_emotions_outlined, size: 48),
                    const SizedBox(height: Spacing.md),
                    const Text('Aún no tienes stickers instalados.'),
                    const SizedBox(height: Spacing.md),
                    FilledButton.icon(
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Abrir el marketplace'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                        );
                      },
                    ),
                  ],
                ),
              )
            : GridView.extent(
                shrinkWrap: true,
                maxCrossAxisExtent: 96,
                padding: const EdgeInsets.all(Spacing.lg),
                mainAxisSpacing: Spacing.sm,
                crossAxisSpacing: Spacing.sm,
                children: [
                  for (final path in stickers)
                    InkWell(
                      borderRadius: Radii.mdAll,
                      onTap: () => Navigator.pop(context, path),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xs),
                        child: Image.file(File(path), fit: BoxFit.contain),
                      ),
                    ),
                ],
              ),
      ),
    );
    if (chosen == null) return;
    try {
      // Copia a la carpeta de imágenes (el paquete puede desinstalarse).
      final localPath = await _imageService.importToApp(chosen);
      final img = await _imageService.decode(localPath);
      _imageService.cache[localPath] = img;
      final w = img.width.toDouble(), h = img.height.toDouble();
      final fit = 160 / (w > h ? w : h);
      final center = _c.viewportToWorld(
        Offset(_c.viewportSize.width / 2, _c.viewportSize.height / 2),
        _c.viewportSize,
      );
      _c.addImage(ImageItem(
        id: newId('img'),
        localPath: localPath,
        x: center.dx,
        y: center.dy,
        width: w * fit / _c.scale,
        height: h * fit / _c.scale,
      ));
    } catch (e) {
      _snack('No se pudo insertar el sticker: $e');
    }
  }

  void _openTemplates() => showTemplatePicker(
        context,
        controller: _controller,
        imageService: _imageService,
        templateLibrary: _templateLibrary,
      );

  /// ☁️ Estado de sincronización del cuaderno + acceso al menú de Drive.
  Widget _buildCloudButton() {
    final controller = _c;
    return ControllerSelector<Listenable, Object>(
      listenable: _topBarListenable,
      selector: (_) => (
        _syncService.isSignedIn,
        _syncService.statusFor(controller.note.id),
        _syncing,
      ),
      builder: (context, _) {
        final status = _syncService.statusFor(controller.note.id);
        final scheme = context.colors;
        final (IconData icon, Color? color, String tooltip) = _syncing
            ? (Icons.sync, null, 'Sincronizando…')
            : !_syncService.isSignedIn
                ? (Icons.cloud_upload_outlined, null, 'Sincronizar con Google Drive')
                : switch (status) {
                    SyncStatus.synced => (Icons.cloud_done, scheme.primary, 'Sincronizado'),
                    SyncStatus.syncing => (Icons.sync, null, 'Sincronizando…'),
                    SyncStatus.error => (Icons.cloud_off, scheme.error, 'Error de sincronización'),
                    SyncStatus.disabled => (Icons.cloud_queue, scheme.outline, 'Sync desactivada para este cuaderno'),
                    SyncStatus.pending => (Icons.cloud_upload_outlined, null, 'Sincronizar con Google Drive'),
                  };
        return IconButton(
          tooltip: tooltip,
          icon: _syncing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color),
          onPressed: _syncing ? null : _syncPressed,
        );
      },
    );
  }

  /// Menú ⋮ agrupado en submenús (antes: ~25 entradas en una sola lista).
  Widget _buildMenuButton() {
    MenuItemButton item(String action, IconData icon, String label, {bool enabled = true}) =>
        MenuItemButton(
          leadingIcon: Icon(icon),
          onPressed: enabled ? () => _onMenuAction(action) : null,
          child: Text(label),
        );
    return MenuAnchor(
      menuChildren: [
        SubmenuButton(
          leadingIcon: const Icon(Icons.ios_share),
          menuChildren: [
            item('png', Icons.image_outlined, 'Página como imagen (PNG)'),
            item('pdf', Icons.picture_as_pdf_outlined, 'Página como PDF'),
            item('pdfAll', Icons.menu_book_outlined, 'Nota completa (PDF)'),
            item('svg', Icons.code_outlined, 'Trazos (SVG)'),
            item('pptx', Icons.slideshow_outlined, 'Presentación (PowerPoint)'),
            item('inklus', Icons.save_alt, 'Copia .inklus'),
            const Divider(),
            item('sharePng', Icons.share_outlined, 'Compartir imagen'),
            item('sharePdf', Icons.share_outlined, 'Compartir PDF'),
            item('shareInklus', Icons.share_outlined, 'Compartir .inklus'),
          ],
          child: const Text('Exportar y compartir'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.description_outlined),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: _openTemplates,
              child: const Text('Plantilla…'),
            ),
            MenuItemButton(
              leadingIcon: Icon(_c.page.bookmarked ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
              onPressed: _c.toggleBookmark,
              child: Text(_c.page.bookmarked ? 'Quitar marcador' : 'Marcar página'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.format_list_numbered),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
              onPressed: _goToPageDialog,
              child: const Text('Ir a página…'),
            ),
            item('importPdf', Icons.picture_as_pdf_outlined, 'Importar PDF para anotar'),
            item('clear', Icons.cleaning_services_outlined, 'Limpiar página'),
          ],
          child: const Text('Página'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.sticky_note_2_outlined),
          menuChildren: [
            item('searchContent', Icons.search, 'Buscar en la nota'),
            item('indexInk', Icons.manage_search,
                OcrService.isSupported ? 'Indexar escritura (para buscarla)' : 'Indexar escritura (solo Android/iOS)',
                enabled: OcrService.isSupported),
            item('ocr', Icons.text_snippet_outlined,
                OcrService.isSupported ? 'Reconocer texto (OCR)' : 'OCR (solo Android/iOS)',
                enabled: OcrService.isSupported),
            item('versions', Icons.history, 'Historial de versiones'),
            item('reminder', Icons.alarm_add_outlined, 'Crear recordatorio'),
          ],
          child: const Text('Nota'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.visibility_outlined),
          menuChildren: [
            item('nightMode', _nightMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                _nightMode ? 'Desactivar modo nocturno' : 'Modo nocturno de escritura'),
            item('present', Icons.fullscreen, 'Modo presentación'),
            item('haptics', _c.hapticEnabled ? Icons.vibration : Icons.mobile_off,
                _c.hapticEnabled ? 'Vibración al escribir: sí' : 'Vibración al escribir: no'),
            CheckboxMenuButton(
              value: _c.continuousScroll,
              onChanged: (v) => _c.setContinuousScroll(v ?? true),
              child: const Text('Desplazamiento continuo entre hojas'),
            ),
          ],
          child: const Text('Ver'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.backup_outlined),
          menuChildren: [
            item('backup', Icons.backup_outlined, 'Exportar respaldo completo'),
            item('restoreBackup', Icons.file_download_outlined, 'Importar .inklus o respaldo'),
          ],
          child: const Text('Datos'),
        ),
        const Divider(),
        item('stats', Icons.analytics_outlined, 'Estadísticas de escritura'),
        item('settings', Icons.settings_outlined, 'Configuración'),
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: 'Más opciones',
        icon: const Icon(Icons.more_vert),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }

  bool _leaving = false;

  /// Guarda el último cambio pendiente y vuelve a la biblioteca.
  Future<void> _goBack() async {
    if (_leaving) return;
    _leaving = true;
    await _controller.flush();
    unawaited(_search.indexNote(widget.notebookId, _controller.note));
    // Instantánea al salir si hubo cambios en esta sesión (respeta el
    // intervalo mínimo del historial). No bloquea la navegación.
    if (_controller.note.updatedAt != _openedAt) {
      unawaited(_versions.snapshot(_controller.note));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmClearPage() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar página'),
        content: const Text(
          'Se borrará todo el contenido de la página. Puedes deshacerlo después.',
        ),
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

/// "‹ 2 / 5 ›": pasar de página sin abrir el panel. Tocar el número abre
/// "Ir a página"; la marca indica si la página está marcada.
class _PageNavPill extends StatelessWidget {
  const _PageNavPill({required this.controller, required this.onGoToPage});

  final CanvasController controller;
  final VoidCallback onGoToPage;

  @override
  Widget build(BuildContext context) {
    return ControllerSelector<CanvasController, (int, int, bool)>(
      listenable: controller,
      selector: (c) => (c.pageIndex, c.pageCount, c.page.bookmarked),
      builder: (context, state) {
        final (index, count, bookmarked) = state;
        if (count <= 1 && !bookmarked) return const SizedBox.shrink();
        return Material(
          color: context.colors.surfaceContainerHigh.withValues(alpha: 0.92),
          elevation: 2,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: index > 0 ? controller.previousPage : null,
              ),
              Tooltip(
                message: 'Ir a página…',
                child: InkWell(
                  borderRadius: Radii.smAll,
                  onTap: onGoToPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (bookmarked)
                          Padding(
                            padding: const EdgeInsets.only(right: Spacing.xs),
                            child: Icon(Icons.bookmark, size: 16, color: context.colors.primary),
                          ),
                        Text('${index + 1} / $count', style: context.text.labelLarge),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: index < count - 1 ? controller.nextPage : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Indicador de zoom: muestra el % y al tocarlo ajusta la página a la vista.
/// (Los gestos con dos dedos siguen siendo la forma principal de hacer zoom.)
class _ZoomPill extends StatelessWidget {
  const _ZoomPill({required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return ControllerSelector<CanvasController, int>(
      listenable: controller,
      selector: (c) => (c.scale * 100).round(),
      builder: (context, percent) => Material(
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.92),
        elevation: 2,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Alejar',
              icon: const Icon(Icons.remove),
              onPressed: () => controller.zoomAt(0.8, _center, controller.viewportSize),
            ),
            Tooltip(
              message: 'Ajustar a la vista',
              child: InkWell(
                borderRadius: Radii.smAll,
                onTap: () => controller.fitView(controller.viewportSize),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.sm),
                  child: Text('$percent %', style: context.text.labelLarge),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Acercar',
              icon: const Icon(Icons.add),
              onPressed: () => controller.zoomAt(1.25, _center, controller.viewportSize),
            ),
          ],
        ),
      ),
    );
  }

  Offset get _center => Offset(
        controller.viewportSize.width / 2,
        controller.viewportSize.height / 2,
      );
}
