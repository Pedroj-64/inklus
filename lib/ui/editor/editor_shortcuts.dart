// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';

/// Atajos de teclado del editor (teclado físico en tablet / escritorio).
///
/// | Tecla | Acción |
/// |---|---|
/// | Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y | deshacer / rehacer |
/// | Ctrl+C / Ctrl+V / Ctrl+D | copiar / pegar / duplicar selección |
/// | Supr / Retroceso | eliminar selección |
/// | Esc | quitar selección |
/// | P · H · E · L · T · V | pluma · resaltador · borrador · lazo · texto · mover |
/// | RePág / AvPág | página anterior / siguiente |
/// | Ctrl+B | marcar página · Ctrl+G ir a página |
/// | Ctrl + / Ctrl − / Ctrl+0 | acercar / alejar / ajustar |
abstract final class EditorShortcuts {
  /// Procesa [event]; devuelve `handled` si era un atajo.
  ///
  /// [onGoToPage] abre el diálogo "Ir a página" (lo aporta la pantalla).
  static KeyEventResult handle(
    KeyEvent event,
    CanvasController c, {
    VoidCallback? onGoToPage,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;
    final shift = keyboard.isShiftPressed;
    final key = event.logicalKey;

    bool done(void Function() action) {
      action();
      return true;
    }

    final handled = switch (key) {
      _ when ctrl && key == LogicalKeyboardKey.keyZ && !shift =>
        done(() => c.canUndo ? c.undo() : null),
      _ when ctrl &&
              ((key == LogicalKeyboardKey.keyZ && shift) || key == LogicalKeyboardKey.keyY) =>
        done(() => c.canRedo ? c.redo() : null),
      _ when ctrl && key == LogicalKeyboardKey.keyC => done(c.copySelectedStrokes),
      _ when ctrl && key == LogicalKeyboardKey.keyV => done(c.pasteStrokes),
      _ when ctrl && key == LogicalKeyboardKey.keyD => done(c.duplicateSelectedStrokes),
      _ when ctrl && key == LogicalKeyboardKey.keyB => done(c.toggleBookmark),
      _ when ctrl && key == LogicalKeyboardKey.keyG && onGoToPage != null => done(onGoToPage),
      _ when ctrl && (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add ||
              key == LogicalKeyboardKey.numpadAdd) =>
        done(() => c.zoomAt(1.25, _center(c), c.viewportSize)),
      _ when ctrl && (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) =>
        done(() => c.zoomAt(0.8, _center(c), c.viewportSize)),
      _ when ctrl && (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) =>
        done(() => c.fitView(c.viewportSize)),
      LogicalKeyboardKey.pageDown => done(c.nextPage),
      LogicalKeyboardKey.pageUp => done(c.previousPage),
      LogicalKeyboardKey.delete || LogicalKeyboardKey.backspace
          when c.selectedStrokes.isNotEmpty =>
        done(c.deleteSelectedStrokes),
      LogicalKeyboardKey.escape => done(c.clearLassoSelection),
      _ when !ctrl && !_typingText() => _toolKey(key, c),
      _ => false,
    };
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  /// Teclas de una letra para cambiar de herramienta.
  static bool _toolKey(LogicalKeyboardKey key, CanvasController c) {
    final tool = switch (key) {
      LogicalKeyboardKey.keyP => ToolType.pen,
      LogicalKeyboardKey.keyH => ToolType.highlighter,
      LogicalKeyboardKey.keyE => ToolType.eraser,
      LogicalKeyboardKey.keyL => ToolType.lasso,
      LogicalKeyboardKey.keyT => ToolType.text,
      LogicalKeyboardKey.keyV => ToolType.select,
      _ => null,
    };
    if (tool == null) return false;
    c.setTool(tool);
    return true;
  }

  /// true si el foco está en un campo de texto: entonces las letras son
  /// texto, no atajos.
  static bool _typingText() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null && ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  static Offset _center(CanvasController c) =>
      Offset(c.viewportSize.width / 2, c.viewportSize.height / 2);
}
