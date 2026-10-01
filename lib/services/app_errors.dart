// SPDX-License-Identifier: GPL-3.0-or-later
import '../l10n/l10n.dart';
import 'drive_sync_service.dart';

/// Errores de la app que el usuario puede ver. Llevan un **código** (no un
/// texto): la UI los traduce con [userError].
///
/// Extiende [FormatException] para que los `on FormatException` y los tests
/// existentes sigan funcionando.
enum AppErrorCode { notInklus, notInklusFile, notInklusV2, catalogTooLarge, catalogVersion }

class AppError extends FormatException {
  const AppError(this.code, [this.detail = '']) : super('');

  final AppErrorCode code;
  final String detail;

  @override
  String toString() => 'AppError(${code.name}${detail.isEmpty ? '' : ': $detail'})';

  String text(AppLocalizations l10n) => switch (code) {
        AppErrorCode.notInklus => l10n.errNotInklus,
        AppErrorCode.notInklusFile => l10n.errNotInklusFile,
        AppErrorCode.notInklusV2 => l10n.errNotInklusV2,
        AppErrorCode.catalogTooLarge => l10n.errCatalogTooLarge,
        AppErrorCode.catalogVersion => l10n.errCatalogVersion(detail),
      };
}

/// Texto traducido de un error para mostrar al usuario.
String userError(AppLocalizations l10n, Object e) => switch (e) {
      AppError() => e.text(l10n),
      NotSignedInException() => l10n.errNotSignedIn,
      EncryptedBackupException() => l10n.errEncrypted,
      UnsupportedError() => l10n.errOcrUnsupported,
      FormatException() when e.message.isNotEmpty => e.message,
      _ => l10n.commonError('$e'),
    };
