import 'package:flutter/foundation.dart';

@immutable
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure($code: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_DENIED',
  });
}

class LocationFailure extends Failure {
  const LocationFailure({
    required super.message,
    super.code = 'LOCATION_ERROR',
  });
}

class AudioFailure extends Failure {
  const AudioFailure({
    required super.message,
    super.code = 'AUDIO_ERROR',
  });
}

class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code = 'STORAGE_ERROR',
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
  });
}
