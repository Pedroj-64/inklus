// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/document.dart';
import '../models/id.dart';
import '../models/note.dart';
import '../models/image_item.dart';
import '../models/page.dart';
import '../models/stroke.dart';
import '../models/template.dart';
import '../models/text_item.dart';
import '../services/storage_service.dart';
import '../utils/geometry_utils.dart';
import 'bucket_fill.dart';
import 'eraser.dart';
import 'lasso.dart';
import 'ruler.dart';
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
  Note _note;
  String _notebookId;
  int _pageIndex = 0;

  // ---- Herramientas ----
  ToolType _tool = ToolType.pen;
  Color _color = kDefaultStrokeColor;
  final Map<ToolType, double> _toolSizes = Map.of(kDefaultToolSizes);
  bool _fingerDrawingEnabled = true;
  ShapeMode _shapeMode = ShapeMode.hold;

  // ---- Ajustes de presión / streamline por herramienta ----
  final Map<ToolType, double> _thinning = Map.of(kDefaultThinning);
  final Map<ToolType, double> _smoothing = Map.of(kDefaultSmoothing);
  final Map<ToolType, double> _streamline = Map.of(kDefaultStreamline);

  // ---- Transformación de vista ----
  double _scale = kDefaultZoom;
  Offset _translate = Offset.zero;
  bool _viewInitialized = false;

  /// Tamaño del viewport del lienzo (lo actualiza la vista en cada layout).
  Size viewportSize = Size.zero;

  // ---- Trazo en progreso ----
  // El trazo activo comparte esta lista mutable: añadir un punto es O(1)
  // (antes se copiaba la lista entera en cada evento → O(n²) por trazo).
  List<StrokePoint> _activePoints = [];
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

  // ---- Regla virtual ----
  bool _rulerEnabled = false;
  RulerType _rulerType = RulerType.straight;
  Offset _rulerCenter = Offset.zero;
  double _rulerAngle = 0; // radianes

  /// Borde/arco al que se engancha el trazo en curso (null = trazo libre).
  RulerSnap? _rulerSnap;

  // ---- Lupa ----
  bool _magnifierEnabled = false;
  Offset _magnifierPosition = Offset.zero;
  double _magnifierZoom = kMagnifierDefaultZoom;

  // ---- Selección con lazo ----
  List<Offset> _lassoPath = [];
  List<Stroke> _selectedStrokes = [];

  // ---- Portapapeles de trazos (copy/paste) ----
  List<Stroke> _clipboardStrokes = [];

  final UndoStack _undoStack = UndoStack(maxDepth: kMaxUndoDepth);

  // ---- Notificadores granulares ----
  // Permiten que la barra del editor y sus popovers solo se reconstruyan cuando
  // cambia lo que realmente les importa, en vez de en cada trazo.
  /// Cambia cuando: tool, rulerEnabled, magnifierEnabled.
  final ValueNotifier<int> _toolContextNotifier = ValueNotifier<int>(0);
  ValueListenable<int> get toolContextNotifier => _toolContextNotifier;

  /// Cambia cuando: tool, color, toolSize, shapeDetection, fingerDrawing,
  /// selectedStrokes, hasClipboard.
  final ValueNotifier<int> _bottomBarContextNotifier = ValueNotifier<int>(0);
  ValueListenable<int> get bottomBarContextNotifier => _bottomBarContextNotifier;

  int _toolContextVersion = 0;
  int _bottomBarContextVersion = 0;

  /// Notifica solo a los listeners del tool rail.
  void _notifyToolContext() {
    _toolContextNotifier.value = ++_toolContextVersion;
  }

  /// Notifica solo a los listeners de la bottom bar.
  void _notifyBottomBarContext() {
    _bottomBarContextNotifier.value = ++_bottomBarContextVersion;
  }

  int? _lastToolKey;
  int? _lastBottomBarKey;

  /// Además de avisar a los listeners generales, avisa a los notificadores
  /// granulares **solo si cambió lo que ellos muestran**. Así el tool rail y
  /// la bottom bar se mantienen correctos sin que la pantalla entera tenga
  /// que reconstruirse en cada punto del trazo.
  @override
  void notifyListeners() {
    final toolKey = Object.hash(_tool, _rulerEnabled, _rulerType, _magnifierEnabled);
    if (toolKey != _lastToolKey) {
      _lastToolKey = toolKey;
      _notifyToolContext();
    }
    final bottomKey = Object.hash(
      _tool,
      _color,
      toolSize,
      _shapeMode,
      _fingerDrawingEnabled,
      selectionCount,
      _clipboardStrokes.isNotEmpty,
    );
    if (bottomKey != _lastBottomBarKey) {
      _lastBottomBarKey = bottomKey;
      _notifyBottomBarContext();
    }
    super.notifyListeners();
  }

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
  /// para replicar el Note en Google Drive cuando hay sesión.
  Future<void> Function(Note note)? onRemoteSync;

  /// Callback invocado cuando se intenta editar en una capa bloqueada.
  VoidCallback? _onLayerBlocked;

  /// Registra el callback de capa bloqueada.
  set onLayerBlocked(VoidCallback? cb) => _onLayerBlocked = cb;

  Timer? _saveTimer;
  Duration _autosaveDebounce = kSaveDebounce;

  CanvasController(this._storage, {Note? initial, String? notebookId})
      : _note = initial ?? Note.newBlank(),
        _notebookId = notebookId ?? '' {
    _loadAutosaveInterval();
    _loadInputPrefs();
  }

  /// Carga el intervalo de autoguardado desde SharedPreferences.
  Future<void> _loadAutosaveInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt('autosave_interval') ?? 0;
      if (seconds > 0) {
        _autosaveDebounce = Duration(seconds: seconds);
      }
    } catch (_) {}
  }

  /// Persiste el intervalo de autoguardado.
  static Future<void> setAutosaveInterval(Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autosave_interval', interval.inSeconds);
  }

  Duration get autosaveDebounce => _autosaveDebounce;

  // ------------------------------------------------------------------
  // Accesores
  // ------------------------------------------------------------------

  Note get note => _note;
  String get notebookId => _notebookId;

  /// Compatibilidad: devuelve un Document construido desde el Note.
  /// Se usa en exportación y sync (que todavía esperan Document).
  Document get document => Document(
        id: _note.id,
        title: _note.title,
        createdAt: _note.createdAt,
        updatedAt: _note.updatedAt,
        pages: _note.pages,
      );

  List<Page> get pages => _note.pages;
  Page get page => _note.pages[_pageIndex];
  int get pageIndex => _pageIndex;
  int get pageCount => _note.pages.length;

  ToolType get tool => _tool;
  Color get color => _color;
  double get toolSize => _toolSizes[_tool] ?? kDefaultToolSizes[ToolType.pen]!;
  bool get fingerDrawingEnabled => _fingerDrawingEnabled;

  /// true si la herramienta actual escribe tinta (plumas; no resaltador).
  bool get isInkTool => const {
        ToolType.pen,
        ToolType.pencil,
        ToolType.calligraphy,
        ToolType.brush,
        ToolType.marker,
        ToolType.spray,
      }.contains(_tool);

  /// Rango de tamaño permitido para la herramienta actual.
  (double, double) get sizeRange => kToolSizeRanges[_tool] ?? (2, 14);

  double get scale => _scale;
  Offset get translate => _translate;
  Stroke? get activeStroke => _activeStroke;
  bool get isDrawing => _isDrawing;
  List<Offset> get activeEraserPath => _activeEraserPath;
  String? get selectedImageId => _selectedImageId;
  List<Offset> get lassoPath => List.unmodifiable(_lassoPath);
  List<Stroke> get selectedStrokes => List.unmodifiable(_selectedStrokes);

  // ---- Selección del lazo: imágenes y cajas de texto ----
  // Se guardan por id: sus instancias se reemplazan al moverlas.
  Set<String> _selectedImageIds = {};
  Set<String> _selectedTextIds = {};

  /// Imágenes seleccionadas con el lazo (instancias actuales de la página).
  List<ImageItem> get selectedImages =>
      page.images.where((i) => _selectedImageIds.contains(i.id)).toList();

  /// Cajas de texto seleccionadas con el lazo.
  List<TextItem> get selectedTexts =>
      page.textItems.where((t) => _selectedTextIds.contains(t.id)).toList();

  /// Número total de elementos seleccionados con el lazo.
  int get selectionCount =>
      _selectedStrokes.length + _selectedImageIds.length + _selectedTextIds.length;

  bool get hasLassoSelection => selectionCount > 0;

  /// Rectángulo que envuelve toda la selección (trazos, imágenes y textos).
  Rect get selectionBoundsAll {
    Rect? r = _selectedStrokes.isEmpty ? null : selectionBounds(_selectedStrokes);
    for (final i in selectedImages) {
      r = r == null ? i.rect : r.expandToInclude(i.rect);
    }
    for (final t in selectedTexts) {
      r = r == null ? t.rect : r.expandToInclude(t.rect);
    }
    return r ?? Rect.zero;
  }

  void _clearItemSelection() {
    _selectedImageIds = {};
    _selectedTextIds = {};
    _moveImagesBefore = null;
    _moveTextsBefore = null;
  }

  /// Estado de imágenes/textos al empezar a mover la selección.
  List<ImageItem>? _moveImagesBefore;
  List<TextItem>? _moveTextsBefore;
  int get activeLayerIndex => _activeLayerIndex;
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;
  bool get viewNeedsInit => !_viewInitialized;

  // ---- Regla ----
  bool get rulerEnabled => _rulerEnabled;
  RulerType get rulerType => _rulerType;
  Offset get rulerCenter => _rulerCenter;
  double get rulerAngle => _rulerAngle;

  /// Geometría actual de la regla (depende del zoom: tamaño fijo en pantalla).
  RulerGeometry get rulerGeometry => RulerGeometry(
        type: _rulerType,
        center: _rulerCenter,
        angle: _rulerAngle,
        scale: _scale,
      );

  // ---- Lupa ----
  bool get magnifierEnabled => _magnifierEnabled;
  Offset get magnifierPosition => _magnifierPosition;
  double get magnifierZoom => _magnifierZoom;
  double get magnifierRadius => kMagnifierRadius;

  /// Radio (mundo) del círculo de borrado actual.
  double get eraserRadius => _toolSizes[ToolType.eraser]! / 2;

  /// Tamaño de la hoja finita actual (sheet o custom sin relleno).
  Size get sheetSize => page.template.sheetSize;

  // ------------------------------------------------------------------
  // Capas bloqueadas
  // ------------------------------------------------------------------

  /// Verifica si la capa activa está bloqueada.
  bool get isActiveLayerLocked {
    if (_activeLayerIndex < page.layers.length) {
      return page.layers[_activeLayerIndex].locked;
    }
    return false;
  }

  /// Verifica si la capa de un trazo/imagen/texto está bloqueada.
  bool _isLayerLocked(int layerIndex) {
    if (layerIndex < page.layers.length) {
      return page.layers[layerIndex].locked;
    }
    return false;
  }

  bool _isLayerVisible(int layerIndex) =>
      layerIndex >= page.layers.length || page.layers[layerIndex].visible;

  // ------------------------------------------------------------------
  // Herramientas
  // ------------------------------------------------------------------

  void setTool(ToolType tool) {
    if (_tool == tool) return;
    _tool = tool;
    _selectedImageId = null;
    _notifyToolContext();
    _notifyBottomBarContext();
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    _notifyBottomBarContext();
    notifyListeners();
  }

  void setToolSize(double size) {
    final range = kToolSizeRanges[_tool];
    if (range != null) {
      _toolSizes[_tool] = size.clamp(range.$1, range.$2);
    }
    _notifyBottomBarContext();
    notifyListeners();
  }

  /// Activa/desactiva dibujar con el dedo. Si lo cambia el usuario
  /// ([byUser]), su elección se recuerda y la detección automática del
  /// lápiz deja de tocarla.
  void setFingerDrawing(bool enabled, {bool byUser = true}) {
    _fingerDrawingEnabled = enabled;
    if (byUser) _fingerDrawingUserSet = true;
    _notifyBottomBarContext();
    notifyListeners();
    _saveInputPrefs();
  }

  static const _prefFingerDrawing = 'finger_drawing';
  static const _prefFingerDrawingUserSet = 'finger_drawing_user_set';
  bool _fingerDrawingUserSet = false;

  /// Mensajes informativos para la UI (p. ej. "Lápiz detectado").
  void Function(String message)? onNotice;

  /// Lo llama el lienzo al ver un lápiz. La primera vez (si el usuario no
  /// eligió otra cosa) pasa a modo *solo lápiz*: el dedo desplaza la página
  /// y la palma no puede rayar. Es el comportamiento de GoodNotes/Notability.
  void onStylusDetected() {
    if (_fingerDrawingUserSet || !_fingerDrawingEnabled) return;
    _fingerDrawingEnabled = false;
    _fingerDrawingUserSet = true; // solo una vez; luego manda el usuario
    _notifyBottomBarContext();
    notifyListeners();
    _saveInputPrefs();
    onNotice?.call(
      'Lápiz detectado: ahora el dedo desplaza la página (actívalo en la barra si quieres dibujar con el dedo)',
    );
  }

  Future<void> _loadInputPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fingerDrawingUserSet = prefs.getBool(_prefFingerDrawingUserSet) ?? false;
      final saved = prefs.getBool(_prefFingerDrawing);
      if (saved != null && saved != _fingerDrawingEnabled && !_disposed) {
        _fingerDrawingEnabled = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveInputPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefFingerDrawing, _fingerDrawingEnabled);
      await prefs.setBool(_prefFingerDrawingUserSet, _fingerDrawingUserSet);
    } catch (_) {}
  }

  ShapeMode get shapeMode => _shapeMode;

  /// Compatibilidad: true si se enderezan figuras de algún modo.
  bool get shapeDetectionEnabled => _shapeMode != ShapeMode.off;

  void setShapeMode(ShapeMode mode) {
    _shapeMode = mode;
    notifyListeners();
  }

  /// Compatibilidad: true = [ShapeMode.always], false = [ShapeMode.off].
  void setShapeDetection(bool enabled) =>
      setShapeMode(enabled ? ShapeMode.always : ShapeMode.off);

  // ---- Mantener para enderezar ----
  Timer? _holdTimer;
  Offset? _holdAnchor;
  String? _heldShapeType; // figura aplicada al mantener (trazo en curso)

  /// Tiempo quieto al final del trazo para enderezar la figura.
  static const holdToShapeDelay = Duration(milliseconds: 550);

  void _trackHold(Offset worldPoint) {
    if (_shapeMode != ShapeMode.hold || _heldShapeType != null) return;
    final anchor = _holdAnchor;
    // Movimiento real (> ~3 px en pantalla): reinicia la cuenta.
    if (anchor == null || (worldPoint - anchor).distance * _scale > 3) {
      _holdAnchor = worldPoint;
      _holdTimer?.cancel();
      _holdTimer = Timer(holdToShapeDelay, _onHold);
    }
  }

  void _onHold() {
    final active = _activeStroke;
    if (!_isDrawing || active == null || _heldShapeType != null) return;
    if (active.tool == ToolType.highlighter || _activePoints.length < 10) return;
    final shape = ShapeDetector.detect(_activePoints);
    if (shape == null) return;
    _activePoints
      ..clear()
      ..addAll(shape.normalizedPoints);
    _heldShapeType = shape.type.name;
    if (_hapticEnabled) HapticFeedback.lightImpact();
    notifyListeners();
  }

  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdAnchor = null;
    _heldShapeType = null;
  }

  // ---- Puntero láser ----
  bool _laserMode = false;
  bool get laserMode => _laserMode;

  /// Estela del láser: puntos con su instante (ms). Se desvanece sola.
  final List<({Offset point, int t})> _laserTrail = [];
  List<({Offset point, int t})> get laserTrail => _laserTrail;
  Timer? _laserTicker;

  /// Duración de la estela del láser.
  static const laserFade = Duration(milliseconds: 750);

  void toggleLaser() {
    _laserMode = !_laserMode;
    if (!_laserMode) _laserTrail.clear();
    notifyListeners();
  }

  void _addLaserPoint(Offset p) {
    _laserTrail.add((point: p, t: DateTime.now().millisecondsSinceEpoch));
    _laserTicker ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final cutoff = DateTime.now().millisecondsSinceEpoch - laserFade.inMilliseconds;
      _laserTrail.removeWhere((e) => e.t < cutoff);
      if (_laserTrail.isEmpty && !_isDrawing) {
        _laserTicker?.cancel();
        _laserTicker = null;
      }
      if (!_disposed) notifyListeners();
    });
  }

  // ---- Regla virtual ----

  /// Muestra/oculta la regla. Al mostrarla se coloca en el centro de la
  /// vista, horizontal.
  void toggleRuler() {
    _rulerEnabled = !_rulerEnabled;
    if (_rulerEnabled) _placeRulerAtViewCenter();
    _notifyToolContext();
    notifyListeners();
  }

  /// Botón de la barra: apagada → regla → transportador → apagada.
  void cycleRuler() {
    if (!_rulerEnabled) {
      _rulerType = RulerType.straight;
      _rulerEnabled = true;
      _placeRulerAtViewCenter();
    } else if (_rulerType == RulerType.straight) {
      _rulerType = RulerType.protractor;
    } else {
      _rulerEnabled = false;
    }
    _notifyToolContext();
    notifyListeners();
  }

  /// Compatibilidad: cambia el tipo (la activa si estaba apagada).
  void cycleRulerType() => cycleRuler();

  void _placeRulerAtViewCenter() {
    _rulerCenter = viewportToWorld(
      Offset(viewportSize.width / 2, viewportSize.height / 2),
      viewportSize,
    );
    _rulerAngle = 0;
  }

  /// Mueve/rota la regla (gestos con los dedos). El ángulo tiene imán a
  /// múltiplos de 45°.
  void setRulerTransform(Offset center, double angle) {
    _rulerCenter = center;
    _rulerAngle = RulerGeometry.snapAngle(angle);
    notifyListeners();
  }

  /// Borde/arco al que se está enganchando el trazo en curso (para
  /// resaltarlo en pantalla); null si no hay trazo con regla.
  RulerSnap? get activeRulerSnap => _isDrawing ? _rulerSnap : null;

  /// true si [worldPoint] cae sobre la regla visible (para arrastrarla).
  bool hitsRuler(Offset worldPoint) =>
      _rulerEnabled && rulerGeometry.hitTest(worldPoint);

  // ---- Lupa ----

  void toggleMagnifier() {
    _magnifierEnabled = !_magnifierEnabled;
    _notifyToolContext();
    notifyListeners();
  }

  /// Actualiza la posición de la lupa (llamado en cada frame del stylus).
  void updateMagnifierPosition(Offset worldPoint) {
    _magnifierPosition = worldPoint;
    notifyListeners();
  }

  void setMagnifierZoom(double zoom) {
    _magnifierZoom = zoom.clamp(kMagnifierMinZoom, kMagnifierMaxZoom);
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
    // Láser: estela efímera, nunca se guarda ni pasa por deshacer.
    if (_laserMode && tool != ToolType.eraser) {
      _isDrawing = true;
      _activeStroke = null;
      _activeEraserPath = [];
      _addLaserPoint(worldPoint);
      return;
    }
    // Hoja fija: no se empieza a escribir fuera del papel (se guardaría un
    // trazo invisible, recortado por la hoja).
    if (tool != ToolType.eraser && page.template.isFinite) {
      final sheet = Rect.fromCenter(
        center: Offset.zero,
        width: sheetSize.width,
        height: sheetSize.height,
      );
      if (!sheet.inflate(4).contains(worldPoint)) return;
    }
    // Bloquear escritura si la capa activa está bloqueada.
    if (_isLayerLocked(_activeLayerIndex) && tool != ToolType.eraser) {
      _onLayerBlocked?.call();
      return;
    }
    _isDrawing = true;
    // Háptica sutil al empezar a escribir.
    if (_hapticEnabled && tool != ToolType.eraser) {
      HapticFeedback.selectionClick();
    }
    _selectedImageId = null;

    // Regla: el trazo se engancha solo si EMPIEZA cerca de un borde (o del
    // arco del transportador); si no, se dibuja libremente.
    _rulerSnap = (_rulerEnabled && tool != ToolType.eraser)
        ? rulerGeometry.snapFor(worldPoint)
        : null;
    final constrainedPoint = _rulerSnap != null
        ? rulerGeometry.project(_rulerSnap!, worldPoint)
        : worldPoint;

    if (tool == ToolType.eraser) {
      _activeEraserPath = [worldPoint];
      _activeStroke = null;
    } else {
      _activePoints = [
        StrokePoint.fromOffset(constrainedPoint, _pressure(pressure)),
      ];
      _activeStroke = Stroke(
        id: newId('st'),
        points: _activePoints,
        tool: tool,
        colorValue: _color.toARGB32(),
        size: _toolSizes[tool] ?? 3.5,
        layerIndex: _activeLayerIndex,
        // Solo se guardan los ajustes si difieren del valor por defecto:
        // así los trazos existentes/por defecto no cambian de forma.
        thinning: _customOption(_thinning, kDefaultThinning, tool),
        smoothing: _customOption(_smoothing, kDefaultSmoothing, tool),
        streamline: _customOption(_streamline, kDefaultStreamline, tool),
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
    if (_laserMode && _activeStroke == null && _activeEraserPath.isEmpty) {
      _addLaserPoint(worldPoint);
      return;
    }
    if (_activeStroke != null) {
      // Figura ya enderezada al mantener: se congela hasta soltar.
      if (_heldShapeType != null) return;
      // Si la regla está activa, proyecta el punto sobre su borde.
      final snap = _rulerSnap;
      final constrained =
          snap != null ? rulerGeometry.project(snap, worldPoint) : worldPoint;
      _activePoints.add(StrokePoint.fromOffset(constrained, _pressure(pressure)));
      if (snap == null) _trackHold(worldPoint);
    } else {
      _activeEraserPath.add(worldPoint);
    }
    // Actualiza posición de la lupa si está activa.
    if (_magnifierEnabled) {
      _magnifierPosition = worldPoint;
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
    final heldShape = _heldShapeType;
    _resetHold();
    if (_laserMode && _activeStroke == null && _activeEraserPath.isEmpty) {
      notifyListeners(); // la estela se desvanece sola
      return;
    }
    final active = _activeStroke;
    _activeStroke = null;
    final activePoints = _activePoints;
    _activePoints = [];
    final eraserPath = _activeEraserPath;
    _activeEraserPath = [];

    if (active != null && activePoints.length >= 2) {
      // Congela los puntos: a partir de aquí el trazo es inmutable.
      Stroke finalStroke = active.copyWith(
        points: List<StrokePoint>.unmodifiable(activePoints),
      );
      // Figuras: si ya se enderezó al mantener, solo se etiqueta; en modo
      // "siempre" se detecta ahora al soltar.
      if (heldShape != null) {
        finalStroke = finalStroke.copyWith(shapeType: heldShape);
      } else if (_shapeMode == ShapeMode.always &&
          active.tool != ToolType.highlighter &&
          active.tool != ToolType.eraser) {
        final shape = ShapeDetector.detect(finalStroke.points);
        if (shape != null) {
          // copyWith conserva capa, ajustes y demás atributos.
          finalStroke = finalStroke.copyWith(
            points: shape.normalizedPoints,
            shapeType: shape.type.name,
          );
        }
      }
      page.strokes.add(finalStroke);
      _undoStack.push(CanvasAction(
        strokesAdded: [finalStroke],
        strokesAddedAt: [page.strokes.length - 1],
      ));
    } else if (eraserPath.isNotEmpty) {
      _applyEraser(eraserPath);
    }
    _touch();
  }

  /// Borra con [eraserPath] conservando el orden de los trazos (los
  /// fragmentos ocupan el lugar del original) y sin tocar capas bloqueadas.
  /// El deshacer guarda solo los trazos afectados y sus posiciones.
  void _applyEraser(List<Offset> eraserPath) {
    final before = page.strokes;
    final after = <Stroke>[];
    var changed = false;
    for (final s in before) {
      final skip = _isLayerLocked(s.layerIndex) ||
          (_eraserMode == EraserMode.highlighterOnly &&
              s.tool != ToolType.highlighter);
      if (skip) {
        after.add(s);
        continue;
      }
      var fragments = StrokeEraser.eraseStroke(s, eraserPath, eraserRadius);
      // Modo trazo completo: si se tocó, desaparece entero.
      if (fragments != null && _eraserMode == EraserMode.stroke) {
        fragments = const [];
      }
      if (fragments == null) {
        after.add(s);
      } else {
        after.addAll(fragments);
        changed = true;
      }
    }
    if (!changed) return;
    final action = CanvasAction.strokeDiff(before, after);
    page.strokes
      ..clear()
      ..addAll(after);
    _undoStack.push(action);
  }

  EraserMode _eraserMode = EraserMode.partial;
  EraserMode get eraserMode => _eraserMode;

  void setEraserMode(EraserMode mode) {
    if (_eraserMode == mode) return;
    _eraserMode = mode;
    notifyListeners();
  }

  /// Valor de un ajuste de trazo solo si el usuario lo cambió.
  double? _customOption(
    Map<ToolType, double> current,
    Map<ToolType, double> defaults,
    ToolType tool,
  ) {
    final v = current[tool];
    if (v == null || v == defaults[tool]) return null;
    return v;
  }

  void cancelStroke() {
    _resetHold();
    _isDrawing = false;
    _activeStroke = null;
    _activePoints = [];
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
    applyOrderedSwap<Stroke>(
      p.strokes,
      remove: undo ? action.strokesAdded : action.strokesRemoved,
      add: undo ? action.strokesRemoved : action.strokesAdded,
      addAt: undo ? action.strokesRemovedAt : action.strokesAddedAt,
      idOf: (s) => s.id,
    );
    applyOrderedSwap<ImageItem>(
      p.images,
      remove: undo ? action.imagesAdded : action.imagesRemoved,
      add: undo ? action.imagesRemoved : action.imagesAdded,
      idOf: (i) => i.id,
    );
    applyOrderedSwap<TextItem>(
      p.textItems,
      remove: undo ? action.textItemsAdded : action.textItemsRemoved,
      add: undo ? action.textItemsRemoved : action.textItemsAdded,
      idOf: (t) => t.id,
    );
    // La selección apuntaría a instancias que ya no existen.
    _selectedStrokes = [];
    _clearItemSelection();
    _selectedImageId = null;
  }

  void setTitle(String title) {
    if (title.trim().isEmpty || title == _note.title) return;
    _note.title = title.trim();
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
    _note.pages.add(newPage);
    _pageIndex = pageCount - 1;
    _resetPageState();
    _viewInitialized = false; // re-ajusta la vista en el siguiente layout
    _touch();
  }

  void goToPage(int index) {
    if (index < 0 || index >= pageCount || index == _pageIndex) return;
    _pageIndex = index;
    _resetPageState();
    _viewInitialized = false;
    notifyListeners();
  }

  /// Limpia el estado ligado a la página actual (selecciones, deshacer,
  /// capa activa) al cambiar de página o de nota.
  void _resetPageState() {
    _selectedImageId = null;
    _selectedStrokes = [];
    _clearItemSelection();
    _lassoPath = [];
    _editingTextId = null;
    _undoStack.clear();
    _activeLayerIndex = 0;
  }

  /// Aviso con acción de deshacer (la UI lo muestra como snackbar).
  void Function(String message, VoidCallback undo)? onUndoableNotice;

  bool get canGoNext => _pageIndex < pageCount - 1;
  bool get canGoPrevious => _pageIndex > 0;

  void nextPage() {
    if (canGoNext) goToPage(_pageIndex + 1);
  }

  void previousPage() {
    if (canGoPrevious) goToPage(_pageIndex - 1);
  }

  /// Marca / desmarca la página actual.
  void toggleBookmark() {
    page.bookmarked = !page.bookmarked;
    _touch();
  }

  void deleteCurrentPage() {
    if (pageCount <= 1) return;
    final index = _pageIndex;
    final removed = _note.pages.removeAt(index);
    _pageIndex = min(_pageIndex, pageCount - 1);
    _resetPageState();
    _viewInitialized = false;
    _touch();
    onUndoableNotice?.call('Página eliminada', () => _restorePage(removed, index));
  }

  void _restorePage(Page removed, int index) {
    if (_note.pages.contains(removed)) return;
    _note.pages.insert(index.clamp(0, _note.pages.length), removed);
    _pageIndex = index.clamp(0, _note.pages.length - 1);
    _resetPageState();
    _viewInitialized = false;
    _touch();
  }

  /// Borra todo el contenido de la página. Se puede deshacer (Ctrl+Z /
  /// dos dedos) como cualquier otra acción.
  void clearPage() {
    final action = CanvasAction(
      strokesRemoved: List.of(page.strokes),
      strokesRemovedAt: [for (var i = 0; i < page.strokes.length; i++) i],
      imagesRemoved: List.of(page.images),
      textItemsRemoved: List.of(page.textItems),
    );
    page.strokes.clear();
    page.images.clear();
    page.textItems.clear();
    _undoStack.push(action);
    _selectedImageId = null;
    _selectedStrokes = [];
    _editingTextId = null;
    _touch();
  }

  /// Duplica la página actual y la inserta justo después.
  void duplicatePage() {
    final src = page;
    // Trazos, imágenes y textos son inmutables: basta con copiar las listas.
    // Las capas son mutables, así que se clonan.
    final dup = Page(
      id: newId('pg'),
      name: '${src.name} (copia)',
      strokes: List<Stroke>.of(src.strokes),
      images: List<ImageItem>.of(src.images),
      textItems: List<TextItem>.of(src.textItems),
      layers: [for (final l in src.layers) l.copyWith()],
      template: src.template,
    );
    _note.pages.insert(_pageIndex + 1, dup);
    _pageIndex++;
    _resetPageState();
    _viewInitialized = false;
    _touch();
  }

  /// Inserta páginas de un PDF importado (una página de la nota por página
  /// del PDF, como hoja FIJA con el PDF de fondo). Se escalan a ancho A4 en
  /// unidades de mundo para que la escritura tenga el mismo tamaño que en el
  /// resto de la libreta. Si la página actual está vacía, se reutiliza.
  void insertPdfPages(List<({String path, int width, int height})> pdfPages) {
    if (pdfPages.isEmpty) return;
    final pagesToAdd = <Page>[];
    for (var i = 0; i < pdfPages.length; i++) {
      final p = pdfPages[i];
      final w = PageTemplate.sheetWidth;
      final h = p.width == 0 ? PageTemplate.sheetHeight : w * p.height / p.width;
      pagesToAdd.add(Page.blank(
        name: 'PDF ${i + 1}',
        template: PageTemplate(
          type: TemplateType.custom,
          imagePath: p.path,
          infiniteFill: false,
          customWidth: w,
          customHeight: h,
        ),
      ));
    }
    final current = page;
    final currentEmpty = current.strokes.isEmpty &&
        current.images.isEmpty &&
        current.textItems.isEmpty;
    if (currentEmpty) {
      current.template = pagesToAdd.first.template;
      current.name = pagesToAdd.first.name;
      _note.pages.insertAll(_pageIndex + 1, pagesToAdd.skip(1));
    } else {
      _note.pages.insertAll(_pageIndex + 1, pagesToAdd);
      _pageIndex++;
    }
    _resetPageState();
    _viewInitialized = false;
    _touch();
  }

  /// Reordena las páginas moviendo la página en [oldIndex] a [newIndex].
  void reorderPage(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= pageCount) return;
    if (newIndex < 0 || newIndex >= pageCount) return;
    final page = _note.pages.removeAt(oldIndex);
    _note.pages.insert(newIndex, page);
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
    if (_isLayerLocked(item.layerIndex)) return;
    page.images.add(item);
    _selectedImageId = item.id;
    _undoStack.push(CanvasAction(imagesAdded: [item]));
    _touch();
  }

  void updateImage(ImageItem oldItem, ImageItem newItem) {
    if (_isLayerLocked(oldItem.layerIndex)) return;
    final index = page.images.indexWhere((i) => i.id == oldItem.id);
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
    if (_isLayerLocked(updated.layerIndex)) return;
    final index = page.images.indexWhere((i) => i.id == updated.id);
    if (index < 0) return;
    page.images[index] = updated;
    _touchLive();
  }

  /// Confirma el cambio de una imagen al soltar el dedo: reemplaza el item y
  /// registra una única acción de deshacer ([before] → [after]).
  void commitImageChange(ImageItem before, ImageItem after) {
    if (_isLayerLocked(before.layerIndex)) return;
    final index = page.images.indexWhere((i) => i.id == after.id);
    if (index >= 0) page.images[index] = after;
    _undoStack.push(
      CanvasAction(imagesRemoved: [before], imagesAdded: [after]),
    );
    _touch();
  }

  void removeImage(ImageItem item) {
    if (_isLayerLocked(item.layerIndex)) return;
    page.images.removeWhere((i) => i.id == item.id);
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
  ///
  /// Usa una estrategia de 3 niveles para una selección precisa:
  /// 1. **Punto dentro**: al menos un punto del trazo está dentro del polígono.
  /// 2. **Borde cruzado**: el contorno del trazo cruza el borde del lazo.
  /// 3. **Bounding box**: el rectángulo delimitador del trazo está completamente
  ///    dentro del lazo (para trazos grandes que no tienen puntos dentro).
  void endLasso() {
    if (_lassoPath.length < 3) {
      _lassoPath = [];
      notifyListeners();
      return;
    }
    final lassoPolygon = _lassoPath;
    final lassoBounds = polygonBounds(lassoPolygon);

    _selectedStrokes = page.strokes.where((stroke) {
      // Ignorar trazos en capas ocultas.
      if (stroke.layerIndex < page.layers.length &&
          !page.layers[stroke.layerIndex].visible) {
        return false;
      }
      // Ignorar herramientas especiales.
      if (stroke.tool == ToolType.eraser ||
          stroke.tool == ToolType.select ||
          stroke.tool == ToolType.lasso) {
        return false;
      }
      return isStrokeInLasso(stroke, lassoPolygon, lassoBounds);
    }).toList();

    // Imágenes y cajas de texto: entran si su centro está dentro del lazo
    // (capas ocultas o bloqueadas se ignoran).
    bool selectable(int layer) => _isLayerVisible(layer) && !_isLayerLocked(layer);
    _selectedImageIds = {
      for (final i in page.images)
        if (selectable(i.layerIndex) && pointInPolygon(Offset(i.x, i.y), lassoPolygon)) i.id,
    };
    _selectedTextIds = {
      for (final t in page.textItems)
        if (selectable(t.layerIndex) && pointInPolygon(Offset(t.x, t.y), lassoPolygon)) t.id,
    };

    _lassoPath = [];
    // Auto-cambiar a herramienta select para poder mover/redimensionar.
    if (hasLassoSelection) {
      _tool = ToolType.select;
    }
    _notifyToolContext();
    _notifyBottomBarContext();
    notifyListeners();
  }

  void clearLassoSelection() {
    _selectedStrokes = [];
    _clearItemSelection();
    _lassoPath = [];
    notifyListeners();
  }

  /// Restaura los trazos seleccionados a su estado original (sin mover).
  ///
  /// Se usa al cancelar un gesto de movimiento.
  void restoreStrokeSelection(List<Stroke> originals) {
    for (final original in originals) {
      final idx = page.strokes.indexWhere((s) => s.id == original.id);
      if (idx >= 0) {
        page.strokes[idx] = original;
      }
    }
    _selectedStrokes = List<Stroke>.from(originals);
    // Imágenes y textos vuelven a donde estaban al empezar a mover.
    for (final img in _moveImagesBefore ?? const <ImageItem>[]) {
      final idx = page.images.indexWhere((i) => i.id == img.id);
      if (idx >= 0) page.images[idx] = img;
    }
    for (final txt in _moveTextsBefore ?? const <TextItem>[]) {
      final idx = page.textItems.indexWhere((t) => t.id == txt.id);
      if (idx >= 0) page.textItems[idx] = txt;
    }
    _moveImagesBefore = null;
    _moveTextsBefore = null;
    _touch();
  }

  /// Elimina los trazos seleccionados con el lazo (deshacer possible).
  /// Elimina toda la selección del lazo (trazos, imágenes y textos) en una
  /// sola acción deshacible. Las capas bloqueadas no se tocan.
  void deleteSelectedStrokes() {
    if (!hasLassoSelection) return;
    final removable = Set<Stroke>.identity()
      ..addAll(_selectedStrokes.where((s) => !_isLayerLocked(s.layerIndex)));
    final images = selectedImages.where((i) => !_isLayerLocked(i.layerIndex)).toList();
    final texts = selectedTexts.where((t) => !_isLayerLocked(t.layerIndex)).toList();
    if (removable.isEmpty && images.isEmpty && texts.isEmpty) return;
    final before = List<Stroke>.of(page.strokes);
    page.strokes.removeWhere(removable.contains);
    _selectedStrokes.removeWhere(removable.contains);
    final imageIds = {for (final i in images) i.id};
    final textIds = {for (final t in texts) t.id};
    page.images.removeWhere((i) => imageIds.contains(i.id));
    page.textItems.removeWhere((t) => textIds.contains(t.id));
    _selectedImageIds.removeAll(imageIds);
    _selectedTextIds.removeAll(textIds);
    final diff = CanvasAction.strokeDiff(before, page.strokes);
    _undoStack.push(CanvasAction(
      strokesRemoved: diff.strokesRemoved,
      strokesRemovedAt: diff.strokesRemovedAt,
      imagesRemoved: images,
      textItemsRemoved: texts,
    ));
    _notifyBottomBarContext();
    _touch();
  }

  /// Copia los trazos seleccionados al portapapeles interno.
  void copySelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;
    _clipboardStrokes = List<Stroke>.from(_selectedStrokes);
    _notifyBottomBarContext();
  }

  /// Pega los trazos del portapapeles en la página actual,
  /// desplazándolos 30 unidades en X e Y para que no se superpongan.
  void pasteStrokes() {
    if (_clipboardStrokes.isEmpty) return;
    const offset = Offset(kPasteOffset, kPasteOffset);
    final newStrokes = <Stroke>[];
    // Pegar en una capa bloqueada no tiene sentido.
    if (_isLayerLocked(_activeLayerIndex)) {
      _onLayerBlocked?.call();
      return;
    }
    for (final s in _clipboardStrokes) {
      // Conserva color, relleno, figura y ajustes; se pega en la capa activa.
      final newStroke = s.translated(offset).copyWith(
            id: newId('st'),
            layerIndex: _activeLayerIndex,
          );
      newStrokes.add(newStroke);
      page.strokes.add(newStroke);
    }
    _undoStack.push(CanvasAction(strokesAdded: newStrokes));
    _selectedStrokes = newStrokes;
    _notifyBottomBarContext();
    _touch();
  }

  bool get hasClipboard => _clipboardStrokes.isNotEmpty;

  /// Cambia el color de los trazos seleccionados (deshacible). Los trazos
  /// rellenos conservan su relleno; solo cambia la tinta.
  void recolorSelection(Color color) {
    _editSelection((s) => s.copyWith(colorValue: color.toARGB32()));
  }

  /// Multiplica el grosor de los trazos seleccionados (deshacible).
  void scaleSelectionThickness(double factor) {
    _editSelection((s) => s.copyWith(size: (s.size * factor).clamp(0.5, 120.0)));
  }

  /// Aplica [edit] a cada trazo seleccionado (salvo capas bloqueadas),
  /// reemplazándolo en su sitio y registrando una sola acción de deshacer.
  void _editSelection(Stroke Function(Stroke) edit) {
    if (_selectedStrokes.isEmpty) return;
    final positions = <String, int>{
      for (var i = 0; i < page.strokes.length; i++) page.strokes[i].id: i,
    };
    final before = <Stroke>[]; // originales editados
    final edited = <Stroke>[]; // sus reemplazos (mismo id, mismo orden)
    final newSelection = <Stroke>[];
    for (final original in _selectedStrokes) {
      final idx = positions[original.id];
      if (idx == null || _isLayerLocked(original.layerIndex)) {
        newSelection.add(original);
        continue;
      }
      final replacement = edit(original);
      page.strokes[idx] = replacement;
      before.add(original);
      edited.add(replacement);
      newSelection.add(replacement);
    }
    if (before.isEmpty) return;
    _selectedStrokes = newSelection;
    // Mismos ids → deshacer/rehacer reemplazan en sitio (z-order intacto).
    _undoStack.push(CanvasAction(strokesRemoved: before, strokesAdded: edited));
    _touch();
  }

  /// Sustituye los trazos seleccionados por una caja de texto con [text]
  /// (resultado del reconocimiento de escritura), en el mismo sitio y con un
  /// tamaño de letra acorde a la altura escrita. Una sola acción de deshacer.
  void convertSelectionToText(String text) {
    final removable = _selectedStrokes
        .where((s) => !_isLayerLocked(s.layerIndex))
        .toList();
    if (removable.isEmpty || text.trim().isEmpty) return;
    final bounds = selectionBounds(removable);
    final lines = '\n'.allMatches(text.trim()).length + 1;
    final fontSize = (bounds.height / lines * 0.75).clamp(12.0, 96.0);
    final item = TextItem(
      id: newId('txt'),
      x: bounds.center.dx,
      y: bounds.center.dy,
      width: bounds.width.clamp(120.0, 4000.0),
      text: text.trim(),
      fontSize: fontSize,
      colorValue: removable.first.colorValue,
      layerIndex: removable.first.layerIndex,
    );
    final before = List<Stroke>.of(page.strokes);
    final removeSet = Set<Stroke>.identity()..addAll(removable);
    page.strokes.removeWhere(removeSet.contains);
    page.textItems.add(item);
    final diff = CanvasAction.strokeDiff(before, page.strokes);
    _undoStack.push(CanvasAction(
      strokesRemoved: diff.strokesRemoved,
      strokesRemovedAt: diff.strokesRemovedAt,
      textItemsAdded: [item],
    ));
    _selectedStrokes = [];
    _touch();
  }

  /// Duplica la selección (copiar + pegar desplazado) sin tocar el
  /// portapapeles del usuario.
  void duplicateSelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;
    final saved = _clipboardStrokes;
    _clipboardStrokes = List.of(_selectedStrokes);
    pasteStrokes();
    _clipboardStrokes = saved;
  }

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
      if (_isLayerLocked(original.layerIndex)) continue;
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

      // copyWith conserva capa, figura, relleno y ajustes.
      final newStroke = original.copyWith(
        points: newPoints,
        size: original.size * scaleFactor,
      );

      // Reemplaza el trazo en la página (misma posición = mismo z-order).
      final idx = page.strokes.indexWhere((s) => s.id == original.id);
      if (idx >= 0) page.strokes[idx] = newStroke;
      // Actualiza la referencia en la selección.
      final selIdx = _selectedStrokes.indexOf(original);
      if (selIdx >= 0) _selectedStrokes[selIdx] = newStroke;
    }
    _touchLive();
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
    _touch();
  }

  // ------------------------------------------------------------------
  // Seleccionar trazos por hit-test (herramienta select)
  // ------------------------------------------------------------------

  /// Selecciona el trazo más cercano a [worldPoint].
  ///
  /// Se usa con la herramienta select: al tocar un trazo, se selecciona
  /// (si no había otro seleccionado) o se añade/quita de la selección.
  /// Devuelve true si se seleccionó algún trazo.
  bool selectStrokeAt(Offset worldPoint) {
    final hit = StrokeEngine.findStrokeAt(
      worldPoint,
      page.strokes,
      maxDistance: 20.0 / _scale,
    );
    if (hit == null) return false;
    _selectedImageId = null;
    if (_selectedStrokes.contains(hit)) {
      _selectedStrokes.remove(hit);
    } else {
      _selectedStrokes = [hit];
    }
    _touch();
    return true;
  }

  /// Mueve todos los trazos seleccionados por un [delta] total desde [before].
  ///
  /// [before] es el estado original de los trazos antes de empezar a mover.
  /// Se traslada cada trazo original por el delta completo (no incremental)
  /// para evitar acumulación durante el arrastre.
  ///
  /// Se busca el trazo en `page.strokes` por **id** (no por identidad de
  /// instancia) porque después del primer frame los originales ya fueron
  /// reemplazados y `indexOf` devolvería -1.
  void moveSelectedStrokes(Offset delta, {required List<Stroke> before}) {
    // Imágenes y textos del lazo: se trasladan desde su estado inicial.
    _moveImagesBefore ??=
        selectedImages.where((i) => !_isLayerLocked(i.layerIndex)).toList();
    _moveTextsBefore ??=
        selectedTexts.where((t) => !_isLayerLocked(t.layerIndex)).toList();
    for (final img in _moveImagesBefore!) {
      final idx = page.images.indexWhere((i) => i.id == img.id);
      if (idx >= 0) page.images[idx] = img.copyWith(x: img.x + delta.dx, y: img.y + delta.dy);
    }
    for (final txt in _moveTextsBefore!) {
      final idx = page.textItems.indexWhere((t) => t.id == txt.id);
      if (idx >= 0) {
        page.textItems[idx] = txt.copyWith(x: txt.x + delta.dx, y: txt.y + delta.dy);
      }
    }
    // Filtrar trazos en capas bloqueadas: esos no se mueven.
    final movable = before.where((s) => !_isLayerLocked(s.layerIndex)).toList();
    if (movable.isEmpty) {
      _touchLive();
      return;
    }
    // Índice por id de la página (una pasada, no indexWhere por trazo).
    final positions = <String, int>{
      for (var i = 0; i < page.strokes.length; i++) page.strokes[i].id: i,
    };
    _selectedStrokes = [];
    for (final original in movable) {
      final newStroke = original.translated(delta);
      // Buscar por id (no por identidad) — después del primer frame,
      // el objeto original ya no está en page.strokes.
      final idx = positions[original.id];
      if (idx != null) page.strokes[idx] = newStroke;
      _selectedStrokes.add(newStroke);
    }
    // Durante el arrastre: repintar sin agendar guardado (se guarda al soltar).
    _touchLive();
  }

  /// Confirma el movimiento de trazos seleccionados (empuja acción de deshacer).
  /// Confirma el movimiento: una sola acción con trazos, imágenes y textos
  /// (mismos ids → deshacer los devuelve a su sitio sin cambiar el orden).
  void commitMoveStrokes(List<Stroke> before) {
    if (!hasLassoSelection) return;
    final movedIds = {for (final s in _selectedStrokes) s.id};
    final imagesBefore = _moveImagesBefore ?? const <ImageItem>[];
    final textsBefore = _moveTextsBefore ?? const <TextItem>[];
    final imageIds = {for (final i in imagesBefore) i.id};
    final textIds = {for (final t in textsBefore) t.id};
    _undoStack.push(
      CanvasAction(
        strokesRemoved: before.where((s) => movedIds.contains(s.id)).toList(),
        strokesAdded: List<Stroke>.from(_selectedStrokes),
        imagesRemoved: imagesBefore,
        imagesAdded: page.images.where((i) => imageIds.contains(i.id)).toList(),
        textItemsRemoved: textsBefore,
        textItemsAdded: page.textItems.where((t) => textIds.contains(t.id)).toList(),
      ),
    );
    _moveImagesBefore = null;
    _moveTextsBefore = null;
    _touch();
  }

  // ------------------------------------------------------------------
  // TextItems (cajas de texto)
  // ------------------------------------------------------------------

  String? _editingTextId;

  String? get editingTextId => _editingTextId;

  void addTextItem(Offset worldPoint) {
    final item = TextItem(
      id: newId('txt'),
      x: worldPoint.dx,
      y: worldPoint.dy,
      width: kDefaultTextWidth,
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
      // Repinta; el guardado se agenda con el debounce normal (no por tecla).
      _touch();
    }
  }

  void commitTextItem(TextItem item) {
    _editingTextId = null;
    _touch();
  }

  void removeTextItem(TextItem item) {
    if (_isLayerLocked(item.layerIndex)) return;
    page.textItems.removeWhere((t) => t.id == item.id);
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

  void setLayerOpacity(int index, double opacity) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].opacity = opacity.clamp(0.0, 1.0);
    _touch();
  }

  // ------------------------------------------------------------------
  // Bucket fill (relleno de áreas)
  // ------------------------------------------------------------------

  /// Rellena el área más cercana al punto con el color actual.
  void _bucketFill(Offset worldPoint) {
    if (_isLayerLocked(_activeLayerIndex)) {
      _onLayerBlocked?.call();
      return;
    }
    // --- Paso 1: buscar un trazo individual cuyo contorno encierre el punto ---
    Stroke? enclosingStroke;
    var bestDistance = double.infinity;

    for (final stroke in page.strokes) {
      if (!_isLayerVisible(stroke.layerIndex)) continue;
      if (!stroke.paintBounds.contains(worldPoint)) continue;
      final outline = StrokeEngine.outlineFor(stroke);
      if (outline.length < 3) continue;
      if (pointInPolygon(worldPoint, outline)) {
        final center = polygonCenter(outline);
        final dist = (worldPoint - center).distance;
        if (dist < bestDistance) {
          bestDistance = dist;
          enclosingStroke = stroke;
        }
      }
    }

    if (enclosingStroke != null) {
      // Rellena el trazo encontrado directamente.
      final fillStroke = enclosingStroke.copyWith(
        id: newId('st'),
        fillColorValue: _color.toARGB32(),
        layerIndex: _activeLayerIndex,
      );
      page.strokes.add(fillStroke);
      _undoStack.push(CanvasAction(strokesAdded: [fillStroke]));
      _touch();
      return;
    }

    // --- Paso 2: buscar entre trazos agrupados (forma cerrada por
    //     múltiples trazos). Agrupa trazos cercanos en componentes
    //     conectados y comprueba si el punto está dentro del bounding
    //     polygon de cada componente. ---
    final visibleStrokes =
        page.strokes.where((s) => _isLayerVisible(s.layerIndex)).toList();
    if (visibleStrokes.isEmpty) return;

    // Agrupar trazos cercanos en componentes conectados.
    final components = groupStrokesIntoComponents(visibleStrokes, 80.0);

    for (final component in components) {
      // Calcular el polígono delimitador de todos los trazos del componente.
      final allPoints = <Offset>[];
      for (final s in component) {
        for (final p in s.points) {
          allPoints.add(p.offset);
        }
      }
      if (allPoints.length < 3) continue;

      // Convex hull como polígono aproximado.
      final hull = convexHull(allPoints);
      if (hull.length < 3) continue;

      if (pointInPolygon(worldPoint, hull)) {
        // El punto está dentro del componente: crea un fill que cubra
        // el área usando el polígono convexo como referencia.
        final fillStroke = component.first.copyWith(
          id: newId('st'),
          fillColorValue: _color.toARGB32(),
          layerIndex: _activeLayerIndex,
        );
        page.strokes.add(fillStroke);
        _undoStack.push(CanvasAction(strokesAdded: [fillStroke]));
        _touch();
        return;
      }
    }
  }

  // ------------------------------------------------------------------
  // Transformación de vista (zoom / pan)
  // ------------------------------------------------------------------

  void _setView(double scale, Offset translate) {
    _scale = scale.clamp(kMinZoom, kMaxZoom);
    _translate = translate;
    notifyListeners();
  }

  /// Aplica directamente una transformación (usado por el gesto de pellizco).
  void setView(double scale, Offset translate) => _setView(scale, translate);

  /// Aplica zoom alrededor de un punto de la pantalla (en coordenadas del
  /// viewport). Usado por el gesto de pellizco y por los botones de zoom.
  void zoomAt(double factor, Offset focal, Size viewportSize) {
    final newScale = (_scale * factor).clamp(kMinZoom, kMaxZoom);
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
      // La hoja se dibuja CENTRADA en el origen del mundo (ver paintWorld:
      // Rect.fromCenter(center: Offset.zero)), así que el origen debe caer en
      // el centro del viewport. (Antes se trataba como si la esquina superior
      // izquierda estuviera en el origen y la hoja salía desplazada.)
      _setView(
        scale,
        Offset(viewportSize.width / 2, viewportSize.height / 2),
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
    _note.updatedAt = DateTime.now();
    _dirty = true;
    _contentVersion++;
    notifyListeners();
    _scheduleSave();
  }

  /// Repinta la capa confirmada sin agendar guardado (arrastres en vivo).
  /// El cambio se persiste con el `_touch()` del commit al soltar.
  void _touchLive() {
    _contentVersion++;
    notifyListeners();
  }

  /// Hay cambios sin guardar.
  bool _dirty = false;
  bool _disposed = false;

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_autosaveDebounce, () async {
      await saveNow();
      // Replica a la nube si la UI registró un callback (sesión iniciada).
      // La UI decide con qué frecuencia sube realmente (debounce propio).
      if (!_disposed) onRemoteSync?.call(_note);
    });
  }

  /// Reemplaza el note completo (tras restaurar desde la nube).
  void replaceNote(Note note, {String? notebookId}) {
    _note = note;
    if (notebookId != null) _notebookId = notebookId;
    _pageIndex = 0;
    _resetPageState();
    _viewInitialized = false;
    _touch();
  }

  /// Compatibilidad: acepta un Document y lo convierte a Note interno.
  void replaceDocument(Document doc) {
    replaceNote(
      Note(
        id: doc.id,
        title: doc.title,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
        pages: doc.pages,
      ),
    );
  }

  /// Guarda de inmediato si hay cambios pendientes. Seguro de llamar varias
  /// veces: si no hay cambios no escribe nada.
  Future<void> saveNow() async {
    _saveTimer?.cancel();
    if (!_dirty || _notebookId.isEmpty) return;
    _dirty = false;
    try {
      await _storage.saveNote(_notebookId, _note);
    } catch (e) {
      _dirty = true; // se reintentará en el siguiente guardado
      debugPrint('CanvasController.saveNow: $e');
    }
  }

  /// Cancela el autoguardado pendiente y guarda lo que falte. La UI debe
  /// esperar este Future antes de cerrar el editor.
  Future<void> flush() => saveNow();

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    _holdTimer?.cancel();
    _laserTicker?.cancel();
    // Red de seguridad: si la UI no llamó a flush(), guardar lo pendiente.
    if (_dirty) unawaited(saveNow());
    _toolContextNotifier.dispose();
    _bottomBarContextNotifier.dispose();
    super.dispose();
  }
}
