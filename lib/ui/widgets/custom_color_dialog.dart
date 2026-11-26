// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';
import '../theme/inklus_colors.dart';
import '../../logic/canvas_controller.dart';
import 'color_wheel_picker.dart';
import '../../l10n/l10n.dart';
import '../theme/tokens.dart';

/// Diálogo de color personalizado (rueda HSV + hex), compartido por los
/// popovers de herramienta y la barra de selección.
/// Actualiza el hex del controlador de texto a partir de un HSVColor.
void _syncHex(TextEditingController hexCtrl, HSVColor hsv) {
  hexCtrl.text = '#${hsv.toColor().toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// Parsea un string hex a Color. Devuelve null si es inválido.
Color? _parseHex(String hex) {
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length != 6 && clean.length != 8) return null;
  try {
    return Color(int.parse('FF$clean', radix: 16));
  } catch (_) {
    return null;
  }
}

/// Diálogo de color personalizado con dos modos:
/// - **Rueda**: selector visual tipo rueda de color (intuitivo)
/// - **Sliders**: sliders HSV con gradiente (preciso)
///
/// Ambos modos comparten el preview Actual/Nuevo y el campo hex.
Future<void> showCustomColorDialog(
  BuildContext context,
  CanvasController controller,
) async {
  final previousColor = controller.color;
  var hsv = HSVColor.fromColor(controller.color);
  final hexController = TextEditingController(
    text: '#${controller.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
  );

  // 0 = Rueda, 1 = Sliders
  int mode = 0;

  final result = await showDialog<Color>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.colorCustomTitle),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---- Preview: Actual → Nuevo + Hex ----
              Row(
                children: [
                  // Color actual
                  Column(
                    children: [
                      Text(context.l10n.colorCurrent,
                          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      const SizedBox(height: Spacing.xs),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: previousColor,
                          border: Border.all(color: context.colors.outline, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    child: Icon(Icons.arrow_forward, size: 16, color: context.colors.onSurfaceVariant),
                  ),
                  // Color nuevo
                  Column(
                    children: [
                      Text(context.l10n.colorNew,
                          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      const SizedBox(height: Spacing.xs),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hsv.toColor(),
                          border: Border.all(color: context.colors.outline, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: Spacing.md),
                  // Campo hex
                  Expanded(
                    child: TextField(
                      controller: hexController,
                      decoration: const InputDecoration(
                        labelText: 'Hex',
                        hintText: '#FF0000',
                        prefixIcon: Icon(Icons.tag, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: Radii.smAll,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        final parsed = _parseHex(v);
                        if (parsed != null) {
                          setState(() {
                            hsv = HSVColor.fromColor(parsed);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // ---- Toggle: Rueda / Sliders ----
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: Radii.smAll,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.circle,
                        label: context.l10n.colorWheel,
                        selected: mode == 0,
                        onTap: () => setState(() => mode = 0),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.tune,
                        label: context.l10n.colorSliders,
                        selected: mode == 1,
                        onTap: () => setState(() => mode = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              // ---- Contenido según modo ----
              if (mode == 0)
                // Rueda de color
                ColorWheelPicker(
                  initialColor: hsv,
                  size: 260,
                  onColorChanged: (c) {
                    setState(() {
                      hsv = HSVColor.fromColor(c);
                      _syncHex(hexController, hsv);
                    });
                  },
                )
              else
                // Sliders HSV
                Column(
                  children: [
                    _HsvSliderWithGradient(
                      label: context.l10n.colorHue,
                      value: hsv.hue,
                      min: 0,
                      max: 360,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000), Color(0xFFFFFF00),
                          Color(0xFF00FF00), Color(0xFF00FFFF),
                          Color(0xFF0000FF), Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                      valueLabel: '${hsv.hue.round()}°',
                      onChanged: (v) => setState(() {
                        hsv = hsv.withHue(v);
                        _syncHex(hexController, hsv);
                      }),
                    ),
                    const SizedBox(height: Spacing.xs),
                    _HsvSliderWithGradient(
                      label: context.l10n.colorSaturation,
                      value: hsv.saturation,
                      min: 0,
                      max: 1,
                      gradient: LinearGradient(
                        colors: [
                          HSVColor.fromAHSV(1, hsv.hue, 0, hsv.value).toColor(),
                          HSVColor.fromAHSV(1, hsv.hue, 1, hsv.value).toColor(),
                        ],
                      ),
                      valueLabel: '${(hsv.saturation * 100).round()}%',
                      onChanged: (v) => setState(() {
                        hsv = hsv.withSaturation(v);
                        _syncHex(hexController, hsv);
                      }),
                    ),
                    const SizedBox(height: Spacing.xs),
                    _HsvSliderWithGradient(
                      label: context.l10n.colorBrightness,
                      value: hsv.value,
                      min: 0,
                      max: 1,
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          HSVColor.fromAHSV(1, hsv.hue, hsv.saturation, 1).toColor(),
                        ],
                      ),
                      valueLabel: '${(hsv.value * 100).round()}%',
                      onChanged: (v) => setState(() {
                        hsv = hsv.withValue(v);
                        _syncHex(hexController, hsv);
                      }),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, hsv.toColor()),
            child: Text(context.l10n.colorUse),
          ),
        ],
      ),
    ),
  );

  if (result != null) {
    controller.setColor(result);
  }
  hexController.dispose();
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: Radii.smAll,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16,
                color: selected ? context.colors.primary : context.colors.onSurfaceVariant),
            const SizedBox(width: Spacing.xs),
            Text(label,
                style: context.text.labelMedium?.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? context.colors.primary : context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _HsvSliderWithGradient extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Gradient gradient;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _HsvSliderWithGradient({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.gradient,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
            const Spacer(),
            Text(valueLabel,
                style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Spacing.xxs),
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
