import 'package:flutter/material.dart';

import 'ui/notebook_library.dart';

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
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Inklus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEFEDE8),
        visualDensity: VisualDensity.comfortable,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1B1E),
        visualDensity: VisualDensity.comfortable,
      ),
      themeMode: _themeMode,
      home: NotebookLibraryScreen(onToggleTheme: _toggleTheme),
    );
  }
}
