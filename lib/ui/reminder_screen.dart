// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import '../services/reminder_service.dart';
import '../services/storage_service.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'widgets/dialogs.dart';
import 'widgets/page_scaffold.dart';
import '../l10n/l10n.dart';

/// Pantalla de recordatorios.
///
/// Muestra los recordatorios pendientes y pasados, y permite crear nuevos
/// vinculados a un cuaderno específico.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _reminderService = ReminderService();
  final _storage = StorageService.instance;
  List<NotebookMeta> _notebooks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _reminderService.load();
    _notebooks = await _storage.loadIndex();
    if (mounted) setState(() {});
  }

  Future<void> _createReminder() async {
    if (_notebooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.remNoNotebooks)),
      );
      return;
    }

    // Seleccionar cuaderno.
    final docId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              icon: Icons.book_outlined,
              title: context.l10n.remPickNotebook,
              subtitle: context.l10n.remPickHint,
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _notebooks.length,
                itemBuilder: (context, index) {
                  final meta = _notebooks[index];
                  return ListTile(
                    leading: const Icon(Icons.book_outlined),
                    title: Text(meta.title),
                    onTap: () => Navigator.pop(context, meta.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (docId == null) return;
    if (!mounted) return;

    final meta = _notebooks.firstWhere((m) => m.id == docId);

    // Seleccionar fecha y hora.
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Mensaje opcional.
    final message = await _promptMessage();
    if (message == null) return;

    await _reminderService.create(
      documentId: docId,
      documentTitle: meta.title,
      dateTime: dateTime,
      message: message,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.remCreated)),
      );
      await _load();
    }
  }

  Future<String?> _promptMessage() {
    return showTextPrompt(
      context,
      title: context.l10n.remMessageTitle,
      hint: context.l10n.remMessageHint,
      secondaryLabel: context.l10n.remNoMessage,
      secondaryValue: '',
    );
  }

  Future<void> _remove(Reminder r) async {
    await _reminderService.remove(r.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _reminderService.pending;
    final fired = _reminderService.fired;

    return InklusPage(
      title: context.l10n.remTitle,
      subtitle: context.l10n.remSubtitle,
      icon: Icons.alarm_outlined,
      maxWidth: 820,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReminder,
        icon: const Icon(Icons.add_alarm),
        label: Text(context.l10n.colorNew),
      ),
      slivers: [
        if (pending.isEmpty && fired.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.notifications_none,
              title: context.l10n.remEmptyTitle,
              message: context.l10n.remEmptyBody,
            ),
          )
        else
          SliverList.list(
            children: [
              if (pending.isNotEmpty) ...[
                SectionLabel(context.l10n.remPending),
                for (final r in pending)
                  _ReminderCard(reminder: r, isPending: true, onDismiss: () => _remove(r)),
              ],
              if (fired.isNotEmpty) ...[
                SectionLabel(context.l10n.remDone),
                for (final r in fired)
                  _ReminderCard(reminder: r, isPending: false, onDismiss: () => _remove(r)),
              ],
            ],
          ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final bool isPending;
  final VoidCallback onDismiss;

  const _ReminderCard({
    required this.reminder,
    required this.isPending,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final dt = reminder.dateTime.toLocal();
    final overdue = isPending && dt.isBefore(DateTime.now());
    final accent = !isPending
        ? context.colors.onSurfaceVariant
        : overdue
            ? context.inklus.warning
            : context.colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Spacing.xl),
          decoration: BoxDecoration(
            color: context.inklus.danger,
            borderRadius: Radii.lgAll,
          ),
          child: Icon(Icons.delete_outline, color: context.colors.onError),
        ),
        child: Card(
          color: overdue
              ? context.inklus.warning.withValues(alpha: 0.12)
              : isPending
                  ? null
                  : context.colors.surfaceContainerLow.withValues(alpha: 0.6),
          child: SettingsTile(
            icon: !isPending
                ? Icons.check_circle_outline
                : overdue
                    ? Icons.alarm_off
                    : Icons.alarm,
            accent: accent,
            title: reminder.documentTitle,
            subtitle: [
              _formatDateTime(reminder.dateTime) + (overdue ? context.l10n.remOverdue : ''),
              if (reminder.message.isNotEmpty) reminder.message,
            ].join('\n'),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final l = dt.toLocal();
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}
