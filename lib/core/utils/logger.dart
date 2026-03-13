import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(message, name: tag ?? 'SafeRide');
    }
  }

  static void info(String message, {String? tag}) {
    dev.log('[INFO] $message', name: tag ?? 'SafeRide');
  }

  static void warning(String message, {String? tag}) {
    dev.log('[WARN] $message', name: tag ?? 'SafeRide');
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '[ERROR] $message',
      name: tag ?? 'SafeRide',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '[CRITICAL] $message',
      name: tag ?? 'SafeRide',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
