// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Muestra [builder] en una tarjeta flotante **anclada** bajo el widget de
/// [anchorContext] (p. ej. el botón de la herramienta). Se cierra al tocar
/// fuera o con atrás. Devuelve el valor con el que se haga `Navigator.pop`.
///
/// Se usa para las opciones de cada herramienta: así no ocupan una barra fija
/// y el lienzo queda libre (patrón de GoodNotes/Notability).
Future<T?> showAnchoredPopover<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required WidgetBuilder builder,
  double width = Sizes.popoverWidth,
}) {
  final box = anchorContext.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  Rect anchor = Rect.zero;
  if (box != null && overlay != null) {
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    anchor = topLeft & box.size;
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Motion.normal,
    pageBuilder: (dialogContext, _, _) {
      final screen = MediaQuery.sizeOf(dialogContext);
      final w = width.clamp(200.0, screen.width - 2 * Spacing.sm);
      final left = (anchor.center.dx - w / 2)
          .clamp(Spacing.sm, screen.width - w - Spacing.sm);
      final top = anchor.bottom + Spacing.sm;
      final scheme = Theme.of(dialogContext).colorScheme;
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: w,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screen.height - top - Spacing.lg).clamp(160.0, 720.0),
              ),
              child: Material(
                color: scheme.surfaceContainerHigh,
                elevation: 8,
                shadowColor: scheme.shadow.withValues(alpha: 0.35),
                borderRadius: Radii.xlAll,
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: builder(dialogContext),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          alignment: Alignment.topCenter,
          child: child,
        ),
      );
    },
  );
}
