// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/template.dart';
import '../utils/theme_colors.dart';
import 'widgets/notebook_covers.dart';

/// Resultado de la pantalla de creación de cuaderno.
class CreateNotebookResult {
  final String name;
  final PageTemplate template;
  final CoverStyle coverStyle;
  final int? coverColorValue;
  final String? coverImagePath;

  const CreateNotebookResult({
    required this.name,
    required this.template,
    required this.coverStyle,
    this.coverColorValue,
    this.coverImagePath,
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
  final double _spacing = 52;

  // Colores de portada disponibles
  static const _coverColors = <(String, int?)>[
    ('Azul', 0xFF3B82F6),
    ('Verde', 0xFF4CAF50),
    ('Rojo', 0xFFE53935),
    ('Naranja', 0xFFFF9800),
    ('Morado', 0xFF9C27B0),
    ('Rosa', 0xFFEC407A),
    ('Turquesa', 0xFF26C6DA),
    ('Gris', 0xFF78909C),
  ];

  /// Plantillas favoritas (las más usadas, se muestran primero).
  static const _favoriteTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.blank, Icons.crop_free, 'Blanco'),
    (TemplateType.ruled, Icons.subject, 'Rayas'),
    (TemplateType.grid, Icons.grid_on, 'Cuadrícula'),
    (TemplateType.sheet, Icons.description, 'Hoja A4'),
  ];

  /// Todas las plantillas disponibles.
  static const _allTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.blank, Icons.crop_free, 'Blanco'),
    (TemplateType.ruled, Icons.subject, 'Rayas'),
    (TemplateType.grid, Icons.grid_on, 'Cuadrícula'),
    (TemplateType.dots, Icons.grain, 'Puntos'),
    (TemplateType.music, Icons.music_note, 'Pentagrama'),
    (TemplateType.planner, Icons.view_week, 'Agenda'),
    (TemplateType.habit, Icons.check_box_outlined, 'Hábitos'),
    (TemplateType.sheet, Icons.description, 'Hoja A4'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Cuaderno ${widget.notebookCount}');
    _coverColorValue = _coverColors[0].$2;
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _effectiveCoverColor =>
      _coverColorValue != null ? Color(_coverColorValue!) : kAccentColor;

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo cuaderno',
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
            ? _buildStep1(tc, isDark)
            : _buildStep2(tc, isDark),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // PASO 1: Nombre + Portada
  // ------------------------------------------------------------------------

  Widget _buildStep1(ThemeColors tc, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Nombre ----
          Text(
            'Nombre',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Mi cuaderno',
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
            'Portada',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.textSecondary,
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
                    color: Colors.black.withAlpha(isDark ? 60 : 25),
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

          // Selector de estilo de portada
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CoverStyle.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final style = CoverStyle.values[index];
                final isSelected = style == _coverStyle;
                return GestureDetector(
                  onTap: () async {
                    if (style == CoverStyle.custom) {
                      // Seleccionar imagen del dispositivo.
                      final files = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      if (files.isNotEmpty && files.first.path != null) {
                        setState(() {
                          _coverStyle = style;
                          _coverImagePath = files.first.path;
                        });
                      }
                    } else {
                      setState(() => _coverStyle = style);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? kAccentColor : tc.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: style == CoverStyle.custom && _coverImagePath != null
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
                                style: style,
                                color: _effectiveCoverColor,
                                isDark: isDark,
                              ),
                            ),
                            ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Selector de color de portada
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _coverColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (name, colorValue) = _coverColors[index];
                final isSelected = colorValue == _coverColorValue;
                return GestureDetector(
                  onTap: () => setState(() => _coverColorValue = colorValue),
                  child: Tooltip(
                    message: name,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(colorValue!),
                        border: Border.all(
                          color: isSelected ? Colors.white : tc.border,
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Siguiente',
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

  Widget _buildStep2(ThemeColors tc, bool isDark) {
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
              color: kAccentColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kAccentColor.withAlpha(40)),
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
                        'Paso 2: Elige una plantilla',
                        style: TextStyle(
                          fontSize: 12,
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Volver al paso 1',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: _prevStep,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Plantilla ----
          Text(
            'Plantilla',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tc.textSecondary,
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
                label: const Text('Ver más plantillas'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllTemplates = false),
                icon: const Icon(Icons.expand_less, size: 18),
                label: const Text('Ver menos'),
              ),
            ),

          // Toggle infinito/finito para tipos que lo soportan
          if (_showInfiniteToggle) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Lienzo infinito',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _infinite
                    ? 'El lienzo se alarga al escribir'
                    : 'Hoja de tamaño fijo (A4)',
                style: TextStyle(fontSize: 12, color: tc.textSecondary),
              ),
              value: _infinite,
              onChanged: (v) => setState(() => _infinite = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
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
              child: const Text(
                'Crear cuaderno',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _templateTile(TemplateType type, IconData icon, String label) {
    final isSelected = _templateType == type;
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: () => setState(() => _templateType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kAccentColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kAccentColor : tc.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? kAccentColor : tc.iconSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? kAccentColor : tc.textSecondary,
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
            color: kAccentColor,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 3,
            color: currentStep >= 1 ? kAccentColor : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
