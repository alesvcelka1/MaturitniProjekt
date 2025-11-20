import 'package:flutter/foundation.dart';

/// Centralizovaný logger pro aplikaci
/// V production módu je logging vypnutý pro lepší výkon
class AppLogger {
  AppLogger._();

  /// Debug log - pouze ve debug režimu
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔍 DEBUG: $message');
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
    }
  }

  /// Info log - obecné informace
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Warning log - varování
  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
      if (error != null) debugPrint('  Error: $error');
    }
  }

  /// Error log - chyby (loguje i v production)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  StackTrace: $stackTrace');
  }

  /// Success log - úspěšné operace
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}
