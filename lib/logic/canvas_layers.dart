// SPDX-License-Identifier: GPL-3.0-or-later
part of 'canvas_controller.dart';

/// Capas de la página del [CanvasController] (activa, visibles, bloqueadas).
mixin _CanvasLayers on _CanvasCore {
  // ---- Capas ----
  @override
  int _activeLayerIndex = 0;

  int get activeLayerIndex => _activeLayerIndex;

  // ------------------------------------------------------------------
  // Capas bloqueadas
  // ------------------------------------------------------------------

  /// Verifica si la capa activa está bloqueada.
  bool get isActiveLayerLocked {
    if (_activeLayerIndex < page.layers.length) {
      return page.layers[_activeLayerIndex].locked;
    }
    return false;
  }

  /// Verifica si la capa de un trazo/imagen/texto está bloqueada.
  @override
  bool _isLayerLocked(int layerIndex) {
    if (layerIndex < page.layers.length) {
      return page.layers[layerIndex].locked;
    }
    return false;
  }

  @override
  bool _isLayerVisible(int layerIndex) =>
      layerIndex >= page.layers.length || page.layers[layerIndex].visible;

  // ------------------------------------------------------------------
  // Capas
  // ------------------------------------------------------------------

  void setActiveLayer(int index) {
    if (index < 0 || index >= page.layers.length) return;
    _activeLayerIndex = index;
    notifyListeners();
  }

  void addLayer() {
    final name = 'Capa ${page.layers.length + 1}';
    page.layers.add(Layer(name: name));
    _activeLayerIndex = page.layers.length - 1;
    _touch();
  }

  void removeLayer(int index) {
    if (page.layers.length <= 1 || index == 0) return; // No eliminar la capa 0
    page.layers.removeAt(index);
    if (_activeLayerIndex >= page.layers.length) {
      _activeLayerIndex = page.layers.length - 1;
    }
    _touch();
  }

  void toggleLayerVisibility(int index) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].visible = !page.layers[index].visible;
    _touch();
  }

  void toggleLayerLocked(int index) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].locked = !page.layers[index].locked;
    _touch();
  }

  void renameLayer(int index, String name) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].name = name;
    _touch();
  }

  void setLayerOpacity(int index, double opacity) {
    if (index < 0 || index >= page.layers.length) return;
    page.layers[index].opacity = opacity.clamp(0.0, 1.0);
    _touch();
  }
}
