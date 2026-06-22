import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/core/errors/error_mapper.dart';

void main() {
  test('maps RLS PostgrestException to forbidden', () {
    final ex = mapToAppException(
      const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      ),
    );
    expect(ex.code, AppExceptionCodes.forbidden);
  });

  test('maps JWT expired to sessionExpired', () {
    final ex = mapToAppException(
      const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
    );
    expect(ex.code, AppExceptionCodes.sessionExpired);
  });

  test('maps edge UNAUTHORIZED payload', () {
    final ex = mapEdgeErrorPayload({
      'code': 'UNAUTHORIZED',
      'message': 'Token invalid',
    });
    expect(ex.code, AppExceptionCodes.sessionExpired);
    expect(ex.message, contains('sessão expirou'));
  });

  test('maps invalid credentials AuthException', () {
    final ex = mapToAppException(
      const AuthException('Invalid login credentials'),
    );
    expect(ex.code, AppExceptionCodes.invalidCredentials);
  });

  test('messageForApiCode returns validation message', () {
    expect(
      messageForApiCode('VALIDATION_ERROR', 'CPF inválido'),
      'CPF inválido',
    );
  });

  test('maps unavailable Edge Function to a retryable Portuguese message', () {
    final ex = mapToAppException(
      const FunctionException(
        status: 503,
        reasonPhrase: 'Service Temporarily Unavailable',
      ),
    );

    expect(ex.code, AppExceptionCodes.network);
    expect(ex.message, 'Serviço temporariamente indisponível. Tente novamente.');
  });
}
