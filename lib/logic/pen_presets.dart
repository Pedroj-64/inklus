// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stroke.dart';
import 'canvas_controller.dart';

/// Una pluma guardada: herramienta + color + grosor.
@immutable
class PenPreset {
  const PenPreset({required this.tool, required this.colorValue, required this.size});

  final ToolType tool;
  final int colorValue;
  final double size;

  Color get color => Color(colorValue);

  PenPreset copyWith({ToolType? tool, int? colorValue, double? size}) => PenPreset(
        tool: tool ?? this.tool,
        colorValue: colorValue ?? this.colorValue,
        size: size ?? this.size,
      );

  Map<String, dynamic> toJson() => {'tool': tool.name, 'color': colorValue, 'size': size};

  factory PenPreset.fromJson(Map<String, dynamic> j) => PenPreset(
        tool: toolTypeFromName(j['tool'] as String? ?? 'pen'),
        colorValue: (j['color'] as num?)?.toInt() ?? 0xFF1A1A1A,
        size: (j['size'] as num?)?.toDouble() ?? 3.5,
      );

  @override
  bool operator ==(Object other) =>
      other is PenPreset &&
      other.tool == tool &&
      other.colorValue == colorValue &&
      other.size == size;

  @override
  int get hashCode => Object.hash(tool, colorValue, size);
}

/// Plumas favoritas del editor (como en GoodNotes): tres plumas + el
/// resaltador, cada una con su **propio** color y grosor, recordados entre
/// sesiones. También lleva la lista de colores recientes.
///
/// Uso: la barra llama a [activate]; cuando el usuario cambia color/grosor
/// en el lienzo, [syncFrom] actualiza la pluma activa.
class PenPresetsController extends ChangeNotifier {
  PenPresetsController({this.persist = true});

  /// false en tests (no toca SharedPreferences).
  final bool persist;

  static const _prefKey = 'pen_presets_v1';
  static const slotCount = 3;
  static const highlighterSlot = slotCount; // índice del resaltador
  static const maxRecent = 8;

  static const defaultPens = [
    PenPreset(tool: ToolType.pen, colorValue: 0xFF1A1A1A, size: 3.5),
    PenPreset(tool: ToolType.pen, colorValue: 0xFF1E56C8, size: 3.5),
    PenPreset(tool: ToolType.pencil, colorValue: 0xFFC62828, size: 3.0),
  ];
  static const defaultHighlighter =
      PenPreset(tool: ToolType.highlighter, colorValue: 0xFFFDD835, size: 18);

  List<PenPreset> _pens = List.of(defaultPens);
  PenPreset _highlighter = defaultHighlighter;
  int _active = 0;
  final List<int> _recent = [];

  List<PenPreset> get pens => List.unmodifiable(_pens);
  PenPreset get highlighter => _highlighter;
  List<Color> get recentColors => [for (final c in _recent) Color(c)];

  /// Índice de la pluma activa (0..2, o [highlighterSlot]).
  int get activeSlot => _active;

  PenPreset presetAt(int slot) => slot == highlighterSlot ? _highlighter : _pens[slot];

  /// true si la herramienta del lienzo corresponde a la ranura [slot].
  bool isShowing(int slot, ToolType currentTool) {
    if (slot != _active) return false;
    return slot == highlighterSlot
        ? currentTool == ToolType.highlighter
        : currentTool != ToolType.highlighter && presetAt(slot).tool == currentTool;
  }

  /// Aplica la pluma [slot] al lienzo.
  void activate(int slot, CanvasController canvas) {
    _active = slot;
    final p = presetAt(slot);
    // setTool/setColor notifican de inmediato: sin esta guarda, syncFrom
    // copiaría el color de la pluma anterior en la nueva.
    _applying = true;
    try {
      canvas.setTool(p.tool);
      canvas.setColor(p.color);
      canvas.setToolSize(p.size);
    } finally {
      _applying = false;
    }
    notifyListeners();
  }

  bool _applying = false;

  /// Copia al preset activo el estado actual del lienzo (tras cambiar
  /// color, grosor o tipo de pluma en el popover).
  void syncFrom(CanvasController canvas) {
    if (_applying) return;
    final tool = canvas.tool;
    final isHighlighter = tool == ToolType.highlighter;
    if (isHighlighter != (_active == highlighterSlot)) return;
    if (!isHighlighter && !canvas.isInkTool) return;
    final updated = PenPreset(
      tool: tool,
      colorValue: canvas.color.toARGB32(),
      size: canvas.toolSize,
    );
    if (updated == presetAt(_active)) return;
    if (_active == highlighterSlot) {
      _highlighter = updated;
    } else {
      _pens[_active] = updated;
    }
    notifyListeners();
    _save();
  }

  /// Registra un color usado (al principio de la lista de recientes).
  void addRecentColor(Color color) {
    final v = color.toARGB32();
    _recent
      ..remove(v)
      ..insert(0, v);
    if (_recent.length > maxRecent) _recent.removeLast();
    notifyListeners();
    _save();
  }

  Future<void> load() async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final pens = (j['pens'] as List? ?? [])
          .map((e) => PenPreset.fromJson(e as Map<String, dynamic>))
          .toList();
      if (pens.length == slotCount) _pens = pens;
      if (j['highlighter'] is Map<String, dynamic>) {
        _highlighter = PenPreset.fromJson(j['highlighter'] as Map<String, dynamic>);
      }
      _recent
        ..clear()
        ..addAll((j['recent'] as List? ?? []).map((e) => (e as num).toInt()));
      notifyListeners();
    } catch (e) {
      debugPrint('PenPresetsController.load: $e');
    }
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        jsonEncode({
          'pens': [for (final p in _pens) p.toJson()],
          'highlighter': _highlighter.toJson(),
          'recent': _recent,
        }),
      );
    } catch (e) {
      debugPrint('PenPresetsController._save: $e');
    }
  }
}
