// SPDX-License-Identifier: GPL-3.0-or-later
import '../../constants.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/inklus_colors.dart';

import '../../logic/canvas_controller.dart';
import '../../models/template.dart';
import '../../services/image_service.dart';
import '../../services/template_library_service.dart';
import '../../services/marketplace/marketplace_service.dart';
import '../../l10n/l10n.dart';
import '../theme/tokens.dart';
import 'dialogs.dart';
import 'page_scaffold.dart';

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
    // Por defecto se conserva el modo de la página actual: si era infinita
    // (p. ej. en blanco), la plantilla elegida también lo será.
    _infiniteFill = !t.isFinite;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.page.template;
    final hasLines =
        current.type == TemplateType.ruled || current.type == TemplateType.grid;
    final isFiniteSheet = current.isFinite;
    // B6: tipos que soportan toggle entre infinito y finito.
    // Todos los tipos excepto blank, sheet soportan toggle infinito/finito.
    final supportsInfiniteToggle =
        PageTemplate.supportsInfiniteToggle(current.type);

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              icon: Icons.dashboard_customize_outlined,
              title: context.l10n.marketTemplates,
              subtitle: context.l10n.tplInfiniteHint,
            ),

            // ---- Sección: Plantillas infinitas ----
            _SectionLabel(label: context.l10n.createInfinite),
            const SizedBox(height: Spacing.sm),

            // --- Tiles de plantillas infinitas ---
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TemplateTile(
                  icon: Icons.crop_free,
                  label: context.l10n.createTplBlank,
                  selected: current.type == TemplateType.blank,
                  onTap: () => _apply(const PageTemplate(type: TemplateType.blank)),
                ),
                _TemplateTile(
                  icon: Icons.subject,
                  label: context.l10n.createTplRuled,
                  selected: current.type == TemplateType.ruled,
                  onTap: () => _selectTemplate(TemplateType.ruled),
                ),
                _TemplateTile(
                  icon: Icons.grid_on,
                  label: context.l10n.createTplGrid,
                  selected: current.type == TemplateType.grid,
                  onTap: () => _selectTemplate(TemplateType.grid),
                ),
                _TemplateTile(
                  icon: Icons.brush_outlined,
                  label: context.l10n.createTplDots,
                  selected: current.type == TemplateType.dots,
                  onTap: () => _selectTemplate(TemplateType.dots),
                ),
                _TemplateTile(
                  icon: Icons.music_note,
                  label: context.l10n.createTplMusic,
                  selected: current.type == TemplateType.music,
                  onTap: () => _selectTemplate(TemplateType.music),
                ),
                _TemplateTile(
                  icon: Icons.view_week,
                  label: context.l10n.createTplPlanner,
                  selected: current.type == TemplateType.planner,
                  onTap: () => _selectTemplate(TemplateType.planner),
                ),
                _TemplateTile(
                  icon: Icons.check_box_outlined,
                  label: context.l10n.createTplHabit,
                  selected: current.type == TemplateType.habit,
                  onTap: () => _selectTemplate(TemplateType.habit),
                ),
                _TemplateTile(
                  icon: Icons.straighten,
                  label: context.l10n.createTplMillimeter,
                  selected: current.type == TemplateType.millimeter,
                  onTap: () => _selectTemplate(TemplateType.millimeter),
                ),
              ],
            ),

            // --- Sección: Hoja fija ---
            const SizedBox(height: Spacing.lg),
            _SectionLabel(label: context.l10n.noteTplSheet),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TemplateTile(
                  icon: Icons.description_outlined,
                  label: context.l10n.tplNormalSheet,
                  selected: current.type == TemplateType.sheet,
                  onTap: () => _apply(PageTemplate(
                    type: TemplateType.sheet,
                    lineColorValue: _lineColor.toARGB32(),
                  )),
                ),
                for (final (type, icon, label) in [
                  (TemplateType.cornell, Icons.vertical_split, context.l10n.createTplCornell),
                  (TemplateType.weekly, Icons.calendar_view_week, context.l10n.createTplWeekly),
                  (TemplateType.monthly, Icons.calendar_month, context.l10n.createTplMonthly),
                  (TemplateType.todo, Icons.checklist_rtl, context.l10n.createTplTodo),
                  (TemplateType.storyboard, Icons.movie_creation_outlined, context.l10n.createTplStoryboard),
                ])
                  _TemplateTile(
                    icon: icon,
                    label: label,
                    selected: current.type == type,
                    onTap: () => _apply(PageTemplate(
                      type: type,
                      lineColorValue: _lineColor.toARGB32(),
                    )),
                  ),
                _TemplateTile(
                  icon: Icons.add_photo_alternate_outlined,
                  label: context.l10n.tplOwn,
                  selected: current.type == TemplateType.custom,
                  onTap: _pickCustomTemplate,
                ),
              ],
            ),

            // --- Plantillas instaladas desde el marketplace ---
            FutureBuilder<List<({String name, PageTemplate template})>>(
              future: MarketplaceService.instance.installedTemplates(),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Spacing.lg),
                    _SectionLabel(label: context.l10n.tplFromMarket),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in list)
                          ActionChip(
                            avatar: const Icon(Icons.storefront_outlined, size: 18),
                            label: Text(t.name),
                            onPressed: () => _apply(t.template),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),

            // --- Mis plantillas guardadas ---
            if (widget.templateLibrary.entries.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Text(
                    context.l10n.tplMine,
                    style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saveCurrentAsTemplate,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.tplSaveCurrent),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.templateLibrary.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
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
              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.sm),
              Text(
                context.l10n.tplCustomize,
                style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],

            // Color de línea (para rayas, cuadrícula y hoja normal)
            if (hasLines || current.type == TemplateType.sheet ||
                kStructuredTemplates.contains(current.type)) ...[
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Text(
                    context.l10n.tplLineColor,
                    style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        border: Border.all(color: context.colors.outline),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Separación (rayas / cuadrícula)
            if (hasLines) ...[
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Text(
                    context.l10n.tplSpacing,
                    style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
                      style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],

            // B6: Toggle Lienzo infinito (para plantillas que lo soportan)
            if (supportsInfiniteToggle) ...[
              const SizedBox(height: Spacing.sm),
              SwitchListTile(
                title: Text(
                  context.l10n.createInfinite,
                  style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _infiniteFill
                      ? context.l10n.createInfiniteOn
                      : context.l10n.tplFixedSheet,
                  style: context.text.labelSmall?.copyWith(),
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
              const SizedBox(height: Spacing.sm),
              Text(
                context.l10n.tplSheetSize,
                style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Spacing.xs),
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
                  const SizedBox(width: Spacing.sm),
                  _SizePreset(
                    label: context.l10n.tplLetter,
                    width: 1275,
                    height: 1650,
                    isActive: _sheetWidth == 1275 && _sheetHeight == 1650,
                    onTap: () => _applySheetSize(1275, 1650),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _SizePreset(
                    label: 'B5',
                    width: 1031,
                    height: 1457,
                    isActive: _sheetWidth == 1031 && _sheetHeight == 1457,
                    onTap: () => _applySheetSize(1031, 1457),
                  ),
                  const SizedBox(width: Spacing.sm),
                  _SizePreset(
                    label: context.l10n.tplHalfLetter,
                    width: 638,
                    height: 986,
                    isActive: _sheetWidth == 638 && _sheetHeight == 986,
                    onTap: () => _applySheetSize(638, 986),
                  ),
                ],
              ),
            ],

            const SizedBox(height: Spacing.sm),
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
      // Tipos sin interruptor: blank/music/habit siempre infinitos.
      infiniteFill: PageTemplate.supportsInfiniteToggle(type)
          ? _infiniteFill
          : type != TemplateType.sheet,
      customWidth: type == TemplateType.sheet || !_infiniteFill ? _sheetWidth : null,
      customHeight: type == TemplateType.sheet || !_infiniteFill ? _sheetHeight : null,
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
            SheetHeader(icon: Icons.palette_outlined, title: context.l10n.tplLineColor),
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
            const SizedBox(height: Spacing.lg),
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
          title: Text(context.l10n.tplHowTitle),
          content: Text(
            context.l10n.tplHowBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'sheet'),
              child: Text(context.l10n.tplAsSheet),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'fill'),
              child: Text(context.l10n.tplAsFill),
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
        showSnack(context, context.l10n.tplImageLoadFailed('$e'));
      }
    }
  }

  /// Guarda la plantilla actual como template propio reutilizable.
  Future<void> _saveCurrentAsTemplate() async {
    final t = widget.controller.page.template;
    if (t.type != TemplateType.custom || t.imagePath == null) {
      showSnack(context, context.l10n.tplOnlyImage);
      return;
    }
    final name = await showTextPrompt(
      context,
      title: context.l10n.tplSaveTitle,
      hint: context.l10n.createName,
      initialValue: context.l10n.tplDefaultName,
      confirmLabel: context.l10n.commonSave,
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
        showSnack(context, context.l10n.tplSaved);
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, context.l10n.tplSaveFailed('$e'));
      }
    }
  }

  /// Elimina una plantilla guardada.
  Future<void> _deleteTemplate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tplDeleteTitle),
        content: Text(context.l10n.tplDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.libDelete),
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
          color: selected ? context.colors.secondaryContainer : context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withAlpha(30),
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
                    ? context.colors.primary.withAlpha(20)
                    : context.colors.surfaceContainerHighest,
                borderRadius: Radii.mdAll,
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.labelSmall?.copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? context.colors.primary : context.colors.onSurfaceVariant),
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
            color: showBorder || selected ? context.colors.outline : Colors.transparent,
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
      borderRadius: Radii.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          color: isActive ? context.colors.secondaryContainer : context.colors.surfaceContainerHighest,
          borderRadius: Radii.smAll,
          border: Border.all(
            color: isActive ? context.colors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: context.text.labelSmall?.copyWith(fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? context.colors.primary : context.colors.onSurfaceVariant),
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
          color: selected ? context.colors.secondaryContainer : context.colors.surfaceContainerHighest,
          borderRadius: Radii.mdAll,
          border: Border.all(
            color: selected ? context.colors.primary : Colors.transparent,
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
                    color: context.colors.outline,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text(
                entry.name,
                style: context.text.labelSmall?.copyWith(fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? context.colors.primary : context.colors.onSurfaceVariant),
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
      style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurfaceVariant),
    );
  }
}
