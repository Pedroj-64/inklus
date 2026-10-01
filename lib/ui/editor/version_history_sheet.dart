// SPDX-License-Identifier: GPL-3.0-or-later
import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../services/drive_sync_service.dart';
import '../../services/version_history_service.dart';
import '../../utils/date_utils.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../widgets/page_scaffold.dart';

/// Historial de versiones de una nota en una sola hoja: copias **locales**
/// (al abrir/cerrar la nota) y **revisiones de Google Drive** (cada subida).
///
/// Devuelve la versión elegida: un [NoteVersion] o un [DriveRevision]; null
/// si se cierra. La sección de Drive solo aparece con [driveRevisions]
/// (sesión iniciada) y se carga sin bloquear la local.
Future<Object?> showVersionHistorySheet(
  BuildContext context, {
  required List<NoteVersion> local,
  Future<List<DriveRevision>>? driveRevisions,
}) {
  return showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.xl),
        children: [
          SheetHeader(
            icon: Icons.history,
            title: context.l10n.menuVersions,
            subtitle: context.l10n.verSubtitle,
          ),
          _Label(context.l10n.verOnDevice),
          if (local.isEmpty)
            _Hint(context.l10n.verNoLocal)
          else
            for (final v in local)
              _VersionTile(
                icon: Icons.phone_android_outlined,
                date: v.savedAt,
                sizeBytes: v.sizeBytes,
                onTap: () => Navigator.pop(context, v),
              ),
          if (driveRevisions != null) ...[
            _Label(context.l10n.verOnDrive),
            FutureBuilder<List<DriveRevision>>(
              future: driveRevisions,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(Spacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _Hint(context.l10n.verDriveFailed('${snap.error}'));
                }
                final revs = snap.data ?? const [];
                if (revs.isEmpty) {
                  return _Hint(context.l10n.verNotUploaded);
                }
                return Column(
                  children: [
                    for (final r in revs)
                      _VersionTile(
                        icon: Icons.cloud_outlined,
                        date: r.modifiedTime,
                        sizeBytes: r.sizeBytes,
                        onTap: () => Navigator.pop(context, r),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    ),
  );
}

/// Fecha legible de una versión (dd/mm/aaaa hh:mm).
String formatVersionDate(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.icon,
    required this.date,
    required this.sizeBytes,
    required this.onTap,
  });

  final IconData icon;
  final DateTime date;
  final int sizeBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: context.colors.onSurfaceVariant),
        title: Text(formatVersionDate(date), style: context.text.titleSmall),
        subtitle: Text(
          '${relativeTime(context.l10n, date)}'
          '${sizeBytes > 0 ? ' · ${(sizeBytes / 1024).toStringAsFixed(0)} KB' : ''}',
          style: context.text.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.restore),
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        onTap: onTap,
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.xs),
        child: Text(
          text,
          style: context.text.titleSmall?.copyWith(color: context.colors.primary),
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
        child: Text(
          text,
          style: context.text.bodyMedium
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      );
}
