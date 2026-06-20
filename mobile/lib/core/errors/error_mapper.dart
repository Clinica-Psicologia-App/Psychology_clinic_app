import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

AppException mapToAppException(Object error) {
  if (error is AppException) return error;

  if (error is AuthException) {
    return _mapAuthException(error);
  }

  if (error is PostgrestException) {
    return _mapPostgrestException(error);
  }

  if (error is FunctionException) {
    return _mapFunctionException(error);
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('connection') ||
      text.contains('network') ||
      text.contains('failed host lookup')) {
    return AppException(
      code: AppExceptionCodes.network,
      message:
          'Sem conexão com o servidor. Verifique a internet e tente de novo.',
      cause: error,
    );
  }

  if (_looksLikeSessionExpired(text)) {
    return AppException(
      code: AppExceptionCodes.sessionExpired,
      message: userMessageForCode(AppExceptionCodes.sessionExpired),
      cause: error,
    );
  }

  return AppException(
    code: AppExceptionCodes.unknown,
    message: 'Ocorreu um erro inesperado. Tente novamente.',
    cause: error,
  );
}

AppException _mapAuthException(AuthException error) {
  final msg = error.message.toLowerCase();

  if (msg.contains('invalid') ||
      msg.contains('credentials') ||
      msg.contains('invalid login')) {
    return AppException(
      code: AppExceptionCodes.invalidCredentials,
      message: 'E-mail ou senha inválidos.',
      cause: error,
    );
  }

  if (msg.contains('database error')) {
    return AppException(
      code: AppExceptionCodes.unknown,
      message:
          'Erro no servidor de autenticação. Verifique o Supabase ou contate o suporte.',
      cause: error,
    );
  }

  if (_looksLikeSessionExpired(msg)) {
    return AppException(
      code: AppExceptionCodes.sessionExpired,
      message: userMessageForCode(AppExceptionCodes.sessionExpired),
      cause: error,
    );
  }

  return AppException(
    code: AppExceptionCodes.unauthorized,
    message: error.message,
    cause: error,
  );
}

AppException _mapPostgrestException(PostgrestException error) {
  final code = error.code ?? '';
  final msg = error.message.toLowerCase();

  if (code == 'PGRST116') {
    return AppException(
      code: AppExceptionCodes.profileNotFound,
      message: 'Perfil não encontrado para este usuário.',
      cause: error,
      details: {'code': code},
    );
  }

  if (code == 'PGRST301' ||
      code == 'PGRST303' ||
      _looksLikeSessionExpired(msg)) {
    return AppException(
      code: AppExceptionCodes.sessionExpired,
      message: userMessageForCode(AppExceptionCodes.sessionExpired),
      cause: error,
      details: {'code': code},
    );
  }

  if (code == '42501' ||
      msg.contains('row-level security') ||
      msg.contains('permission denied') ||
      msg.contains('violates row-level')) {
    return AppException(
      code: AppExceptionCodes.forbidden,
      message:
          'Você não tem permissão para esta ação ou registro (política de segurança).',
      cause: error,
      details: {'code': code},
    );
  }

  if (code == '23505' || msg.contains('duplicate key')) {
    return AppException(
      code: AppExceptionCodes.conflict,
      message: 'Registro duplicado. Verifique os dados enviados.',
      cause: error,
      details: {'code': code},
    );
  }

  if (code == '23503' || msg.contains('foreign key')) {
    return AppException(
      code: AppExceptionCodes.validation,
      message: 'Referência inválida. Atualize a tela e tente novamente.',
      cause: error,
      details: {'code': code},
    );
  }

  return AppException(
    code: AppExceptionCodes.unknown,
    message: _sanitizePostgrestMessage(error.message),
    cause: error,
    details: {'code': code},
  );
}

AppException _mapFunctionException(FunctionException error) {
  final status = error.status;
  final details = error.details;
  Map<String, dynamic>? payload;

  if (details is Map) {
    payload = Map<String, dynamic>.from(details);
  } else if (details is String && details.isNotEmpty) {
    try {
      // ignore: avoid_dynamic_calls
      final decoded = details;
      if (decoded.startsWith('{')) {
        // body may be raw JSON string in some SDK versions
      }
    } catch (_) {}
  }

  if (payload != null && payload['error'] is Map) {
    return mapEdgeErrorPayload(
      Map<String, dynamic>.from(payload['error'] as Map),
      httpStatus: status,
    );
  }

  if (status == 401) {
    return AppException(
      code: AppExceptionCodes.sessionExpired,
      message: userMessageForCode(AppExceptionCodes.sessionExpired),
      cause: error,
      details: {'httpStatus': status},
    );
  }

  if (status == 403) {
    return AppException(
      code: AppExceptionCodes.forbidden,
      message: userMessageForCode(AppExceptionCodes.forbidden),
      cause: error,
      details: {'httpStatus': status},
    );
  }

  if (status == 502 || status == 503 || status == 504) {
    return AppException(
      code: AppExceptionCodes.network,
      message: 'Serviço temporariamente indisponível. Tente novamente.',
      cause: error,
      details: {'httpStatus': status},
    );
  }

  return AppException(
    code: AppExceptionCodes.unknown,
    message: error.reasonPhrase ?? 'Erro ao chamar o servidor.',
    cause: error,
    details: {'httpStatus': status},
  );
}

/// Erro `{ code, message }` das Edge Functions (`ok: false`).
AppException mapEdgeErrorPayload(
  Map<String, dynamic> error, {
  int? httpStatus,
}) {
  final code = error['code']?.toString() ?? AppExceptionCodes.unknown;
  final apiMessage = error['message']?.toString();

  return AppException(
    code: _normalizeApiCode(code),
    message: messageForApiCode(code, apiMessage),
    details: {
      if (error['details'] is Map)
        'details': Map<String, dynamic>.from(error['details'] as Map),
      if (httpStatus != null) 'httpStatus': httpStatus,
    },
  );
}

String _normalizeApiCode(String code) {
  switch (code) {
    case 'UNAUTHORIZED':
      return AppExceptionCodes.sessionExpired;
    case 'FORBIDDEN':
      return AppExceptionCodes.forbidden;
    case 'NOT_FOUND':
      return AppExceptionCodes.notFound;
    case 'VALIDATION_ERROR':
      return AppExceptionCodes.validation;
    case 'CONFLICT':
      return AppExceptionCodes.conflict;
    default:
      return code;
  }
}

String messageForApiCode(String code, String? apiMessage) {
  switch (code) {
    case 'VALIDATION_ERROR':
      return apiMessage ?? 'Dados inválidos. Revise o formulário.';
    case 'UNAUTHORIZED':
      return userMessageForCode(AppExceptionCodes.sessionExpired);
    case 'FORBIDDEN':
      return apiMessage ?? userMessageForCode(AppExceptionCodes.forbidden);
    case 'NOT_FOUND':
      return apiMessage ?? 'Registro não encontrado.';
    case 'INVALID_STATE':
      return apiMessage ?? 'Operação não permitida neste estado.';
    case 'CONFLICT':
      return apiMessage?.contains('Email') == true
          ? 'Este e-mail já está em uso na clínica.'
          : (apiMessage ?? 'Conflito ao salvar. Verifique os dados.');
    case 'INTERNAL_ERROR':
      return 'Erro no servidor. Tente novamente em instantes.';
    default:
      return apiMessage ?? 'Ocorreu um erro. Tente novamente.';
  }
}

String userMessageFor(AppException error) {
  if (error.code == AppExceptionCodes.unknown &&
      error.message.isNotEmpty &&
      !error.message.startsWith('Ocorreu um erro inesperado')) {
    return error.message;
  }
  return userMessageForCode(error.code, fallback: error.message);
}

String userMessageForCode(String code, {String? fallback}) {
  switch (code) {
    case AppExceptionCodes.sessionExpired:
      return 'Sua sessão expirou. Faça login novamente.';
    case AppExceptionCodes.unauthorized:
      return fallback ?? 'Não autorizado. Faça login novamente.';
    case AppExceptionCodes.invalidCredentials:
      return 'E-mail ou senha inválidos.';
    case AppExceptionCodes.profileNotFound:
      return 'Perfil não encontrado para este usuário.';
    case AppExceptionCodes.forbidden:
      return fallback ??
          'Você não tem permissão para esta ação (política de segurança).';
    case AppExceptionCodes.notFound:
      return fallback ?? 'Registro não encontrado.';
    case AppExceptionCodes.validation:
      return fallback ?? 'Dados inválidos. Revise o formulário.';
    case AppExceptionCodes.conflict:
      return fallback ?? 'Conflito ao salvar. Verifique os dados.';
    case AppExceptionCodes.network:
      return 'Sem conexão com o servidor. Verifique a internet.';
    case AppExceptionCodes.unknown:
      return fallback ?? 'Ocorreu um erro inesperado. Tente novamente.';
    default:
      return fallback ?? messageForApiCode(code, fallback);
  }
}

bool _looksLikeSessionExpired(String text) {
  return text.contains('jwt expired') ||
      text.contains('token is expired') ||
      text.contains('session expired') ||
      text.contains('invalid jwt') ||
      text.contains('refresh_token');
}

String _sanitizePostgrestMessage(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('jwt') || lower.contains('permission')) {
    return userMessageForCode(AppExceptionCodes.forbidden);
  }
  if (raw.length > 120) {
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
  return raw;
}
