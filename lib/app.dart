import 'package:flutter/material.dart';

import 'ui/notebook_library.dart';

/// Widget raíz de Inklus.
class InklusApp extends StatelessWidget {
  const InklusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Inklus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEFEDE8),
        visualDensity: VisualDensity.comfortable,
      ),
      home: const NotebookLibraryScreen(),
    );
  }
}
