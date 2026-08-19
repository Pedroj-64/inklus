import 'dart:ui' show Color, Size;

/// Tipo de plantilla de fondo de una página.
///
/// - [blank]: lienzo infinito en blanco (se alarga al escribir).
/// - [sheet]: hoja normal de tamaño fijo (tipo papel A4), como el mercado actual.
/// - [ruled]: rayas tipo cuaderno, infinitas.
/// - [grid]: cuadrícula tipo cuaderno, infinita.
/// - [custom]: plantilla de usuario (imagen subida del dispositivo). Puede
///   usarse como hoja fija o como relleno infinito (se repite al escribir).
enum TemplateType { blank, sheet, ruled, grid, custom, music, planner, habit, dots }

TemplateType templateTypeFromName(String name) => TemplateType.values
    .firstWhere((t) => t.name == name, orElse: () => TemplateType.blank);

/// Configuración de la plantilla de fondo de una página.
///
/// Los valores están en unidades de "mundo" (1 unidad ≈ 1 píxel lógico a
/// zoom 100%). Una hoja A4 a ~144 dpi son 1191 × 1684.
class PageTemplate {
  final TemplateType type;

  /// Color de las líneas (rayas/cuadrícula) o del marco de la hoja.
  final int lineColorValue;

  /// Separación entre rayas o tamaño de celda de la cuadrícula.
  final double spacing;

  /// Ruta local (copia en la app) de la imagen para plantillas [custom].
  final String? imagePath;

  /// En plantillas [custom]: true = la imagen se repite infinitamente
  /// (relleno); false = la imagen actúa como hoja de tamaño fijo.
  final bool infiniteFill;

  /// En plantillas [custom] con [infiniteFill] = false: tamaño de la hoja
  /// en unidades de mundo (por defecto, las dimensiones en píxeles de la
  /// imagen subida).
  final double? customWidth;
  final double? customHeight;

  const PageTemplate({
    this.type = TemplateType.blank,
    this.lineColorValue = 0xFF9DB6D9,
    this.spacing = 52,
    this.imagePath,
    this.infiniteFill = false,
    this.customWidth,
    this.customHeight,
  });

  Color get lineColor => Color(lineColorValue);

  /// Tamaño de la hoja cuando la plantilla es finita ([sheet] o [custom] sin relleno).
  /// Para [custom] se ajusta en runtime según las dimensiones de la imagen.
  static const double sheetWidth = 1191;
  static const double sheetHeight = 1684;

  /// Si el tipo de plantilla debe ser infinito cuando infiniteFill no está
  /// establecido explícitamente (es decir, el campo no viene en el JSON guardado).
  /// B6: ruled/grid/dots/planner son infinitos por defecto; el usuario puede
  /// volverlos finitos desde el template picker (checkbox "Lienzo infinito").
  static bool _shouldBeInfiniteByDefault(TemplateType type) =>
      type == TemplateType.blank || type == TemplateType.music ||
      type == TemplateType.habit || type == TemplateType.ruled ||
      type == TemplateType.grid || type == TemplateType.dots ||
      type == TemplateType.planner;

  /// Tamaño efectivo de la hoja de esta plantilla.
  Size get sheetSize => type == TemplateType.custom
      ? Size(customWidth ?? sheetWidth, customHeight ?? sheetHeight)
      : const Size(sheetWidth, sheetHeight);

  /// Si la plantilla es finita (hoja de tamaño fijo).
  /// B6: ruled/grid/dots/planner son infinitos por defecto. El usuario puede
  /// volverlos finitos desde el template picker (checkbox "Lienzo infinito").
  /// sheet siempre es finito. blank/music/habit siempre son infinitos.
  bool get isFinite => type == TemplateType.sheet ||
      (type != TemplateType.blank && type != TemplateType.music &&
       type != TemplateType.habit && !infiniteFill);

  PageTemplate copyWith({
    TemplateType? type,
    int? lineColorValue,
    double? spacing,
    String? imagePath,
    bool? infiniteFill,
    double? customWidth,
    double? customHeight,
  }) =>
      PageTemplate(
        type: type ?? this.type,
        lineColorValue: lineColorValue ?? this.lineColorValue,
        spacing: spacing ?? this.spacing,
        imagePath: imagePath ?? this.imagePath,
        infiniteFill: infiniteFill ?? this.infiniteFill,
        customWidth: customWidth ?? this.customWidth,
        customHeight: customHeight ?? this.customHeight,
      );

  factory PageTemplate.fromJson(Map<String, dynamic> json) {
        final type = templateTypeFromName(json['type'] as String? ?? 'blank');
        // B6: si el campo infiniteFill no está en el JSON (templates antiguos),
        // usamos el default apropiado para el tipo.
        final hasInfiniteFill = json.containsKey('infiniteFill');
        final infiniteFill = hasInfiniteFill
            ? json['infiniteFill'] as bool
            : _shouldBeInfiniteByDefault(type);
        return PageTemplate(
          type: type,
          lineColorValue: (json['lineColor'] as num?)?.toInt() ?? 0xFF9DB6D9,
          spacing: (json['spacing'] as num?)?.toDouble() ?? 52,
          imagePath: json['imagePath'] as String?,
          infiniteFill: infiniteFill,
          customWidth: (json['customW'] as num?)?.toDouble(),
          customHeight: (json['customH'] as num?)?.toDouble(),
        );
      }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'lineColor': lineColorValue,
        'spacing': spacing,
        'imagePath': imagePath,
        'infiniteFill': infiniteFill,
        if (customWidth != null) 'customW': customWidth,
        if (customHeight != null) 'customH': customHeight,
      };
}
