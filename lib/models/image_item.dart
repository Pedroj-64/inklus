import 'dart:ui';

/// Imagen insertada sobre el lienzo (subida del dispositivo).
///
/// La imagen se copia a la carpeta de datos de la app y aquí solo se guarda
/// la referencia [localPath] más su posición/tamaño en el "mundo".
class ImageItem {
  final String id;
  final String localPath;

  /// Centro del item en coordenadas de mundo.
  double x;
  double y;

  /// Ancho y alto en unidades de mundo (aspect ratio real de la imagen).
  double width;
  double height;

  ImageItem({
    required this.id,
    required this.localPath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect get rect => Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );

  bool contains(Offset worldPoint) => rect.inflate(6).contains(worldPoint);

  ImageItem copyWith({
    String? localPath,
    double? x,
    double? y,
    double? width,
    double? height,
  }) =>
      ImageItem(
        id: id,
        localPath: localPath ?? this.localPath,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  factory ImageItem.fromJson(Map<String, dynamic> json) => ImageItem(
        id: json['id'] as String,
        localPath: json['path'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['w'] as num).toDouble(),
        height: (json['h'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': localPath,
        'x': x,
        'y': y,
        'w': width,
        'h': height,
      };
}
