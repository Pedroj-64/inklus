// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/drive_sync_service.dart';
import '../services/import_service.dart';
import '../services/storage_service.dart';
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
      title: 'Configuración',
      subtitle: 'Inklus $kAppVersion · tus notas se guardan en este dispositivo',
      maxWidth: 820,
      slivers: [
        SliverList.list(
          children: [
            const SectionLabel('Google Drive', trailing: null),
            ListenableBuilder(listenable: _sync, builder: (context, _) => _driveCard()),
            const SectionLabel('Apariencia'),
            SectionCard(children: [_themeTile()]),
            const SectionLabel('Copias y archivos'),
            SectionCard(
              children: [
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Importar .inklus o respaldo',
                  subtitle: 'Un cuaderno (.inklus) o un respaldo completo (.zip); '
                      'se reconoce solo',
                  onTap: _busy ? null : _import,
                ),
                SettingsTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Exportar respaldo completo',
                  subtitle: 'Todos los cuadernos, imágenes y papelera en un .zip',
                  onTap: _busy ? null : _exportAll,
                ),
                const SettingsTile(
                  icon: Icons.save_outlined,
                  title: 'Guardado automático',
                  subtitle: 'Cada cambio se guarda al instante en este dispositivo. '
                      'Al abrir y cerrar una nota se guarda una versión '
                      '(menú ⋮ → Historial de versiones).',
                ),
              ],
            ),
            const SectionLabel('Herramientas'),
            SectionCard(
              children: [
                SettingsTile(
                  icon: Icons.insights_outlined,
                  title: 'Estadísticas de escritura',
                  subtitle: 'Trazos, páginas, rachas y actividad',
                  onTap: () => _push(const WritingStatsScreen()),
                ),
                SettingsTile(
                  icon: Icons.alarm_outlined,
                  title: 'Recordatorios',
                  subtitle: 'Avisos vinculados a tus cuadernos',
                  onTap: () => _push(const ReminderScreen()),
                ),
                SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Papelera',
                  subtitle: 'Recupera cuadernos eliminados',
                  onTap: () => _push(TrashScreen(storage: _storage)),
                ),
              ],
            ),
            const SectionLabel('Acerca de'),
            SectionCard(
              children: [
                const SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Inklus $kAppVersion',
                  subtitle: 'Escritura a mano para tablets con lápiz',
                ),
                SettingsTile(
                  icon: Icons.favorite_outline,
                  accent: context.inklus.danger,
                  title: 'Libre y gratuito',
                  subtitle: 'Código abierto (GPL-3.0). Sin funciones de pago, '
                      'sin anuncios y sin analítica.',
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
          title: signedIn ? 'Conectado' : 'Copia en la nube',
          subtitle: signedIn
              ? (_sync.email ?? 'Cuenta de Google')
              : 'Opcional: guarda una copia de tus notas en tu Google Drive',
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
                      label: const Text('Conectar'),
                    ),
        ),
        if (signedIn) ...[
          SettingsTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Subir ahora',
            subtitle: 'Sube las notas de los cuadernos con sincronización activa',
            onTap: _busy ? null : _backupNow,
          ),
          SettingsTile(
            icon: Icons.cloud_download_outlined,
            title: 'Restaurar desde Drive',
            subtitle: 'Trae las versiones más recientes y recupera las notas '
                'que no estén en este dispositivo',
            onTap: _busy ? null : _restoreFromDrive,
          ),
          SettingsTile(
            icon: Icons.history,
            title: 'Versiones de una nota',
            subtitle: 'En el editor: ☁️ → Ver versiones',
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
            child: const Text('Cambiar de cuenta'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.logout),
            onPressed: _signOut,
            child: const Text('Cerrar sesión'),
          ),
        ],
        builder: (context, menu, _) => IconButton(
          tooltip: 'Cuenta',
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
              Expanded(child: Text('Tema', style: context.text.titleMedium)),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                  ButtonSegment(
                      value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Oscuro')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Sistema')),
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
      if (mounted) _snack(e is FormatException ? e.message : 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
        if (await _sync.signIn() && mounted) _snack('Conectado como ${_sync.email}');
      });

  Future<void> _switchAccount() => _run(() async {
        if (await _sync.switchAccount() && mounted) _snack('Conectado como ${_sync.email}');
      });

  void _showConfigErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: context.inklus.warning, size: 40),
        title: const Text('Google no está configurado'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Dejarán de subirse copias a Google Drive. '
          'Las copias que ya están en Drive no se borran.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok != true) return;
    await _sync.signOut();
    if (mounted) _snack('Sesión cerrada');
  }

  Future<void> _backupNow() => _run(() async {
        var count = 0;
        for (final meta in await _storage.loadIndex()) {
          if (!meta.isSyncEnabled) continue;
          final nb = await _storage.loadNotebook(meta.id);
          for (final note in nb?.notes ?? const []) {
            await _sync.backupNote(note, promptForConsent: true);
            count++;
          }
        }
        _snack(count > 0 ? '$count nota(s) subida(s) a Drive' : 'No hay cuadernos con sincronización activa');
      });

  Future<void> _restoreFromDrive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_download_outlined),
        title: const Text('Restaurar desde Drive'),
        content: const Text(
          'Las notas de este dispositivo se reemplazan solo si la copia de Drive es '
          'más reciente. Las que no existan aquí se guardan en un cuaderno nuevo '
          '"Recuperado de Drive".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurar')),
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
        final bytes = await _storage.exportFullBackup();
        final stamp = DateTime.now().toIso8601String().substring(0, 10);
        final saved = await FilePicker.saveFile(
          dialogTitle: 'Guardar respaldo de Inklus',
          fileName: 'inklus_respaldo_$stamp.zip',
          bytes: bytes,
        );
        if (saved != null) _snack('Respaldo guardado');
      });

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
