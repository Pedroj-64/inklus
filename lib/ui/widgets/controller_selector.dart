// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';

/// Reconstruye [builder] solo cuando cambia el valor que devuelve
/// [selector] (comparado con `==`), no en cada notificación de [listenable].
///
/// El [CanvasController] notifica en cada punto del trazo; los widgets que
/// solo muestran, p. ej., el título o el zoom no deben reconstruirse tanto.
/// Usar records para seleccionar varios valores: `(c.canUndo, c.canRedo)`.
class ControllerSelector<L extends Listenable, T> extends StatefulWidget {
  const ControllerSelector({
    super.key,
    required this.listenable,
    required this.selector,
    required this.builder,
  });

  final L listenable;
  final T Function(L listenable) selector;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<ControllerSelector<L, T>> createState() =>
      _ControllerSelectorState<L, T>();
}

class _ControllerSelectorState<L extends Listenable, T>
    extends State<ControllerSelector<L, T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.listenable);
    widget.listenable.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant ControllerSelector<L, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onChange);
      widget.listenable.addListener(_onChange);
    }
    _value = widget.selector(widget.listenable);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final next = widget.selector(widget.listenable);
    if (next != _value) setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
