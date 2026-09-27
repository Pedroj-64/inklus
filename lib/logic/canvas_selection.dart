// SPDX-License-Identifier: GPL-3.0-or-later
part of 'canvas_controller.dart';

/// Selección del [CanvasController]: lazo (trazos, imágenes y textos),
/// portapapeles, mover/escalar/rotar y selección por toque.
mixin _CanvasSelection on _CanvasCore {
  // ---- Selección con lazo ----
  List<Offset> _lassoPath = [];
  List<Stroke> _selectedStrokes = [];

  // ---- Portapapeles de trazos (copy/paste) ----
  List<Stroke> _clipboardStrokes = [];
  List<ImageItem> _clipboardImages = [];
  List<TextItem> _clipboardTexts = [];

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

  /// Estado de imágenes/textos al empezar a escalar/rotar la selección.
  List<ImageItem>? _transformImagesBefore;
  List<TextItem>? _transformTextsBefore;

  /// Asas del recuadro de selección en coordenadas de mundo: escala (esquina
  /// inferior derecha) y rotación (sobre el centro superior). **Única
  /// fuente** para pintarlas y para detectar el toque.
  ({Rect frame, Offset scale, Offset rotate, double radius}) get selectionHandles {
    final frame = selectionBoundsAll.inflate(8 / _scale);
    final r = 11 / _scale;
    return (
      frame: frame,
      scale: frame.bottomRight,
      rotate: Offset(frame.center.dx, frame.top - r * 3),
      radius: r,
    );
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

  /// Copia la selección (trazos, imágenes y textos) al portapapeles interno.
  void copySelectedStrokes() {
    if (!hasLassoSelection) return;
    _clipboardStrokes = List<Stroke>.from(_selectedStrokes);
    _clipboardImages = selectedImages;
    _clipboardTexts = selectedTexts;
    _notifyBottomBarContext();
  }

  /// Pega el portapapeles en la página actual (en la capa activa),
  /// desplazado [kPasteOffset] para que no quede encima del original. Lo
  /// pegado queda seleccionado.
  void pasteStrokes() {
    if (!hasClipboard) return;
    // Pegar en una capa bloqueada no tiene sentido.
    if (_isLayerLocked(_activeLayerIndex)) {
      _onLayerBlocked?.call();
      return;
    }
    const offset = Offset(kPasteOffset, kPasteOffset);
    // Conservan color, relleno, figura y ajustes; se pegan en la capa activa.
    final strokes = [
      for (final s in _clipboardStrokes)
        s.translated(offset).copyWith(id: newId('st'), layerIndex: _activeLayerIndex),
    ];
    final images = [
      for (final i in _clipboardImages)
        i.copyWith(
          id: newId('img'),
          x: i.x + offset.dx,
          y: i.y + offset.dy,
          layerIndex: _activeLayerIndex,
        ),
    ];
    final texts = [
      for (final t in _clipboardTexts)
        t.copyWith(
          id: newId('txt'),
          x: t.x + offset.dx,
          y: t.y + offset.dy,
          layerIndex: _activeLayerIndex,
        ),
    ];
    page.strokes.addAll(strokes);
    page.images.addAll(images);
    page.textItems.addAll(texts);
    _undoStack.push(CanvasAction(
      strokesAdded: strokes,
      imagesAdded: images,
      textItemsAdded: texts,
    ));
    _selectedStrokes = strokes;
    _selectedImageIds = {for (final i in images) i.id};
    _selectedTextIds = {for (final t in texts) t.id};
    _notifyBottomBarContext();
    _touch();
  }

  bool get hasClipboard =>
      _clipboardStrokes.isNotEmpty ||
      _clipboardImages.isNotEmpty ||
      _clipboardTexts.isNotEmpty;

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
    if (!hasLassoSelection) return;
    final saved = (_clipboardStrokes, _clipboardImages, _clipboardTexts);
    copySelectedStrokes();
    pasteStrokes();
    _clipboardStrokes = saved.$1;
    _clipboardImages = saved.$2;
    _clipboardTexts = saved.$3;
    _notifyBottomBarContext();
  }

  // ------------------------------------------------------------------
  // Transformar selección (escalar/rotar)
  // ------------------------------------------------------------------

  /// Aplica una transformación afín **incremental** a la selección:
  /// [scaleFactor] y [rotationAngle] (radianes) alrededor de [pivotPoint].
  ///
  /// - Trazos: se transforman sus puntos (y su grosor con la escala).
  /// - Imágenes: centro, tamaño y rotación.
  /// - Textos: posición, ancho y tamaño de letra; se mantienen derechos
  ///   (una caja de texto no tiene rotación).
  ///
  /// El estado inicial se guarda la primera vez para que
  /// [commitTransformSelection] empuje una única acción de deshacer.
  void transformSelectedStrokes({
    required double scaleFactor,
    required double rotationAngle,
    required Offset pivotPoint,
  }) {
    if (!hasLassoSelection) return;
    final cosA = cos(rotationAngle);
    final sinA = sin(rotationAngle);
    Offset map(double x, double y) {
      final dx = (x - pivotPoint.dx) * scaleFactor;
      final dy = (y - pivotPoint.dy) * scaleFactor;
      return Offset(
        dx * cosA - dy * sinA + pivotPoint.dx,
        dx * sinA + dy * cosA + pivotPoint.dy,
      );
    }

    for (final original in List<Stroke>.from(_selectedStrokes)) {
      if (_isLayerLocked(original.layerIndex)) continue;
      final newPoints = [
        for (final p in original.points)
          StrokePoint.fromOffset(map(p.x, p.y), p.pressure),
      ];
      // copyWith conserva capa, figura, relleno y ajustes.
      final newStroke = original.copyWith(
        points: newPoints,
        size: original.size * scaleFactor,
      );
      // Reemplaza el trazo en la página (misma posición = mismo z-order).
      final idx = page.strokes.indexWhere((s) => s.id == original.id);
      if (idx >= 0) page.strokes[idx] = newStroke;
      final selIdx = _selectedStrokes.indexOf(original);
      if (selIdx >= 0) _selectedStrokes[selIdx] = newStroke;
    }

    _transformImagesBefore ??=
        selectedImages.where((i) => !_isLayerLocked(i.layerIndex)).toList();
    _transformTextsBefore ??=
        selectedTexts.where((t) => !_isLayerLocked(t.layerIndex)).toList();
    final imageIds = {for (final i in _transformImagesBefore!) i.id};
    final textIds = {for (final t in _transformTextsBefore!) t.id};
    for (var i = 0; i < page.images.length; i++) {
      final img = page.images[i];
      if (!imageIds.contains(img.id)) continue;
      final c = map(img.x, img.y);
      page.images[i] = img.copyWith(
        x: c.dx,
        y: c.dy,
        width: max(4.0, img.width * scaleFactor),
        height: max(4.0, img.height * scaleFactor),
        rotation: img.rotation + rotationAngle,
      );
    }
    for (var i = 0; i < page.textItems.length; i++) {
      final t = page.textItems[i];
      if (!textIds.contains(t.id)) continue;
      final c = map(t.x, t.y);
      page.textItems[i] = t.copyWith(
        x: c.dx,
        y: c.dy,
        width: max(24.0, t.width * scaleFactor),
        fontSize: (t.fontSize * scaleFactor).clamp(6.0, 400.0),
      );
    }
    _touchLive();
  }

  /// Confirma la transformación de la selección: una sola acción de
  /// deshacer con trazos, imágenes y textos.
  void commitTransformSelection(List<Stroke> before) {
    final imagesBefore = _transformImagesBefore ?? const <ImageItem>[];
    final textsBefore = _transformTextsBefore ?? const <TextItem>[];
    _transformImagesBefore = null;
    _transformTextsBefore = null;
    if (!hasLassoSelection) return;
    final imageIds = {for (final i in imagesBefore) i.id};
    final textIds = {for (final t in textsBefore) t.id};
    _undoStack.push(
      CanvasAction(
        strokesRemoved: before,
        strokesAdded: List<Stroke>.from(_selectedStrokes),
        imagesRemoved: imagesBefore,
        imagesAdded: page.images.where((i) => imageIds.contains(i.id)).toList(),
        textItemsRemoved: textsBefore,
        textItemsAdded:
            page.textItems.where((t) => textIds.contains(t.id)).toList(),
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
}
