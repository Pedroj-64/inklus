import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura errores no atrapados para depuración en release.
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  runZonedGuarded(
    () => runApp(const InklusApp()),
    (error, stackTrace) {
      debugPrint('Uncaught exception: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
