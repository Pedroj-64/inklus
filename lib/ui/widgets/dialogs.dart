// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Diálogos reutilizables (antes había varias copias casi idénticas, y
/// ninguna liberaba su TextEditingController).

/// Pide un texto al usuario. Devuelve null si se cancela.
///
/// [secondaryLabel]/[secondaryValue]: botón izquierdo alternativo (p. ej.
/// "Sin contraseña" → ''), en lugar de "Cancelar" → null.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  String? hint,
  String initialValue = '',
  bool obscure = false,
  String confirmLabel = 'Aceptar',
  String cancelLabel = 'Cancelar',
  String? secondaryLabel,
  String? secondaryValue,
  bool multiline = false,
  TextInputType? keyboardType,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      hint: hint,
      initialValue: initialValue,
      obscure: obscure,
      confirmLabel: confirmLabel,
      cancelLabel: secondaryLabel ?? cancelLabel,
      cancelValue: secondaryLabel != null ? secondaryValue : null,
      multiline: multiline,
      keyboardType: keyboardType,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.obscure,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.cancelValue,
    this.multiline = false,
    this.keyboardType,
  });

  final String title;
  final String? hint;
  final String initialValue;
  final bool obscure;
  final String confirmLabel;
  final String cancelLabel;
  final String? cancelValue;
  final bool multiline;
  final TextInputType? keyboardType;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        obscureText: widget.obscure,
        decoration: InputDecoration(hintText: widget.hint),
        keyboardType: widget.keyboardType,
        maxLines: widget.multiline ? null : 1,
        minLines: widget.multiline ? 2 : 1,
        onSubmitted: widget.multiline ? null : (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.cancelValue),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Muestra un indicador de progreso modal mientras corre [task] y lo cierra
/// al terminar (también si falla; el error se propaga al llamador).
Future<T> runWithLoading<T>(BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}
