// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Delegados de la app. No usar `kLocalizationsDelegates`:
/// gen-l10n aún genera los de `flutter_localizations`, que desde Flutter 3.50
/// no sirven a los widgets de `material_ui` (salían sin textos de Material).
const List<LocalizationsDelegate<dynamic>> kLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Acceso corto a los textos traducidos: `context.l10n.settingsTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
