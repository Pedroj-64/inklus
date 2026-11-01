// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'l10n/l10n.dart';

import 'services/low_power_mode.dart';
import 'theme_controller.dart';
import 'ui/theme/app_theme.dart';
import 'ui/notebook_library.dart';
import 'ui/onboarding_screen.dart';

/// Widget raíz de Inklus.
///
/// Soporta tema claro y oscuro. El usuario puede alternar desde la
/// configuración del sistema o desde un toggle manual.
class InklusApp extends StatefulWidget {
  /// Solo para tests: fija el idioma (null = el del sistema).
  const InklusApp({super.key, this.locale});

  final Locale? locale;

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
    LowPowerMode.load();
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
      // Sin `locale`: sigue el idioma del sistema; si no hay traducción, inglés.
      locale: widget.locale,
      localeListResolutionCallback: resolveAppLocale,
      home: _showOnboarding
          ? OnboardingScreen(
              onDone: () => setState(() => _showOnboarding = false),
            )
          : const NotebookLibraryScreen(),
      ),
    );
  }
}

/// Primer idioma preferido del sistema que Inklus traduce (es, en, pt, fr, de);
/// si ninguno, inglés (sin esto caería en el primero de la lista: alemán).
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final p in preferred ?? const <Locale>[]) {
    for (final s in supported) {
      if (s.languageCode == p.languageCode) return s;
    }
  }
  return const Locale('en');
}
