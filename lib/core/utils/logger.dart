import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static final _phonePattern = RegExp(r'\+?[0-9]{10,15}');

  static String _redactSensitiveData(String message) {
    return message.replaceAll(_phonePattern, '[REDACTED]');
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(
        _redactSensitiveData(message),
        name: tag ?? 'SafeRide',
      );
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(
        '[INFO] ${_redactSensitiveData(message)}',
        name: tag ?? 'SafeRide',
      );
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(
        '[WARN] ${_redactSensitiveData(message)}',
        name: tag ?? 'SafeRide',
      );
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        '[ERROR] ${_redactSensitiveData(message)}',
        name: tag ?? 'SafeRide',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '[CRITICAL] ${_redactSensitiveData(message)}',
      name: tag ?? 'SafeRide',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
