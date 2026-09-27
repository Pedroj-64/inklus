// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:typed_data';


import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/document.dart';
import '../models/id.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import 'inklus_format.dart';
import 'backup_crypto.dart';
import 'storage_service.dart';

/// Estados de sincronización de un cuaderno con Google Drive.
enum SyncStatus {
  /// Sincronizado correctamente (la copia local coincide con Drive).
  synced,

  /// Sincronización en curso (subiendo o descargando).
  syncing,

  /// Error en la última operación de sincronización.
  error,

  /// Este cuaderno no está marcado para sincronización.
  disabled,

  /// Aún no se ha intentado sincronizar.
  pending,
}

/// Resultado de listar versiones de un cuaderno en Drive.
class DriveVersion {
  final String fileId;
  final String name;
  final DateTime modifiedTime;
  final int sizeBytes;

  const DriveVersion({
    required this.fileId,
    required this.name,
    required this.modifiedTime,
    required this.sizeBytes,
  });
}

/// Resultado de restaurar desde Drive: puede incluir múltiples versiones
/// cuando hay un conflicto (dos dispositivos editaron el mismo cuaderno
/// sin conexión).
///
/// **C5**: Cuando dos dispositivos editan el mismo cuaderno sin conexión,
/// el usuario puede elegir conservar la versión más reciente o ver ambas.
class RestoreResult {
  /// La versión más reciente (last-write-wins por defecto).
  final Document? latest;

  /// Todas las versiones encontradas (más reciente primero).
  /// Si solo hay una versión, [versions] tiene un solo elemento.
  /// Si hay múltiples, la UI puede mostrar un diálogo de resolución.
  final List<Document> versions;

  /// Si hay conflicto (múltiples versiones con updatedAt diferente).
  final bool hasConflict;

  const RestoreResult({
    this.latest,
    this.versions = const [],
    this.hasConflict = false,
  });
}

/// Sincronización con **Google Drive** (respaldo opcional).
///
/// Modelo **offline-first**:
/// - Todo el contenido (trazos, páginas, plantillas e **imágenes**) vive en el
///   dispositivo; la app funciona 100% sin red ni cuenta.
/// - Si el usuario inicia sesión, cada guardado local replica el cuaderno a
///   una carpeta "Inklus" en su Drive con el scope `drive.file` (la app solo
///   ve/crea sus propios archivos; 15 GB gratis).
/// - El respaldo usa el formato propio **.inklus** ([InklusFormat]): un único
///   archivo autocontenido por cuaderno con el documento y sus imágenes
///   embebidas, igual que hacen las apps del mercado (.goodnotes / .sdoc).
///
/// La sesión de Google se restaura silenciosamente al arrancar
/// ([restoreSession]); los tokens de acceso se piden con
/// `authorizationForScopes` (silencioso) y solo se fuerza el consentimiento
/// en acciones explícitas del usuario (botón ☁️ → "Subir ahora").
class DriveSyncService extends ChangeNotifier {
  DriveSyncService._();

  /// Instancia única: la sesión y el estado de sincronización se comparten
  /// entre la biblioteca y el editor.
  static final DriveSyncService instance = DriveSyncService._();

  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const _folderName = 'Inklus';
  static const _folderMimeType = 'application/vnd.google-apps.folder';
  static const _inklusMimeType = 'application/x-inklus';

  /// Cliente OAuth **web** del proyecto de Google Cloud (el mismo que
  /// `default_web_client_id` en `android/app/src/main/res/values/strings.xml`).
  /// En Android, Credential Manager lo exige como `serverClientId`; se pasa
  /// explícito para no depender de que el recurso sobreviva al shrinker.
  static const _serverClientId =
      '895214163532-kbqh115nrc5417lbs3b1sqmsguqqeje4.apps.googleusercontent.com';

  GoogleSignInAccount? _account;
  bool _restoreAttempted = false;

  /// google_sign_in 7 exige `initialize()` **una sola vez** y esperar a que
  /// termine antes de cualquier otra llamada (si no, el sign-in falla con
  /// "serverClientId must be provided").
  Future<void>? _initFuture;
  Future<void> _ensureInitialized() => _initFuture ??= GoogleSignIn.instance
      .initialize(serverClientId: _serverClientId)
      .catchError((Object e) {
        _initFuture = null; // permitir reintentar
        throw e;
      });

  /// Estado de sincronización por id de documento.
  final Map<String, SyncStatus> _syncStatus = {};

  /// Callback notificado cuando termina un backup/restore (para toast).
  void Function(String message)? onSyncComplete;

  bool get isSignedIn => _account != null;
  String? get email => _account?.email;

  /// La integración con Drive no requiere configuración previa (los clientes
  /// OAuth viajan en el APK). Se conserva la propiedad para no tocar la UI.
  bool get isConfigured => true;

  /// Estado de sincronización de un cuaderno.
  SyncStatus statusFor(String documentId) =>
      _syncStatus[documentId] ?? SyncStatus.pending;

  /// Actualiza el estado de un cuaderno y notifica a los listeners.
  void _setStatus(String documentId, SyncStatus status) {
    _syncStatus[documentId] = status;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Sesión
  // -------------------------------------------------------------------------

  /// Restaura la sesión previa sin interacción (One Tap en Android) o
  /// devuelve null si no hay sesión. Se llama al arrancar la app.
  Future<void> restoreSession() async {
    if (_account != null || _restoreAttempted) return;
    _restoreAttempted = true;
    // Google Sign-In no está soportado en Linux desktop.
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    try {
      await _ensureInitialized();
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = future == null ? null : await future;
      if (account != null) {
        _account = account;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DriveSyncService.restoreSession: $e');
    }
  }

  /// Inicia sesión interactiva. Devuelve false si el usuario canceló.
  Future<bool> signIn() async {
    GoogleSignInAccount account;
    try {
      await _ensureInitialized();
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const [_driveScope],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      // clientConfigurationError: el OAuth client ID no coincide con
      // la SHA-1 del keystore o no está habilitado en Google Cloud.
      if (e.code ==
          // ignore: lines_longer_than_80_chars
          GoogleSignInExceptionCode.clientConfigurationError) {
        throw GoogleConfigException(
          'Error de configuración Google (clientConfigurationError).\n\n'
          'Causa probable: la SHA-1 del keystore de firma no está registrada '
          'en Google Cloud Console para el package com.inklus.inklus.\n\n'
          'Solución:\n'
          '1. Obtén la SHA-1: keytool -list -v -alias androiddebugkey \\\n' '             -keystore ~/.android/debug.keystore -storepass android\n'
          '2. Ve a Google Cloud Console → APIs y servicios → Credenciales\n'
          '3. Crea/edita el OAuth client ID Android con package '
          'com.inklus.inklus y la SHA-1 obtenida\n'
          '4. Habilita Google Sign-In en la pantalla de consentimiento\n\n'
          'Error original: ${e.description}',
        );
      }
      rethrow;
    }
    _account = account;
    notifyListeners();
    return true;
  }

  /// Cierra sesión y limpia el estado.
  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    _account = null;
    _syncStatus.clear();
    notifyListeners();
  }

  /// Cambia a otra cuenta Google (cierra sesión y abre el selector).
  Future<bool> switchAccount() async {
    await signOut();
    return signIn();
  }

  /// Token de acceso silencioso para Drive si ya está autorizado; null si
  /// haría falta mostrar consentimiento.
  Future<String?> _silentToken() async {
    final account = _account;
    if (account == null) return null;
    try {
      final authz = await account.authorizationClient
          .authorizationForScopes(const [_driveScope]);
      return authz?.accessToken;
    } catch (e) {
      debugPrint('DriveSyncService._silentToken: $e');
      return null;
    }
  }

  /// Token de acceso pidiendo consentimiento si es necesario. Solo debe
  /// llamarse desde interacción del usuario (p. ej. el botón ☁️).
  Future<String> _interactiveToken() async {
    final account = _account;
    if (account == null) throw const NotSignedInException();
    final authz = await account.authorizationClient
        .authorizeScopes(const [_driveScope]);
    return authz.accessToken;
  }

  /// Cliente HTTP con el token de acceso como cabecera de autorización.
  http.Client _authClient(String token) => _BearerClient(token);

  // -------------------------------------------------------------------------
  // Backup / restauración (Drive API)
  // -------------------------------------------------------------------------

  /// Sube el cuaderno a la carpeta "Inklus" de Drive como `<id>.inklus`
  /// (contenedor autocontenido con documento + imágenes embebidas).
  ///
  /// Por defecto es silencioso (si el scope aún no está autorizado, se omite
  /// sin mostrar UI — el guardado local ya protege los datos). Con
  /// [promptForConsent] = true fuerza el consentimiento si hiciera falta
  /// (acción explícita del usuario).
  ///
  /// [password] opcional: si se pasa, el archivo .inklus se cifra con esa
  /// contraseña (usa AES-256 del paquete `archive`).
  Future<void> backupDocument(
    Document document, {
    bool promptForConsent = false,
    String? password,
  }) async {
    if (_account == null) throw const NotSignedInException();
    _setStatus(document.id, SyncStatus.syncing);
    final token = promptForConsent
        ? await _interactiveToken()
        : await _silentToken();
    if (token == null) {
      _setStatus(document.id, SyncStatus.pending);
      return; // sin autorización silenciosa: se omite
    }

    try {
      var bytes = await InklusFormat.exportBytes(document);

      // Cifrar si se proporciona contraseña.
      if (password != null && password.isNotEmpty) {
        bytes = await _encryptBytes(bytes, password);
      }

      final client = _authClient(token);
      try {
        final api = drive.DriveApi(client);
        final folderId = await _ensureFolder(api);
        final name = '${document.id}.inklus';
        final existing = await _findFile(api, folderId, name);
        final media = commons.Media(
          Stream<List<int>>.value(bytes),
          bytes.length,
          contentType: _inklusMimeType,
        );
        if (existing == null) {
          await api.files.create(
            drive.File(
              name: name,
              mimeType: _inklusMimeType,
              parents: [folderId],
            ),
            uploadMedia: media,
          );
        } else {
          await api.files.update(
            drive.File(name: name, mimeType: _inklusMimeType),
            existing.id!,
            uploadMedia: media,
          );
        }
      } finally {
        client.close();
      }
      _setStatus(document.id, SyncStatus.synced);
      onSyncComplete?.call('Cuaderno sincronizado con Google Drive');
    } catch (e) {
      _setStatus(document.id, SyncStatus.error);
      rethrow;
    }
  }

  /// Sube un archivo .inklus existente (exportado por el usuario) a Drive.
  Future<void> uploadInklusFile(
    Uint8List bytes,
    String fileName, {
    bool promptForConsent = false,
  }) async {
    if (_account == null) throw const NotSignedInException();
    final token = promptForConsent
        ? await _interactiveToken()
        : await _silentToken();      if (token == null) return;

      final client = _authClient(token);
      try {
        final api = drive.DriveApi(client);
        final folderId = await _ensureFolder(api);
        // ignore: unnecessary_lambdas
        final existing = await _findFile(api, folderId, fileName);
      final media = commons.Media(
        Stream<List<int>>.value(bytes),
        bytes.length,
        contentType: _inklusMimeType,
      );
      if (existing == null) {
        await api.files.create(
          drive.File(
            name: fileName,
            mimeType: _inklusMimeType,
            parents: [folderId],
          ),
          uploadMedia: media,
        );
      } else {
        await api.files.update(
          drive.File(name: fileName, mimeType: _inklusMimeType),
          existing.id!,
          uploadMedia: media,
        );
      }
    } finally {
      client.close();
    }
    onSyncComplete?.call('Archivo subido a Google Drive');
  }

  /// Lista versiones de notas en Drive, opcionalmente filtrado por noteId.
  ///
  /// Sin [noteId] devuelve todos los archivos .inklus de la carpeta.
  /// Con [noteId] filtra solo los archivos que empiezan por ese id.
  /// Devuelve una lista de [DriveVersion] ordenadas de más reciente a más
  /// antigua. Útil para que el usuario elija cuál restaurar.
  Future<List<DriveVersion>> listVersions({String? noteId}) async {
    if (_account == null) throw const NotSignedInException();
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureFolder(api);
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id,name,modifiedTime,size)',
        orderBy: 'modifiedTime desc',
      );
      final files = list.files ?? [];
      final versions = <DriveVersion>[];
      for (final file in files) {
        final id = file.id;
        final name = file.name ?? '';
        if (id == null || !name.endsWith('.inklus')) continue;
        if (noteId != null && !name.startsWith(noteId)) continue;
        versions.add(DriveVersion(
          fileId: id,
          name: name,
          modifiedTime: file.modifiedTime ?? DateTime.now(),
          sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
        ));
      }
      return versions;
    } finally {
      client.close();
    }
  }

  /// Descarga una versión específica de Drive por fileId.
  ///
  /// [password] opcional: si el archivo estaba cifrado, se descifra con
  /// esta contraseña. Devuelve null si no se pudo leer.
  Future<Document?> downloadVersion(String fileId, {String? password}) async {
    if (_account == null) throw const NotSignedInException();
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final resp = await client.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
      );
      if (resp.statusCode != 200) return null;
      var bytes = resp.bodyBytes;
      if (password != null && password.isNotEmpty) {
        bytes = await _decryptBytes(bytes, password);
      }
      return await InklusFormat.importBytes(bytes);
    } catch (e) {
      debugPrint('DriveSyncService.downloadVersion: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Descarga las copias `.inklus` del usuario y devuelve la más reciente
  /// (por `updatedAt` del documento), con las imágenes ya extraídas a local.
  /// Devuelve null si no hay ninguna.
  ///
  /// Implementa **last-write-wins** por defecto, pero también devuelve
  /// todas las versiones para que la UI pueda mostrar un diálogo de
  /// resolución de conflictos cuando hay múltiples versiones.
  ///
  /// **C5**: Cuando dos dispositivos editan el mismo cuaderno sin conexión,
  /// el usuario puede elegir conservar la versión más reciente o ver ambas.
  Future<RestoreResult> restoreDocument({String? password}) async {
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureFolder(api);
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id,name)',
      );
      final files = list.files ?? [];

      Document? latest;
      DateTime? latestUpdated;
      final versions = <Document>[];

      for (final file in files) {
        final id = file.id;
        final name = file.name ?? '';
        if (id == null || !name.endsWith('.inklus')) continue;
        try {
          final resp = await client.get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files/$id?alt=media',
            ),
          );
          if (resp.statusCode != 200) continue;
          var bytes = resp.bodyBytes;
          if (password != null && password.isNotEmpty) {
            bytes = await _decryptBytes(bytes, password);
          }
          final doc = await InklusFormat.importBytes(bytes);
          versions.add(doc);
          if (latest == null || doc.updatedAt.isAfter(latestUpdated!)) {
            latest = doc;
            latestUpdated = doc.updatedAt;
          }
        } catch (e) {
          debugPrint('DriveSyncService: copia no legible ($name): $e');
        }
      }

      // Detectar conflicto: múltiples versiones con updatedAt diferente
      final hasConflict = versions.length > 1 &&
          versions.any((v) => v.updatedAt != latest!.updatedAt);

      if (latest != null) {
        onSyncComplete?.call(
          hasConflict
              ? 'Conflicto detectado: ${versions.length} versiones encontradas'
              : 'Cuaderno restaurado desde Google Drive',
        );
      }

      return RestoreResult(
        latest: latest,
        versions: versions,
        hasConflict: hasConflict,
      );
    } finally {
      client.close();
    }
  }

  /// Elimina un archivo de Drive por fileId.
  Future<void> deleteFile(String fileId) async {
    if (_account == null) throw const NotSignedInException();
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final api = drive.DriveApi(client);
      await api.files.delete(fileId);
    } finally {
      client.close();
    }
  }

  // -------------------------------------------------------------------------
  // Cifrado AES-256-GCM (ver BackupCrypto)
  // -------------------------------------------------------------------------

  Future<Uint8List> _encryptBytes(Uint8List data, String password) =>
      BackupCrypto.encrypt(data, password);

  Future<Uint8List> _decryptBytes(Uint8List data, String password) =>
      BackupCrypto.decrypt(data, password);

  // -------------------------------------------------------------------------
  // Helpers Drive
  // -------------------------------------------------------------------------

  /// Busca (o crea) la carpeta "Inklus" y devuelve su id.
  Future<String> _ensureFolder(drive.DriveApi api) async {
    final existing = await api.files.list(
      q: "name = '$_folderName' and "
          "mimeType = '$_folderMimeType' and trashed = false",
      $fields: 'files(id)',
    );
    final files = existing.files ?? [];
    if (files.isNotEmpty && files.first.id != null) {
      return files.first.id!;
    }
    final folder = await api.files.create(
      drive.File(name: _folderName, mimeType: _folderMimeType),
    );
    return folder.id!;
  }

  /// Busca un archivo por nombre dentro de la carpeta.
  Future<drive.File?> _findFile(
    drive.DriveApi api,
    String folderId,
    String name,
  ) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and "
          "name = '$name' and trashed = false",
      $fields: 'files(id)',
    );
    final files = result.files ?? [];
    return files.isEmpty ? null : files.first;
  }

  // -------------------------------------------------------------------------
  // Variantes para Note (nuevo formato v2)
  // -------------------------------------------------------------------------

  /// Sube un Note individual a Drive como archivo .inklus.
  ///
  /// Cada Note se sincroniza por separado para minimizar tráfico y conflictos.
  Future<void> backupNote(
    Note note, {
    bool promptForConsent = false,
    String? password,
  }) async {
    if (_account == null) throw const NotSignedInException();
    _setStatus(note.id, SyncStatus.syncing);
    final token = promptForConsent
        ? await _interactiveToken()
        : await _silentToken();
    if (token == null) {
      _setStatus(note.id, SyncStatus.pending);
      return;
    }

    try {
      var bytes = await InklusFormat.exportNoteBytes(note);
      if (password != null && password.isNotEmpty) {
        bytes = await _encryptBytes(bytes, password);
      }

      final client = _authClient(token);
      try {
        final api = drive.DriveApi(client);
        final folderId = await _ensureFolder(api);
        final name = '${note.id}.inklus';
        final existing = await _findFile(api, folderId, name);
        final media = commons.Media(
          Stream<List<int>>.value(bytes),
          bytes.length,
          contentType: _inklusMimeType,
        );
        if (existing == null) {
          await api.files.create(
            drive.File(
              name: name,
              mimeType: _inklusMimeType,
              parents: [folderId],
            ),
            uploadMedia: media,
          );
        } else {
          await api.files.update(
            drive.File(name: name, mimeType: _inklusMimeType),
            existing.id!,
            uploadMedia: media,
          );
        }
        _setStatus(note.id, SyncStatus.synced);
        onSyncComplete?.call('Nota sincronizada con Google Drive');
      } finally {
        client.close();
      }
    } catch (e) {
      _setStatus(note.id, SyncStatus.error);
      rethrow;
    }
  }

  /// Descarga un Note desde Drive (last-write-wins).
  Future<Note?> restoreNote({
    required String noteId,
    String? password,
  }) async {
    if (_account == null) throw const NotSignedInException();
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureFolder(api);
      final name = '$noteId.inklus';
      final file = await _findFile(api, folderId, name);
      if (file == null) return null;

      final response = await api.files.get(
        file.id!,
        downloadOptions: commons.DownloadOptions.fullMedia,
      );
      if (response is! commons.Media) return null;
      final stream = response.stream;
      final bytesBuilder = BytesBuilder();
      await for (final chunk in stream) {
        bytesBuilder.add(chunk);
      }
      var rawBytes = bytesBuilder.toBytes();
      if (password != null && password.isNotEmpty) {
        rawBytes = await _decryptBytes(rawBytes, password);
      }
      return await InklusFormat.importNoteBytes(rawBytes);
    } finally {
      client.close();
    }
  }

  /// Descarga **todas** las notas `.inklus` de la carpeta "Inklus" de Drive
  /// (las imágenes embebidas se extraen a local). Las copias ilegibles se
  /// omiten.
  Future<List<Note>> downloadAllNotes({String? password}) async {
    if (_account == null) throw const NotSignedInException();
    final token = await _interactiveToken();
    final client = _authClient(token);
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureFolder(api);
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id,name)',
      );
      final notes = <Note>[];
      for (final file in list.files ?? const <drive.File>[]) {
        final id = file.id;
        final name = file.name ?? '';
        if (id == null || !name.endsWith('.inklus')) continue;
        try {
          final resp = await client.get(
            Uri.parse('https://www.googleapis.com/drive/v3/files/$id?alt=media'),
          );
          if (resp.statusCode != 200) continue;
          var bytes = resp.bodyBytes;
          if (password != null && password.isNotEmpty) {
            bytes = await _decryptBytes(bytes, password);
          }
          notes.add(await InklusFormat.importNoteBytes(bytes));
        } catch (e) {
          debugPrint('DriveSyncService.downloadAllNotes: copia no legible ($name): $e');
        }
      }
      return notes;
    } finally {
      client.close();
    }
  }

  /// Restaura la biblioteca desde Drive (**last-write-wins** por nota):
  /// - si la nota existe en local y la de Drive es más reciente, se actualiza
  ///   en su cuaderno;
  /// - si no existe (p. ej. en un dispositivo nuevo), se reúne en un cuaderno
  ///   "Recuperado de Drive" (Drive guarda notas sueltas, no los cuadernos).
  Future<LibraryRestoreResult> restoreLibrary(StorageService storage) async {
    final remote = await downloadAllNotes();
    // noteId → (cuaderno, nota local)
    final local = <String, (String, Note)>{};
    for (final meta in await storage.loadIndex()) {
      final nb = await storage.loadNotebook(meta.id);
      if (nb == null) continue;
      for (final n in nb.notes) {
        local[n.id] = (nb.id, n);
      }
    }
    var updated = 0;
    final missing = <Note>[];
    for (final note in remote) {
      final hit = local[note.id];
      if (hit == null) {
        missing.add(note);
      } else if (note.updatedAt.isAfter(hit.$2.updatedAt)) {
        await storage.saveNote(hit.$1, note);
        updated++;
      }
    }
    if (missing.isNotEmpty) {
      missing.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      await storage.saveNotebook(Notebook(
        id: newId('nb'),
        title: 'Recuperado de Drive',
        notes: missing,
      ));
    }
    return LibraryRestoreResult(
      found: remote.length,
      updated: updated,
      added: missing.length,
    );
  }
}

/// Resumen de [DriveSyncService.restoreLibrary].
class LibraryRestoreResult {
  const LibraryRestoreResult({
    required this.found,
    required this.updated,
    required this.added,
  });

  /// Notas encontradas en Drive.
  final int found;

  /// Notas locales reemplazadas por una versión más reciente de Drive.
  final int updated;

  /// Notas que no existían en local (van a "Recuperado de Drive").
  final int added;

  String get message {
    if (found == 0) return 'No hay copias de Inklus en tu Google Drive';
    if (updated == 0 && added == 0) return 'Todo está al día: nada que restaurar';
    return [
      if (updated > 0) '$updated nota(s) actualizada(s)',
      if (added > 0) '$added recuperada(s) en "Recuperado de Drive"',
    ].join(' · ');
  }
}

/// Cliente HTTP mínimo que añade `Authorization: Bearer <token>` a cada
/// petición (googleapis_auth no expone su `AuthenticatedClient` como API
/// pública, así que usamos nuestro propio wrapper sobre `http`).
class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);

  final String _token;
  final http.Client _inner = http.Client();

  /// Tiempo máximo hasta recibir la respuesta (cabeceras). Sin él, una red
  /// que se queda colgada dejaba el ☁️ "sincronizando" para siempre.
  static const _timeout = Duration(seconds: 60);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request).timeout(_timeout);
  }

  @override
  void close() => _inner.close();
}

/// Se requiere iniciar sesión con Google antes de subir/restaurar.
class NotSignedInException implements Exception {
  const NotSignedInException();

  @override
  String toString() => 'Inicia sesión con Google primero.';
}

/// Error de configuración OAuth de Google (SHA-1 no registrada, etc.).
///
/// Propaga un mensaje de ayuda al usuario en lugar de un stack trace críptico.
class GoogleConfigException implements Exception {
  final String message;
  const GoogleConfigException(this.message);

  @override
  String toString() => message;
}
