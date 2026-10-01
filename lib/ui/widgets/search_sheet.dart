// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/search_service.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';

/// Hoja de búsqueda de contenido (texto tecleado, escritura reconocida y
/// títulos). Se usa en el editor (solo la nota abierta, [onlyNoteId]) y en
/// la biblioteca (todas las notas).
///
/// Al tocar una coincidencia llama a [onOpen] con la nota y la página.
Future<void> showSearchSheet(
  BuildContext context, {
  String initialQuery = '',
  String? onlyNoteId,
  required void Function(SearchResult result, SearchMatch match) onOpen,
}) async {
  await SearchService.instance.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _SearchSheet(
        initialQuery: initialQuery,
        onlyNoteId: onlyNoteId,
        onOpen: onOpen,
      ),
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.initialQuery, this.onlyNoteId, required this.onOpen});

  final String initialQuery;
  final String? onlyNoteId;
  final void Function(SearchResult, SearchMatch) onOpen;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final TextEditingController _query =
      TextEditingController(text: widget.initialQuery);
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _run() => setState(() {
        _results = SearchService.instance.search(_query.text, onlyNoteId: widget.onlyNoteId);
      });

  @override
  Widget build(BuildContext context) {
    final total = _results.fold<int>(0, (n, r) => n + r.matches.length);
    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: widget.onlyNoteId != null
                  ? context.l10n.searchInNote
                  : context.l10n.searchInAll,
            ),
            onChanged: (_) => _run(),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            _query.text.trim().isEmpty ? context.l10n.searchPrompt : context.l10n.searchMatches(total),
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            context.l10n.searchInfo,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: ListView(
              children: [
                for (final r in _results) ...[
                  if (widget.onlyNoteId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xs),
                      child: Text(r.noteTitle, style: context.text.titleSmall),
                    ),
                  for (final m in r.matches)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(switch (m.source) {
                        SearchSource.title => Icons.title,
                        SearchSource.typed => Icons.text_fields,
                        SearchSource.handwriting => Icons.draw,
                      }),
                      title: Text(m.snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(m.pageIndex < 0 ? context.l10n.searchTitleMatch : context.l10n.commonPageN(m.pageIndex + 1)),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onOpen(r, m);
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
