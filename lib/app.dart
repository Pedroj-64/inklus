import 'package:flutter/material.dart';

import 'constants.dart';
import 'ui/notebook_library.dart';
import 'ui/onboarding_screen.dart';
import 'ui/settings_screen.dart';

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
  ThemeMode _themeMode = ThemeMode.system;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingScreen.shouldShow();
    if (mounted) setState(() => _showOnboarding = shouldShow);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: kAccentColor,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: kAccentColor,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Inklus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kScaffoldLight,
        visualDensity: VisualDensity.comfortable,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kScaffoldDark,
        visualDensity: VisualDensity.comfortable,
      ),
      themeMode: _themeMode,
      home: _showOnboarding
          ? OnboardingScreen(
              onDone: () => setState(() => _showOnboarding = false),
            )
          : NotebookLibraryScreen(
              onToggleTheme: _toggleTheme,
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      onToggleTheme: _toggleTheme,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
