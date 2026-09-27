// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import '../models/image_item.dart';
import '../models/stroke.dart';

/// Resultado del snapping: el punto ajustado y las guías a mostrar.
class SnapResult {
  /// Punto ajustado (snapped) si hay coincidencia cercana.
  final Offset snappedPoint;

  /// Líneas guía verticales a dibujar (en coordenadas de mundo).
  final List<double> verticalGuides;

  /// Líneas guía horizontales a dibujar (en coordenadas de mundo).
  final List<double> horizontalGuides;

  const SnapResult({
    required this.snappedPoint,
    this.verticalGuides = const [],
    this.horizontalGuides = const [],
  });

  /// true si hubo ajuste en algún eje. Usar esto (no comparar con
  /// Offset.zero): el centro de la hoja (0,0) es un snap válido.
  bool get hasSnap => verticalGuides.isNotEmpty || horizontalGuides.isNotEmpty;

  static const none = SnapResult(snappedPoint: Offset.zero);
}

/// Servicio de snapping / guías magnéticas.
///
/// Detecta alineación entre trazos, imágenes, bordes de hoja y centro
/// del viewport, y ajusta la posición de un item cuando está cerca de
/// una guía.
class SnapGuides {
  const SnapGuides._();

  static const double _snapThreshold = 8.0;

  /// Analiza la posición de un item y devuelve el snap resultante.
  static SnapResult compute({
    required Offset candidateCenter,
    required Rect candidateBounds,
    required List<Stroke> strokes,
    required List<ImageItem> images,
    required Size? sheetSize,
    String? excludeImageId,
  }) {
    final candidatesX = <double>[];
    final candidatesY = <double>[];

    // 1. Centro de la hoja (si es finita).
    if (sheetSize != null) {
      candidatesX.add(0); // centro en x=0 (origen del mundo)
      candidatesY.add(0); // centro en y=0
      candidatesX.addAll([-sheetSize.width / 2, sheetSize.width / 2]);
      candidatesY.addAll([-sheetSize.height / 2, sheetSize.height / 2]);
    }

    // 2. Centros y bordes de imágenes existentes (excluyendo la candidata).
    for (final img in images) {
      // La imagen que se arrastra no debe engancharse a sí misma.
      if (img.id == excludeImageId) continue;
      final r = img.rect;
      candidatesX.add(img.x);
      candidatesY.add(img.y);
      candidatesX.addAll([r.left, r.right]);
      candidatesY.addAll([r.top, r.bottom]);
    }

    // 3. Centros de trazos existentes (aproximación: bounding box).
    // (bounding box cacheado por trazo: antes se recorrían todos los puntos
    // de todos los trazos en cada evento de arrastre).
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final b = s.pointBounds;
      candidatesX.addAll([b.center.dx, b.left, b.right]);
      candidatesY.addAll([b.center.dy, b.top, b.bottom]);
    }

    // 4. Encuentra el snap más cercano.
    var bestDx = _snapThreshold + 1;
    var bestDy = _snapThreshold + 1;
    var snapX = candidateCenter.dx;
    var snapY = candidateCenter.dy;
    final guidesX = <double>[];
    final guidesY = <double>[];

    for (final cx in candidatesX) {
      final d = (candidateCenter.dx - cx).abs();
      if (d < bestDx) {
        bestDx = d;
        snapX = cx;
      }
    }
    if (bestDx <= _snapThreshold) {
      guidesX.add(snapX);
    } else {
      snapX = candidateCenter.dx;
    }

    for (final cy in candidatesY) {
      final d = (candidateCenter.dy - cy).abs();
      if (d < bestDy) {
        bestDy = d;
        snapY = cy;
      }
    }
    if (bestDy <= _snapThreshold) {
      guidesY.add(snapY);
    } else {
      snapY = candidateCenter.dy;
    }

    if (guidesX.isEmpty && guidesY.isEmpty) {
      return SnapResult.none;
    }

    return SnapResult(
      snappedPoint: Offset(snapX, snapY),
      verticalGuides: guidesX,
      horizontalGuides: guidesY,
    );
  }
}
