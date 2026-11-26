// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

/// Colores propios de Inklus que no existen en [ColorScheme] (papel,
/// escritorio, selección de trazos…). Se leen con `context.inklus`.
///
/// Es una [ThemeExtension]: cambia automáticamente entre claro y oscuro y
/// se interpola en las transiciones de tema.
@immutable
class InklusColors extends ThemeExtension<InklusColors> {
  const InklusColors({
    required this.paper,
    required this.ink,
    required this.desk,
    required this.toolbar,
    required this.toolbarBorder,
    required this.selection,
    required this.danger,
    required this.success,
    required this.warning,
    required this.shadow,
  });

  /// Color del papel. Siempre claro (también en modo oscuro: el contenido
  /// se escribe en tinta oscura; el modo nocturno de escritura es aparte).
  final Color paper;

  /// Tinta sobre [paper] (texto de placas y etiquetas apoyadas en papel).
  final Color ink;

  /// Fondo alrededor de la hoja.
  final Color desk;

  /// Superficie de barras y paneles del editor.
  final Color toolbar;
  final Color toolbarBorder;

  /// Resaltado de trazos seleccionados con el lazo.
  final Color selection;

  final Color danger;
  final Color success;
  final Color warning;
  final Color shadow;

  static const light = InklusColors(
    paper: Color(0xFFFEFDF9),
    ink: Color(0xFF26231F),
    desk: Color(0xFFE4E1DA),
    toolbar: Color(0xFFFFFFFF),
    toolbarBorder: Color(0x14000000),
    selection: Color(0xFF0D9488),
    danger: Color(0xFFDC2626),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    shadow: Color(0x1F000000),
  );

  static const dark = InklusColors(
    paper: Color(0xFFFEFDF9),
    ink: Color(0xFF26231F),
    desk: Color(0xFF16171A),
    toolbar: Color(0xFF232428),
    toolbarBorder: Color(0x1FFFFFFF),
    selection: Color(0xFF2DD4BF),
    danger: Color(0xFFF87171),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    shadow: Color(0x66000000),
  );

  @override
  InklusColors copyWith({
    Color? paper,
    Color? ink,
    Color? desk,
    Color? toolbar,
    Color? toolbarBorder,
    Color? selection,
    Color? danger,
    Color? success,
    Color? warning,
    Color? shadow,
  }) =>
      InklusColors(
        paper: paper ?? this.paper,
        ink: ink ?? this.ink,
        desk: desk ?? this.desk,
        toolbar: toolbar ?? this.toolbar,
        toolbarBorder: toolbarBorder ?? this.toolbarBorder,
        selection: selection ?? this.selection,
        danger: danger ?? this.danger,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        shadow: shadow ?? this.shadow,
      );

  @override
  InklusColors lerp(InklusColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return InklusColors(
      paper: c(paper, other.paper),
      ink: c(ink, other.ink),
      desk: c(desk, other.desk),
      toolbar: c(toolbar, other.toolbar),
      toolbarBorder: c(toolbarBorder, other.toolbarBorder),
      selection: c(selection, other.selection),
      danger: c(danger, other.danger),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// Acceso corto: `context.inklus.desk`, `context.colors.primary`,
/// `context.text.titleMedium`.
extension InklusThemeContext on BuildContext {
  InklusColors get inklus =>
      Theme.of(this).extension<InklusColors>() ??
      // Sin extensión (p. ej. un MaterialApp de test): según el brillo.
      (Theme.of(this).brightness == Brightness.dark
          ? InklusColors.dark
          : InklusColors.light);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Sombra en capas (contacto + difusa) de tarjetas y portadas: más
  /// natural que una sola sombra grande.
  List<BoxShadow> get shadowSoft => [
        BoxShadow(color: inklus.shadow, blurRadius: 3, offset: const Offset(0, 1)),
        BoxShadow(color: inklus.shadow, blurRadius: 16, offset: const Offset(0, 6)),
      ];

  /// Sombra corta para botones pequeños flotantes.
  List<BoxShadow> get shadowRaised =>
      [BoxShadow(color: inklus.shadow, blurRadius: 4, offset: const Offset(0, 1))];
}
