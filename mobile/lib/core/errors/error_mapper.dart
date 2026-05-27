import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

AppException mapToAppException(Object error) {
  if (error is AppException) return error;

  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return AppException(
        code: AppExceptionCodes.invalidCredentials,
        message: 'E-mail ou senha inválidos.',
        cause: error,
      );
    }
    return AppException(
      code: AppExceptionCodes.unauthorized,
      message: error.message,
      cause: error,
    );
  }

  if (error is PostgrestException) {
    if (error.code == 'PGRST116') {
      return AppException(
        code: AppExceptionCodes.profileNotFound,
        message: 'Perfil não encontrado para este usuário.',
        cause: error,
      );
    }
    return AppException(
      code: AppExceptionCodes.unknown,
      message: error.message,
      cause: error,
      details: {'code': error.code},
    );
  }

  return AppException(
    code: AppExceptionCodes.unknown,
    message: 'Ocorreu um erro inesperado. Tente novamente.',
    cause: error,
  );
}

String userMessageFor(AppException error) => error.message;
