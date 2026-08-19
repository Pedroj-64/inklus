import '../constants.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/drive_sync_service.dart';
import '../services/storage_service.dart';
import 'writing_stats_screen.dart';
import 'reminder_screen.dart';

/// Pantalla de configuración / ajustes de la app.
///
/// Accesible desde la biblioteca (icono de engranaje) y contiene:
/// - Respaldo en la nube (Google Drive)
/// - Tema claro / oscuro
/// - Backup local (exportar/importar todo)
/// - Acerca de
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const SettingsScreen({super.key, this.onToggleTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _syncService = DriveSyncService.instance;
  final _storage = StorageService.instance;
  bool _syncing = false;
  int _autosaveInterval = 300; // 5 minutos por defecto (en segundos)

  @override
  void initState() {
    super.initState();
    _syncService.restoreSession();
    _loadAutosaveInterval();
  }

  Future<void> _loadAutosaveInterval() async {
    // TODO: cargar de SharedPreferences cuando esté implementado
  }

  String _autosaveLabel(int seconds) {
    if (seconds < 60) return 'Cada $seconds segundos';
    if (seconds == 60) return 'Cada minuto';
    return 'Cada ${seconds ~/ 60} minutos';
  }

  void _showAutosavePicker() {
    showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Intervalo de autoguardado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: const Text('30 segundos'),
              leading: _autosaveInterval == 30 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 30),
            ),
            ListTile(
              title: const Text('1 minuto'),
              leading: _autosaveInterval == 60 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 60),
            ),
            ListTile(
              title: const Text('2 minutos'),
              leading: _autosaveInterval == 120 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 120),
            ),
            ListTile(
              title: const Text('5 minutos (predeterminado)'),
              leading: _autosaveInterval == 300 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 300),
            ),
            ListTile(
              title: const Text('10 minutos'),
              leading: _autosaveInterval == 600 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 600),
            ),
            ListTile(
              title: const Text('30 minutos'),
              leading: _autosaveInterval == 1800 ? const Icon(Icons.check, color: kAccentColor) : null,
              onTap: () => Navigator.pop(context, 1800),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).then((v) {
      if (v != null) setState(() => _autosaveInterval = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ===== SECCIÓN: Nube =====
          _SectionHeader(title: 'Nube y respaldo'),
          _SettingsCard(
            children: [
              // Estado de sesión
              ListenableBuilder(
                listenable: _syncService,
                builder: (context, _) {
                  final isSignedIn = _syncService.isSignedIn;
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSignedIn
                            ? const Color(0xFF10B981).withAlpha(25)
                            : Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                        color: isSignedIn
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      isSignedIn
                          ? 'Conectado a Google Drive'
                          : 'Respaldar en la nube',
                    ),
                    subtitle: Text(
                      isSignedIn
                          ? _syncService.email ?? 'Cuenta Google'
                          : 'Inicia sesión para respaldar tus cuadernos',
                      style: TextStyle(
                        color: isSignedIn
                            ? Colors.black54
                            : Colors.grey.shade500,
                      ),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: _syncing
                          ? null
                          : (isSignedIn ? _signOut : _signIn),
                      child: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isSignedIn ? 'Salir' : 'Conectar'),
                    ),
                  );
                },
              ),
              if (_syncService.isSignedIn) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Subir respaldo ahora'),
                  subtitle: const Text('Copia tu cuaderno a Google Drive'),
                  onTap: _backupNow,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Restaurar desde la nube'),
                  subtitle: const Text('Descarga la última versión guardada'),
                  onTap: () => _snack('Abre un cuaderno y usa el botón ☁️'),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Versiones en Drive'),
                  subtitle: const Text('Ver y restaurar versiones anteriores'),
                  onTap: () => _snack('Abre un cuaderno y usa el botón ☁️'),
                ),
              ],
            ],
          ),

          // ===== SECCIÓN: Apariencia =====
          _SectionHeader(title: 'Apariencia'),
          _SettingsCard(
            children: [
              SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Modo oscuro'),
                subtitle: Text(
                  isDark ? 'Activado' : 'Desactivado',
                  style: const TextStyle(color: Colors.black54),
                ),
                value: isDark,
                onChanged: (_) => widget.onToggleTheme?.call(),
              ),
            ],
          ),

          // ===== SECCIÓN: Datos =====
          _SectionHeader(title: 'Datos y almacenamiento'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Exportar todos los cuadernos'),
                subtitle: const Text('Guarda un ZIP con todo tu contenido'),
                onTap: _exportAll,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload_outlined),
                title: const Text('Importar respaldo'),
                subtitle: const Text('Restaura desde un ZIP anterior'),
                onTap: _importAll,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Intervalo de autoguardado'),
                subtitle: Text(_autosaveLabel(_autosaveInterval)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAutosavePicker,
              ),
            ],
          ),

          // ===== SECCIÓN: Herramientas =====
          _SectionHeader(title: 'Herramientas'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('Estadísticas de escritura'),
                subtitle: const Text('Trazos, páginas, rachas y actividad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WritingStatsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.alarm_outlined),
                title: const Text('Recordatorios'),
                subtitle: const Text('Vinculados a tus cuadernos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReminderScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // ===== SECCIÓN: Acerca de =====
          _SectionHeader(title: 'Acerca de'),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Inklus'),
                subtitle: Text('Versión 1.0.0 — App de escritura a mano'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('Código abierto'),
                subtitle: Text(
                  'Inklus es open source y gratuito. Sin funciones premium.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _signIn() async {
    setState(() => _syncing = true);
    try {
      final ok = await _syncService.signIn();
      if (ok && mounted) {
        _snack('Conectado como ${_syncService.email}');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Se cerrará la sesión de Google Drive. '
          'Los respaldos existentes no se eliminarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _syncService.signOut();
    if (mounted) _snack('Sesión cerrada');
  }

  Future<void> _backupNow() async {
    setState(() => _syncing = true);
    try {
      // A8: backup individual por Note (no el Document completo).
      // Iteramos notebooks → notes y subimos cada Note por separado.
      final metas = await _storage.loadIndex();
      var noteCount = 0;
      for (final meta in metas) {
        if (!meta.isSyncEnabled) continue;
        try {
          final nb = await _storage.loadNotebook(meta.id);
          if (nb == null) continue;
          for (final note in nb.notes) {
            await _syncService.backupNote(note, promptForConsent: true);
            noteCount++;
          }
        } catch (_) {}
      }
      if (mounted) {
        _snack(noteCount > 0
            ? '$noteCount nota(s) sincronizada(s)'
            : 'No hay cuadernos para respaldar');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _exportAll() async {
    try {
      _snack('Preparando respaldo completo...');
      final bytes = await _storage.exportFullBackup();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Guardar respaldo Inklus',
        fileName: 'inklus_backup.zip',
        bytes: bytes,
      );
      if (saved != null && mounted) {
        _snack('Respaldo exportado');
      }
    } catch (e) {
      if (mounted) _snack('Error al exportar: $e');
    }
  }

  Future<void> _importAll() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      if (files.isEmpty) return;
      final bytes = await files.first.xFile.readAsBytes();
      final count = await _storage.importFullBackup(bytes);
      if (mounted) {
        _snack('$count cuaderno(s) importado(s)');
      }
    } catch (e) {
      if (mounted) _snack('Error al importar: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}
