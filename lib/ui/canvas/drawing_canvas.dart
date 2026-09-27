// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../logic/palm_rejection.dart';
import '../../logic/snap_guides.dart';
import '../../logic/stroke_engine.dart';
import '../../models/image_item.dart';
import '../../models/page.dart';
import '../../models/stroke.dart';
import '../../services/image_service.dart';
import '../../utils/geometry_utils.dart';
import '../editor/editor_shortcuts.dart';
import '../widgets/text_edit_overlay.dart';
import 'canvas_overlays.dart';
import 'world_painter.dart';

// Paints reutilizados para la capa activa (evitan allocations por frame).
final Paint _eraserCursorFillPaint = Paint()
  ..color = const Color(0x40FFFFFF)
  ..style = PaintingStyle.fill;
final Paint _eraserCursorStrokePaint = Paint()
  ..color = const Color(0x99000000)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5;
final Paint _cursorPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;
final Paint _lassoPaint = Paint()
  ..color = kAccentColor
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.5
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
final Paint _selectionFillPaint = Paint()
  ..color = const Color(0xFF009688).withValues(alpha: 0.25)
  ..style = PaintingStyle.fill;

/// Color de selección de trazos (teal) — distinto del de imágenes (azul).
const Color _strokeSelectionColor = Color(0xFF009688);

/// ---------------------------------------------------------------------------
/// CAPA CONFIRMADA (base)
///
/// Pinta plantilla + imágenes + trazos ya confirmados. Está dentro de un
/// [RepaintBoundary] y su `shouldRepaint` devuelve false cuando solo cambió
/// el trazo en progreso, de modo que la GPU reutiliza la capa cacheada y no
/// se repinta el lienzo completo en cada frame del trazo activo.
/// ---------------------------------------------------------------------------
class CanvasPainter extends CustomPainter {
  final Page page;
  final int contentVersion;
  final Size sheetSize;
  final Map<String, ui.Image> imageCache;
  final int imageCacheVersion;
  final double scale;
  final Offset translate;
  final bool isDark;

  CanvasPainter({
    required this.page,
    required this.contentVersion,
    required this.sheetSize,
    required this.imageCache,
    this.imageCacheVersion = 0,
    required this.scale,
    required this.translate,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(translate.dx, translate.dy);
    canvas.scale(scale);
    final visibleWorld = Rect.fromLTWH(
      -translate.dx / scale,
      -translate.dy / scale,
      size.width / scale,
      size.height / scale,
    );
    paintWorld(
      canvas,
      visibleWorldRect: visibleWorld,
      page: page,
      sheetSize: sheetSize,
      imageCache: imageCache,
      isDark: isDark,
      viewScale: scale,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.page != page ||
      oldDelegate.contentVersion != contentVersion ||
      oldDelegate.sheetSize != sheetSize ||
      oldDelegate.scale != scale ||
      oldDelegate.translate != translate ||
      oldDelegate.imageCache != imageCache ||
      oldDelegate.imageCacheVersion != imageCacheVersion ||
      oldDelegate.isDark != isDark;
}

/// ---------------------------------------------------------------------------
/// CAPA ACTIVA
///
/// Pinta el trazo en progreso, el cursor del borrador y la selección de
/// imágenes. Se repinta en cada frame sin invalidar la capa confirmada.
/// ---------------------------------------------------------------------------
class ActiveLayerPainter extends CustomPainter {
  final CanvasController controller;
  final Map<String, ui.Image> imageCache;

  ActiveLayerPainter({required this.controller, required this.imageCache});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = controller.scale;
    final translate = controller.translate;
    final active = controller.activeStroke;
    final eraserPath = controller.activeEraserPath;

    canvas.save();
    canvas.translate(translate.dx, translate.dy);
    canvas.scale(scale);

    // Si la plantilla es finita, recortar el trazo activo y selección
    // al área de la hoja para que el usuario vea dónde puede escribir.
    final template = controller.page.template;
    if (template.isFinite) {
      final sheetRect = Rect.fromCenter(
        center: Offset.zero,
        width: controller.sheetSize.width,
        height: controller.sheetSize.height,
      );
      canvas.clipRect(sheetRect);
    }

    // Trazo en progreso.
    if (active != null) {
      paintActiveStroke(canvas, active);
    }

    // Puntero láser: estela roja que se desvanece (no se guarda).
    _paintLaser(canvas, controller, scale);

    // Lazo en progreso (trazo punteado del lazo).
    final lassoPath = controller.lassoPath;
    if (lassoPath.length >= 2) {
      final path = Path()..moveTo(lassoPath.first.dx, lassoPath.first.dy);
      for (var i = 1; i < lassoPath.length; i++) {
        path.lineTo(lassoPath[i].dx, lassoPath[i].dy);
      }
      _lassoPaint.strokeWidth = 2.5 / scale;
      canvas.drawPath(path, _lassoPaint);
    }

    // Selección del lazo: trazos resaltados + recuadro de toda la selección
    // (también imágenes y cajas de texto).
    final selectedStrokes = controller.selectedStrokes;
    if (controller.hasLassoSelection) {
      for (final stroke in selectedStrokes) {
        if (StrokeEngine.outlineFor(stroke).length < 3) continue;
        canvas.drawPath(StrokeEngine.pathFor(stroke), _selectionFillPaint);
      }
      // Recuadro punteado (marching ants) + asas de escala/rotación, que
      // solo afectan a los trazos.
      {
        final bounds = controller.selectionBoundsAll;
        if (!bounds.isEmpty && selectedStrokes.isEmpty) {
          drawMarchingAnts(canvas, bounds.inflate(8 / scale), scale);
        } else if (!bounds.isEmpty) {
          final inflated = bounds.inflate(8 / scale);
          drawMarchingAnts(canvas, inflated, scale);
          // Handle de escala (esquina inferior derecha).
          final r = 11 / scale;
          canvas.drawCircle(inflated.bottomRight, r,
            Paint()..color = _strokeSelectionColor);
          canvas.drawCircle(inflated.bottomRight, r, Paint()
            ..style = PaintingStyle.stroke..strokeWidth = 2 / scale..color = Colors.white);
          // Handle de rotación (centro superior).
          final rotH = Offset(inflated.center.dx, inflated.top - r * 3);
          canvas.drawLine(inflated.topCenter, rotH,
            Paint()..color = _strokeSelectionColor..strokeWidth = 2 / scale);
          canvas.drawCircle(rotH, r, Paint()..color = _strokeSelectionColor);
          canvas.drawCircle(rotH, r, Paint()
            ..style = PaintingStyle.stroke..strokeWidth = 2 / scale..color = Colors.white);
        }
      }
    }

    // Selección de imagen (borde + asa de redimensionado + asa de rotación).
    final selectedId = controller.selectedImageId;
    if (selectedId != null) {
      for (final item in controller.page.images) {
        if (item.id != selectedId) continue;
        final rect = item.rect;
        canvas.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 / scale
            ..color = kAccentColor,
        );
        // Asa de redimensionado (esquina inferior derecha).
        final handle = rect.bottomRight;
        final r = 11 / scale;
        canvas.drawCircle(
          handle,
          r,
          Paint()..color = kAccentColor,
        );
        canvas.drawCircle(
          handle,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale
            ..color = Colors.white,
        );
        // Asa de rotación (línea hacia arriba desde el centro superior).
        final rotHandle = Offset(
          rect.center.dx,
          rect.top - r * 3,
        );
        canvas.drawLine(
          rect.topCenter,
          rotHandle,
          Paint()
            ..color = kAccentColor
            ..strokeWidth = 2 / scale,
        );
        canvas.drawCircle(
          rotHandle,
          r,
          Paint()..color = kAccentColor,
        );
        canvas.drawCircle(
          rotHandle,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale
            ..color = Colors.white,
        );
        break;
      }
    }

    // ---- Guías magnéticas (snap) — en espacio de mundo ----
    if (controller.snapVerticalGuides.isNotEmpty ||
        controller.snapHorizontalGuides.isNotEmpty) {
      final guidePaint = Paint()
        ..color = kAccentColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.5 / scale
        ..style = PaintingStyle.stroke;
      for (final x in controller.snapVerticalGuides) {
        canvas.drawLine(Offset(x, -10000), Offset(x, 10000), guidePaint);
      }
      for (final y in controller.snapHorizontalGuides) {
        canvas.drawLine(Offset(-10000, y), Offset(10000, y), guidePaint);
      }
    }

    canvas.restore();

    // ---- Regla virtual (dibujada en espacio de pantalla, con su propio save/restore) ----
    if (controller.rulerEnabled) {
      canvas.save();
      drawRuler(canvas, controller, size);
      canvas.restore();
    }

    // ---- Lupa (dibujada en espacio de pantalla, con su propio save/restore) ----
    if (controller.magnifierEnabled && controller.isDrawing) {
      canvas.save();
      drawMagnifier(canvas, controller, size, imageCache);
      canvas.restore();
    }

    // ---- Cursor del borrador (espacio de pantalla, tamaño constante) ----
    if (eraserPath.isNotEmpty) {
      final last = eraserPath.last;
      final screen = last * scale + translate;
      final radius = controller.eraserRadius * scale;
      canvas.drawCircle(screen, radius, _eraserCursorFillPaint);
      canvas.drawCircle(screen, radius, _eraserCursorStrokePaint);
    } else if (active != null && active.points.isNotEmpty) {
      // Pequeño cursor que muestra el grosor actual de la punta.
      final last = active.points.last.offset;
      final screen = last * scale + translate;
      final r = (active.size * scale) / 2;
      _cursorPaint.color = active.color.withValues(alpha: 0.25);
      canvas.drawCircle(screen, r, _cursorPaint);
    }
  }

  @override
  bool shouldRepaint(ActiveLayerPainter oldDelegate) => true;

  static final Paint _laserGlow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _laserCore = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Dibuja la estela del láser: cada segmento con opacidad según su edad.
  static void _paintLaser(Canvas canvas, CanvasController c, double scale) {
    final trail = c.laserTrail;
    if (trail.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final fade = CanvasController.laserFade.inMilliseconds;
    _laserGlow.strokeWidth = 14 / scale;
    _laserCore.strokeWidth = 5 / scale;
    for (var i = 1; i < trail.length; i++) {
      final age = (now - trail[i].t).clamp(0, fade);
      final alpha = 1 - age / fade;
      if (alpha <= 0) continue;
      _laserGlow.color = const Color(0xFFFF1744).withValues(alpha: 0.35 * alpha);
      _laserCore.color = const Color(0xFFFF5252).withValues(alpha: alpha);
      canvas.drawLine(trail[i - 1].point, trail[i].point, _laserGlow);
      canvas.drawLine(trail[i - 1].point, trail[i].point, _laserCore);
    }
  }
}

/// ---------------------------------------------------------------------------
/// LIENZO
///
/// Arquitectura de eventos:
/// - Un [Listener] crudo recibe TODOS los eventos de puntero y decide si
///   dibujar (stylus, mouse o dedo si está habilitado) o ignorarlos
///   (rechazo de palma: cualquier `touch` mientras un stylus está en
///   contacto se descarta por completo).
/// - Un [GestureDetector] con callbacks de escala gestiona SOLO el zoom/pan
///   con dos dedos. Nunca interfiere con la escritura: se ignora mientras el
///   stylus esté activo o con un solo dedo.
/// ---------------------------------------------------------------------------
class DrawingCanvas extends StatefulWidget {
  final CanvasController controller;
  final ImageService imageService;

  /// Modo nocturno de escritura: invierte la luminosidad del lienzo
  /// (conserva el tono) solo en pantalla; la exportación no cambia.
  final bool nightMode;

  /// Abre "Ir a página" (atajo Ctrl+G). Opcional.
  final VoidCallback? onGoToPage;

  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.imageService,
    this.nightMode = false,
    this.onGoToPage,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Size _viewport = Size.zero;

  // Estado de punteros.
  int? _drawingPointer;
  bool _transforming = false;

  /// Rechazo de palma (lápiz apoyado/cerca, contacto grande).
  final PalmRejection _palm = PalmRejection();

  /// Toques de dedo aceptados y toques descartados como palma.
  final Set<int> _touchPointers = {};
  final Set<int> _rejectedPointers = {};

  /// Dedos que están manipulando la regla (posición en pantalla).
  final Map<int, Offset> _rulerPointers = {};
  Map<int, Offset> _rulerGrab = {};
  Offset _rulerGrabCenter = Offset.zero;
  double _rulerGrabAngle = 0;

  // Gesto de transformación (zoom/pan).
  double _startScale = 1;
  Offset _startTranslate = Offset.zero;
  DateTime? _transformStartTime;
  int _gesturePointerCount = 0;
  double _prevGestureScale = 1;

  // Interacción con imágenes (herramienta select).
  bool _movingImage = false;
  bool _resizingImage = false;
  bool _rotatingImage = false;
  ImageItem? _imageGestureOriginal;
  Offset _imageGestureStartWorld = Offset.zero;
  Rect _imageGestureStartRect = Rect.zero;
  double _imageGestureStartRotation = 0;

  // ---- Atajo: toque con dos dedos = deshacer ----
  DateTime? _twoFingerStartTime;
  bool _twoFingerMoved = false;

  // ---- Transformar selección ----
  bool _scalingSelection = false;
  bool _rotatingSelection = false;
  double _transformStartDist = 1;
  double _transformStartAngle = 0;
  Rect _transformSelectionBounds = Rect.zero;
  List<Stroke> _transformStrokesBefore = [];

  // ---- Mover trazos seleccionados (herramienta select) ----
  bool _movingStrokes = false;
  Offset _strokeMoveStartWorld = Offset.zero;
  List<Stroke> _strokesBeforeMove = [];

  /// Desplazamiento total del gesto de mover selección en curso.
  Offset _strokeMoveDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        widget.controller.viewportSize = _viewport;
        if (widget.controller.viewNeedsInit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.controller.ensureViewInitialized(_viewport);
            }
          });
        }
        _ensureImagesDecoded();

        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) => EditorShortcuts.handle(
            event,
            widget.controller,
            onGoToPage: widget.onGoToPage,
          ),
          child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerHover: _onPointerHover,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: (_) => _transforming = false,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Capa confirmada, cacheada por RepaintBoundary.
                  _nightFilter(RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: CanvasPainter(
                            page: widget.controller.page,
                            contentVersion: widget.controller.contentVersion,
                            sheetSize: widget.controller.sheetSize,
                            imageCache: widget.imageService.cache,
                            imageCacheVersion: widget.imageService.cache.version,
                            scale: widget.controller.scale,
                            translate: widget.controller.translate,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ),
                        );
                      },
                    ),
                  )),
                  // Capa activa (trazo en curso, cursor, selección).
                  _nightFilter(ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: ActiveLayerPainter(
                        controller: widget.controller,
                        imageCache: widget.imageService.cache,
                      ),
                    ),
                  )),
                  // Overlay de edición de texto.
                  TextEditOverlay(controller: widget.controller),
                ],
              ),  // Stack
            ),    // ClipRect
          ),      // GestureDetector
          ),      // Listener
        );        // Focus + return
      },
    );
  }

  /// Invierte la luminosidad conservando el tono (inversión + rotación de
  /// tono 180°): papel blanco → oscuro, tinta negra → clara, rojo → rojo.
  static const ColorFilter _nightModeFilter = ColorFilter.matrix(<double>[
    0.574, -1.43, -0.144, 0, 255, //
    -0.426, -0.43, -0.144, 0, 255, //
    -0.426, -1.43, 0.856, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  Widget _nightFilter(Widget child) => widget.nightMode
      ? ColorFiltered(colorFilter: _nightModeFilter, child: child)
      : child;

  /// Decodifica (una sola vez) las imágenes de la página y de la plantilla
  /// para poder pintarlas. Al terminar, repinta.
  void _ensureImagesDecoded() {
    for (final item in widget.controller.page.images) {
      widget.imageService.ensureCached(item.localPath).then((_) {
        if (mounted) setState(() {});
      });
    }
    final templatePath = widget.controller.page.template.imagePath;
    if (templatePath != null) {
      widget.imageService.ensureCached(templatePath).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // -------------------------------------------------------------------------
  // Eventos de puntero: detección de stylus + rechazo de palma
  // -------------------------------------------------------------------------

  void _onPointerHover(PointerHoverEvent event) {
    // S-Pen / Apple Pencil reportan hover a ~1 cm de la pantalla: sabemos que
    // el lápiz viene ANTES de que la palma se apoye.
    if (PalmRejection.isStylusKind(event.kind)) _palm.stylusHoverEvent();
  }

  void _onPointerDown(PointerDownEvent event) {
    final kind = event.kind;
    final c = widget.controller;
    final world = c.viewportToWorld(event.localPosition, _viewport);

    if (PalmRejection.isStylusKind(kind) || kind == PointerDeviceKind.mouse) {
      if (PalmRejection.isStylusKind(kind)) {
        _palm.stylusDownEvent(event.pointer);
        c.onStylusDetected();
        _rejectPalmInProgress();
      }
      _drawingPointer = event.pointer;
      // Goma física del lápiz (invertedStylus) o botón lateral del S-Pen
      // pulsado = borrador para este trazo.
      final eraserButton = kind == PointerDeviceKind.invertedStylus ||
          (kind == PointerDeviceKind.stylus &&
              (event.buttons & kSecondaryStylusButton) != 0);
      if (eraserButton) {
        c.beginStroke(world, event.pressure, tool: ToolType.eraser);
      } else if (c.tool == ToolType.select) {
        _handleSelectDown(event.localPosition, world, event.pointer);
      } else {
        c.beginStroke(world, event.pressure, tool: c.tool);
      }
      return;
    }

    if (kind != PointerDeviceKind.touch) return;

    // Rechazo de palma: lápiz apoyado / cerca / recién levantado, o
    // contacto demasiado grande → el toque se ignora por completo.
    if (_palm.rejectTouch(radiusMajor: event.radiusMajor)) {
      _rejectedPointers.add(event.pointer);
      return;
    }
    // Regla: un dedo sobre ella la arrastra; un segundo dedo la rota.
    if (c.rulerEnabled && (_rulerPointers.isNotEmpty || c.hitsRuler(world))) {
      _rulerPointers[event.pointer] = event.localPosition;
      _restartRulerGesture();
      return;
    }
    _touchPointers.add(event.pointer);
    if (_touchPointers.length == 2) {
      _twoFingerStartTime = DateTime.now();
      _twoFingerMoved = false;
    }
    if (_touchPointers.length > 1) {
      // Segundo dedo = gesto (zoom/pan/deshacer): cancelar el trazo del primero.
      if (c.isDrawing && _touchPointers.contains(_drawingPointer)) {
        c.cancelStroke();
        _drawingPointer = null;
      }
      return;
    }
    if (c.tool == ToolType.select) {
      _handleSelectDown(event.localPosition, world, event.pointer);
    } else if (c.fingerDrawingEnabled) {
      _drawingPointer = event.pointer;
      c.beginStroke(world, event.pressure, tool: c.tool);
    }
    // Si no se dibuja con el dedo, el GestureDetector desplaza la página.
  }

  /// Un lápiz acaba de apoyarse: lo que estuviera haciendo un dedo en ese
  /// momento era casi seguro la palma → se descarta (trazo o desplazamiento).
  void _rejectPalmInProgress() {
    final c = widget.controller;
    if (_drawingPointer != null && _touchPointers.contains(_drawingPointer)) {
      c.cancelStroke();
      _drawingPointer = null;
    }
    if (_transforming) {
      final start = _transformStartTime;
      if (start != null &&
          DateTime.now().difference(start) < const Duration(milliseconds: 600)) {
        c.setView(_startScale, _startTranslate); // deshace el pan de la palma
      }
      _transforming = false;
    }
    _rejectedPointers.addAll(_touchPointers);
    _touchPointers.clear();
    _twoFingerStartTime = null;
  }

  bool get _selectGestureActive =>
      _movingImage ||
      _resizingImage ||
      _rotatingImage ||
      _movingStrokes ||
      _scalingSelection ||
      _rotatingSelection;

  void _onPointerMove(PointerMoveEvent event) {
    if (_rulerPointers.containsKey(event.pointer)) {
      _rulerPointers[event.pointer] = event.localPosition;
      _updateRulerGesture();
      return;
    }
    if (event.pointer != _drawingPointer) return;
    if (_selectGestureActive) {
      _handleSelectMove(event.localPosition);
      return;
    }
    final world = widget.controller.viewportToWorld(
      event.localPosition,
      _viewport,
    );
    widget.controller.addStrokePoint(world, event.pressure);
  }

  void _onPointerUp(PointerUpEvent event) {
    // Siempre, antes de cualquier return: si no, el estado "lápiz apoyado"
    // se quedaba atascado y la pantalla dejaba de responder al tacto.
    if (PalmRejection.isStylusKind(event.kind)) _palm.stylusUpEvent(event.pointer);
    _rejectedPointers.remove(event.pointer);
    if (_rulerPointers.remove(event.pointer) != null) {
      _restartRulerGesture();
      return;
    }
    final wasTouch = _touchPointers.remove(event.pointer);

    // ---- Atajo: toque rápido con dos dedos = deshacer ----
    if (wasTouch && _touchPointers.isEmpty && _twoFingerStartTime != null) {
      final elapsed = DateTime.now().difference(_twoFingerStartTime!);
      _twoFingerStartTime = null;
      if (elapsed.inMilliseconds < 300 && !_twoFingerMoved && !_palm.stylusNearby) {
        widget.controller.undo();
        return;
      }
    }

    if (event.pointer != _drawingPointer) return;
    _drawingPointer = null;

    if (_scalingSelection || _rotatingSelection) {
      widget.controller.commitTransformSelection(_transformStrokesBefore);
      _scalingSelection = false;
      _rotatingSelection = false;
      return;
    }
    if (_movingStrokes) {
      _commitStrokeMove();
      return;
    }
    if (_movingImage || _resizingImage || _rotatingImage) {
      _commitImageGesture();
      return;
    }
    widget.controller.endStroke();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (PalmRejection.isStylusKind(event.kind)) _palm.stylusUpEvent(event.pointer);
    _rejectedPointers.remove(event.pointer);
    if (_rulerPointers.remove(event.pointer) != null) {
      _restartRulerGesture();
      return;
    }
    _touchPointers.remove(event.pointer);
    if (event.pointer != _drawingPointer) return;
    if (_movingStrokes) {
      _cancelStrokeMove();
      return;
    }
    if (_movingImage || _resizingImage || _rotatingImage) {
      _cancelImageGesture();
      return;
    }
    if (_scalingSelection || _rotatingSelection) {
      widget.controller.commitTransformSelection(_transformStrokesBefore);
      _scalingSelection = false;
      _rotatingSelection = false;
      _drawingPointer = null;
      return;
    }
    _drawingPointer = null;
    widget.controller.cancelStroke();
  }

  // -------------------------------------------------------------------------
  // Zoom / pan (dos dedos; o un dedo en modo "solo lápiz")
  // -------------------------------------------------------------------------

  /// En modo solo lápiz, un dedo desplaza la página (como GoodNotes).
  bool get _oneFingerPans =>
      !widget.controller.fingerDrawingEnabled &&
      widget.controller.tool != ToolType.select;

  bool get _gestureBlocked =>
      _palm.stylusDown || _rejectedPointers.isNotEmpty || _rulerPointers.isNotEmpty;

  // -------------------------------------------------------------------------
  // Regla: arrastrar (1 dedo) y rotar (2 dedos)
  // -------------------------------------------------------------------------

  /// Toma como referencia la posición actual de los dedos y de la regla
  /// (al entrar o salir un dedo, para que no dé saltos).
  void _restartRulerGesture() {
    _rulerGrab = Map.of(_rulerPointers);
    _rulerGrabCenter = widget.controller.rulerCenter;
    _rulerGrabAngle = widget.controller.rulerAngle;
  }

  void _updateRulerGesture() {
    final c = widget.controller;
    final ids = _rulerGrab.keys.where(_rulerPointers.containsKey).take(2).toList();
    if (ids.isEmpty) return;
    if (ids.length == 1) {
      final delta = (_rulerPointers[ids[0]]! - _rulerGrab[ids[0]]!) / c.scale;
      c.setRulerTransform(_rulerGrabCenter + delta, _rulerGrabAngle);
      return;
    }
    final a0 = _rulerGrab[ids[0]]!, b0 = _rulerGrab[ids[1]]!;
    final a1 = _rulerPointers[ids[0]]!, b1 = _rulerPointers[ids[1]]!;
    final dAngle = (b1 - a1).direction - (b0 - a0).direction;
    // Gira alrededor del punto medio de los dedos y lo sigue al desplazarse.
    final m0 = c.viewportToWorld((a0 + b0) / 2, _viewport);
    final m1 = c.viewportToWorld((a1 + b1) / 2, _viewport);
    final rel = _rulerGrabCenter - m0;
    final rotated = Offset(
      rel.dx * cos(dAngle) - rel.dy * sin(dAngle),
      rel.dx * sin(dAngle) + rel.dy * cos(dAngle),
    );
    c.setRulerTransform(m1 + rotated, _rulerGrabAngle + dAngle);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_gestureBlocked) return;
    if (details.pointerCount >= 2 || _oneFingerPans) _beginTransform(details.pointerCount);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_gestureBlocked) {
      _transforming = false;
      return;
    }
    if (details.pointerCount >= 2 &&
        ((details.scale - 1).abs() > 0.05 || details.focalPointDelta.distance > 3)) {
      _twoFingerMoved = true;
    }
    if (!_transforming) {
      if (details.pointerCount >= 2 || _oneFingerPans) {
        _beginTransform(details.pointerCount);
      } else {
        return;
      }
    }
    // Al entrar/salir un dedo el reconocedor reinicia su escala: se toma
    // como nueva referencia en vez de dar un salto de zoom.
    if (details.pointerCount != _gesturePointerCount) {
      _gesturePointerCount = details.pointerCount;
      _prevGestureScale = details.scale;
      return;
    }
    final controller = widget.controller;
    final factor = _prevGestureScale == 0 ? 1.0 : details.scale / _prevGestureScale;
    _prevGestureScale = details.scale;
    final newScale = (controller.scale * factor).clamp(kMinZoom, kMaxZoom);
    final ratio = newScale / controller.scale;
    final focal = details.localFocalPoint;
    // Mantiene fijo el punto bajo los dedos y aplica el desplazamiento.
    final newTranslate =
        focal - (focal - controller.translate) * ratio + details.focalPointDelta;
    controller.setView(newScale, newTranslate);
  }

  void _beginTransform(int pointerCount) {
    // Si había un trazo de dedo en curso, se cancela al empezar el gesto.
    if (widget.controller.isDrawing && _touchPointers.contains(_drawingPointer)) {
      widget.controller.cancelStroke();
      _drawingPointer = null;
    }
    _transforming = true;
    _transformStartTime = DateTime.now();
    _gesturePointerCount = pointerCount;
    _prevGestureScale = 1.0;
    _startScale = widget.controller.scale;
    _startTranslate = widget.controller.translate;
  }

  // -------------------------------------------------------------------------
  // Herramienta select: mover / redimensionar imágenes
  // -------------------------------------------------------------------------

  void _handleSelectDown(Offset local, Offset world, int pointer) {
    _drawingPointer = pointer;
    final controller = widget.controller;
    final selectedId = controller.selectedImageId;
    final selectedStrokes = controller.selectedStrokes;
    final handleWorld = 30 / controller.scale;

    // 0) ¿Hay selección del lazo? Detectar asas o mover.
    if (controller.hasLassoSelection && selectedId == null) {
      final bounds = controller.selectionBoundsAll;
      _transformSelectionBounds = bounds;
      final handleSize = handleWorld * 1.5;
      final hasStrokes = selectedStrokes.isNotEmpty;

      // ¿Toca el asa de rotación (centro superior)? Solo trazos.
      final rotHandle = Offset(bounds.center.dx, bounds.top - handleSize * 2);
      if (hasStrokes && (world - rotHandle).distance <= handleSize) {
        _rotatingSelection = true;
        _transformStartAngle = (world - bounds.center).direction;
        _transformStrokesBefore = List<Stroke>.from(selectedStrokes);
        return;
      }
      // ¿Toca el handle de escala (esquina inferior derecha)?
      final scaleHandle = bounds.bottomRight;
      if (hasStrokes && (world - scaleHandle).distance <= handleSize) {
        _scalingSelection = true;
        _transformStartDist = (world - bounds.center).distance;
        _transformStrokesBefore = List<Stroke>.from(selectedStrokes);
        return;
      }
      // Toca dentro de los límites de la selección → mover todos.
      final inflated = bounds.inflate(handleSize);
      if (inflated.contains(world)) {
        _movingStrokes = true;
        _strokeMoveStartWorld = world;
        _strokesBeforeMove = List<Stroke>.from(selectedStrokes);
        return;
      }
      // Toca fuera → deseleccionar y continuar.
      controller.clearLassoSelection();
    }

    // 1) ¿Toca el asa de rotación de la imagen seleccionada?
    if (selectedId != null) {
      ImageItem? selected;
      for (final i in controller.page.images) {
        if (i.id == selectedId) {
          selected = i;
          break;
        }
      }
      if (selected != null) {
        final rotHandle = Offset(
          selected.rect.center.dx,
          selected.rect.top - handleWorld * 1.5,
        );
        if ((world - rotHandle).distance <= handleWorld) {
          _rotatingImage = true;
          _imageGestureOriginal = selected;
          _imageGestureStartWorld = world;
          _imageGestureStartRect = selected.rect;
          _imageGestureStartRotation = selected.rotation;
          return;
        }
        // ¿Toca el asa de redimensionado?
        if ((world - selected.rect.bottomRight).distance <= handleWorld) {
          _resizingImage = true;
          _imageGestureOriginal = selected;
          _imageGestureStartWorld = world;
          _imageGestureStartRect = selected.rect;
          _imageGestureStartRotation = selected.rotation;
          return;
        }
      }
    }

    // 2) ¿Toca alguna imagen? (la de más arriba gana)
    ImageItem? hit;
    for (final item in controller.page.images.reversed) {
      if (item.contains(world)) {
        hit = item;
        break;
      }
    }
    if (hit != null) {
      controller.selectImage(hit.id);
      _movingImage = true;
      _imageGestureOriginal = hit;
      _imageGestureStartWorld = world;
      _imageGestureStartRect = hit.rect;
      _imageGestureStartRotation = hit.rotation;
      return;
    }

    // 3) ¿Toca algún trazo? Seleccionar y permitir mover.
    if (controller.selectStrokeAt(world)) {
      _movingStrokes = true;
      _strokeMoveStartWorld = world;
      _strokesBeforeMove = List<Stroke>.from(controller.selectedStrokes);
      return;
    }

    // 4) No se tocó nada: deseleccionar todo.
    controller.selectImage(null);
    controller.clearLassoSelection();
  }

  void _handleSelectMove(Offset local) {
    final world = widget.controller.viewportToWorld(local, _viewport);

    // Transformar selección de trazos (escalar/rotar incremental).
    if (_scalingSelection || _rotatingSelection) {
      final pivot = _transformSelectionBounds.center;
      if (_scalingSelection) {
        final currentDist = (world - pivot).distance;
        if (_transformStartDist > 1 && currentDist > 0) {
          // Factor incremental: solo la diferencia desde el último frame.
          final incrementalFactor = currentDist / _transformStartDist;
          widget.controller.transformSelectedStrokes(
            scaleFactor: incrementalFactor,
            rotationAngle: 0,
            pivotPoint: pivot,
          );
          _transformStartDist = currentDist;
          // Actualizar bounds para que el handle se mantenga sincronizado.
          _transformSelectionBounds = _computeSelectionBounds(
            widget.controller.selectedStrokes,
          );
        }
      } else if (_rotatingSelection) {
        final currentAngle = (world - pivot).direction;
        final delta = currentAngle - _transformStartAngle;
        widget.controller.transformSelectedStrokes(
          scaleFactor: 1,
          rotationAngle: delta,
          pivotPoint: pivot,
        );
        _transformStartAngle = currentAngle;
        _transformSelectionBounds = _computeSelectionBounds(
          widget.controller.selectedStrokes,
        );
      }
      return;
    }

    // Mover trazos seleccionados (delta total desde el inicio).
    if (_movingStrokes) {
      final delta = world - _strokeMoveStartWorld;
      _strokeMoveDelta = delta;
      widget.controller.moveSelectedStrokes(delta, before: _strokesBeforeMove);
      return;
    }

    final original = _imageGestureOriginal;
    if (original == null) return;

    if (_rotatingImage) {
      // Rotación: calcula el ángulo desde el centro de la imagen.
      final center = _imageGestureStartRect.center;
      final startAngle = (world - center).direction -
          (_imageGestureStartWorld - center).direction;
      widget.controller.updateImageLive(
        original.copyWith(
          rotation: _imageGestureStartRotation + startAngle,
        ),
      );
    } else if (_resizingImage) {
      // Redimensionado manteniendo el aspect ratio.
      final deltaW = (world.dx - _imageGestureStartWorld.dx);
      final newWidth = max(40.0, _imageGestureStartRect.width + deltaW);
      final aspect =
          _imageGestureStartRect.width / _imageGestureStartRect.height;
      widget.controller.updateImageLive(
        original.copyWith(
          width: newWidth,
          height: newWidth / aspect,
        ),
      );
    } else if (_movingImage) {
      final delta = world - _imageGestureStartWorld;
      final candidateCenter = Offset(
        _imageGestureStartRect.center.dx + delta.dx,
        _imageGestureStartRect.center.dy + delta.dy,
      );
      // Snapping: ajusta a guías si está cerca.
      final snap = SnapGuides.compute(
        candidateCenter: candidateCenter,
        candidateBounds: original.rect,
        strokes: widget.controller.page.strokes,
        images: widget.controller.page.images,
        sheetSize: widget.controller.page.template.isFinite
            ? widget.controller.sheetSize
            : null,
        excludeImageId: original.id,
      );
      widget.controller.setSnapGuides(snap.verticalGuides, snap.horizontalGuides);
      // hasSnap (no `!= Offset.zero`): ajustar al centro (0,0) es un snap válido.
      final adjusted = snap.hasSnap ? snap.snappedPoint : candidateCenter;
      widget.controller.updateImageLive(
        original.copyWith(
          x: adjusted.dx,
          y: adjusted.dy,
        ),
      );
    }
  }

  void _commitImageGesture() {
    final original = _imageGestureOriginal;
    final moved = _movingImage || _resizingImage || _rotatingImage;
    _movingImage = false;
    _resizingImage = false;
    _rotatingImage = false;
    _imageGestureOriginal = null;
    _drawingPointer = null;
    widget.controller.clearSnapGuides();
    if (original == null) return;

    // Busca el item actual (modificado en vivo) para confirmar el cambio.
    ImageItem? current;
    for (final i in widget.controller.page.images) {
      if (i.id == original.id) {
        current = i;
        break;
      }
    }
    if (current != null && moved) {
      widget.controller.commitImageChange(original, current);
    }
  }

  void _cancelImageGesture() {
    _movingImage = false;
    _resizingImage = false;
    _rotatingImage = false;
    _imageGestureOriginal = null;
    _drawingPointer = null;
  }

  void _commitStrokeMove() {
    // Solo registrar deshacer si hubo movimiento real.
    if (_strokeMoveDelta.distance > 0.5) {
      widget.controller.commitMoveStrokes(_strokesBeforeMove);
    }
    _movingStrokes = false;
    _strokeMoveDelta = Offset.zero;
    _strokesBeforeMove = [];
    _drawingPointer = null;
  }

  void _cancelStrokeMove() {
    widget.controller.restoreStrokeSelection(_strokesBeforeMove);
    _movingStrokes = false;
    _strokeMoveDelta = Offset.zero;
    _strokesBeforeMove = [];
    _drawingPointer = null;
  }


  Rect _computeSelectionBounds(List<Stroke> strokes) => selectionBounds(strokes);
}
