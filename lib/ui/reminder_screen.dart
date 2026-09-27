// SPDX-License-Identifier: GPL-3.0-or-later
import '../constants.dart';
import 'package:flutter/material.dart';

import '../services/reminder_service.dart';
import '../services/storage_service.dart';
import '../utils/theme_colors.dart';
import 'widgets/dialogs.dart';

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
        const SnackBar(content: Text('No hay cuadernos para vincular')),
      );
      return;
    }

    // Seleccionar cuaderno.
    final docId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Seleccionar cuaderno',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
        const SnackBar(content: Text('Recordatorio creado')),
      );
      await _load();
    }
  }

  Future<String?> _promptMessage() {
    return showTextPrompt(
      context,
      title: 'Mensaje del recordatorio',
      hint: 'Ej: Revisar apuntes de clase',
      secondaryLabel: 'Sin mensaje',
      secondaryValue: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _reminderService.pending;
    final fired = _reminderService.fired;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recordatorios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        onPressed: _createReminder,
        child: const Icon(Icons.add),
      ),
      body: pending.isEmpty && fired.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kAccentColor.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 40,
                      color: kAccentColor.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin recordatorios',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea recordatorios vinculados a tus cuadernos\npara no olvidar nada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, height: 1.4),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  const _SectionLabel(label: 'Pendientes'),
                  const SizedBox(height: 8),
                  ...pending.map((r) => _ReminderCard(
                        reminder: r,
                        isPending: true,
                        onDismiss: () async {
                          await _reminderService.remove(r.id);
                          await _load();
                        },
                      )),
                  const SizedBox(height: 16),
                ],
                if (fired.isNotEmpty) ...[
                  const _SectionLabel(label: 'Completados'),
                  const SizedBox(height: 8),
                  ...fired.map((r) => _ReminderCard(
                        reminder: r,
                        isPending: false,
                        onDismiss: () async {
                          await _reminderService.remove(r.id);
                          await _load();
                        },
                      )),
                ],
                // Espacio para el FAB.
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
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
    final isPast = dt.isBefore(DateTime.now());

    return Dismissible(
      key: Key(reminder.id),
      onDismissed: (_) => onDismiss,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isPending
              ? (isPast
                  ? Colors.orange.shade50
                  : Theme.of(context).colorScheme.surface)
              : Theme.of(context).colorScheme.surface.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? (isPast ? Colors.orange.shade200 : Colors.grey.shade200)
                : Colors.grey.shade100,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPending
                  ? (isPast
                      ? Colors.orange.withAlpha(20)
                      : kAccentColor.withAlpha(20))
                  : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPending
                  ? (isPast ? Icons.alarm_off : Icons.alarm)
                  : Icons.check_circle_outline,
              color: isPending
                  ? (isPast ? Colors.orange : kAccentColor)
                  : Colors.grey,
            ),
          ),
          title: Text(
            reminder.documentTitle,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                _formatDateTime(reminder.dateTime),
                style: TextStyle(
                  fontSize: 13,
                  color: isPending && isPast ? Colors.orange : ThemeColors.of(context).textSecondary,
                ),
              ),
              if (reminder.message.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  reminder.message,
                  style: TextStyle(fontSize: 12, color: ThemeColors.of(context).textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: isPending && isPast
              ? const Text('⏰', style: TextStyle(fontSize: 20))
              : null,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
