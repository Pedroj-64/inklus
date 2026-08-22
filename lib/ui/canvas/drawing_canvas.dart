import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../logic/snap_guides.dart';
import '../../logic/stroke_engine.dart';
import '../../models/image_item.dart';
import '../../models/page.dart';
import '../../models/stroke.dart';
import '../../services/image_service.dart';
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
  final double scale;
  final Offset translate;
  final bool isDark;

  CanvasPainter({
    required this.page,
    required this.contentVersion,
    required this.sheetSize,
    required this.imageCache,
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
    if (active != null && active.points.length >= 2) {
      final path = strokeToPath(active.points, active.tool, active.size);
      final activePaint = Paint()
        ..color = active.tool == ToolType.highlighter
            ? active.color.withValues(alpha: 0.38)
            : active.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, activePaint);
    }

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

    // Trazos seleccionados con el lazo (resaltados).
    final selectedStrokes = controller.selectedStrokes;
    if (selectedStrokes.isNotEmpty) {
      for (final stroke in selectedStrokes) {
        final outline = StrokeEngine.outlineFor(stroke);
        if (outline.length < 3) continue;
        final path = Path()..addPolygon(outline, true);
        canvas.drawPath(path, _selectionFillPaint);
      }
      // Dashed border around selected strokes (marching ants simplificado).
      if (selectedStrokes.isNotEmpty) {
        var left = double.infinity, top = double.infinity;
        var right = double.negativeInfinity, bottom = double.negativeInfinity;
        for (final s in selectedStrokes) {
          for (final p in s.points) {
            if (p.x < left) left = p.x;
            if (p.y < top) top = p.y;
            if (p.x > right) right = p.x;
            if (p.y > bottom) bottom = p.y;
          }
        }
        final bounds = Rect.fromLTRB(left, top, right, bottom);
        if (!bounds.isEmpty) {
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

  const DrawingCanvas({
    super.key,
    required this.controller,
    required this.imageService,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Size _viewport = Size.zero;

  // Estado de punteros.
  int? _drawingPointer;
  bool _stylusDown = false;
  bool _transforming = false;

  // Gesto de transformación.
  double _startScale = 1;
  Offset _startTranslate = Offset.zero;

  // Interacción con imágenes (herramienta select).
  bool _movingImage = false;
  bool _resizingImage = false;
  bool _rotatingImage = false;
  ImageItem? _imageGestureOriginal;
  Offset _imageGestureStartWorld = Offset.zero;
  Rect _imageGestureStartRect = Rect.zero;
  double _imageGestureStartRotation = 0;

  // ---- Gestos y atajos ----
  DateTime? _lastInvertedStylusTapTime;
  // Para detectar dos-dedos tap (undo): rastrea pointers y tiempos.
  final Set<int> _twoFingerPointers = {};
  DateTime? _twoFingerStartTime;

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
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            final ctrl = HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;
            if (!ctrl) return KeyEventResult.ignored;

            final key = event.logicalKey;

            // C9: Ctrl+Z → deshacer
            if (key == LogicalKeyboardKey.keyZ &&
                !HardwareKeyboard.instance.isShiftPressed) {
              if (widget.controller.canUndo) widget.controller.undo();
              return KeyEventResult.handled;
            }
            // C9: Ctrl+Shift+Z / Ctrl+Y → rehacer
            if ((key == LogicalKeyboardKey.keyZ &&
                    HardwareKeyboard.instance.isShiftPressed) ||
                key == LogicalKeyboardKey.keyY) {
              if (widget.controller.canRedo) widget.controller.redo();
              return KeyEventResult.handled;
            }
            // C9: Ctrl+C → copiar selección
            if (key == LogicalKeyboardKey.keyC) {
              widget.controller.copySelectedStrokes();
              return KeyEventResult.handled;
            }
            // C9: Ctrl+V → pegar
            if (key == LogicalKeyboardKey.keyV) {
              widget.controller.pasteStrokes();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
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
                  RepaintBoundary(
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
                            scale: widget.controller.scale,
                            translate: widget.controller.translate,
                            isDark: Theme.of(context).brightness == Brightness.dark,
                          ),
                        );
                      },
                    ),
                  ),
                  // Capa activa (trazo en curso, cursor, selección).
                  ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => CustomPaint(
                      size: Size.infinite,
                      painter: ActiveLayerPainter(
                        controller: widget.controller,
                        imageCache: widget.imageService.cache,
                      ),
                    ),
                  ),
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

  void _onPointerDown(PointerDownEvent event) {
    final kind = event.kind;
    final world = widget.controller.viewportToWorld(
      event.localPosition,
      _viewport,
    );

    if (kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus ||
        kind == PointerDeviceKind.mouse) {
      // Puntero "serio": stylus, borrador físico (invertedStylus) o mouse
      // (útil para probar en escritorio). El stylus activa el rechazo de
      // palma para cualquier touch simultáneo.
      _stylusDown = kind != PointerDeviceKind.mouse;
      _drawingPointer = event.pointer;

      if (kind == PointerDeviceKind.invertedStylus) {
        // ---- Atajo: doble toque con borrador físico = borrar página ----
        final now = DateTime.now();
        final last = _lastInvertedStylusTapTime;
        if (last != null && now.difference(last).inMilliseconds < 350) {
          _lastInvertedStylusTapTime = null;
          if (widget.controller.pageCount > 1) {
            widget.controller.deleteCurrentPage();
          }
          return; // No comienza trazo
        }
        _lastInvertedStylusTapTime = now;
        // InvertedStylus = borrador automático
        widget.controller.beginStroke(world, event.pressure, tool: ToolType.eraser);
      } else if (widget.controller.tool == ToolType.select) {
        _handleSelectDown(event.localPosition, world, event.pointer);
      } else {
        // Lasso y herramientas de escritura: beginStroke gestiona internamente.
        _drawingPointer = event.pointer;
        widget.controller.beginStroke(world, event.pressure, tool: widget.controller.tool);
      }
    } else if (kind == PointerDeviceKind.touch) {
      // REchazo de palma: mientras un stylus esté en contacto, todo touch
      // se ignora por completo (no dibuja, no panea, no selecciona).
      if (_stylusDown || _transforming) return;

      // ---- Atajo: dos dedos tap = deshacer ----
      _twoFingerPointers.add(event.pointer);
      if (_twoFingerPointers.length == 2) {
        _twoFingerStartTime = DateTime.now();
      }

      if (widget.controller.tool == ToolType.select) {
        _handleSelectDown(event.localPosition, world, event.pointer);
      } else if (widget.controller.fingerDrawingEnabled) {
        _drawingPointer = event.pointer;
        widget.controller.beginStroke(world, event.pressure,
            tool: widget.controller.tool);
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_movingImage || _resizingImage || _rotatingImage || _movingStrokes ||
        _scalingSelection || _rotatingSelection) {
      _handleSelectMove(event.localPosition);
      return;
    }
    if (event.pointer != _drawingPointer) return;
    final world = widget.controller.viewportToWorld(
      event.localPosition,
      _viewport,
    );
    widget.controller.addStrokePoint(world, event.pressure);
  }

  void _onPointerUp(PointerUpEvent event) {
    // ---- Atajo: dos dedos tap = deshacer ----
    _twoFingerPointers.remove(event.pointer);
    if (_twoFingerPointers.isEmpty && _twoFingerStartTime != null) {
      final elapsed = DateTime.now().difference(_twoFingerStartTime!);
      _twoFingerStartTime = null;
      if (elapsed.inMilliseconds < 300 && !_transforming && !_stylusDown) {
        widget.controller.undo();
        return;
      }
    }

    // ---- Transformar selección: confirmar ----
    if (_scalingSelection || _rotatingSelection) {
      widget.controller.commitTransformSelection(_transformStrokesBefore);
      _scalingSelection = false;
      _rotatingSelection = false;
      _drawingPointer = null;
      return;
    }

    if (event.pointer != _drawingPointer && !_movingImage && !_resizingImage && !_rotatingImage && !_movingStrokes) {
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
    _drawingPointer = null;
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      _stylusDown = false;
    }
    widget.controller.endStroke();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _twoFingerPointers.remove(event.pointer);
    if (_movingStrokes) {
      _cancelStrokeMove();
      return;
    }
    if (_movingImage || _resizingImage || _rotatingImage) {
      _cancelImageGesture();
      return;
    }
    if (event.pointer == _drawingPointer) {
      _drawingPointer = null;
      _stylusDown = false;
      widget.controller.cancelStroke();
    }
  }

  // -------------------------------------------------------------------------
  // Zoom / pan con dos dedos (táctil)
  // -------------------------------------------------------------------------

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2 && !_stylusDown) {
      _beginTransform();
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2 && !_stylusDown && !_transforming) {
      _beginTransform();
    }
    if (!_transforming) return;

    final controller = widget.controller;
    final newScale = (_startScale * details.scale).clamp(0.1, 6.0);
    final ratio = newScale / _startScale;
    final focal = details.localFocalPoint;
    // Mantiene fijo el punto del mundo que estaba bajo el foco inicial.
    final newTranslate = focal - (focal - _startTranslate) * ratio;
    controller.setView(newScale, newTranslate);
  }

  void _beginTransform() {
    // Si había un trazo de dedo en curso, se cancela al empezar el zoom.
    if (widget.controller.isDrawing) {
      widget.controller.cancelStroke();
      _drawingPointer = null;
    }
    _transforming = true;
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

    // 0) ¿Hay trazos seleccionados con lazo? Detectar handles o mover.
    if (selectedStrokes.isNotEmpty && selectedId == null) {
      final bounds = _computeSelectionBounds(selectedStrokes);
      _transformSelectionBounds = bounds;
      final handleSize = handleWorld * 1.5;

      // ¿Toca el handle de rotación (centro superior)?
      final rotHandle = Offset(bounds.center.dx, bounds.top - handleSize * 2);
      if ((world - rotHandle).distance <= handleSize) {
        _rotatingSelection = true;
        _transformStartAngle = (world - bounds.center).direction;
        _transformStrokesBefore = List<Stroke>.from(selectedStrokes);
        return;
      }
      // ¿Toca el handle de escala (esquina inferior derecha)?
      final scaleHandle = bounds.bottomRight;
      if ((world - scaleHandle).distance <= handleSize) {
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
        sheetSize: widget.controller.sheetSize,
      );
      widget.controller.setSnapGuides(snap.verticalGuides, snap.horizontalGuides);
      final adjusted = snap.snappedPoint != Offset.zero
          ? snap.snappedPoint
          : candidateCenter;
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
  }  void _cancelImageGesture() {
    _movingImage = false;
    _resizingImage = false;
    _rotatingImage = false;
    _imageGestureOriginal = null;
    _drawingPointer = null;
  }

  void _commitStrokeMove() {
    if (_strokesBeforeMove.isNotEmpty) {
      // Solo empujar undo si hubo movimiento real.
      final delta = widget.controller.selectedStrokes.isNotEmpty
          ? widget.controller.selectedStrokes.first.points.first.offset -
            _strokesBeforeMove.first.points.first.offset
          : Offset.zero;
      if (delta.distance > 0.5) {
        widget.controller.commitMoveStrokes(_strokesBeforeMove);
      }
    }
    _movingStrokes = false;
    _strokesBeforeMove = [];
    _drawingPointer = null;
  }

  void _cancelStrokeMove() {
    if (_strokesBeforeMove.isNotEmpty) {
      widget.controller.restoreStrokeSelection(_strokesBeforeMove);
    }
    _movingStrokes = false;
    _strokesBeforeMove = [];
    _drawingPointer = null;
  }


  /// Calcula el rectángulo delimitador de los trazos seleccionados.
  Rect _computeSelectionBounds(List<Stroke> strokes) {
    if (strokes.isEmpty) return Rect.zero;
    var left = double.infinity, top = double.infinity;
    var right = double.negativeInfinity, bottom = double.negativeInfinity;
    for (final s in strokes) {
      for (final p in s.points) {
        if (p.x < left) left = p.x;
        if (p.y < top) top = p.y;
        if (p.x > right) right = p.x;
        if (p.y > bottom) bottom = p.y;
      }
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
