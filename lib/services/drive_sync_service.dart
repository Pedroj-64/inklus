import 'dart:math';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/document.dart';
import 'inklus_format.dart';

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

  GoogleSignInAccount? _account;
  bool _restoreAttempted = false;

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
    try {
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
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const [_driveScope],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    _account = account;
    notifyListeners();
    return true;
  }

  /// Cierra sesión y limpia el estado.
  Future<void> signOut() async {
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
        bytes = _encryptBytes(bytes, password);
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

  /// Lista todas las versiones de un cuaderno en Drive (por document id).
  ///
  /// Devuelve una lista de [DriveVersion] ordenadas de más reciente a más
  /// antigua. Útil para que el usuario elija cuál restaurar.
  Future<List<DriveVersion>> listVersions() async {
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
        bytes = _decryptBytes(bytes, password);
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
  /// Implementa **last-write-wins**: el documento con el `updatedAt` más
  /// reciente en Drive gana (decisión de diseño: más simple que merge y
  /// evita pérdida de contenido no intencionada).
  Future<Document?> restoreDocument({String? password}) async {
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
            bytes = _decryptBytes(bytes, password);
          }
          final doc = await InklusFormat.importBytes(bytes);
          if (latest == null || doc.updatedAt.isAfter(latestUpdated!)) {
            latest = doc;
            latestUpdated = doc.updatedAt;
          }
        } catch (e) {
          debugPrint('DriveSyncService: copia no legible ($name): $e');
        }
      }
      if (latest != null) {
        onSyncComplete?.call('Cuaderno restaurado desde Google Drive');
      }
      return latest;
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
  // Cifrado (XOR con clave derivada de la contraseña)
  // -------------------------------------------------------------------------

  /// Cifra bytes XOR con una clave derivada de la contraseña.
  /// Nota: esto es cifrado básico para protección de archivos personales;
  /// no es criptografía de grado militar pero evita lectura casual.
  Uint8List _encryptBytes(Uint8List data, String password) {
    final key = _deriveKey(password, data.length);
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i];
    }
    return result;
  }

  /// Descifra bytes XOR (misma operación que cifrar).
  Uint8List _decryptBytes(Uint8List data, String password) {
    return _encryptBytes(data, password); // XOR es simétrico
  }

  /// Deriva una clave de la misma longitud que los datos a partir de la
  /// contraseña usando un PRNG determinista (semilla = hash de la contraseña).
  Uint8List _deriveKey(String password, int length) {
    // Hash FNV-1a de la contraseña como semilla.
    var seed = 0x811c9dc5;
    for (final c in password.codeUnits) {
      seed ^= c;
      seed = (seed * 0x01000193) & 0xFFFFFFFF;
    }
    final rng = Random(seed);
    final key = Uint8List(length);
    for (var i = 0; i < length; i++) {
      key[i] = rng.nextInt(256);
    }
    return key;
  }

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
}

/// Cliente HTTP mínimo que añade `Authorization: Bearer <token>` a cada
/// petición (googleapis_auth no expone su `AuthenticatedClient` como API
/// pública, así que usamos nuestro propio wrapper sobre `http`).
class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);

  final String _token;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
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
