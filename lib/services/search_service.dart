// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'file_utils.dart';
import 'storage_service.dart';

/// De dónde viene el texto que coincidió.
enum SearchSource { title, typed, handwriting }

/// Una coincidencia dentro de una nota.
class SearchMatch {
  const SearchMatch({
    required this.pageIndex,
    required this.pageId,
    required this.snippet,
    required this.source,
  });

  /// Página (0-based) o -1 si coincidió el título.
  final int pageIndex;
  final String? pageId;
  final String snippet;
  final SearchSource source;
}

/// Resultado: una nota con sus coincidencias.
class SearchResult {
  const SearchResult({
    required this.noteId,
    required this.notebookId,
    required this.noteTitle,
    required this.matches,
  });

  final String noteId;
  final String notebookId;
  final String noteTitle;
  final List<SearchMatch> matches;
}

/// Índice de búsqueda de contenido (offline, local).
///
/// Por cada nota guarda su título y, por página, el **texto tecleado**
/// (cajas de texto, se recalcula al indexar) y la **escritura reconocida**
/// (OCR/ML Kit, se conserva hasta que se vuelva a reconocer esa página).
///
/// La búsqueda ignora mayúsculas y acentos ("matematicas" encuentra
/// "Matemáticas"). Archivo: `<appSupport>/inklus/search_index.json`.
class SearchService {
  SearchService({StorageService? storage}) : _storage = storage ?? StorageService.instance;

  /// Instancia compartida (biblioteca y editor ven el mismo índice).
  static final SearchService instance = SearchService();

  static const _fileName = 'search_index.json';
  static const _version = 2;

  final StorageService _storage;
  final Map<String, _NoteIndex> _index = {};
  bool _loaded = false;

  Future<File> _file() async {
    final base = await _storage.baseDirectory();
    return File('${base.path}/$_fileName');
  }

  /// Carga el índice (una vez). Índices de versiones antiguas se descartan
  /// y se reconstruyen al abrir las notas.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final json = jsonDecode(await f.readAsString());
      if (json is! Map<String, dynamic> || json['v'] != _version) return;
      for (final e in (json['notes'] as Map<String, dynamic>).entries) {
        _index[e.key] = _NoteIndex.fromJson(e.value as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('SearchService.load: $e');
    }
  }

  Future<void> _save() async {
    try {
      await writeAtomic(
        await _file(),
        jsonEncode({
          'v': _version,
          'notes': {for (final e in _index.entries) e.key: e.value.toJson()},
        }),
      );
    } catch (e) {
      debugPrint('SearchService._save: $e');
    }
  }

  /// (Re)indexa una nota. El texto tecleado se toma de la nota; la escritura
  /// reconocida previamente se conserva por página.
  Future<void> indexNote(String notebookId, Note note) async {
    await load();
    final previous = _index[note.id];
    _index[note.id] = _NoteIndex(
      noteId: note.id,
      notebookId: notebookId,
      title: note.title,
      pages: [
        for (final page in note.pages)
          _PageIndex(
            pageId: page.id,
            typed: page.textItems.map((t) => t.text).where((t) => t.isNotEmpty).join('\n'),
            handwriting: previous?.pages
                    .where((p) => p.pageId == page.id)
                    .map((p) => p.handwriting)
                    .firstOrNull ??
                '',
          ),
      ],
    );
    await _save();
  }

  /// Guarda el texto reconocido de la escritura de una página.
  Future<void> setHandwriting(String noteId, String pageId, String text) async {
    await load();
    final note = _index[noteId];
    if (note == null) return;
    final i = note.pages.indexWhere((p) => p.pageId == pageId);
    if (i < 0) return;
    note.pages[i] = note.pages[i].copyWith(handwriting: text);
    await _save();
  }

  Future<void> removeNote(String noteId) async {
    await load();
    if (_index.remove(noteId) != null) await _save();
  }

  /// Busca en todas las notas indexadas (o solo en [onlyNoteId]).
  List<SearchResult> search(String query, {String? onlyNoteId}) {
    final q = normalize(query.trim());
    if (q.isEmpty) return [];
    final results = <SearchResult>[];
    for (final note in _index.values) {
      if (onlyNoteId != null && note.noteId != onlyNoteId) continue;
      final matches = <SearchMatch>[];
      if (normalize(note.title).contains(q)) {
        matches.add(SearchMatch(
          pageIndex: -1,
          pageId: null,
          snippet: note.title,
          source: SearchSource.title,
        ));
      }
      for (var i = 0; i < note.pages.length; i++) {
        final page = note.pages[i];
        for (final (text, source) in [
          (page.typed, SearchSource.typed),
          (page.handwriting, SearchSource.handwriting),
        ]) {
          final snippet = _snippet(text, q);
          if (snippet != null) {
            matches.add(SearchMatch(
              pageIndex: i,
              pageId: page.pageId,
              snippet: snippet,
              source: source,
            ));
          }
        }
      }
      if (matches.isNotEmpty) {
        results.add(SearchResult(
          noteId: note.noteId,
          notebookId: note.notebookId,
          noteTitle: note.title,
          matches: matches,
        ));
      }
    }
    return results;
  }

  /// Minúsculas y sin acentos, para comparar.
  static String normalize(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString();
  }

  /// Fragmento de ~70 caracteres alrededor de la coincidencia, o null.
  /// (La normalización no cambia la longitud, así que los índices valen.)
  static String? _snippet(String text, String normalizedQuery) {
    if (text.isEmpty) return null;
    final idx = normalize(text).indexOf(normalizedQuery);
    if (idx < 0) return null;
    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + normalizedQuery.length + 30).clamp(0, text.length);
    return '${start > 0 ? '…' : ''}${text.substring(start, end).replaceAll('\n', ' ')}'
        '${end < text.length ? '…' : ''}';
  }

  int get indexedNotes => _index.length;
}

class _NoteIndex {
  _NoteIndex({
    required this.noteId,
    required this.notebookId,
    required this.title,
    required this.pages,
  });

  final String noteId;
  final String notebookId;
  final String title;
  final List<_PageIndex> pages;

  factory _NoteIndex.fromJson(Map<String, dynamic> j) => _NoteIndex(
        noteId: j['id'] as String,
        notebookId: j['nb'] as String? ?? '',
        title: j['title'] as String? ?? '',
        pages: (j['pages'] as List? ?? [])
            .map((p) => _PageIndex.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': noteId,
        'nb': notebookId,
        'title': title,
        'pages': [for (final p in pages) p.toJson()],
      };
}

class _PageIndex {
  const _PageIndex({required this.pageId, required this.typed, required this.handwriting});

  final String pageId;
  final String typed;
  final String handwriting;

  _PageIndex copyWith({String? handwriting}) =>
      _PageIndex(pageId: pageId, typed: typed, handwriting: handwriting ?? this.handwriting);

  factory _PageIndex.fromJson(Map<String, dynamic> j) => _PageIndex(
        pageId: j['id'] as String? ?? '',
        typed: j['typed'] as String? ?? '',
        handwriting: j['ink'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': pageId,
        if (typed.isNotEmpty) 'typed': typed,
        if (handwriting.isNotEmpty) 'ink': handwriting,
      };
}
