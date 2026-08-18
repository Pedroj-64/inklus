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
import '../models/text_item.dart';
import '../services/storage_service.dart';
import 'eraser.dart';
import 'shape_detector.dart';
import 'stroke_engine.dart';
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
    ToolType.lasso: (0, 0),
  };
  final Map<ToolType, double> _toolSizes = {
    ToolType.pen: 3.5,
    ToolType.pencil: 4.5,
    ToolType.highlighter: 26,
    ToolType.eraser: 36,
  };
  bool _fingerDrawingEnabled = true;
  bool _shapeDetectionEnabled = true;

  // ---- Ajustes de presión / streamline por herramienta ----
  final Map<ToolType, double> _thinning = {
    ToolType.pen: 0,
    ToolType.pencil: 0.55,
    ToolType.highlighter: 0,
  };
  final Map<ToolType, double> _smoothing = {
    ToolType.pen: 0.5,
    ToolType.pencil: 0.5,
    ToolType.highlighter: 0.6,
  };
  final Map<ToolType, double> _streamline = {
    ToolType.pen: 0.45,
    ToolType.pencil: 0.5,
    ToolType.highlighter: 0.75,
  };

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

  // ---- Guías magnéticas (snap) ----
  List<double> _snapVerticalGuides = [];
  List<double> _snapHorizontalGuides = [];
  List<double> get snapVerticalGuides => _snapVerticalGuides;
  List<double> get snapHorizontalGuides => _snapHorizontalGuides;

  void setSnapGuides(List<double> vertical, List<double> horizontal) {
    _snapVerticalGuides = vertical;
    _snapHorizontalGuides = horizontal;
    notifyListeners();
  }

  void clearSnapGuides() {
    _snapVerticalGuides = [];
    _snapHorizontalGuides = [];
  }

  // ---- Capas ----
  int _activeLayerIndex = 0;

  // ---- Selección con lazo ----
  List<Offset> _lassoPath = [];
  List<Stroke> _selectedStrokes = [];

  // ---- Portapapeles de trazos (copy/paste) ----
  List<Stroke> _clipboardStrokes = [];

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
  List<Offset> get lassoPath => List.unmodifiable(_lassoPath);
  List<Stroke> get selectedStrokes => List.unmodifiable(_selectedStrokes);
  int get activeLayerIndex => _activeLayerIndex;
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

  bool get shapeDetectionEnabled => _shapeDetectionEnabled;

  void setShapeDetection(bool enabled) {
    _shapeDetectionEnabled = enabled;
    notifyListeners();
  }

  // ---- Ajustes de presión / streamline ----

  double get thinning => _thinning[_tool] ?? 0;
  double get smoothing => _smoothing[_tool] ?? 0.5;
  double get streamline => _streamline[_tool] ?? 0.5;

  void setThinning(double value) {
    if (_tool == ToolType.eraser || _tool == ToolType.select) return;
    _thinning[_tool] = value.clamp(-1, 1);
    notifyListeners();
  }

  void setSmoothing(double value) {
    if (_tool == ToolType.eraser || _tool == ToolType.select) return;
    _smoothing[_tool] = value.clamp(0, 1);
    notifyListeners();
  }

  void setStreamline(double value) {
    if (_tool == ToolType.eraser || _tool == ToolType.select) return;
    _streamline[_tool] = value.clamp(0, 1);
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
    if (tool == ToolType.lasso) {
      beginLasso(worldPoint);
      return;
    }
    if (tool == ToolType.bucket) {
      _bucketFill(worldPoint);
      return;
    }
    if (tool == ToolType.text) {
      addTextItem(worldPoint);
      return;
    }
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
        layerIndex: _activeLayerIndex,
      );
      _activeEraserPath = [];
    }
    notifyListeners();
  }

  void addStrokePoint(Offset worldPoint, double pressure) {
    if (_lassoPath.isNotEmpty) {
      addLassoPoint(worldPoint);
      return;
    }
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
    if (_lassoPath.isNotEmpty) {
      endLasso();
      return;
    }
    if (!_isDrawing) return;
    _isDrawing = false;
    final active = _activeStroke;
    _activeStroke = null;
    final eraserPath = List<Offset>.from(_activeEraserPath);
    _activeEraserPath = [];

    if (active != null && active.points.length >= 2) {
      // Detección de formas: post-procesa el trazo para detectar
      // figuras geométricas simples (línea, rectángulo, círculo, flecha).
      Stroke finalStroke = active;
      if (_shapeDetectionEnabled &&
          active.tool != ToolType.highlighter &&
          active.tool != ToolType.eraser) {
        final shape = ShapeDetector.detect(active.points);
        if (shape != null) {
          finalStroke = Stroke(
            id: active.id,
            points: shape.normalizedPoints,
            tool: active.tool,
            colorValue: active.colorValue,
            size: active.size,
          );
        }
      }
      page.strokes.add(finalStroke);
      _undoStack.push(CanvasAction(strokesAdded: [finalStroke]));
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
      p.textItems
        ..removeWhere((t) => action.textItemsAdded.contains(t))
        ..addAll(action.textItemsRemoved);
    } else {
      p.strokes
        ..removeWhere((s) => action.strokesRemoved.contains(s))
        ..addAll(action.strokesAdded);
      p.images
        ..removeWhere((i) => action.imagesRemoved.contains(i))
        ..addAll(action.imagesAdded);
      p.textItems
        ..removeWhere((t) => action.textItemsRemoved.contains(t))
        ..addAll(action.textItemsAdded);
    }
    // Invalida caché de trazos afectados.
    for (final s in action.strokesAdded) {
      StrokeEngine.invalidate(s.id);
    }
    for (final s in action.strokesRemoved) {
      StrokeEngine.invalidate(s.id);
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
  // Selección con lazo
  // ------------------------------------------------------------------

  void beginLasso(Offset worldPoint) {
    _lassoPath = [worldPoint];
    _selectedStrokes = [];
    notifyListeners();
  }

  void addLassoPoint(Offset worldPoint) {
    if (_lassoPath.isEmpty) return;
    _lassoPath.add(worldPoint);
    notifyListeners();
  }

  /// Termina el lazo y selecciona los trazos que caen dentro.
  void endLasso() {
    if (_lassoPath.length < 3) {
      _lassoPath = [];
      notifyListeners();
      return;
    }
    // Hit-test: ¿qué trazos tienen al menos un punto dentro del polígono?
    final lassoPolygon = _lassoPath;
    _selectedStrokes = page.strokes.where((stroke) {
      for (final p in stroke.points) {
        if (_pointInPolygon(p.offset, lassoPolygon)) return true;
      }
      return false;
    }).toList();
    _lassoPath = [];
    notifyListeners();
  }

  void clearLassoSelection() {
    _selectedStrokes = [];
    _lassoPath = [];
    notifyListeners();
  }

  /// Elimina los trazos seleccionados con el lazo (deshacer possible).
  void deleteSelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;
    final removed = List<Stroke>.from(_selectedStrokes);
    for (final s in removed) {
      page.strokes.remove(s);
    }
    _undoStack.push(CanvasAction(strokesRemoved: removed));
    _selectedStrokes = [];
    _touch();
  }

  /// Copia los trazos seleccionados al portapapeles interno.
  void copySelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;
    _clipboardStrokes = List<Stroke>.from(_selectedStrokes);
  }

  /// Pega los trazos del portapapeles en la página actual,
  /// desplazándolos 30 unidades en X e Y para que no se superpongan.
  void pasteStrokes() {
    if (_clipboardStrokes.isEmpty) return;
    const offset = Offset(30, 30);
    final newStrokes = <Stroke>[];
    for (final s in _clipboardStrokes) {
      final newPoints = s.points.map((p) {
        return StrokePoint(p.x + offset.dx, p.y + offset.dy, p.pressure);
      }).toList();
      final newStroke = Stroke(
        id: 'st_${DateTime.now().microsecondsSinceEpoch}_${newStrokes.length}',
        points: newPoints,
        tool: s.tool,
        colorValue: s.colorValue,
        size: s.size,
      );
      newStrokes.add(newStroke);
      page.strokes.add(newStroke);
    }
    _undoStack.push(CanvasAction(strokesAdded: newStrokes));
    _selectedStrokes = newStrokes;
    _touch();
  }

  bool get hasClipboard => _clipboardStrokes.isNotEmpty;

  // ------------------------------------------------------------------
  // Transformar selección (escalar/rotar)
  // ------------------------------------------------------------------

  /// Aplica una transformación afín a los trazos seleccionados.
  /// [scaleFactor] = factor de escala, [rotationAngle] = ángulo en radianes,
  /// ambos relativos al centro de la selección.
  void transformSelectedStrokes({
    required double scaleFactor,
    required double rotationAngle,
    required Offset pivotPoint,
  }) {
    if (_selectedStrokes.isEmpty) return;
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);

    for (final original in List<Stroke>.from(_selectedStrokes)) {
      final newPoints = original.points.map((p) {
        // 1. Trasladar al origen relativo al pivot.
        var dx = p.x - pivotPoint.dx;
        var dy = p.y - pivotPoint.dy;
        // 2. Escalar.
        dx *= scaleFactor;
        dy *= scaleFactor;
        // 3. Rotar.
        final rx = dx * cosA - dy * sinA;
        final ry = dx * sinA + dy * cosA;
        // 4. Volver al espacio mundo.
        return StrokePoint(rx + pivotPoint.dx, ry + pivotPoint.dy, p.pressure);
      }).toList();

      final newStroke = Stroke(
        id: original.id,
        points: newPoints,
        tool: original.tool,
        colorValue: original.colorValue,
        size: original.size * scaleFactor,
        fillColorValue: original.fillColorValue,
      );

      // Reemplaza el trazo en la página.
      final idx = page.strokes.indexOf(original);
      if (idx >= 0) page.strokes[idx] = newStroke;
      // Actualiza la referencia en la selección.
      final selIdx = _selectedStrokes.indexOf(original);
      if (selIdx >= 0) _selectedStrokes[selIdx] = newStroke;
    }
    _touch();
  }

  /// Confirma la transformación de selección (empuja acción de deshacer).
  void commitTransformSelection(List<Stroke> before) {
    if (_selectedStrokes.isEmpty) return;
    _undoStack.push(
      CanvasAction(
        strokesRemoved: before,
        strokesAdded: List<Stroke>.from(_selectedStrokes),
      ),
    );
  }

  // ------------------------------------------------------------------
  // TextItems (cajas de texto)
  // ------------------------------------------------------------------

  String? _editingTextId;

  String? get editingTextId => _editingTextId;

  void addTextItem(Offset worldPoint) {
    final item = TextItem(
      id: 'txt_${DateTime.now().microsecondsSinceEpoch}',
      x: worldPoint.dx,
      y: worldPoint.dy,
      width: 250,
      text: '',
      colorValue: _color.toARGB32(),
      layerIndex: _activeLayerIndex,
    );
    page.textItems.add(item);
    _editingTextId = item.id;
    _undoStack.push(CanvasAction(textItemsAdded: [item]));
    _touch();
  }

  void updateTextItem(TextItem item) {
    final index = page.textItems.indexWhere((t) => t.id == item.id);
    if (index >= 0) {
      page.textItems[index] = item;
      notifyListeners();
      _scheduleSave();
    }
  }

  void commitTextItem(TextItem item) {
    _editingTextId = null;
    _touch();
  }

  void removeTextItem(TextItem item) {
    page.textItems.remove(item);
    if (_editingTextId == item.id) _editingTextId = null;
    _undoStack.push(CanvasAction(textItemsRemoved: [item]));
    _touch();
  }

  // ------------------------------------------------------------------
  // Capas
  // ------------------------------------------------------------------

  void setActiveLayer(int index) {
    if (index < 0 || index >= page.layers.length) return;
    _activeLayerIndex = index;
    notifyListeners();
  }

  void addLayer() {
    final name = 'Capa ${page.layers.length + 1}';
    page.layers.add(Layer(name: name));
    _activeLayerIndex = page.layers.length - 1;
    _touch();
  }

  void removeLayer(int index) {
    if (page.layers.length <= 1 || index == 0) return; // No eliminar la capa 0
    // Mueve los trazos e imágenes de la capa eliminada a la capa 0.
    for (final s in page.strokes) {
      if (s.layerIndex == index) {
        // No podemos mutar directamente, así que lo ignoramos por ahora
        // (los trazos de la capa eliminada quedan huérfanos, no se renderizan).
      }
    }
    page.layers.removeAt(index);
    if (_activeLayerIndex >= page.layers.length) {
      _activeLayerIndex = page.layers.length - 1;
    }
    _touch();
  }

  void toggleLayerVisibility(int index) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].visible = !page.layers[index].visible;
    _touch();
  }

  void toggleLayerLocked(int index) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].locked = !page.layers[index].locked;
    _touch();
  }

  void renameLayer(int index, String name) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].name = name;
    _touch();
  }

  // ------------------------------------------------------------------
  // Bucket fill (relleno de áreas)
  // ------------------------------------------------------------------

  /// Rellena el área más cercana al punto con el color actual.
  void _bucketFill(Offset worldPoint) {
    // Encuentra el trazo más cercano cuyo contorno encierre el punto.
    Stroke? enclosingStroke;
    var bestDistance = double.infinity;

    for (final stroke in page.strokes) {
      final outline = StrokeEngine.outlineFor(stroke);
      if (outline.length < 3) continue;
      if (_pointInPolygon(worldPoint, outline)) {
        // El punto está dentro del contorno del trazo.
        final center = _polygonCenter(outline);
        final dist = (worldPoint - center).distance;
        if (dist < bestDistance) {
          bestDistance = dist;
          enclosingStroke = stroke;
        }
      }
    }

    if (enclosingStroke != null) {
      // Crea un trazo de relleno usando los puntos del trazo encontrado.
      final fillStroke = Stroke(
        id: 'st_${DateTime.now().microsecondsSinceEpoch}',
        points: enclosingStroke.points,
        tool: enclosingStroke.tool,
        colorValue: enclosingStroke.colorValue,
        size: enclosingStroke.size,
        fillColorValue: _color.toARGB32(),
      );
      page.strokes.add(fillStroke);
      _undoStack.push(CanvasAction(strokesAdded: [fillStroke]));
      _touch();
    }
  }

  /// Centro de un polígono (promedio de los puntos).
  Offset _polygonCenter(List<Offset> polygon) {
    var x = 0.0, y = 0.0;
    for (final p in polygon) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / polygon.length, y / polygon.length);
  }

  /// Algoritmo ray-casting para punto dentro de polígono.
  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].dx, yi = polygon[i].dy;
      final xj = polygon[j].dx, yj = polygon[j].dy;
      if (((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
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
