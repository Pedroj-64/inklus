// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/drive_sync_service.dart';
import '../services/error_log.dart';
import '../services/import_service.dart';
import '../services/storage_service.dart';
import '../l10n/l10n.dart';
import '../theme_controller.dart';
import 'reminder_screen.dart';
import 'theme/inklus_colors.dart';
import 'theme/tokens.dart';
import 'trash_screen.dart';
import 'widgets/dialogs.dart';
import 'widgets/page_scaffold.dart';
import 'writing_stats_screen.dart';

/// Configuración de la app: Google Drive, apariencia, copias/archivos,
/// herramientas y "acerca de".
class SettingsScreen extends StatefulWidget {
  /// Se conserva por compatibilidad; el tema se elige ahora con un selector
  /// Claro / Oscuro / Sistema ([ThemeModeController]).
  final VoidCallback? onToggleTheme;

  const SettingsScreen({super.key, this.onToggleTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sync = DriveSyncService.instance;
  final _storage = StorageService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sync.restoreSession();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return InklusPage(
      title: context.l10n.settingsTitle,
      subtitle: context.l10n.settingsSubtitle(kAppVersion),
      maxWidth: 820,
      slivers: [
        SliverList.list(
          children: [
            SectionLabel(context.l10n.settingsSectionDrive),
            ListenableBuilder(listenable: _sync, builder: (context, _) => _driveCard()),
            SectionLabel(context.l10n.settingsSectionAppearance),
            SectionCard(children: [_themeTile()]),
            SectionLabel(context.l10n.settingsSectionFiles),
            SectionCard(
              children: [
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: context.l10n.settingsImportTitle,
                  subtitle: context.l10n.settingsImportSubtitle,
                  onTap: _busy ? null : _import,
                ),
                SettingsTile(
                  icon: Icons.inventory_2_outlined,
                  title: context.l10n.settingsExportTitle,
                  subtitle: context.l10n.settingsExportSubtitle,
                  onTap: _busy ? null : _exportAll,
                ),
                SettingsTile(
                  icon: Icons.save_outlined,
                  title: context.l10n.settingsAutosaveTitle,
                  subtitle: context.l10n.settingsAutosaveSubtitle,
                ),
              ],
            ),
            SectionLabel(context.l10n.settingsSectionTools),
            SectionCard(
              children: [
                SettingsTile(
                  icon: Icons.insights_outlined,
                  title: context.l10n.settingsStatsTitle,
                  subtitle: context.l10n.settingsStatsSubtitle,
                  onTap: () => _push(const WritingStatsScreen()),
                ),
                SettingsTile(
                  icon: Icons.alarm_outlined,
                  title: context.l10n.settingsRemindersTitle,
                  subtitle: context.l10n.settingsRemindersSubtitle,
                  onTap: () => _push(const ReminderScreen()),
                ),
                SettingsTile(
                  icon: Icons.delete_outline,
                  title: context.l10n.settingsTrashTitle,
                  subtitle: context.l10n.settingsTrashSubtitle,
                  onTap: () => _push(TrashScreen(storage: _storage)),
                ),
              ],
            ),
            SectionLabel(context.l10n.settingsSectionAbout),
            SectionCard(
              children: [
                SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Inklus $kAppVersion',
                  subtitle: context.l10n.settingsAppTagline,
                ),
                SettingsTile(
                  icon: Icons.favorite_outline,
                  accent: context.inklus.danger,
                  title: context.l10n.settingsFreeTitle,
                  subtitle: context.l10n.settingsFreeSubtitle,
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.settingsPrivacyTitle,
                  subtitle: context.l10n.settingsPrivacySubtitle,
                  onTap: () => _open(kPrivacyPolicyUrl),
                ),
                SettingsTile(
                  icon: Icons.code,
                  title: context.l10n.settingsSourceTitle,
                  subtitle: context.l10n.settingsSourceSubtitle,
                  onTap: () => _open(kSourceCodeUrl),
                ),
                SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: context.l10n.settingsErrorLogTitle,
                  subtitle: context.l10n.settingsErrorLogSubtitle,
                  onTap: _showErrorLog,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _driveCard() {
    final signedIn = _sync.isSignedIn;
    return SectionCard(
      children: [
        SettingsTile(
          icon: signedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          accent: signedIn ? context.inklus.success : context.colors.onSurfaceVariant,
          title: signedIn ? context.l10n.driveConnected : context.l10n.driveCloudCopy,
          subtitle: signedIn
              ? (_sync.email ?? context.l10n.driveGoogleAccount)
              : context.l10n.driveOptionalPitch,
          trailing: _busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : signedIn
                  ? _accountMenu()
                  : FilledButton.icon(
                      onPressed: _signIn,
                      icon: const Icon(Icons.login),
                      label: Text(context.l10n.driveConnect),
                    ),
        ),
        if (signedIn) ...[
          SettingsTile(
            icon: Icons.cloud_upload_outlined,
            title: context.l10n.driveUploadNow,
            subtitle: context.l10n.driveUploadNowSubtitle,
            onTap: _busy ? null : _backupNow,
          ),
          SettingsTile(
            icon: Icons.cloud_download_outlined,
            title: context.l10n.driveRestore,
            subtitle: context.l10n.driveRestoreSubtitle,
            onTap: _busy ? null : _restoreFromDrive,
          ),
          SettingsTile(
            icon: Icons.history,
            title: context.l10n.driveNoteVersions,
            subtitle: context.l10n.driveNoteVersionsSubtitle,
            accent: context.colors.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget _accountMenu() => MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.switch_account_outlined),
            onPressed: _switchAccount,
            child: Text(context.l10n.driveSwitchAccount),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.logout),
            onPressed: _signOut,
            child: Text(context.l10n.driveSignOut),
          ),
        ],
        builder: (context, menu, _) => IconButton(
          tooltip: context.l10n.driveAccount,
          icon: const Icon(Icons.more_vert),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        ),
      );

  Widget _themeTile() => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeModeController.mode,
        builder: (context, mode, _) => Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              IconBadge(icon: context.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              const SizedBox(width: Spacing.lg),
              Expanded(child: Text(context.l10n.settingsTheme, style: context.text.titleMedium)),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text(context.l10n.settingsThemeLight)),
                  ButtonSegment(
                      value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text(context.l10n.settingsThemeDark)),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text(context.l10n.settingsThemeSystem)),
                ],
                selected: {mode},
                onSelectionChanged: (v) => ThemeModeController.set(v.first),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  /// Ejecuta [task] marcando la tarjeta como ocupada y avisa del error.
  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } on GoogleConfigException catch (e) {
      if (mounted) _showConfigErrorDialog(e.message);
    } catch (e) {
      if (mounted) _snack(e is FormatException ? e.message : context.l10n.commonError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
        if (await _sync.signIn() && mounted) _snack(context.l10n.driveConnectedAs(_sync.email ?? ''));
      });

  Future<void> _switchAccount() => _run(() async {
        if (await _sync.switchAccount() && mounted) _snack(context.l10n.driveConnectedAs(_sync.email ?? ''));
      });

  void _showConfigErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: context.inklus.warning, size: 40),
        title: Text(context.l10n.driveNotConfigured),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonGotIt)),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.driveSignOutQuestion),
        content: Text(
          context.l10n.driveSignOutBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.driveSignOut)),
        ],
      ),
    );
    if (ok != true) return;
    await _sync.signOut();
    if (mounted) _snack(context.l10n.driveSignedOut);
  }

  Future<void> _backupNow() => _run(() async {
        final l10n = context.l10n;
        var count = 0;
        for (final meta in await _storage.loadIndex()) {
          if (!meta.isSyncEnabled) continue;
          final nb = await _storage.loadNotebook(meta.id);
          for (final note in nb?.notes ?? const []) {
            await _sync.backupNote(note, promptForConsent: true);
            count++;
          }
        }
        _snack(l10n.driveUploaded(count));
      });

  Future<void> _restoreFromDrive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_download_outlined),
        title: Text(context.l10n.driveRestore),
        content: Text(
          context.l10n.driveRestoreBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.commonRestore)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final result = await _sync.restoreLibrary(_storage);
      _snack(result.message);
    });
  }

  Future<void> _import() async {
    final bytes = await ImportService.pickFile();
    if (bytes == null || !mounted) return;
    await _run(() async {
      final result = await runWithLoading(context, () => ImportService.importBytes(bytes));
      _snack(result.message);
    });
  }

  Future<void> _exportAll() => _run(() async {
        final l10n = context.l10n;
        final bytes = await _storage.exportFullBackup();
        final stamp = DateTime.now().toIso8601String().substring(0, 10);
        final saved = await FilePicker.saveFile(
          dialogTitle: l10n.backupSaveTitle,
          fileName: 'inklus_respaldo_$stamp.zip',
          bytes: bytes,
        );
        if (saved != null) _snack(l10n.backupSaved);
      });

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack(context.l10n.settingsOpenFailed(url));
  }

  Future<void> _showErrorLog() async {
    final count = await ErrorLog.count();
    if (!mounted) return;
    if (count == 0) {
      _snack(context.l10n.settingsErrorLogEmpty);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              icon: Icons.bug_report_outlined,
              title: context.l10n.settingsErrorLogTitle,
              subtitle: context.l10n.settingsErrorLogCount(count),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(context.l10n.commonShare),
              subtitle: Text(context.l10n.settingsErrorLogShareSubtitle),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.inklus.danger),
              title: Text(context.l10n.settingsErrorLogClear),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
    if (!mounted) return;
    final l10n = context.l10n;
    switch (action) {
      case 'share':
        await SharePlus.instance.share(ShareParams(
          text: await ErrorLog.read(),
          subject: l10n.settingsErrorLogSubject(kAppVersion),
        ));
      case 'clear':
        await ErrorLog.clear();
        _snack(l10n.settingsErrorLogCleared);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
