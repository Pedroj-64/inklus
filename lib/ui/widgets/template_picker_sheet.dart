import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/template.dart';
import '../../services/image_service.dart';

/// Selector de plantillas de la página actual.
///
/// Muestra las plantillas integradas y permite subir una imagen del
/// dispositivo para usarla como plantilla propia, con dos modos:
/// - Hoja fija: la imagen actúa como una hoja de tamaño fijo.
/// - Relleno infinito: la imagen se repite y el lienzo se alarga al escribir.
///
/// Incluye controles para personalizar el color de las líneas, la separación
/// y el tamaño de la hoja (para plantillas finitas).
Future<void> showTemplatePicker(
  BuildContext context, {
  required CanvasController controller,
  required ImageService imageService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _TemplateSheet(
      controller: controller,
      imageService: imageService,
    ),
  );
}

class _TemplateSheet extends StatefulWidget {
  final CanvasController controller;
  final ImageService imageService;

  const _TemplateSheet({
    required this.controller,
    required this.imageService,
  });

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  late double _spacing;
  late Color _lineColor;
  late double _sheetWidth;
  late double _sheetHeight;

  @override
  void initState() {
    super.initState();
    final t = widget.controller.page.template;
    _spacing = t.spacing;
    _lineColor = t.lineColor;
    _sheetWidth = t.customWidth ?? PageTemplate.sheetWidth;
    _sheetHeight = t.customHeight ?? PageTemplate.sheetHeight;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.page.template;
    final hasLines =
        current.type == TemplateType.ruled || current.type == TemplateType.grid;
    final isFiniteSheet = current.type == TemplateType.sheet ||
        (current.type == TemplateType.custom && !current.infiniteFill);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plantillas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige el fondo de la página. Las plantillas infinitas se alargan conforme escribes.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // --- Tiles de tipo de plantilla ---
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TemplateTile(
                  icon: Icons.crop_free,
                  label: 'Lienzo infinito',
                  selected: current.type == TemplateType.blank,
                  onTap: () => _apply(const PageTemplate(type: TemplateType.blank)),
                ),
                _TemplateTile(
                  icon: Icons.description_outlined,
                  label: 'Hoja normal',
                  selected: current.type == TemplateType.sheet,
                  onTap: () => _apply(PageTemplate(
                    type: TemplateType.sheet,
                    lineColorValue: _lineColor.toARGB32(),
                  )),
                ),
                _TemplateTile(
                  icon: Icons.subject,
                  label: 'Rayas',
                  selected: current.type == TemplateType.ruled,
                  onTap: () => _apply(PageTemplate(
                    type: TemplateType.ruled,
                    spacing: _spacing,
                    lineColorValue: _lineColor.toARGB32(),
                  )),
                ),
                _TemplateTile(
                  icon: Icons.grid_on,
                  label: 'Cuadrícula',
                  selected: current.type == TemplateType.grid,
                  onTap: () => _apply(PageTemplate(
                    type: TemplateType.grid,
                    spacing: _spacing,
                    lineColorValue: _lineColor.toARGB32(),
                  )),
                ),
                _TemplateTile(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Plantilla propia',
                  selected: current.type == TemplateType.custom,
                  onTap: _pickCustomTemplate,
                ),
              ],
            ),

            // --- Opciones de personalización ---
            if (hasLines || isFiniteSheet) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Personalizar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],

            // Color de línea (para rayas, cuadrícula y hoja normal)
            if (hasLines || current.type == TemplateType.sheet) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Color de línea',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickLineColor,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _lineColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Separación (rayas / cuadrícula)
            if (hasLines) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Separación',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: _spacing,
                      min: 30,
                      max: 96,
                      divisions: 11,
                      label: _spacing.round().toString(),
                      onChanged: (v) {
                        setState(() => _spacing = v);
                        _applyCurrent();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_spacing.round()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],

            // Tamaño de hoja (para hoja normal)
            if (isFiniteSheet && current.type != TemplateType.custom) ...[
              const SizedBox(height: 8),
              const Text(
                'Tamaño de hoja',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Presets de tamaño
                  _SizePreset(
                    label: 'A4',
                    width: 1191,
                    height: 1684,
                    isActive: _sheetWidth == 1191 && _sheetHeight == 1684,
                    onTap: () => _applySheetSize(1191, 1684),
                  ),
                  const SizedBox(width: 8),
                  _SizePreset(
                    label: 'Carta',
                    width: 1275,
                    height: 1650,
                    isActive: _sheetWidth == 1275 && _sheetHeight == 1650,
                    onTap: () => _applySheetSize(1275, 1650),
                  ),
                  const SizedBox(width: 8),
                  _SizePreset(
                    label: 'Letter',
                    width: 1275,
                    height: 1650,
                    isActive: false,
                    onTap: () => _applySheetSize(1275, 1650),
                  ),
                  const SizedBox(width: 8),
                  _SizePreset(
                    label: 'B5',
                    width: 1031,
                    height: 1457,
                    isActive: _sheetWidth == 1031 && _sheetHeight == 1457,
                    onTap: () => _applySheetSize(1031, 1457),
                  ),
                  const SizedBox(width: 8),
                  _SizePreset(
                    label: 'Half Ltr',
                    width: 638,
                    height: 986,
                    isActive: _sheetWidth == 638 && _sheetHeight == 986,
                    onTap: () => _applySheetSize(638, 986),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _apply(PageTemplate template) {
    widget.controller.setTemplate(template);
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fitView(widget.controller.viewportSize);
    });
  }

  /// Aplica la plantilla actual con los valores de personalización sin cerrar.
  void _applyCurrent() {
    final t = widget.controller.page.template;
    widget.controller.setTemplate(t.copyWith(
      spacing: _spacing,
      lineColorValue: _lineColor.toARGB32(),
    ));
  }

  void _applySheetSize(double w, double h) {
    setState(() {
      _sheetWidth = w;
      _sheetHeight = h;
    });
    final t = widget.controller.page.template;
    widget.controller.setTemplate(t.copyWith(
      customWidth: w,
      customHeight: h,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fitView(widget.controller.viewportSize);
    });
  }

  /// Selector de color de línea con preset de colores comunes.
  void _pickLineColor() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Color de línea',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _ColorDot(
                  color: const Color(0xFF9DB6D9),
                  selected: _lineColor.toARGB32() == 0xFF9DB6D9,
                  onTap: () => _setLineColor(const Color(0xFF9DB6D9)),
                ),
                _ColorDot(
                  color: const Color(0xFF88B4E8),
                  selected: _lineColor.toARGB32() == 0xFF88B4E8,
                  onTap: () => _setLineColor(const Color(0xFF88B4E8)),
                ),
                _ColorDot(
                  color: const Color(0xFF81C784),
                  selected: _lineColor.toARGB32() == 0xFF81C784,
                  onTap: () => _setLineColor(const Color(0xFF81C784)),
                ),
                _ColorDot(
                  color: const Color(0xFFE8A0A0),
                  selected: _lineColor.toARGB32() == 0xFFE8A0A0,
                  onTap: () => _setLineColor(const Color(0xFFE8A0A0)),
                ),
                _ColorDot(
                  color: const Color(0xFFCE93D8),
                  selected: _lineColor.toARGB32() == 0xFFCE93D8,
                  onTap: () => _setLineColor(const Color(0xFFCE93D8)),
                ),
                _ColorDot(
                  color: const Color(0xFFFFCC80),
                  selected: _lineColor.toARGB32() == 0xFFFFCC80,
                  onTap: () => _setLineColor(const Color(0xFFFFCC80)),
                ),
                _ColorDot(
                  color: const Color(0xFFB0BEC5),
                  selected: _lineColor.toARGB32() == 0xFFB0BEC5,
                  onTap: () => _setLineColor(const Color(0xFFB0BEC5)),
                ),
                _ColorDot(
                  color: const Color(0xFF424242),
                  selected: _lineColor.toARGB32() == 0xFF424242,
                  onTap: () => _setLineColor(const Color(0xFF424242)),
                ),
                _ColorDot(
                  color: const Color(0xFF1A1A1A),
                  selected: _lineColor.toARGB32() == 0xFF1A1A1A,
                  onTap: () => _setLineColor(const Color(0xFF1A1A1A)),
                ),
                _ColorDot(
                  color: const Color(0xFFFFFFFF),
                  selected: _lineColor.toARGB32() == 0xFFFFFFFF,
                  onTap: () => _setLineColor(const Color(0xFFFFFFFF)),
                  showBorder: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _setLineColor(Color color) {
    setState(() => _lineColor = color);
    _applyCurrent();
    Navigator.pop(context);
  }

  /// Sube una imagen del dispositivo como plantilla propia.
  Future<void> _pickCustomTemplate() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file?.path;
      if (path == null) return;

      final localPath = await widget.imageService.importToApp(path);
      final img = await widget.imageService.decode(localPath);
      widget.imageService.cache[localPath] = img;
      final w = img.width.toDouble();
      final h = img.height.toDouble();

      if (!mounted) return;
      final mode = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Cómo usar la plantilla?'),
          content: const Text(
            'La imagen se usará como fondo para escribir encima.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'sheet'),
              child: const Text('Como hoja fija'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'fill'),
              child: const Text('Relleno infinito'),
            ),
          ],
        ),
      );
      if (mode == null || !mounted) return;

      _apply(
        PageTemplate(
          type: TemplateType.custom,
          imagePath: localPath,
          infiniteFill: mode == 'fill',
          customWidth: w,
          customHeight: h,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar la imagen: $e')),
        );
      }
    }
  }
}

/// Tile de tipo de plantilla.
class _TemplateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3EDFF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 30,
                color: selected ? const Color(0xFF3B82F6) : Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot de color para el selector de color de línea.
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool showBorder;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: showBorder || selected ? Colors.black26 : Colors.transparent,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withAlpha(60),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Botón de preset de tamaño de hoja.
class _SizePreset extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final bool isActive;
  final VoidCallback onTap;

  const _SizePreset({
    required this.label,
    required this.width,
    required this.height,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3EDFF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF3B82F6) : Colors.black54,
          ),
        ),
      ),
    );
  }
}
