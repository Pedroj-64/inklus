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
import '../l10n/l10n.dart';
import '../services/app_errors.dart';

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

  /// Textos traducidos (atajo seguro tras `await`: el `context` del State vive mientras esté montado).
  AppLocalizations get _l10n => context.l10n;
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
    _controller.onNotice = (notice) {
      if (mounted) _snack(_noticeText(notice));
    };
    _controller.onUndoableNotice = (notice, undo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(_noticeText(notice)),
          action: SnackBarAction(label: context.l10n.tbUndo, onPressed: undo),
        ));
    };
    _controller.onLayerBlocked = () {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.edLayerLocked),
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

  void _onSyncComplete(SyncNotice notice) {
    if (!mounted) return;
    _snack(switch (notice) {
      SyncNotice.fileUploaded => _l10n.noticeFileUploaded,
      SyncNotice.noteSynced => _l10n.edNoteSynced,
    });
  }

  String _noticeText(ControllerNotice notice) => switch (notice) {
        ControllerNotice.stylusDetected => _l10n.noticeStylus,
        ControllerNotice.pageDeleted => _l10n.noticePageDeleted,
      };

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
      await _syncService.backupNote(
        _controller.note,
        notebookId: widget.notebookId,
        notebookTitle: meta?.title,
      );
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
      _snack(_l10n.edInsertImageFailed('$e'));
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
          title: Text(context.l10n.expTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // DPI / resolución
              DropdownButton<int>(
                value: maxDimension,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 1024, child: Text(context.l10n.expLow)),
                  DropdownMenuItem(value: 2048, child: Text(context.l10n.expMedium)),
                  DropdownMenuItem(value: 4096, child: Text(context.l10n.expHigh)),
                  DropdownMenuItem(value: 8192, child: Text(context.l10n.expMax)),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => maxDimension = v);
                },
              ),
              const SizedBox(height: 12),
              // Fondo transparente
              SwitchListTile(
                title: Text(context.l10n.expTransparent),
                subtitle: Text(context.l10n.expTransparentHint),
                value: transparentBg,
                onChanged: (v) =>
                    setDialogState(() => transparentBg = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              // Solo trazos
              if (showStrokesOnly)
                SwitchListTile(
                  title: Text(context.l10n.expStrokesOnly),
                  subtitle: Text(context.l10n.expStrokesOnlyHint),
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
              child: Text(context.l10n.commonCancel),
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
              child: Text(context.l10n.expExport),
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
      _snack(_l10n.expSvgFailed('$e'));
    }
  }

  /// Reconoce el texto escrito a mano en la página actual (OCR).
  ///
  /// Usa digital ink recognition (trazos vectoriales) como estrategia
  /// principal, con fallback a bitmap si no hay trazos.
  Future<void> _recognizeText() async {
    if (!OcrService.isSupported) {
      _snack(context.l10n.ocrUnsupported);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: Spacing.lg),
                Text(context.l10n.ocrWorking),
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
        _snack(context.l10n.ocrNoText);
        return;
      }
      // Lo reconocido queda buscable.
      unawaited(_search.setHandwriting(_c.note.id, _c.page.id, result.text));

      // Mostrar resultado y permitir copiar.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.ocrResultTitle),
          content: SingleChildScrollView(
            child: SelectableText(
              result.text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonClose),
            ),
            FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.text));
                Navigator.pop(context);
                _snack(context.l10n.ocrCopied);
              },
              child: Text(context.l10n.selCopy),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack(_l10n.ocrFailed('$e'));
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
      _snack(_l10n.expFailed('$e'));
    }
  }

  /// Diálogo de previsualización para exportaciones de imagen.
  Future<bool?> _showPreviewDialog(Uint8List bytes, String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.expPreview(fileName)),
        content: SingleChildScrollView(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBytes(Uint8List bytes, String fileName) async {
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: _l10n.expSaveDialog(fileName),
        fileName: fileName,
        bytes: bytes,
      );
      if (saved != null) {
        _snack(_l10n.expDone(saved.path));
      }
    } catch (_) {
      // Fallback: carpeta de datos de la app.
      try {
        final folder = await AppPaths.exports();
        await folder.create(recursive: true);
        final file = File('${folder.path}/$fileName');
        await file.writeAsBytes(bytes);
        _snack(_l10n.expDone(file.path));
      } catch (e) {
        _snack(_l10n.expSaveFailed('$e'));
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
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: _l10n.shareTextPage));
    } catch (e) {
      _snack(_l10n.shareFailed('$e'));
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
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: _l10n.shareTextPage));
    } catch (e) {
      _snack(_l10n.shareFailed('$e'));
    }
  }

  Future<void> _shareInklus() async {
    try {
      final bytes = await InklusFormat.exportNoteBytes(_c.note);
      final dir = await getTemporaryDirectory();
      final name = '${_safeName(_c.note.title)}.inklus';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: _l10n.shareTextNotebook));
    } catch (e) {
      _snack(_l10n.shareFailed('$e'));
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
              title: Text(_syncService.email ?? context.l10n.edGoogleAccount),
              subtitle: Text(context.l10n.edSyncedCloud),
              dense: true,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(context.l10n.driveUploadNow),
              onTap: () => Navigator.pop(context, 'upload'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(context.l10n.edRestoreCloud),
              subtitle: Text(context.l10n.edRestoreCloudHint),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(context.l10n.edDriveVersions),
              onTap: () => Navigator.pop(context, 'versions'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(context.l10n.edUploadInklus),
              onTap: () => Navigator.pop(context, 'uploadFile'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(_syncEnabledForCurrent
                  ? context.l10n.edSyncOnForNotebook
                  : context.l10n.edSyncOffForNotebook),
              onTap: () => Navigator.pop(context, 'toggleSync'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.switch_account),
              title: Text(context.l10n.driveSwitchAccount),
              onTap: () => Navigator.pop(context, 'switchAccount'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.l10n.driveSignOut),
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
        if (mounted) _snack(context.l10n.driveSignedOut);
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
          ? context.l10n.edSyncDisabledMsg
          : context.l10n.edSyncEnabledMsg);
    }
  }

  Future<void> _signInAndBackup() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.signIn();
      if (!ok) {
        if (mounted) {
          _snack(_l10n.edSignInIncomplete(_syncService.lastSignInIssue ?? '—'));
        }
        return;
      }
      if (mounted) _snack(_l10n.driveConnectedAs(_syncService.email ?? ''));
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
      final metas = await _storage.loadIndex();
      final meta = metas.where((m) => m.id == widget.notebookId).firstOrNull;
      await _syncService.backupNote(
        _c.note,
        notebookId: widget.notebookId,
        notebookTitle: meta?.title,
        promptForConsent: true,
      );
      if (mounted) _snack(context.l10n.edNoteSynced);
    } catch (e) {
      if (mounted) _snack(_l10n.uploadFailed('$e'));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _syncing = true);
    try {
      // Pedir contraseña si el usuario quiere descifrar.
      final password = await _promptPassword(
        titulo: context.l10n.driveRestore,
        hint: context.l10n.edPasswordHint,
      );
      // A8: restore individual por Note (no el Document completo).
      final restored = await _syncService.restoreNote(
        noteId: _c.note.id,
        password: password?.isEmpty == true ? null : password,
      );
      if (!mounted) return;
      if (restored == null) {
        _snack(context.l10n.edNoCloudCopy);
      } else {
        _c.replaceNote(restored, notebookId: widget.notebookId);
        // Persistir la nota restaurada en disco local.
        await _storage.saveNote(widget.notebookId, restored, touch: false);
        _snack(_l10n.edNoteRestored);
      }
    } catch (e) {
      if (mounted) _snack(_l10n.restoreFailed('$e'));
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
        _snack(_l10n.edIsFullBackup);
        return;
      }
      // Android puede haberlo renombrado a .zip: en Drive siempre .inklus.
      final name = file.name.replaceFirst(RegExp(r'(\.inklus)?\.zip$'), '.inklus');
      setState(() => _syncing = true);
      await _syncService.uploadInklusFile(bytes, name, promptForConsent: true);
      if (mounted) _snack(_l10n.edFileUploaded(name));
    } catch (e) {
      if (mounted) _snack(_l10n.uploadFailed('$e'));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _switchAccount() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.switchAccount();
      if (ok && mounted) {
        _snack(_l10n.driveConnectedAs(_syncService.email ?? ''));
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
      secondaryLabel: context.l10n.edNoPassword,
      secondaryValue: '',
    );
  }

  Future<void> _editTitle() async {
    final result = await showTextPrompt(
      context,
      title: context.l10n.edNotebookTitle,
      hint: context.l10n.createName,
      initialValue: _c.note.title,
      confirmLabel: context.l10n.commonSave,
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
      _snack(context.l10n.pdfUnsupported);
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
        _snack(context.l10n.pdfReadFailed);
        return;
      }
      _c.insertPdfPages(pages);
      _c.fitView(_c.viewportSize);
      _snack(_l10n.pdfImported(pages.length));
    } catch (e) {
      _snack(_l10n.pdfImportFailed('$e'));
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
      title: context.l10n.verRestoreTitle,
      message: _l10n.verRestoreBody(formatVersionDate(date)),
      confirmLabel: context.l10n.commonRestore,
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
      _snack(_l10n.verRestored);
    } catch (e) {
      if (mounted) _snack(_l10n.verRestoreFailed('$e'));
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
        title: context.l10n.verEncrypted,
        hint: context.l10n.verPasswordHint,
        obscure: true,
        confirmLabel: context.l10n.verDecrypt,
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
      _snack(_l10n.pptxFailed('$e'));
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
    _snack(_l10n.reminderCreated('${date.day}/${date.month}', '${time.hour}:${time.minute.toString().padLeft(2, '0')}'));
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
      _snack(context.l10n.inkUnsupported);
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
      _snack(_l10n.inkIndexed(count));
    } catch (e) {
      _snack(_l10n.inkFailed('$e'));
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
      _snack(_l10n.backupFailed('$e'));
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
      _snack(_l10n.importDoneOpen(result.message(_l10n)));
    } catch (e) {
      if (mounted) {
        _snack(e is FormatException ? userError(_l10n, e) : _l10n.libImportError('$e'));
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
                                  tooltip: context.l10n.edDeleteImage,
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
                                      tooltip: context.l10n.edExitPresent,
                                      onPressed: controller.togglePresentationMode,
                                      icon: const Icon(Icons.fullscreen_exit),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    ControllerSelector<CanvasController, bool>(
                                      listenable: controller,
                                      selector: (c) => c.laserMode,
                                      builder: (context, on) => IconButton.filledTonal(
                                        tooltip: on ? context.l10n.edLaserOff : context.l10n.tbLaser,
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
      title: context.l10n.edGoToPage,
      hint: '1 – ${_c.pageCount}',
      confirmLabel: context.l10n.edGo,
      keyboardType: TextInputType.number,
    );
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null) return;
    if (n < 1 || n > _c.pageCount) {
      _snack(_l10n.noteHasPages(_c.pageCount));
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
                    Text(context.l10n.edNoStickers),
                    const SizedBox(height: Spacing.md),
                    FilledButton.icon(
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(context.l10n.edOpenMarket),
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
      _snack(_l10n.stickerInsertFailed('$e'));
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
            ? (Icons.sync, null, context.l10n.edSyncing)
            : !_syncService.isSignedIn
                ? (Icons.cloud_upload_outlined, null, context.l10n.edSyncToDrive)
                : switch (status) {
                    SyncStatus.synced => (Icons.cloud_done, scheme.primary, context.l10n.edSynced),
                    SyncStatus.syncing => (Icons.sync, null, context.l10n.edSyncing),
                    SyncStatus.error => (Icons.cloud_off, scheme.error, context.l10n.edSyncError),
                    SyncStatus.disabled => (Icons.cloud_queue, scheme.outline, context.l10n.edSyncDisabledMsg),
                    SyncStatus.pending => (Icons.cloud_upload_outlined, null, context.l10n.edSyncToDrive),
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
            item('png', Icons.image_outlined, context.l10n.menuPagePng),
            item('pdf', Icons.picture_as_pdf_outlined, context.l10n.menuPagePdf),
            item('pdfAll', Icons.menu_book_outlined, context.l10n.menuNotePdf),
            item('svg', Icons.code_outlined, context.l10n.menuStrokesSvg),
            item('pptx', Icons.slideshow_outlined, context.l10n.menuPptx),
            item('inklus', Icons.save_alt, context.l10n.menuInklusCopy),
            const Divider(),
            item('sharePng', Icons.share_outlined, context.l10n.menuShareImage),
            item('sharePdf', Icons.share_outlined, context.l10n.menuSharePdf),
            item('shareInklus', Icons.share_outlined, context.l10n.menuShareInklus),
          ],
          child: Text(context.l10n.menuExportShare),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.description_outlined),
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: _openTemplates,
              child: Text(context.l10n.menuTemplate),
            ),
            MenuItemButton(
              leadingIcon: Icon(_c.page.bookmarked ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
              onPressed: _c.toggleBookmark,
              child: Text(_c.page.bookmarked ? context.l10n.pgUnbookmark : context.l10n.pgBookmark),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.format_list_numbered),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
              onPressed: _goToPageDialog,
              child: Text(context.l10n.menuGoToPage),
            ),
            item('importPdf', Icons.picture_as_pdf_outlined, context.l10n.menuImportPdf),
            item('clear', Icons.cleaning_services_outlined, context.l10n.menuClearPage),
          ],
          child: Text(context.l10n.menuPage),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.sticky_note_2_outlined),
          menuChildren: [
            item('searchContent', Icons.search, context.l10n.menuSearchNote),
            item('indexInk', Icons.manage_search,
                OcrService.isSupported ? context.l10n.menuIndexInk : context.l10n.menuIndexInkUnsupported,
                enabled: OcrService.isSupported),
            item('ocr', Icons.text_snippet_outlined,
                OcrService.isSupported ? context.l10n.menuOcr : context.l10n.menuOcrUnsupported,
                enabled: OcrService.isSupported),
            item('versions', Icons.history, context.l10n.menuVersions),
            item('reminder', Icons.alarm_add_outlined, context.l10n.menuReminder),
          ],
          child: Text(context.l10n.trashNote),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.visibility_outlined),
          menuChildren: [
            item('nightMode', _nightMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                _nightMode ? context.l10n.menuNightOff : context.l10n.menuNightOn),
            item('present', Icons.fullscreen, context.l10n.menuPresent),
            item('haptics', _c.hapticEnabled ? Icons.vibration : Icons.mobile_off,
                _c.hapticEnabled ? context.l10n.menuHapticsOn : context.l10n.menuHapticsOff),
            CheckboxMenuButton(
              value: _c.continuousScroll,
              onChanged: (v) => _c.setContinuousScroll(v ?? true),
              child: Text(context.l10n.menuContinuousScroll),
            ),
          ],
          child: Text(context.l10n.menuView),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.backup_outlined),
          menuChildren: [
            item('backup', Icons.backup_outlined, context.l10n.menuBackup),
            item('restoreBackup', Icons.file_download_outlined, context.l10n.menuRestoreBackup),
          ],
          child: Text(context.l10n.menuData),
        ),
        const Divider(),
        item('stats', Icons.analytics_outlined, context.l10n.menuStats),
        item('settings', Icons.settings_outlined, context.l10n.settingsTitle),
      ],
      builder: (context, menu, _) => IconButton(
        tooltip: context.l10n.libMoreOptions,
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
        title: Text(context.l10n.menuClearPage),
        content: Text(
          context.l10n.clearPageBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clearPageAction),
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
                tooltip: context.l10n.pgPrev,
                icon: const Icon(Icons.chevron_left),
                onPressed: index > 0 ? controller.previousPage : null,
              ),
              Tooltip(
                message: context.l10n.menuGoToPage,
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
                tooltip: context.l10n.pgNext,
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
              tooltip: context.l10n.zoomOut,
              icon: const Icon(Icons.remove),
              onPressed: () => controller.zoomAt(0.8, _center, controller.viewportSize),
            ),
            Tooltip(
              message: context.l10n.zoomFit,
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
              tooltip: context.l10n.zoomIn,
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
