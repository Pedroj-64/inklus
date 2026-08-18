import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Page;

import '../../logic/canvas_controller.dart';
import '../../models/image_item.dart';
import '../../models/page.dart';
import '../../models/stroke.dart';
import '../../services/image_service.dart';
import 'world_painter.dart';

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

  CanvasPainter({
    required this.page,
    required this.contentVersion,
    required this.sheetSize,
    required this.imageCache,
    required this.scale,
    required this.translate,
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
      oldDelegate.imageCache != imageCache;
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

    // Trazo en progreso.
    if (active != null && active.points.length >= 2) {
      final path = strokeToPath(active.points, active.tool, active.size);
      canvas.drawPath(
        path,
        Paint()
          ..color = active.tool == ToolType.highlighter
              ? active.color.withValues(alpha: 0.38)
              : active.color
          ..style = PaintingStyle.fill,
      );
    }

    // Selección de imagen (borde + asa de redimensionado).
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
            ..color = const Color(0xFF3B82F6),
        );
        final handle = rect.bottomRight;
        final r = 11 / scale;
        canvas.drawCircle(
          handle,
          r,
          Paint()..color = const Color(0xFF3B82F6),
        );
        canvas.drawCircle(
          handle,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale
            ..color = Colors.white,
        );
        break;
      }
    }

    canvas.restore();

    // ---- Cursor del borrador (espacio de pantalla, tamaño constante) ----
    if (eraserPath.isNotEmpty) {
      final last = eraserPath.last;
      final screen = last * scale + translate;
      final radius = controller.eraserRadius * scale;
      canvas.drawCircle(
        screen,
        radius,
        Paint()
          ..color = const Color(0x40FFFFFF)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        screen,
        radius,
        Paint()
          ..color = const Color(0x99000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else if (active != null && active.points.isNotEmpty) {
      // Pequeño cursor que muestra el grosor actual de la punta.
      final last = active.points.last.offset;
      final screen = last * scale + translate;
      final r = (active.size * scale) / 2;
      canvas.drawCircle(
        screen,
        r,
        Paint()
          ..color = active.color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
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
  ImageItem? _imageGestureOriginal;
  Offset _imageGestureStartWorld = Offset.zero;
  Rect _imageGestureStartRect = Rect.zero;

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

        return Listener(
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
                ],
              ),
            ),
          ),
        );
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

      if (widget.controller.tool == ToolType.select &&
          kind != PointerDeviceKind.invertedStylus) {
        _handleSelectDown(event.localPosition, world, event.pointer);
      } else {
        final tool = kind == PointerDeviceKind.invertedStylus
            ? ToolType.eraser // punta trasera del lápiz = borrador automático
            : widget.controller.tool;
        widget.controller.beginStroke(world, event.pressure, tool: tool);
      }
    } else if (kind == PointerDeviceKind.touch) {
      // REchazo de palma: mientras un stylus esté en contacto, todo touch
      // se ignora por completo (no dibuja, no panea, no selecciona).
      if (_stylusDown || _transforming) return;

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
    if (_movingImage || _resizingImage) {
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
    if (event.pointer != _drawingPointer && !_movingImage && !_resizingImage) {
      return;
    }
    if (_movingImage || _resizingImage) {
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
    if (_movingImage || _resizingImage) {
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
    final handleWorld = 30 / controller.scale;

    // 1) ¿Toca el asa de redimensionado de la imagen seleccionada?
    if (selectedId != null) {
      ImageItem? selected;
      for (final i in controller.page.images) {
        if (i.id == selectedId) {
          selected = i;
          break;
        }
      }
      if (selected != null &&
          (world - selected.rect.bottomRight).distance <= handleWorld) {
        _resizingImage = true;
        _imageGestureOriginal = selected;
        _imageGestureStartWorld = world;
        _imageGestureStartRect = selected.rect;
        return;
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
    } else {
      controller.selectImage(null);
    }
  }

  void _handleSelectMove(Offset local) {
    final world = widget.controller.viewportToWorld(local, _viewport);
    final original = _imageGestureOriginal;
    if (original == null) return;

    if (_resizingImage) {
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
      widget.controller.updateImageLive(
        original.copyWith(
          x: _imageGestureStartRect.center.dx + delta.dx,
          y: _imageGestureStartRect.center.dy + delta.dy,
        ),
      );
    }
  }

  void _commitImageGesture() {
    final original = _imageGestureOriginal;
    final moved = _movingImage || _resizingImage;
    _movingImage = false;
    _resizingImage = false;
    _imageGestureOriginal = null;
    _drawingPointer = null;
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
    _imageGestureOriginal = null;
    _drawingPointer = null;
  }
}
