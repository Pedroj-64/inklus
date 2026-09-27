// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'file_utils.dart';
import '../models/id.dart';
import 'app_paths.dart';

/// Un recordatorio vinculado a un cuaderno.
class Reminder {
  final String id;
  final String documentId;
  final String documentTitle;

  /// Fecha y hora del recordatorio.
  DateTime dateTime;

  /// Mensaje opcional.
  String message;

  /// Si ya se disparó.
  bool fired;

  Reminder({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    required this.dateTime,
    this.message = '',
    this.fired = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        documentId: json['docId'] as String,
        documentTitle: json['docTitle'] as String? ?? '',
        dateTime: DateTime.parse(json['dateTime'] as String),
        message: json['message'] as String? ?? '',
        fired: json['fired'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'docId': documentId,
        'docTitle': documentTitle,
        'dateTime': dateTime.toIso8601String(),
        'message': message,
        'fired': fired,
      };
}

/// Servicio de recordatorios locales.
///
/// Persiste en `inklus/reminders.json`. No usa alarma del sistema
/// (sería nativo); en su lugar, verifica al abrir la app y al guardar.
class ReminderService {
  static const _fileName = 'reminders.json';
  List<Reminder> _reminders = [];

  Future<File> _file() async {
    return AppPaths.file(_fileName);
  }

  /// Carga los recordatorios desde disco.
  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw) as List;
      _reminders = list
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ReminderService.load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await writeAtomic(f, jsonEncode(_reminders.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('ReminderService._save: $e');
    }
  }

  /// Lista de todos los recordatorios (pendientes + disparados).
  List<Reminder> get reminders => List.unmodifiable(_reminders);

  /// Recordatorios pendientes (no disparados y en el futuro).
  List<Reminder> get pending =>
      _reminders.where((r) => !r.fired).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  /// Recordatorios vencidos/disparados.
  List<Reminder> get fired => _reminders.where((r) => r.fired).toList();

  /// Crea un recordatorio.
  Future<void> create({
    required String documentId,
    required String documentTitle,
    required DateTime dateTime,
    String message = '',
  }) async {
    final id = newId('rem');
    _reminders.add(Reminder(
      id: id,
      documentId: documentId,
      documentTitle: documentTitle,
      dateTime: dateTime,
      message: message,
    ));
    await _save();
  }

  /// Elimina un recordatorio.
  Future<void> remove(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _save();
  }

  /// Marca un recordatorio como disparado.
  Future<void> markFired(String id) async {
    final r = _reminders.where((rem) => rem.id == id);
    if (r.isNotEmpty) {
      r.first.fired = true;
      await _save();
    }
  }

  /// Verifica si hay recordatorios vencidos (llamar al arrancar/al guardar).
  /// Devuelve la lista de recordatorios que acaban de dispararse.
  List<Reminder> checkFired() {
    final now = DateTime.now();
    final newFired = <Reminder>[];
    for (final r in _reminders) {
      if (!r.fired && r.dateTime.isBefore(now)) {
        r.fired = true;
        newFired.add(r);
      }
    }
    if (newFired.isNotEmpty) _save();
    return newFired;
  }

  /// Elimina todos los recordatorios de un cuaderno.
  Future<void> removeAllForDocument(String documentId) async {
    _reminders.removeWhere((r) => r.documentId == documentId);
    await _save();
  }
}
