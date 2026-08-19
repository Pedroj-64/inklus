import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../logic/canvas_controller.dart';
import '../../models/stroke.dart';
import 'color_wheel_picker.dart';

/// Paleta de colores por defecto.
const kPalette = kDefaultPalette;


/// Barra inferior: color + tamaño + opciones de escritura.
class BottomBar extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback? onStrokeOptions;

  const BottomBar({super.key, required this.controller, this.onStrokeOptions});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isEraser = controller.tool == ToolType.eraser;
        final isSelect = controller.tool == ToolType.select;
        final range = controller.sizeRange;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila principal: paleta + acciones
                  Row(
                    children: [
                      // ---- Paleta de colores (oculta con borrador/selección) ----
                      if (!isEraser && !isSelect) ...[
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: kDefaultPalette.length + 1,
                              separatorBuilder: (_, _) => const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                if (i == kDefaultPalette.length) {
                                  return _CustomColorSwatch(
                                    controller: controller,
                                  );
                                }
                                final color = kDefaultPalette[i];
                                return _ColorSwatch(
                                  color: color,
                                  selected: controller.color == color,
                                  onTap: () => controller.setColor(color),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // ---- Acciones de selección con lazo ----
                      if (controller.selectedStrokes.isNotEmpty) ...[
                        _ActionIcon(
                          icon: Icons.copy,
                          tooltip: 'Copiar',
                          color: kAccentColor,
                          onTap: controller.copySelectedStrokes,
                        ),
                        _ActionIcon(
                          icon: Icons.delete_outline,
                          tooltip: 'Eliminar',
                          color: kErrorColor,
                          onTap: controller.deleteSelectedStrokes,
                        ),
                      ],
                      if (controller.hasClipboard && controller.selectedStrokes.isEmpty)
                        _ActionIcon(
                          icon: Icons.paste,
                          tooltip: 'Pegar',
                          color: kAccentColor,
                          onTap: controller.pasteStrokes,
                        ),

                      // ---- Toggles de herramienta ----
                      if (!isEraser && !isSelect && controller.tool != ToolType.lasso) ...[
                        _ToggleIcon(
                          icon: Icons.change_history,
                          tooltip: 'Formas',
                          active: controller.shapeDetectionEnabled,
                          onTap: () => controller.setShapeDetection(
                            !controller.shapeDetectionEnabled,
                          ),
                        ),
                        _ToggleIcon(
                          icon: Icons.back_hand,
                          tooltip: 'Dedo',
                          active: controller.fingerDrawingEnabled,
                          onTap: () => controller.setFingerDrawing(
                            !controller.fingerDrawingEnabled,
                          ),
                        ),
                      ],
                      // ---- Regla y lupa ----
                      _ToggleIcon(
                        icon: Icons.straighten,
                        tooltip: 'Regla',
                        active: controller.rulerEnabled,
                        onTap: controller.toggleRuler,
                      ),
                      _ToggleIcon(
                        icon: Icons.search,
                        tooltip: 'Lupa',
                        active: controller.magnifierEnabled,
                        onTap: controller.toggleMagnifier,
                      ),

                      // ---- Opciones de trazo ----
                      if (!isEraser && !isSelect && controller.tool != ToolType.lasso)
                        _ActionIcon(
                          icon: Icons.tune,
                          tooltip: 'Opciones de trazo',
                          color: Colors.black45,
                          onTap: onStrokeOptions ?? () {},
                        ),
                    ],
                  ),

                  // ---- Slider de tamaño (segunda fila) ----
                  if (!isSelect)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            isEraser ? Icons.cleaning_services : Icons.circle,
                            size: 14,
                            color: Colors.black38,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),              activeTrackColor: kAccentColor,
                inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                thumbColor: kAccentColor,
                overlayColor: kAccentColor.withAlpha(30),
                              ),
                              child: Slider(
                                value: controller.toolSize,
                                min: range.$1,
                                max: range.$2,
                                onChanged: controller.setToolSize,
                              ),
                            ),
                          ),
                          Icon(
                            isEraser ? Icons.cleaning_services : Icons.circle,
                            size: 22,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? kAccentColor : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CustomColorSwatch extends StatelessWidget {
  final CanvasController controller;

  const _CustomColorSwatch({required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCustomColorDialog(context, controller),
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
        ),
        child: const Icon(Icons.add, size: 18, color: Colors.white),
      ),
    );
  }
}

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
        title: const Text('Color personalizado'),
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
                      const Text('Actual',
                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: previousColor,
                          border: Border.all(color: Colors.black26, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.black38),
                  ),
                  // Color nuevo
                  Column(
                    children: [
                      const Text('Nuevo',
                          style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hsv.toColor(),
                          border: Border.all(color: Colors.black26, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Campo hex
                  Expanded(
                    child: TextField(
                      controller: hexController,
                      decoration: InputDecoration(
                        labelText: 'Hex',
                        hintText: '#FF0000',
                        prefixIcon: const Icon(Icons.tag, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 12),

              // ---- Toggle: Rueda / Sliders ----
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.circle,
                        label: 'Rueda',
                        selected: mode == 0,
                        onTap: () => setState(() => mode = 0),
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        icon: Icons.tune,
                        label: 'Sliders',
                        selected: mode == 1,
                        onTap: () => setState(() => mode = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

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
                      label: 'Matiz',
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
                    const SizedBox(height: 4),
                    _HsvSliderWithGradient(
                      label: 'Saturación',
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
                    const SizedBox(height: 4),
                    _HsvSliderWithGradient(
                      label: 'Brillo',
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, hsv.toColor()),
            child: const Text('Usar'),
          ),
        ],
      ),
    ),
  );
  if (result != null) controller.setColor(result);
}

/// Slider de color con gradiente visual y etiqueta de valor.
///
/// Muestra un gradiente de fondo que refleja el efecto del slider
/// (arcoíris para matiz, gris→puro para saturación, negro→color para brillo).
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
        // Etiqueta + valor
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Slider con gradiente de fondo
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 16,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 2,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            overlayColor: Colors.black12,
            inactiveTrackColor: Colors.transparent,
            activeTrackColor: Colors.transparent,
            thumbColor: Colors.white,
          ),
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: gradient,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón de modo en el selector de color (Rueda / Sliders).
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kAccentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono de acción simple en la bottom bar.
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDark && color == Colors.black45 ? Colors.white54 : color;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: effectiveColor),
        ),
      ),
    );
  }
}

/// Icono toggle (activar/desactivar) en la bottom bar.
class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? kAccentDark : kAccentLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? kAccentColor : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      ),
    );
  }
}
