// SPDX-License-Identifier: GPL-3.0-or-later
import '../models/image_item.dart';
import '../models/stroke.dart';
import '../models/text_item.dart';

/// Una acción reversible sobre la página.
///
/// Deshacer = quitar [strokesAdded]/[imagesAdded]/[textItemsAdded] y restaurar
/// [strokesRemoved]/[imagesRemoved]/[textItemsRemoved]. Rehacer = operación inversa.
///
/// El **orden** (z-order) se conserva:
/// - si un elemento añadido tiene el mismo id que uno quitado (mover,
///   transformar, editar imagen), se reemplaza en su misma posición;
/// - [strokesRemovedAt]/[strokesAddedAt] (opcionales) guardan las posiciones
///   originales para reinsertar en su sitio (borrador, eliminar selección).
class CanvasAction {
  final List<Stroke> strokesAdded;
  final List<Stroke> strokesRemoved;
  final List<ImageItem> imagesAdded;
  final List<ImageItem> imagesRemoved;
  final List<TextItem> textItemsAdded;
  final List<TextItem> textItemsRemoved;

  /// Índices de [strokesRemoved] en la lista ANTES de la acción.
  final List<int>? strokesRemovedAt;

  /// Índices de [strokesAdded] en la lista DESPUÉS de la acción.
  final List<int>? strokesAddedAt;

  const CanvasAction({
    this.strokesAdded = const [],
    this.strokesRemoved = const [],
    this.imagesAdded = const [],
    this.imagesRemoved = const [],
    this.textItemsAdded = const [],
    this.textItemsRemoved = const [],
    this.strokesRemovedAt,
    this.strokesAddedAt,
  });

  /// Construye la acción que lleva [before] a [after] (misma lista de
  /// trazos antes y después), guardando solo lo que cambió y sus posiciones.
  /// O(n) usando identidad de instancia.
  factory CanvasAction.strokeDiff(List<Stroke> before, List<Stroke> after) {
    final beforeSet = Set<Stroke>.identity()..addAll(before);
    final afterSet = Set<Stroke>.identity()..addAll(after);
    final removed = <Stroke>[];
    final removedAt = <int>[];
    for (var i = 0; i < before.length; i++) {
      if (!afterSet.contains(before[i])) {
        removed.add(before[i]);
        removedAt.add(i);
      }
    }
    final added = <Stroke>[];
    final addedAt = <int>[];
    for (var i = 0; i < after.length; i++) {
      if (!beforeSet.contains(after[i])) {
        added.add(after[i]);
        addedAt.add(i);
      }
    }
    return CanvasAction(
      strokesRemoved: removed,
      strokesRemovedAt: removedAt,
      strokesAdded: added,
      strokesAddedAt: addedAt,
    );
  }

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
  final int maxDepth;

  UndoStack({this.maxDepth = 60});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(CanvasAction action) {
    if (action.isEmpty) return;
    _undo.add(action);
    if (_undo.length > maxDepth) _undo.removeAt(0);
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

/// Quita [remove] de [list] y coloca [add] conservando el orden:
/// - con [addAt]: cada elemento se inserta en su índice (ascendente);
/// - sin [addAt]: un elemento con el mismo id que uno quitado ocupa su
///   posición; el resto se añade al final.
///
/// La comparación de [remove] es por identidad de instancia.
void applyOrderedSwap<T extends Object>(
  List<T> list, {
  required List<T> remove,
  required List<T> add,
  List<int>? addAt,
  required String Function(T) idOf,
}) {
  final removeSet = Set<T>.identity()..addAll(remove);
  if (addAt != null && addAt.length == add.length) {
    list.removeWhere(removeSet.contains);
    final order = List<int>.generate(add.length, (i) => i)
      ..sort((a, b) => addAt[a].compareTo(addAt[b]));
    for (final i in order) {
      list.insert(addAt[i].clamp(0, list.length), add[i]);
    }
    return;
  }
  final pending = <String, T>{for (final a in add) idOf(a): a};
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (!removeSet.contains(item)) continue;
    final replacement = pending.remove(idOf(item));
    if (replacement != null) {
      list[i] = replacement;
      removeSet.remove(item);
    }
  }
  if (removeSet.isNotEmpty) list.removeWhere(removeSet.contains);
  // Añade los que no reemplazaron nada, en su orden original.
  for (final a in add) {
    if (pending.containsKey(idOf(a))) list.add(a);
  }
}
