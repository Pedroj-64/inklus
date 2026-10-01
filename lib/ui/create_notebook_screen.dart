// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'theme/inklus_colors.dart';

import '../constants.dart';
import '../models/template.dart';
import '../services/image_service.dart';
import '../services/pdf_import_service.dart';
import 'widgets/dialogs.dart';
import 'widgets/notebook_covers.dart';
import '../l10n/l10n.dart';

/// Resultado de la pantalla de creación de cuaderno.
class CreateNotebookResult {
  final String name;
  final PageTemplate template;
  final CoverStyle coverStyle;
  final int? coverColorValue;
  final String? coverImagePath;

  /// Páginas de fondo (PDF o imágenes) para crear el cuaderno ya con ellas.
  final List<({String path, int width, int height})> backgrounds;

  const CreateNotebookResult({
    required this.name,
    required this.template,
    required this.coverStyle,
    this.coverColorValue,
    this.coverImagePath,
    this.backgrounds = const [],
  });
}

/// Pantalla completa para crear un cuaderno nuevo.
///
/// Wizard de 2 pasos:
/// - **Paso 1**: Nombre + portada (estilo + color con preview en vivo)
/// - **Paso 2**: Plantilla (4 favoritas visibles + "Ver más" para expandir)
class CreateNotebookScreen extends StatefulWidget {
  final int notebookCount;

  const CreateNotebookScreen({super.key, required this.notebookCount});

  @override
  State<CreateNotebookScreen> createState() => _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends State<CreateNotebookScreen> {
  late TextEditingController _nameController;
  int _currentStep = 0; // 0 = nombre+portada, 1 = plantilla
  CoverStyle _coverStyle = CoverStyle.simple;
  int? _coverColorValue;
  String? _coverImagePath;
  TemplateType _templateType = TemplateType.blank;
  bool _infinite = true;
  bool _showAllTemplates = false;
  List<({String path, int width, int height})> _backgrounds = [];
  String? _backgroundsName;
  final double _spacing = 52;

  // Colores de portada disponibles
  // (la misma paleta que el resto de la app, sin "Sin color")
  static final _coverColors = kCoverColors.skip(1).toList();

  /// Plantillas favoritas (las más usadas, se muestran primero).
  static const _favoriteTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.blank, Icons.crop_free, ''),
    (TemplateType.ruled, Icons.subject, ''),
    (TemplateType.grid, Icons.grid_on, ''),
    (TemplateType.sheet, Icons.description, ''),
  ];

  /// Todas las plantillas disponibles.
  static const _allTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.blank, Icons.crop_free, ''),
    (TemplateType.ruled, Icons.subject, ''),
    (TemplateType.grid, Icons.grid_on, ''),
    (TemplateType.dots, Icons.grain, ''),
    (TemplateType.music, Icons.music_note, ''),
    (TemplateType.planner, Icons.view_week, ''),
    (TemplateType.habit, Icons.check_box_outlined, ''),
    (TemplateType.sheet, Icons.description, ''),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _coverColorValue = _coverColors[0].$2;
    _nameController.addListener(() => setState(() {}));
  }

  bool _nameInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized) {
      _nameInitialized = true;
      _nameController.text = context.l10n.createDefaultName(widget.notebookCount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _effectiveCoverColor =>
      _coverColorValue != null ? Color(_coverColorValue!) : context.colors.primary;

  PageTemplate get _selectedTemplate => PageTemplate(
        type: _templateType,
        spacing: _spacing,
        lineColorValue: _lineColor.toARGB32(),
        infiniteFill: _infinite,
      );

  Color get _lineColor => const Color(0xFF9DB6D9);

  bool get _showInfiniteToggle =>
      _templateType != TemplateType.blank &&
      _templateType != TemplateType.sheet;

  List<(TemplateType, IconData, String)> get _visibleTemplates =>
      _showAllTemplates ? _allTemplates : _favoriteTemplates;

  /// Elige una imagen del dispositivo como portada.
  Future<void> _pickCoverImage() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isNotEmpty && files.first.path != null && mounted) {
      setState(() {
        _coverStyle = CoverStyle.custom;
        _coverImagePath = files.first.path;
      });
    }
  }

  static String _tplLabel(BuildContext context, TemplateType t) => switch (t) {
        TemplateType.blank => context.l10n.createTplBlank,
        TemplateType.ruled => context.l10n.createTplRuled,
        TemplateType.grid => context.l10n.createTplGrid,
        TemplateType.dots => context.l10n.createTplDots,
        TemplateType.music => context.l10n.createTplMusic,
        TemplateType.planner => context.l10n.createTplPlanner,
        TemplateType.habit => context.l10n.createTplHabit,
        _ => context.l10n.createTplSheet,
      };

  void _nextStep() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _currentStep = 1);
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      CreateNotebookResult(
        name: name,
        template: _selectedTemplate,
        coverStyle: _coverStyle,
        coverColorValue: _coverColorValue,
        coverImagePath: _coverStyle == CoverStyle.custom ? _coverImagePath : null,
        backgrounds: _backgrounds,
      ),
    );
  }

  void _setBackgrounds(List<({String path, int width, int height})> pages, String name) {
    if (pages.isEmpty || !mounted) return;
    setState(() {
      _backgrounds = pages;
      _backgroundsName = name;
    });
  }

  /// Cuaderno a partir de un PDF: una página por hoja del PDF.
  Future<void> _pickPdf() async {
    if (!PdfImportService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.pdfUnsupported)));
      return;
    }
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = file?.path;
    if (path == null || !mounted) return;
    final l10n = context.l10n;
    final pages = await runWithLoading(context, () async => [
          await for (final p in PdfImportService.importPages(path))
            (path: p.path, width: p.widthPx, height: p.heightPx),
        ]);
    if (!mounted) return;
    if (pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pdfReadFailed)));
      return;
    }
    _setBackgrounds(pages, file!.name);
  }

  /// Cuaderno a partir de imágenes: una página por imagen.
  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
      // ignore: deprecated_member_use (multi-selección requiere allowMultiple)
      allowMultiple: true,
    );
    if (files.isEmpty || !mounted) return;
    final service = ImageService();
    final pages = await runWithLoading(context, () async {
      final list = <({String path, int width, int height})>[];
      for (final f in files) {
        if (f.path == null) continue;
        final local = await service.importToApp(f.path!);
        final img = await service.decode(local);
        list.add((path: local, width: img.width, height: img.height));
        img.dispose();
      }
      return list;
    });
    _setBackgrounds(pages, files.first.name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.createTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        // Indicador de progreso
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(currentStep: _currentStep),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final isNewChild = child.key == const ValueKey(1);
          return SlideTransition(
            position: Tween<Offset>(
              begin: isNewChild ? const Offset(0.3, 0) : const Offset(-0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _currentStep == 0
            ? _buildStep1(isDark)
            : _buildStep2(isDark),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // PASO 1: Nombre + Portada
  // ------------------------------------------------------------------------

  Widget _buildStep1(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Nombre ----
          Text(
            context.l10n.createName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.createNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: 28),

          // ---- Portada ----
          Text(
            context.l10n.createCover,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Preview de la portada
          Center(
            child: Container(
              width: 180,
              height: 252,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.inklus.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _coverStyle == CoverStyle.custom && _coverImagePath != null
                    ? Image.file(
                        File(_coverImagePath!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => CustomPaint(
                          painter: NotebookCoverPainter(
                            style: CoverStyle.simple,
                            color: _effectiveCoverColor,
                            isDark: isDark,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: NotebookCoverPainter(
                          style: _coverStyle,
                          color: _effectiveCoverColor,
                          isDark: isDark,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Diseños de portada (con su nombre) + "Tu imagen" bien visible.
          Text(
            context.l10n.createDesign,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final style in kPaintedCoverStyles)
                _CoverTile(
                  label: coverStyleName(context.l10n, style),
                  selected: style == _coverStyle,
                  onTap: () => setState(() => _coverStyle = style),
                  child: CustomPaint(
                    painter: NotebookCoverPainter(
                      style: style,
                      color: _effectiveCoverColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              _CoverTile(
                label: _coverImagePath == null ? context.l10n.createYourImage : context.l10n.createChangeImage,
                selected: _coverStyle == CoverStyle.custom && _coverImagePath != null,
                dashed: _coverImagePath == null,
                onTap: _pickCoverImage,
                child: _coverImagePath != null
                    ? Image.file(
                        File(_coverImagePath!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const _AddImagePlaceholder(),
                      )
                    : const _AddImagePlaceholder(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.createColor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Selector de color de portada
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _coverColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (_, colorValue) = _coverColors[index];
                final isSelected = colorValue == _coverColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _coverColorValue = colorValue),
                  child: Tooltip(
                    message: coverColorName(context.l10n, colorValue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(colorValue!),
                        border: Border.all(
                          color: isSelected ? Colors.white : context.colors.outline,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(colorValue).withAlpha(80),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),

          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _nameController.text.trim().isEmpty ? null : _nextStep,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.createNext,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // PASO 2: Plantilla
  // ------------------------------------------------------------------------

  Widget _buildStep2(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del paso 1
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                // Mini portada
                Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: NotebookCoverPainter(
                        style: _coverStyle,
                        color: _effectiveCoverColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.createStep2,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.createBackToStep1,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: _prevStep,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Empezar desde un archivo (PDF / imágenes) ----
          if (_backgrounds.isNotEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(_backgroundsName ?? ''),
                subtitle: Text(context.l10n.createFromFilePages(_backgrounds.length)),
                trailing: IconButton(
                  tooltip: context.l10n.createFromFileRemove,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _backgrounds = []),
                ),
              ),
            )
          else ...[
          // ---- Plantilla ----
            Text(
              context.l10n.createTemplate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
  
            // Grid de plantillas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (type, icon, label) in _visibleTemplates)
                  _templateTile(type, icon, label),
              ],
            ),
  
            // Botón ver más / ver menos
            if (!_showAllTemplates)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllTemplates = true),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(context.l10n.createMoreTemplates),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllTemplates = false),
                  icon: const Icon(Icons.expand_less, size: 18),
                  label: Text(context.l10n.createFewer),
                ),
              ),
  
            // Toggle infinito/finito para tipos que lo soportan
            if (_showInfiniteToggle) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  context.l10n.createInfinite,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _infinite
                      ? context.l10n.createInfiniteOn
                      : context.l10n.createInfiniteOff,
                  style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                ),
                value: _infinite,
                onChanged: (v) => setState(() => _infinite = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],

            const SizedBox(height: 24),
            Text(
              context.l10n.createFromFile,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.createFromFileHint,
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(context.l10n.createFromPdf),
                ),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(context.l10n.createFromImages),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Botón crear
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _create,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.createAction,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _templateTile(TemplateType type, IconData icon, String _) {
    final label = _tplLabel(context, type);
    final isSelected = _templateType == type;
    return GestureDetector(
      onTap: () => setState(() => _templateType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de progreso del wizard (pasos 1 y 2).
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 3,
            color: currentStep >= 1 ? context.colors.primary : context.colors.outlineVariant,
          ),
        ),
      ],
    );
  }
}

/// Miniatura de un diseño de portada con su nombre. Con [dashed] (la de
/// "Tu imagen" sin imagen aún) el borde es discontinuo para que se lea como
/// un botón de añadir.
class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.dashed = false,
  });

  final String label;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.createCoverSemantics(label),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 88,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                height: 118,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: dashed
                      ? CustomPaint(
                          foregroundPainter: _DashedBorderPainter(scheme.primary),
                          child: child,
                        )
                      : child,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddImagePlaceholder extends StatelessWidget {
  const _AddImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.colors.primaryContainer.withAlpha(110),
        child: Center(
          child: Icon(Icons.add_photo_alternate_outlined,
              size: 34, color: context.colors.primary),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(3), const Radius.circular(8));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
