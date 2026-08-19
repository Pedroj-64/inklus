import '../../constants.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../logic/canvas_controller.dart';
import '../../models/template.dart';
import '../../services/image_service.dart';
import '../../services/template_library_service.dart';
import '../../utils/theme_colors.dart';

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
  required TemplateLibraryService templateLibrary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _TemplateSheet(
      controller: controller,
      imageService: imageService,
      templateLibrary: templateLibrary,
    ),
  );
}

class _TemplateSheet extends StatefulWidget {
  final CanvasController controller;
  final ImageService imageService;
  final TemplateLibraryService templateLibrary;

  const _TemplateSheet({
    required this.controller,
    required this.imageService,
    required this.templateLibrary,
  });

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  late double _spacing;
  late Color _lineColor;
  late double _sheetWidth;
  late double _sheetHeight;
  late bool _infiniteFill;

  @override
  void initState() {
    super.initState();
    final t = widget.controller.page.template;
    _spacing = t.spacing;
    _lineColor = t.lineColor;
    _sheetWidth = t.customWidth ?? PageTemplate.sheetWidth;
    _sheetHeight = t.customHeight ?? PageTemplate.sheetHeight;
    _infiniteFill = t.infiniteFill;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.page.template;
    final hasLines =
        current.type == TemplateType.ruled || current.type == TemplateType.grid;
    final isFiniteSheet = current.isFinite;
    // B6: tipos que soportan toggle entre infinito y finito.
    // Todos los tipos excepto blank, sheet soportan toggle infinito/finito.
    final supportsInfiniteToggle = current.type != TemplateType.blank &&
        current.type != TemplateType.sheet;

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
            // Encabezado mejorado
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAccentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 20,
                    color: kAccentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plantillas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Infinitas se alargan al escribir',
                        style: TextStyle(fontSize: 12, color: ThemeColors.of(context).textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Sección: Plantillas infinitas ----
            _SectionLabel(label: 'Lienzo infinito'),
            const SizedBox(height: 8),

            // --- Tiles de plantillas infinitas ---
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TemplateTile(
                  icon: Icons.crop_free,
                  label: 'Blanco',
                  selected: current.type == TemplateType.blank,
                  onTap: () => _apply(const PageTemplate(type: TemplateType.blank)),
                ),
                _TemplateTile(
                  icon: Icons.subject,
                  label: 'Rayas',
                  selected: current.type == TemplateType.ruled,
                  onTap: () => _selectTemplate(TemplateType.ruled),
                ),
                _TemplateTile(
                  icon: Icons.grid_on,
                  label: 'Cuadrícula',
                  selected: current.type == TemplateType.grid,
                  onTap: () => _selectTemplate(TemplateType.grid),
                ),
                _TemplateTile(
                  icon: Icons.brush_outlined,
                  label: 'Puntos',
                  selected: current.type == TemplateType.dots,
                  onTap: () => _selectTemplate(TemplateType.dots),
                ),
                _TemplateTile(
                  icon: Icons.music_note,
                  label: 'Pentagrama',
                  selected: current.type == TemplateType.music,
                  onTap: () => _selectTemplate(TemplateType.music),
                ),
                _TemplateTile(
                  icon: Icons.view_week,
                  label: 'Agenda',
                  selected: current.type == TemplateType.planner,
                  onTap: () => _selectTemplate(TemplateType.planner),
                ),
                _TemplateTile(
                  icon: Icons.check_box_outlined,
                  label: 'Hábitos',
                  selected: current.type == TemplateType.habit,
                  onTap: () => _selectTemplate(TemplateType.habit),
                ),
              ],
            ),

            // --- Sección: Hoja fija ---
            const SizedBox(height: 16),
            _SectionLabel(label: 'Hoja fija'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
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
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Plantilla propia',
                  selected: current.type == TemplateType.custom,
                  onTap: _pickCustomTemplate,
                ),
              ],
            ),

            // --- Mis plantillas guardadas ---
            if (widget.templateLibrary.entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Mis plantillas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saveCurrentAsTemplate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Guardar actual'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.templateLibrary.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final entry = widget.templateLibrary.entries[i];
                    final isCurrent = current.type == TemplateType.custom &&
                        current.imagePath == entry.imagePath;
                    return _SavedTemplateTile(
                      entry: entry,
                      selected: isCurrent,
                      onTap: () {
                        final tpl = entry.toPageTemplate();
                        _apply(tpl);
                      },
                      onDelete: () => _deleteTemplate(entry.id),
                    );
                  },
                ),
              ),
            ],

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
                  Text(
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
                        border: Border.all(color: ThemeColors.of(context).border),
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

            // B6: Toggle Lienzo infinito (para plantillas que lo soportan)
            if (supportsInfiniteToggle) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Lienzo infinito',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _infiniteFill
                      ? 'El lienzo se alarga al escribir'
                      : 'Hoja de tamaño fijo',
                  style: const TextStyle(fontSize: 11),
                ),
                value: _infiniteFill,
                onChanged: (v) {
                  setState(() => _infiniteFill = v);
                  _applyCurrent();
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
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

  /// Selecciona un tipo de plantilla y aplica el valor actual de _infiniteFill.
  void _selectTemplate(TemplateType type) {
    _apply(PageTemplate(
      type: type,
      spacing: _spacing,
      lineColorValue: _lineColor.toARGB32(),
      infiniteFill: _infiniteFill,
    ));
  }

  /// Aplica la plantilla actual con los valores de personalización sin cerrar.
  void _applyCurrent() {
    final t = widget.controller.page.template;
    widget.controller.setTemplate(t.copyWith(
      spacing: _spacing,
      lineColorValue: _lineColor.toARGB32(),
      infiniteFill: _infiniteFill,
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
                  color: kDefaultStrokeColor,
                  selected: _lineColor.toARGB32() == kDefaultStrokeColor.toARGB32(),
                  onTap: () => _setLineColor(kDefaultStrokeColor),
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

  /// Guarda la plantilla actual como template propio reutilizable.
  Future<void> _saveCurrentAsTemplate() async {
    final t = widget.controller.page.template;
    if (t.type != TemplateType.custom || t.imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden guardar plantillas con imagen')),
      );
      return;
    }
    final nameController = TextEditingController(
      text: 'Mi plantilla',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar plantilla'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      await widget.templateLibrary.save(
        name: name.trim(),
        sourceImagePath: t.imagePath!,
        infiniteFill: t.infiniteFill,
        customWidth: t.customWidth,
        customHeight: t.customHeight,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  /// Elimina una plantilla guardada.
  Future<void> _deleteTemplate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: const Text('¿Eliminar esta plantilla guardada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.templateLibrary.delete(id);
    if (mounted) setState(() {});
  }
}

/// Tile de tipo de plantilla (estilo profesional con preview visual).
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 108,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEBF0FF) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kAccentColor : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kAccentColor.withAlpha(30),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? kAccentColor.withAlpha(20)
                    : Colors.grey.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? kAccentColor : ThemeColors.of(context).textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? kAccentColor : ThemeColors.of(context).textSecondary,
              ),
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
            color: showBorder || selected ? ThemeColors.of(context).border : Colors.transparent,
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
            color: isActive ? kAccentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? kAccentColor : ThemeColors.of(context).textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Tile de plantilla guardada en la biblioteca.
class _SavedTemplateTile extends StatelessWidget {
  final CustomTemplateEntry entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedTemplateTile({
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3EDFF) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kAccentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.file(
                  File(entry.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.broken_image,
                    color: ThemeColors.of(context).border,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                entry.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? kAccentColor : ThemeColors.of(context).textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de sección en el picker de plantillas.
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }
}
