// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart' hide Page;

import '../l10n/l10n.dart';
import '../logic/canvas_controller.dart';
import '../models/flashcard.dart';
import '../models/page.dart';
import '../services/export_service.dart';
import '../services/image_service.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/dialogs.dart';
import 'widgets/page_scaffold.dart';

/// Repaso de las tarjetas de la nota que tocan hoy (repetición espaciada).
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.controller, required this.imageService});

  final CanvasController controller;
  final ImageService imageService;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  CanvasController get _c => widget.controller;

  /// Cola de la sesión (ids), fijada al entrar: «Otra vez» la vuelve a poner al final.
  late final List<String> _queue = [
    for (final c in _c.note.flashcards)
      if (c.isDue(DateTime.now())) c.id,
  ];
  bool _showBack = false;
  int _done = 0;

  Flashcard? get _card {
    final byId = {for (final c in _c.note.flashcards) c.id: c};
    _queue.removeWhere((id) => !byId.containsKey(id)); // borradas mientras tanto
    return _queue.isEmpty ? null : byId[_queue.first];
  }

  Page? _pageOf(Flashcard c) {
    for (final p in _c.pages) {
      if (p.id == c.pageId) return p;
    }
    return null;
  }

  Future<Uint8List> _render(Page page, Rect region) async {
    for (final item in page.images) {
      await widget.imageService.ensureCached(item.localPath);
    }
    final tpl = page.template.imagePath;
    if (tpl != null) await widget.imageService.ensureCached(tpl);
    return ExportService.renderPagePng(
      page,
      sheetSize: page.template.sheetSize,
      imageCache: widget.imageService.cache,
      options: ExportOptions(maxDimension: 1400, region: region),
    );
  }

  void _grade(ReviewGrade g) {
    final card = _card;
    if (card == null) return;
    _c.reviewFlashcard(card.id, g);
    setState(() {
      _queue.removeAt(0);
      if (g == ReviewGrade.again) {
        _queue.add(card.id);
      } else {
        _done++;
      }
      _showBack = false;
    });
  }

  Future<void> _delete(Flashcard card) async {
    final ok = await showConfirmDialog(
      context,
      title: context.l10n.studyDeleteTitle,
      message: context.l10n.studyDeleteBody,
      confirmLabel: context.l10n.libDelete,
      destructive: true,
    );
    if (!ok) return;
    _c.removeFlashcard(card.id);
    setState(() {
      _queue.remove(card.id);
      _showBack = false;
    });
  }

  Widget _image(Page page, Rect region) => FutureBuilder<Uint8List>(
        future: _render(page, region),
        builder: (context, snap) => snap.hasData
            ? Image.memory(snap.data!, fit: BoxFit.contain, gaplessPlayback: true)
            : const Padding(
                padding: EdgeInsets.all(Spacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final page = card == null ? null : _pageOf(card);
    return InklusPage(
      title: context.l10n.studyTitle,
      subtitle: context.l10n.studyProgress(_done, _queue.length),
      icon: Icons.style_outlined,
      slivers: [
        SliverToBoxAdapter(
          child: card == null || page == null
              ? EmptyState(
                  icon: Icons.celebration_outlined,
                  title: context.l10n.studyDoneTitle,
                  message: _c.note.flashcards.isEmpty
                      ? context.l10n.studyNoCards
                      : context.l10n.studyDoneBody,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      padding: const EdgeInsets.all(Spacing.md),
                      children: [
                        _image(page, card.front),
                        if (_showBack && card.back != null) ...[
                          const Divider(height: Spacing.xl),
                          _image(page, card.back!),
                        ],
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    if (!_showBack && card.back != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(context.l10n.studyShow),
                        onPressed: () => setState(() => _showBack = true),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: Spacing.md,
                        runSpacing: Spacing.md,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: context.inklus.danger),
                            onPressed: () => _grade(ReviewGrade.again),
                            child: Text(context.l10n.studyAgain),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _grade(ReviewGrade.good),
                            child: Text(context.l10n.studyGood),
                          ),
                          FilledButton(
                            onPressed: () => _grade(ReviewGrade.easy),
                            child: Text(context.l10n.studyEasy),
                          ),
                        ],
                      ),
                    const SizedBox(height: Spacing.md),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.studyDelete),
                      onPressed: () => _delete(card),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
