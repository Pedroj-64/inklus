// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';
import 'dart:ui';

/// Imagen insertada sobre el lienzo (subida del dispositivo).
///
/// La imagen se copia a la carpeta de datos de la app y aquí solo se guarda
/// la referencia [localPath] más su posición/tamaño/rotación en el "mundo".
class ImageItem {
  final String id;
  final String localPath;

  /// Centro del item en coordenadas de mundo.
  double x;
  double y;

  /// Ancho y alto en unidades de mundo (aspect ratio real de la imagen).
  double width;
  double height;

  /// Rotación en radianes (sentido horario).
  double rotation;

  /// Índice de la capa a la que pertenece esta imagen (0 = capa por defecto).
  final int layerIndex;

  ImageItem({
    required this.id,
    required this.localPath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.layerIndex = 0,
  });

  Rect get rect => Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );

  bool contains(Offset worldPoint) {
    // Para rotación: transforma el punto al espacio local de la imagen.
    if (rotation == 0) return rect.inflate(6).contains(worldPoint);
    final cosA = cos(-rotation);
    final sinA = sin(-rotation);
    final d = worldPoint - Offset(x, y);
    final local = Offset(d.dx * cosA - d.dy * sinA, d.dx * sinA + d.dy * cosA);
    final localRect = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    return localRect.inflate(6).contains(local);
  }

  ImageItem copyWith({
    String? localPath,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? layerIndex,
  }) =>
      ImageItem(
        id: id,
        localPath: localPath ?? this.localPath,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        rotation: rotation ?? this.rotation,
        layerIndex: layerIndex ?? this.layerIndex,
      );

  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
        id: json['id'] as String,
        localPath: json['path'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['w'] as num).toDouble(),
        height: (json['h'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        layerIndex: (json['layer'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': localPath,
        'x': x,
        'y': y,
        'w': width,
        'h': height,
        if (rotation != 0) 'rotation': rotation,
        if (layerIndex != 0) 'layer': layerIndex,
      };
}
