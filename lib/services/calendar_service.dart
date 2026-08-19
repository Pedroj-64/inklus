import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Vinculación entre un cuaderno y un evento de calendario.
class CalendarLink {
  final String documentId;
  final String documentTitle;
  final String? eventTitle;
  final DateTime? eventDate;
  final String? calendarId;

  const CalendarLink({
    required this.documentId,
    required this.documentTitle,
    this.eventTitle,
    this.eventDate,
    this.calendarId,
  });

  factory CalendarLink.fromJson(Map<String, dynamic> json) => CalendarLink(
        documentId: json['docId'] as String,
        documentTitle: json['docTitle'] as String? ?? '',
        eventTitle: json['eventTitle'] as String?,
        eventDate: json['eventDate'] != null
            ? DateTime.tryParse(json['eventDate'] as String)
            : null,
        calendarId: json['calendarId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'docId': documentId,
        'docTitle': documentTitle,
        if (eventTitle != null) 'eventTitle': eventTitle,
        if (eventDate != null) 'eventDate': eventDate!.toIso8601String(),
        if (calendarId != null) 'calendarId': calendarId,
      };
}

/// Servicio de integración con calendario.
///
/// Vincula cuadernos a eventos del calendario del dispositivo.
/// Como no se puede acceder al calendario nativo sin platform channels,
/// este servicio mantiene un registro local de las vinculaciones.
/// El usuario puede crear cuadernos pre-nombrados para eventos.
class CalendarService {
  static const _fileName = 'calendar_links.json';
  List<CalendarLink> _links = [];

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inklus/$_fileName');
  }

  /// Carga las vinculaciones desde disco.
  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return;
      final list = jsonDecode(raw) as List;
      _links = list
          .map((e) => CalendarLink.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CalendarService.load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(_links.map((l) => l.toJson()).toList()));
    } catch (e) {
      debugPrint('CalendarService._save: $e');
    }
  }

  /// Todas las vinculaciones.
  List<CalendarLink> get links => List.unmodifiable(_links);

  /// Vinculación de un cuaderno específico.
  CalendarLink? linkForDocument(String documentId) {
    for (final l in _links) {
      if (l.documentId == documentId) return l;
    }
    return null;
  }

  /// Crea una vinculación.
  Future<void> link({
    required String documentId,
    required String documentTitle,
    String? eventTitle,
    DateTime? eventDate,
    String? calendarId,
  }) async {
    // Eliminar vinculación anterior del mismo cuaderno.
    _links.removeWhere((l) => l.documentId == documentId);
    _links.add(CalendarLink(
      documentId: documentId,
      documentTitle: documentTitle,
      eventTitle: eventTitle,
      eventDate: eventDate,
      calendarId: calendarId,
    ));
    await _save();
  }

  /// Elimina una vinculación.
  Future<void> unlink(String documentId) async {
    _links.removeWhere((l) => l.documentId == documentId);
    await _save();
  }

  /// Nombres predefinidos para eventos comunes.
  static const eventPresets = [
    'Reunión de trabajo',
    'Clase / Curso',
    'Sesión de estudio',
    'Conferencia',
    'Taller',
    'Entrevista',
    'Revisión de proyecto',
    'Nota del día',
  ];
}
