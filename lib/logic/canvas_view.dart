// SPDX-License-Identifier: GPL-3.0-or-later
part of 'canvas_controller.dart';

/// Transformación de la vista (zoom/pan) del [CanvasController]. Los trazos
/// viven en coordenadas de mundo; esto solo decide cómo se ven.
mixin _CanvasView on _CanvasCore {
  // ---- Transformación de vista ----
  @override
  double _scale = kDefaultZoom;
  Offset _translate = Offset.zero;
  bool _viewInitialized = false;

  /// Tamaño del viewport del lienzo (lo actualiza la vista en cada layout).
  Size viewportSize = Size.zero;

  double get scale => _scale;
  Offset get translate => _translate;
  bool get viewNeedsInit => !_viewInitialized;

  // ------------------------------------------------------------------
  // Transformación de vista (zoom / pan)
  // ------------------------------------------------------------------

  void _setView(double scale, Offset translate) {
    _scale = scale.clamp(kMinZoom, kMaxZoom);
    if (!page.template.isFinite || viewportSize.isEmpty) {
      _translate = translate;
      notifyListeners();
      return;
    }
    // Hoja fija: la vista no se sale de la hoja… ni de sus vecinas apiladas
    // (desplazamiento continuo).
    var world = Rect.fromCenter(
        center: Offset.zero, width: sheetSize.width, height: sheetSize.height);
    final prev = _neighbor(-1), next = _neighbor(1);
    if (prev != null) {
      world = world.expandToInclude(Rect.fromCenter(
          center: Offset(0, prev.dy),
          width: prev.page.template.sheetSize.width,
          height: prev.page.template.sheetSize.height));
    }
    if (next != null) {
      world = world.expandToInclude(Rect.fromCenter(
          center: Offset(0, next.dy),
          width: next.page.template.sheetSize.width,
          height: next.page.template.sheetSize.height));
    }
    _translate = CanvasController.clampToWorldRect(translate, _scale, world, viewportSize);
    // Si el centro de la pantalla ya está en una vecina, pasa a ser la actual.
    final centerY = (viewportSize.height / 2 - _translate.dy) / _scale;
    final half = sheetSize.height / 2 + CanvasController.pageGap / 2;
    if (next != null && centerY > half) {
      _enterNeighborPage(1);
    } else if (prev != null && centerY < -half) {
      _enterNeighborPage(-1);
    }
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
}
