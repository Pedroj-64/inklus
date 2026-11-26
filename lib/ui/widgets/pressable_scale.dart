// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Envoltorio táctil de tarjetas: onda de tinta, ligera reducción al
/// pulsar y un toque háptico suave. Respeta "reducir animaciones".
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = Radii.lgAll,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _down && animate ? 0.97 : 1,
      duration: Motion.fast,
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onHighlightChanged: (v) => setState(() => _down = v),
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          widget.onTap();
        },
        child: widget.child,
      ),
    );
  }
}
