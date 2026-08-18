import '../models/image_item.dart';
import '../models/stroke.dart';
import '../models/text_item.dart';

/// Una acción reversible sobre la página.
///
/// Deshacer = quitar [strokesAdded]/[imagesAdded]/[textItemsAdded] y restaurar
/// [strokesRemoved]/[imagesRemoved]/[textItemsRemoved]. Rehacer = operación inversa.
class CanvasAction {
  final List<Stroke> strokesAdded;
  final List<Stroke> strokesRemoved;
  final List<ImageItem> imagesAdded;
  final List<ImageItem> imagesRemoved;
  final List<TextItem> textItemsAdded;
  final List<TextItem> textItemsRemoved;

  const CanvasAction({
    this.strokesAdded = const [],
    this.strokesRemoved = const [],
    this.imagesAdded = const [],
    this.imagesRemoved = const [],
    this.textItemsAdded = const [],
    this.textItemsRemoved = const [],
  });

  bool get isEmpty =>
      strokesAdded.isEmpty &&
      strokesRemoved.isEmpty &&
      imagesAdded.isEmpty &&
      imagesRemoved.isEmpty &&
      textItemsAdded.isEmpty &&
      textItemsRemoved.isEmpty;
}

/// Pila de deshacer/rehacer con tope de acciones.
class UndoStack {
  final List<CanvasAction> _undo = [];
  final List<CanvasAction> _redo = [];
  static const int _maxDepth = 60;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(CanvasAction action) {
    if (action.isEmpty) return;
    _undo.add(action);
    if (_undo.length > _maxDepth) _undo.removeAt(0);
    _redo.clear();
  }

  CanvasAction? undo() {
    if (_undo.isEmpty) return null;
    final action = _undo.removeLast();
    _redo.add(action);
    return action;
  }

  CanvasAction? redo() {
    if (_redo.isEmpty) return null;
    final action = _redo.removeLast();
    _undo.add(action);
    return action;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
