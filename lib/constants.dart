// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'models/stroke.dart';
// NOTA: Colors.black54, etc. están en package:flutter/material.dart.
// Para evitar importar Flutter aquí, usamos los valores hex equivalentes.

// ============================================================================
// Constantes globales de Inklus
//
// Centraliza colores, dimensiones, tiempos y configuraciones que antes estaban
// hardcodeadas en múltiples archivos. Usa esta lib para todo valor que pueda
// cambiar o que se repite en más de un lugar.
// ============================================================================

/// Versión visible de la app (debe coincidir con `version:` de pubspec.yaml;
/// lo comprueba `test/app_version_test.dart`).
const String kAppVersion = '1.4.2';

// ---------------------------------------------------------------------------
// Tema / Colores de acento
// ---------------------------------------------------------------------------

/// Color primario de la app (azul Material 3).
const Color kAccentColor = Color(0xFF3B6FF6);

/// Variante del primario con opacidad reducida (fondos de chips, badges).
const Color kAccentLight = Color(0xFFEBF0FF);

/// Variante oscura del primario (modo oscuro).
const Color kAccentDark = Color(0xFF1A3A6B);

/// Color de error/eliminar.
const Color kErrorColor = Color(0xFFD32F2F);

/// Color de éxito.
const Color kSuccessColor = Color(0xFF10B981);

/// Color de advertencia.
const Color kWarningColor = Color(0xFFF59E0B);

// ---------------------------------------------------------------------------
// Colores de papel y escritorio
// ---------------------------------------------------------------------------

/// Fondo de la hoja en modo claro.
const Color kPaperColorLight = Color(0xFFFEFDF9);

/// Fondo del escritorio en modo claro.
/// Debe ser lo suficientemente oscuro para que el papel blanco se distinga.
const Color kDeskColorLight = Color(0xFFE4E1DA);

/// Fondo de la hoja en modo oscuro.
const Color kPaperColorDark = Color(0xFF4A4A4A);

/// Fondo del escritorio en modo oscuro.
const Color kDeskColorDark = Color(0xFF16171A);

/// Fondo del scaffold en modo claro.
const Color kScaffoldLight = Color(0xFFEFEDE8);

/// Fondo del scaffold en modo oscuro.
const Color kScaffoldDark = Color(0xFF1A1B1E);

/// Fondo de tarjetas / bottom bar en modo oscuro.
const Color kSurfaceDark = Color(0xFF2A2A2A);

/// Fondo de búsqueda en modo oscuro.
const Color kSearchDark = Color(0xFF333333);

/// Fondo de superficie claro (cards, inputs).
const Color kSurfaceLight = Color(0xFFF5F5F5);

/// Fondo de superficie oscuro alternativo (thumbnails, rail).
const Color kSurfaceDarkAlt = Color(0xFF3A3A3A);

/// Fondo de selección de accent en modo claro.
const Color kAccentSelectionLight = Color(0xFFE3EDFF);

// ---------------------------------------------------------------------------
// Colores de interfaz
// ---------------------------------------------------------------------------

/// Color de texto secundario / placeholder (≈ Colors.black54).
const Color kTextSecondary = Color(0x8A000000);

/// Color por defecto del trazo (negro oscuro).
const Color kDefaultStrokeColor = Color(0xFF1A1A1A);

/// Color de borde suave (≈ Colors.black26).
const Color kBorderColor = Color(0x42000000);

/// Color de texto deshabilitado en modo claro (≈ Colors.black38).
const Color kTextDisabledLight = Color(0x61000000);

/// Color de texto deshabilitado en modo oscuro (≈ Colors.white38).
const Color kTextDisabledDark = Color(0x61FFFFFF);

// ---------------------------------------------------------------------------
// Paleta de colores del editor (12 colores predefinidos)
// ---------------------------------------------------------------------------

const List<Color> kDefaultPalette = [
  Color(0xFF1A1A1A),
  Color(0xFF6B7280),
  Color(0xFFB3261E),
  Color(0xFFE8590C),
  Color(0xFFF5A623),
  Color(0xFF37B24D),
  Color(0xFF0CA678),
  Color(0xFF1C7ED6),
  Color(0xFF4263EB),
  Color(0xFF7048E8),
  Color(0xFFD6336C),
  Color(0xFF8D6E63),
]; // dartfmt:on

// ---------------------------------------------------------------------------
// Colores de portada de cuaderno
// ---------------------------------------------------------------------------

/// Lista de (nombre, colorValue) para el selector de color de portada.
const List<(String, int?)> kCoverColors = [
  ('Sin color', null),
  ('Azul', 0xFF3B82F6),
  ('Verde', 0xFF4CAF50),
  ('Rojo', 0xFFE53935),
  ('Naranja', 0xFFFF9800),
  ('Morado', 0xFF9C27B0),
  ('Rosa', 0xFFEC407A),
  ('Turquesa', 0xFF26C6DA),
  ('Gris', 0xFF78909C),
];

// ---------------------------------------------------------------------------
// Herramientas: tamaños, rangos y valores por defecto
// ---------------------------------------------------------------------------

/// Rangos de tamaño permitidos por herramienta: (mín, máx).
const Map<ToolType, (double, double)> kToolSizeRanges = {
  ToolType.pen: (2, 14),
  ToolType.pencil: (2, 18),
  ToolType.highlighter: (12, 60),
  ToolType.calligraphy: (2, 20),
  ToolType.brush: (3, 24),
  ToolType.marker: (8, 40),
  ToolType.spray: (20, 100),
  ToolType.eraser: (12, 120),
  ToolType.lasso: (0, 0),
};

/// Tamaños por defecto de cada herramienta.
const Map<ToolType, double> kDefaultToolSizes = {
  ToolType.pen: 3.5,
  ToolType.pencil: 4.5,
  ToolType.highlighter: 26,
  ToolType.calligraphy: 6,
  ToolType.brush: 8,
  ToolType.marker: 16,
  ToolType.spray: 50,
  ToolType.eraser: 36,
};

/// Thinning por defecto (0 = uniforme, 0.5 = variable con presión).
const Map<ToolType, double> kDefaultThinning = {
  ToolType.pen: 0,
  ToolType.pencil: 0.55,
  ToolType.highlighter: 0,
  ToolType.calligraphy: 0.3,
  ToolType.brush: 0.4,
  ToolType.marker: 0,
  ToolType.spray: 0,
};

/// Smoothing por defecto.
const Map<ToolType, double> kDefaultSmoothing = {
  ToolType.pen: 0.5,
  ToolType.pencil: 0.5,
  ToolType.highlighter: 0.6,
  ToolType.calligraphy: 0.4,
  ToolType.brush: 0.55,
  ToolType.marker: 0.65,
  ToolType.spray: 0.4,
};

/// Streamline por defecto.
const Map<ToolType, double> kDefaultStreamline = {
  ToolType.pen: 0.45,
  ToolType.pencil: 0.5,
  ToolType.highlighter: 0.75,
  ToolType.calligraphy: 0.35,
  ToolType.brush: 0.6,
  ToolType.marker: 0.7,
  ToolType.spray: 0.3,
};

// ---------------------------------------------------------------------------
// Vista / Transformación
// ---------------------------------------------------------------------------

/// Zoom mínimo permitido.
const double kMinZoom = 0.1;

/// Zoom máximo permitido.
const double kMaxZoom = 6.0;

/// Zoom inicial por defecto (100%).
const double kDefaultZoom = 1.0;

// ---------------------------------------------------------------------------
// Persistencia
// ---------------------------------------------------------------------------

/// Duración del debounce de guardado automático.
const Duration kSaveDebounce = Duration(milliseconds: 600);

/// Profundidad máxima del stack de deshacer.
const int kMaxUndoDepth = 60;

// ---------------------------------------------------------------------------
// Regla virtual
// ---------------------------------------------------------------------------

/// Tipos de regla disponibles.
enum RulerType { straight, protractor }

/// Cuándo se enderezan las figuras dibujadas a mano.
enum ShapeMode {
  /// Nunca: el trazo queda tal cual.
  off,

  /// Al mantener el lápiz quieto al final del trazo (~0,5 s), como en
  /// Samsung Notes / Apple Notes. Es el modo por defecto: no convierte
  /// "sin querer" las líneas casi rectas.
  hold,

  /// Siempre que el trazo se parezca a una figura.
  always,
}

/// Modos del borrador.
enum EraserMode {
  /// Borra solo la parte tocada y parte el trazo (goma real).
  partial,

  /// Borra el trazo completo al tocarlo (rápido para tachar).
  stroke,

  /// Como [partial] pero solo afecta al resaltador (no borra la tinta).
  highlighterOnly,
}

/// Longitud de la regla en unidades de mundo.
const double kRulerLength = 600;

/// Radio del transportador en unidades de mundo.
const double kProtractorRadius = 300;

/// Ancho del cuerpo de la regla en pantalla (px).
const double kRulerScreenWidth = 18.0;

/// Umbral de proximidad para interactuar con la regla (unidades de mundo).
const double kRulerHitThreshold = 30;

/// Umbral de proximidad para el centro de la regla.
const double kRulerCenterThreshold = 40;

/// Separación entre marcas de medición de la regla.
const double kRulerMarkSpacing = 50;

// ---------------------------------------------------------------------------
// Lupa
// ---------------------------------------------------------------------------

/// Radio de la lupa en pantalla (px).
const double kMagnifierRadius = 60;

/// Zoom mínimo de la lupa.
const double kMagnifierMinZoom = 1.5;

/// Zoom máximo de la lupa.
const double kMagnifierMaxZoom = 8.0;

/// Zoom por defecto de la lupa.
const double kMagnifierDefaultZoom = 3.0;

/// Margen de la lupa respecto a los bordes de la pantalla.
const double kMagnifierMargin = 20;

// ---------------------------------------------------------------------------
// Snapping / Guías magnéticas
// ---------------------------------------------------------------------------

/// Umbral de snapping en unidades de mundo.
const double kSnapThreshold = 8.0;

// ---------------------------------------------------------------------------
// Selección con lazo
// ---------------------------------------------------------------------------

/// Tamaño del handle de escala/rotación en unidades de mundo.
const double kSelectionHandleSize = 11;

/// Desplazamiento del handle de rotación sobre el bounds de la selección.
const double kRotationHandleOffset = 3;

/// Inflado del marching ants alrededor de la selección.
const double kSelectionInflate = 8;

// ---------------------------------------------------------------------------
// Imágenes
// ---------------------------------------------------------------------------

/// Ancho máximo al insertar una imagen (se escala proporcionalmente).
const double kMaxImageInsertWidth = 520;

/// Ancho mínimo para redimensionar una imagen.
const double kMinImageWidth = 40;

/// Tamaño del handle de imagen (radio en mundo).
const double kImageHandleWorld = 30;

/// Margen de hit-test para imágenes (px inflado).
const double kImageHitMargin = 6;

// ---------------------------------------------------------------------------
// Cajas de texto
// ---------------------------------------------------------------------------

/// Ancho por defecto de una caja de texto (unidades de mundo).
const double kDefaultTextWidth = 250;

/// Tamaño de fuente por defecto (unidades de mundo).
const double kDefaultFontSize = 18;

// ---------------------------------------------------------------------------
// Exportación
// ---------------------------------------------------------------------------

/// Resolución baja de exportación (px del lado más largo).
const int kExportLow = 1024;

/// Resolución media de exportación.
const int kExportMedium = 2048;

/// Resolución alta de exportación.
const int kExportHigh = 4096;

/// Resolución máxima de exportación.
const int kExportMax = 8192;

/// Resolución de miniaturas de la biblioteca.
const int kThumbnailResolution = 480;

/// Resolución de OCR.
const int kOcrResolution = 4096;

/// Margen de contenido para exportación de lienzos infinitos.
const double kExportContentPadding = 100;

// ---------------------------------------------------------------------------
// OCR
// ---------------------------------------------------------------------------

/// Resolución máxima para renderizado de PDF (printing).
const int kPdfRenderMaxWidth = 1200;

/// DPI de renderizado de PDF.
const int kPdfRenderDpi = 150;

// ---------------------------------------------------------------------------
// Marketplace de plantillas
// ---------------------------------------------------------------------------

/// Tiempo de vida de la caché remota del marketplace.
const Duration kMarketplaceCacheMaxAge = Duration(hours: 6);

/// Timeout de la petición HTTP del marketplace.
const Duration kMarketplaceTimeout = Duration(seconds: 10);

// ---------------------------------------------------------------------------
// Gestos y atajos
// ---------------------------------------------------------------------------

/// Tiempo máximo entre taps para detectar doble toque del borrador físico.
const Duration kInvertedStylusDoubleTap = Duration(milliseconds: 350);

/// Tiempo máximo para detectar undo con dos dedos.
const Duration kTwoFingerTapMax = Duration(milliseconds: 300);

/// Tiempo del debounce de onboarding check.
// (no constante, se usa directamente)

// ---------------------------------------------------------------------------
// Pegar trazos
// ---------------------------------------------------------------------------

/// Desplazamiento al pegar trazos (evita superposición).
const double kPasteOffset = 30;

// ---------------------------------------------------------------------------
// Página
// ---------------------------------------------------------------------------

/// Ancho de hoja por defecto (A4 a ~144 dpi).
const double kDefaultSheetWidth = 1191;

/// Alto de hoja por defecto (A4 a ~144 dpi).
const double kDefaultSheetHeight = 1684;
