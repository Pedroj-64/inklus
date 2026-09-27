// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';

/// Tokens de diseño de Inklus: **la única fuente** de espaciados, radios,
/// duraciones y tamaños. No escribir números mágicos en los widgets: si
/// falta un valor, se añade aquí con un nombre que explique su intención.
///
/// Escala base de 4 px (Material 3).
abstract final class Spacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radios de esquina.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Píldora (chips, indicadores). Mayor que cualquier alto razonable.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Duraciones de animación (cortas: la app es una herramienta, no un show).
/// (No se llama `Durations` para no chocar con la clase de Material.)
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

/// Tamaños de interfaz.
abstract final class Sizes {
  /// Objetivo táctil mínimo (Material / WCAG): 48 dp.
  static const double minTouch = 48;

  /// Alto de la barra superior del editor.
  static const double editorToolbar = 56;

  /// Icono estándar de herramienta.
  static const double toolIcon = 24;

  /// Muestra de color en paletas (con área táctil de [minTouch]).
  static const double swatch = 32;

  /// Ancho del panel lateral de páginas.
  static const double pagesPanel = 200;

  /// Ancho máximo de popovers de herramienta.
  static const double popoverWidth = 340;
}

/// Puntos de corte de diseño adaptable.
abstract final class Breakpoints {
  /// Por debajo: teléfono (barra compacta con desplazamiento).
  static const double compact = 600;

  /// Por encima: tablet apaisada / escritorio (todo visible).
  static const double expanded = 1000;
}
