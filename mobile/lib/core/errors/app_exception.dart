/// Erro de domínio/aplicação com código estável para UI e logs.
class AppException implements Exception {
  AppException({
    required this.code,
    required this.message,
    this.cause,
    this.details,
  });

  final String code;
  final String message;
  final Object? cause;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'AppException($code): $message';
}

class AppExceptionCodes {
  static const unauthorized = 'UNAUTHORIZED';
  static const sessionExpired = 'SESSION_EXPIRED';
  static const profileNotFound = 'PROFILE_NOT_FOUND';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const network = 'NETWORK_ERROR';
  static const unknown = 'UNKNOWN_ERROR';
  static const validation = 'VALIDATION_ERROR';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
}
