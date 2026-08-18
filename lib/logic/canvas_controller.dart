import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/document.dart';
import '../models/image_item.dart';
import '../models/page.dart';
import '../models/stroke.dart';
import '../models/template.dart';
import '../services/storage_service.dart';
import 'eraser.dart';
import 'undo_stack.dart';

/// Controlador central del lienzo.
///
/// Gestiona: documento actual, herramienta/color/grosor, transformación
/// (zoom/pan), trazo en progreso, selección de imágenes y deshacer/rehacer.
/// Todo el estado mutable vive aquí y las vistas se suscriben con
/// `ListenableBuilder`. Las coordenadas de los trazos son de "mundo"
/// (independientes del zoom); la transformación solo afecta a la vista.
class CanvasController extends ChangeNotifier {
  final StorageService _storage;

  // ignore: prefer_final_fields (se reemplaza al restaurar desde la nube)
  Document _document;
  int _pageIndex = 0;

  // ---- Herramientas ----
  ToolType _tool = ToolType.pen;
  Color _color = const Color(0xFF1A1A1A);
  static const Map<ToolType, (double, double)> _sizeRange = {
    ToolType.pen: (2, 14),
    ToolType.pencil: (2, 18),
    ToolType.highlighter: (12, 60),
    ToolType.eraser: (12, 120),
  };
  final Map<ToolType, double> _toolSizes = {
    ToolType.pen: 3.5,
    ToolType.pencil: 4.5,
    ToolType.highlighter: 26,
    ToolType.eraser: 36,
  };
  bool _fingerDrawingEnabled = true;

  // ---- Transformación de vista ----
  double _scale = 1.0;
  Offset _translate = Offset.zero;
  bool _viewInitialized = false;

  /// Tamaño del viewport del lienzo (lo actualiza la vista en cada layout).
  Size viewportSize = Size.zero;

  // ---- Trazo en progreso ----
  Stroke? _activeStroke;
  List<Offset> _activeEraserPath = [];
  bool _isDrawing = false;

  // ---- Selección de imágenes ----
  String? _selectedImageId;

  final UndoStack _undoStack = UndoStack();

  /// Versión del contenido (trazos/imágenes/plantilla). La capa confirmada
  /// del lienzo la usa para saber cuándo debe repintar de verdad.
  int _contentVersion = 0;
  int get contentVersion => _contentVersion;

  /// Modo presentación / pizarra: oculta todas las barras.
  bool _presentationMode = false;
  bool get presentationMode => _presentationMode;

  /// Háptica habilitada (vibración sutil al escribir).
  bool _hapticEnabled = true;
  bool get hapticEnabled => _hapticEnabled;

  /// Callback opcional invocado en cada guardado automático. La UI lo usa
  /// para replicar el documento en Google Drive cuando hay sesión.
  Future<void> Function(Document document)? onRemoteSync;

  Timer? _saveTimer;

  CanvasController(this._storage, {Document? initial})
      : _document = initial ?? Document.newBlank() {
    _scheduleSave();
  }

  // ------------------------------------------------------------------
  // Accesores
  // ------------------------------------------------------------------

  Document get document => _document;
  List<Page> get pages => _document.pages;
  Page get page => _document.pages[_pageIndex];
  int get pageIndex => _pageIndex;
  int get pageCount => _document.pages.length;

  ToolType get tool => _tool;
  Color get color => _color;
  double get toolSize => _toolSizes[_tool] ?? 3.5;
  bool get fingerDrawingEnabled => _fingerDrawingEnabled;

  /// Rango de tamaño permitido para la herramienta actual.
  (double, double) get sizeRange => _sizeRange[_tool] ?? (2, 14);

  double get scale => _scale;
  Offset get translate => _translate;
  Stroke? get activeStroke => _activeStroke;
  bool get isDrawing => _isDrawing;
  List<Offset> get activeEraserPath => _activeEraserPath;
  String? get selectedImageId => _selectedImageId;
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;
  bool get viewNeedsInit => !_viewInitialized;

  /// Radio (mundo) del círculo de borrado actual.
  double get eraserRadius => _toolSizes[ToolType.eraser]! / 2;

  /// Tamaño de la hoja finita actual (sheet o custom sin relleno).
  Size get sheetSize => page.template.sheetSize;

  // ------------------------------------------------------------------
  // Herramientas
  // ------------------------------------------------------------------

  void setTool(ToolType tool) {
    if (_tool == tool) return;
    _tool = tool;
    _selectedImageId = null;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setToolSize(double size) {
    final range = _sizeRange[_tool];
    if (range != null) {
      _toolSizes[_tool] = size.clamp(range.$1, range.$2);
    }
    notifyListeners();
  }

  void setFingerDrawing(bool enabled) {
    _fingerDrawingEnabled = enabled;
    notifyListeners();
  }

  void togglePresentationMode() {
    _presentationMode = !_presentationMode;
    notifyListeners();
  }

  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Captura de trazo (llamado desde el Listener del lienzo)
  // ------------------------------------------------------------------

  /// Comienza un trazo en coordenadas de mundo.
  ///
  /// [tool] normalmente es la herramienta activa, pero puede sobrescribirse
  /// (p. ej. `invertedStylus` fuerza borrador automático).
  void beginStroke(
    Offset worldPoint,
    double pressure, {
    required ToolType tool,
  }) {
    if (tool == ToolType.select) return;
    _isDrawing = true;
    // Háptica sutil al empezar a escribir.
    if (_hapticEnabled && tool != ToolType.eraser) {
      HapticFeedback.selectionClick();
    }
    _selectedImageId = null;
    if (tool == ToolType.eraser) {
      _activeEraserPath = [worldPoint];
      _activeStroke = null;
    } else {
      _activeStroke = Stroke(
        id: 'st_${DateTime.now().microsecondsSinceEpoch}',
        points: [StrokePoint.fromOffset(worldPoint, _pressure(pressure))],
        tool: tool,
        colorValue: _color.toARGB32(),
        size: _toolSizes[tool] ?? 3.5,
      );
      _activeEraserPath = [];
    }
    notifyListeners();
  }

  void addStrokePoint(Offset worldPoint, double pressure) {
    if (!_isDrawing) return;
    if (_activeStroke != null) {
      _activeStroke = _activeStroke!.copyWith(
        points: [
          ..._activeStroke!.points,
          StrokePoint.fromOffset(worldPoint, _pressure(pressure)),
        ],
      );
    } else {
      _activeEraserPath.add(worldPoint);
    }
    notifyListeners();
  }

  void endStroke() {
    if (!_isDrawing) return;
    _isDrawing = false;
    final active = _activeStroke;
    _activeStroke = null;
    final eraserPath = List<Offset>.from(_activeEraserPath);
    _activeEraserPath = [];

    if (active != null && active.points.length >= 2) {
      page.strokes.add(active);
      _undoStack.push(CanvasAction(strokesAdded: [active]));
    } else if (eraserPath.isNotEmpty) {
      final before = List<Stroke>.from(page.strokes);
      final survivors = StrokeEraser.erase(
        before,
        eraserPath,
        eraserRadius,
      );
      final removed = before.where((s) => !survivors.contains(s)).toList();
      if (removed.isNotEmpty) {
        page.strokes
          ..clear()
          ..addAll(survivors);
        _undoStack.push(
          CanvasAction(strokesRemoved: removed, strokesAdded: survivors),
        );
      }
    }
    _touch();
  }

  void cancelStroke() {
    _isDrawing = false;
    _activeStroke = null;
    _activeEraserPath = [];
    notifyListeners();
  }

  /// Presión de entrada: mouse/touch no reportan presión real, así que se
  /// simula una presión media constante (0.5); el stylus reporta la suya.
  double _pressure(double p) => (p <= 0 || p > 1) ? 0.5 : p;

  // ------------------------------------------------------------------
  // Deshacer / rehacer
  // ------------------------------------------------------------------

  void undo() {
    final action = _undoStack.undo();
    if (action == null) return;
    _applyAction(action, undo: true);
    _touch();
  }

  void redo() {
    final action = _undoStack.redo();
    if (action == null) return;
    _applyAction(action, undo: false);
    _touch();
  }

  void _applyAction(CanvasAction action, {required bool undo}) {
    final p = page;
    if (undo) {
      p.strokes
        ..removeWhere((s) => action.strokesAdded.contains(s))
        ..addAll(action.strokesRemoved);
      p.images
        ..removeWhere((i) => action.imagesAdded.contains(i))
        ..addAll(action.imagesRemoved);
    } else {
      p.strokes
        ..removeWhere((s) => action.strokesRemoved.contains(s))
        ..addAll(action.strokesAdded);
      p.images
        ..removeWhere((i) => action.imagesRemoved.contains(i))
        ..addAll(action.imagesAdded);
    }
    _selectedImageId = null;
  }

  void setTitle(String title) {
    if (title.trim().isEmpty || title == _document.title) return;
    _document.title = title.trim();
    _touch();
  }

  // ------------------------------------------------------------------
  // Páginas
  // ------------------------------------------------------------------

  void addPage() {
    final newPage = Page.blank(
      name: 'Página ${pageCount + 1}',
      template: page.template, // hereda la plantilla actual
    );
    _document.pages.add(newPage);
    _pageIndex = pageCount - 1;
    _undoStack.clear();
    _viewInitialized = false; // re-ajusta la vista en el siguiente layout
    _touch();
  }

  void goToPage(int index) {
    if (index < 0 || index >= pageCount || index == _pageIndex) return;
    _pageIndex = index;
    _selectedImageId = null;
    _undoStack.clear();
    _viewInitialized = false;
    notifyListeners();
  }

  void deleteCurrentPage() {
    if (pageCount <= 1) return;
    _document.pages.removeAt(_pageIndex);
    _pageIndex = min(_pageIndex, pageCount - 1);
    _undoStack.clear();
    _viewInitialized = false;
    _touch();
  }

  void clearPage() {
    page.strokes.clear();
    page.images.clear();
    _undoStack.clear();
    _selectedImageId = null;
    _touch();
  }

  /// Duplica la página actual y la inserta justo después.
  void duplicatePage() {
    final src = page;
    final dup = Page(
      id: 'pg_${DateTime.now().microsecondsSinceEpoch}',
      name: '${src.name} (copia)',
      // Roundtrip JSON para copia profunda de trazos e imágenes.
      strokes: (jsonDecode(jsonEncode(src.strokes.map((s) => s.toJson()).toList())) as List)
          .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      images: (jsonDecode(jsonEncode(src.images.map((i) => i.toJson()).toList())) as List)
          .map((i) => ImageItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      template: src.template,
    );
    _document.pages.insert(_pageIndex + 1, dup);
    _pageIndex++;
    _undoStack.clear();
    _viewInitialized = false;
    _touch();
  }

  /// Reordena las páginas moviendo la página en [oldIndex] a [newIndex].
  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= pageCount) return;
    if (newIndex < 0 || newIndex >= pageCount) return;
    final page = _document.pages.removeAt(oldIndex);
    _document.pages.insert(newIndex, page);
    // Actualiza el índice de la página activa para que siga apuntando a la misma.
    if (_pageIndex == oldIndex) {
      _pageIndex = newIndex;
    } else if (oldIndex < _pageIndex && newIndex >= _pageIndex) {
      _pageIndex--;
    } else if (oldIndex > _pageIndex && newIndex <= _pageIndex) {
      _pageIndex++;
    }
    _touch();
  }

  // ------------------------------------------------------------------
  // Plantillas
  // ------------------------------------------------------------------

  void setTemplate(PageTemplate template) {
    page.template = template;
    _touch();
  }

  // ------------------------------------------------------------------
  // Imágenes
  // ------------------------------------------------------------------

  void addImage(ImageItem item) {
    page.images.add(item);
    _selectedImageId = item.id;
    _undoStack.push(CanvasAction(imagesAdded: [item]));
    _touch();
  }

  void updateImage(ImageItem oldItem, ImageItem newItem) {
    final index = page.images.indexOf(oldItem);
    if (index < 0) return;
    page.images[index] = newItem;
    _undoStack.push(
      CanvasAction(imagesRemoved: [oldItem], imagesAdded: [newItem]),
    );
    _touch();
  }

  /// Actualiza la posición/tamaño de una imagen en vivo (durante el arrastre)
  /// sin empujar acciones de deshacer por cada frame.
  void updateImageLive(ImageItem updated) {
    final index = page.images.indexWhere((i) => i.id == updated.id);
    if (index < 0) return;
    page.images[index] = updated;
    notifyListeners();
  }

  /// Confirma el cambio de una imagen al soltar el dedo: reemplaza el item y
  /// registra una única acción de deshacer ([before] → [after]).
  void commitImageChange(ImageItem before, ImageItem after) {
    final index = page.images.indexWhere((i) => i.id == after.id);
    if (index >= 0) page.images[index] = after;
    _undoStack.push(
      CanvasAction(imagesRemoved: [before], imagesAdded: [after]),
    );
    _touch();
  }

  void removeImage(ImageItem item) {
    page.images.remove(item);
    if (_selectedImageId == item.id) _selectedImageId = null;
    _undoStack.push(CanvasAction(imagesRemoved: [item]));
    _touch();
  }

  void selectImage(String? id) {
    if (_selectedImageId == id) return;
    _selectedImageId = id;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Transformación de vista (zoom / pan)
  // ------------------------------------------------------------------

  void _setView(double scale, Offset translate) {
    _scale = scale.clamp(0.1, 6.0);
    _translate = translate;
    notifyListeners();
  }

  /// Aplica directamente una transformación (usado por el gesto de pellizco).
  void setView(double scale, Offset translate) => _setView(scale, translate);

  /// Aplica zoom alrededor de un punto de la pantalla (en coordenadas del
  /// viewport). Usado por el gesto de pellizco y por los botones de zoom.
  void zoomAt(double factor, Offset focal, Size viewportSize) {
    final newScale = (_scale * factor).clamp(0.1, 6.0);
    final scaleChange = newScale / _scale;
    // Mantiene fijo el punto del mundo que está bajo [focal].
    final newTranslate = focal - (focal - _translate) * scaleChange;
    _setView(newScale, newTranslate);
  }

  /// Pan por un delta de pantalla.
  void panBy(Offset delta) {
    _setView(_scale, _translate + delta);
  }

  /// Ajusta la vista al contenido: hoja finita centrada o zoom 100% para
  /// lienzos infinitos.
  void fitView(Size viewportSize) {
    if (viewportSize.isEmpty) return;
    final t = page.template;
    if (t.isFinite) {
      final s = sheetSize;
      final fit = min(
        viewportSize.width / s.width,
        viewportSize.height / s.height,
      );
      final scale = min(fit * 0.95, 1.5);
      _setView(
        scale,
        Offset(
          (viewportSize.width - s.width * scale) / 2,
          (viewportSize.height - s.height * scale) / 2,
        ),
      );
    } else {
      _setView(1.0, Offset.zero);
    }
    _viewInitialized = true;
  }

  /// Convierte un punto del viewport a coordenadas de mundo.
  Offset viewportToWorld(Offset local, Size viewportSize) =>
      (local - _translate) / _scale;

  /// Convierte coordenadas de mundo a viewport.
  Offset worldToViewport(Offset world, Size viewportSize) =>
      world * _scale + _translate;

  /// Llamado tras el primer layout del lienzo para encuadrar la vista.
  void ensureViewInitialized(Size viewportSize) {
    if (!_viewInitialized) fitView(viewportSize);
  }

  // ------------------------------------------------------------------
  // Persistencia
  // ------------------------------------------------------------------

  /// Marca el documento como modificado y agenda guardado automático
  /// (debounced) para no perder trazos ante cierres inesperados.
  void _touch() {
    _document.updatedAt = DateTime.now();
    _contentVersion++;
    notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      _storage.save(_document);
      // Replica a la nube si la UI registró un callback (sesión iniciada).
      onRemoteSync?.call(_document);
    });
  }

  /// Reemplaza el documento completo (tras restaurar desde la nube).
  void replaceDocument(Document doc) {
    _document = doc;
    _pageIndex = 0;
    _undoStack.clear();
    _selectedImageId = null;
    _viewInitialized = false;
    _touch();
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _storage.save(_document);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Último intento de persistir antes de morir.
    _storage.save(_document);
    super.dispose();
  }
}
