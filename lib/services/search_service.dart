import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document.dart';

/// Resultado de búsqueda: un cuaderno con las páginas que coinciden.
class SearchResult {
  final String documentId;
  final String documentTitle;
  final int? colorValue;
  final List<SearchMatch> matches;

  const SearchResult({
    required this.documentId,
    required this.documentTitle,
    this.colorValue,
    required this.matches,
  });
}

/// Una coincidencia dentro de un documento.
class SearchMatch {
  final int pageIndex;
  final String pageName;
  final String matchedText;

  const SearchMatch({
    required this.pageIndex,
    required this.pageName,
    required this.matchedText,
  });
}

/// Índice de contenido OCR por cuaderno.
class _DocIndex {
  final String documentId;
  final String title;
  final List<_PageIndex> pages;

  const _DocIndex({
    required this.documentId,
    required this.title,
    required this.pages,
  });

  factory _DocIndex.fromJson(Map<String, dynamic> json) => _DocIndex(
        documentId: json['id'] as String,
        title: json['title'] as String? ?? '',
        pages: (json['pages'] as List? ?? [])
            .map((p) => _PageIndex.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': documentId,
        'title': title,
        'pages': pages.map((p) => p.toJson()).toList(),
      };
}

class _PageIndex {
  final int index;
  final String name;
  final String ocrText;

  const _PageIndex({
    required this.index,
    required this.name,
    required this.ocrText,
  });

  factory _PageIndex.fromJson(Map<String, dynamic> json) => _PageIndex(
        index: json['index'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        ocrText: json['text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'text': ocrText,
      };
}

/// Servicio de búsqueda en contenido de cuadernos.
///
/// Mantiene un índice de texto OCR extraído de las páginas.
/// La indexación se hace bajo demanda (no automática para no gastar CPU).
class SearchService {
  static const _fileName = 'search_index.json';

  Map<String, _DocIndex> _index = {};

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/inklus/$_fileName');
  }

  /// Carga el índice desde disco.
  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _index = {
        for (final e in json.entries)
          e.key: _DocIndex.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (e) {
      debugPrint('SearchService.load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      final map = <String, dynamic>{};
      for (final e in _index.entries) {
        map[e.key] = e.value.toJson();
      }
      await f.writeAsString(jsonEncode(map));
    } catch (e) {
      debugPrint('SearchService._save: $e');
    }
  }

  /// Indexa un cuaderno: extrae texto de sus páginas y lo guarda.
  /// [texts] es una lista de textos OCR por página (índice = página).
  Future<void> indexDocument(Document doc, List<String> texts) async {
    final pages = <_PageIndex>[];
    for (var i = 0; i < doc.pages.length; i++) {
      final page = doc.pages[i];
      final text = i < texts.length ? texts[i] : '';
      if (text.isNotEmpty) {
        pages.add(_PageIndex(
          index: i,
          name: page.name,
          ocrText: text,
        ));
      }
      // También indexar textItems embebidos.
      for (final ti in page.textItems) {
        if (ti.text.isNotEmpty) {
          pages.add(_PageIndex(
            index: i,
            name: page.name,
            ocrText: ti.text,
          ));
        }
      }
    }
    _index[doc.id] = _DocIndex(
      documentId: doc.id,
      title: doc.title,
      pages: pages,
    );
    await _save();
  }

  /// Indexa el texto directo de las cajas de texto (sin OCR).
  Future<void> indexTextItems(Document doc) async {
    final pages = <_PageIndex>[];
    for (var i = 0; i < doc.pages.length; i++) {
      final page = doc.pages[i];
      final texts = page.textItems.map((t) => t.text).join(' ');
      if (texts.isNotEmpty) {
        pages.add(_PageIndex(
          index: i,
          name: page.name,
          ocrText: texts,
        ));
      }
    }
    if (pages.isNotEmpty) {
      _index[doc.id] = _DocIndex(
        documentId: doc.id,
        title: doc.title,
        pages: pages,
      );
      await _save();
    }
  }

  /// Elimina un cuaderno del índice.
  Future<void> removeDocument(String documentId) async {
    _index.remove(documentId);
    await _save();
  }

  /// Busca texto en todos los cuadernos indexados.
  List<SearchResult> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    for (final docIndex in _index.values) {
      final matches = <SearchMatch>[];
      for (final page in docIndex.pages) {
        if (page.ocrText.toLowerCase().contains(q)) {
          // Extraer contexto alrededor del match.
          final text = page.ocrText;
          final lowerText = text.toLowerCase();
          final idx = lowerText.indexOf(q);
          final start = (idx - 30).clamp(0, text.length);
          final end = (idx + q.length + 30).clamp(0, text.length);
          final snippet = '...${text.substring(start, end)}...';
          matches.add(SearchMatch(
            pageIndex: page.index,
            pageName: page.name,
            matchedText: snippet,
          ));
        }
      }
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          documentId: docIndex.documentId,
          documentTitle: docIndex.title,
          matches: matches,
        ));
      }
    }
    return results;
  }

  /// Estadísticas del índice.
  int get indexedDocuments => _index.length;

  int get indexedPages =>
      _index.values.fold(0, (sum, d) => sum + d.pages.length);
}
