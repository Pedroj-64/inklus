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

  const CreateNotebookResult({
    required this.name,
    required this.template,
    required this.coverStyle,
    this.coverColorValue,
  });
}

/// Pantalla completa para crear un cuaderno nuevo.
///
/// Muestra un diseño limpio con:
/// - Campo de nombre
/// - Selector de portada (5 estilos + color)
/// - Selector de plantilla (infinitas + finitas como tiles separados)
class CreateNotebookScreen extends StatefulWidget {
  final int notebookCount;

  const CreateNotebookScreen({super.key, required this.notebookCount});

  @override
  State<CreateNotebookScreen> createState() => _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends State<CreateNotebookScreen> {
  late TextEditingController _nameController;
  CoverStyle _coverStyle = CoverStyle.simple;
  int? _coverColorValue;
  TemplateType _templateType = TemplateType.blank;
  bool _infinite = true;
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Cuaderno ${widget.notebookCount}');
    // Color por defecto: el primero de la lista
    _coverColorValue = _coverColors[0].$2;
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

  /// Plantillas disponibles divididas en infinitas y finitas.
  static const _infiniteTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.ruled, Icons.subject, 'Rayas'),
    (TemplateType.grid, Icons.grid_on, 'Cuadrícula'),
    (TemplateType.dots, Icons.grain, 'Puntos'),
    (TemplateType.music, Icons.music_note, 'Pentagrama'),
    (TemplateType.planner, Icons.view_week, 'Agenda'),
    (TemplateType.habit, Icons.check_box_outlined, 'Hábitos'),
  ];

  static const _finiteTemplates = <(TemplateType, IconData, String)>[
    (TemplateType.sheet, Icons.description, 'Hoja A4'),
  ];

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
      ),
      body: SingleChildScrollView(
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
                  child: CustomPaint(
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
                    onTap: () => setState(() => _coverStyle = style),
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
                        child: CustomPaint(
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
            const SizedBox(height: 28),

            // ---- Plantilla ----
            Text(
              'Plantilla',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tc.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Blanco es infinito por defecto',
              style: TextStyle(fontSize: 11, color: tc.textTertiary),
            ),
            const SizedBox(height: 12),

            // Plantillas infinitas
            _SectionLabel(label: 'Lienzo infinito'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _templateTile(TemplateType.blank, Icons.crop_free, 'Blanco'),
                for (final (type, icon, label) in _infiniteTemplates)
                  _templateTile(type, icon, label),
              ],
            ),

            const SizedBox(height: 16),

            // Plantillas finitas
            _SectionLabel(label: 'Hoja fija'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (type, icon, label) in _finiteTemplates)
                  _templateTile(type, icon, label),
              ],
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
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: ThemeColors.of(context).textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}
