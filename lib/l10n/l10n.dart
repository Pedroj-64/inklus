// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Acceso corto a los textos traducidos: `context.l10n.settingsTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
