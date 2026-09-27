// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'l10n/l10n.dart';

import 'theme_controller.dart';
import 'constants.dart';
import 'ui/theme/app_theme.dart';
import 'ui/notebook_library.dart';
import 'ui/onboarding_screen.dart';

/// Widget raíz de Inklus.
///
/// Soporta tema claro y oscuro. El usuario puede alternar desde la
/// configuración del sistema o desde un toggle manual.
class InklusApp extends StatefulWidget {
  const InklusApp({super.key});

  @override
  State<InklusApp> createState() => _InklusAppState();
}

class _InklusAppState extends State<InklusApp> {
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    ThemeModeController.load();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingScreen.shouldShow();
    if (mounted) setState(() => _showOnboarding = shouldShow);
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.mode,
      builder: (context, themeMode, _) => MaterialApp(
      title: 'Inklus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Español fijo hasta que todos los textos estén en los ARB (P2 del
      // roadmap): una interfaz a medio traducir sería peor. Con esto, los
      // selectores de fecha/hora y los textos de Material ya salen en español.
      locale: kAppLocale,
      home: _showOnboarding
          ? OnboardingScreen(
              onDone: () => setState(() => _showOnboarding = false),
            )
          : const NotebookLibraryScreen(),
      ),
    );
  }
}
