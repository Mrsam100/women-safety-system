class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException({required this.message, this.code});

  @override
  String toString() => 'ServerException($code: $message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({required this.message, this.code});

  @override
  String toString() => 'AuthException($code: $message)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'No internet connection',
  });

  @override
  String toString() => 'NetworkException: $message';
}

class PermissionException implements Exception {
  final String message;

  const PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class LocationException implements Exception {
  final String message;

  const LocationException({required this.message});

  @override
  String toString() => 'LocationException: $message';
}

class AudioException implements Exception {
  final String message;

  const AudioException({required this.message});

  @override
  String toString() => 'AudioException: $message';
}

class EncryptionException implements Exception {
  final String message;

  const EncryptionException({required this.message});

  @override
  String toString() => 'EncryptionException: $message';
}
