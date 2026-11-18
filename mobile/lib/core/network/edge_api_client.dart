import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../supabase/supabase_bootstrap.dart';

/// Cliente para Edge Functions com formato `{ ok, data | error }`.
class EdgeApiClient {
  EdgeApiClient({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// [errorOverride] é opcional: recebe o `error` do payload e o status HTTP e,
  /// se devolver uma exceção, ela substitui o mapeamento padrão (por exemplo
  /// para manter uma mensagem do servidor). Sem ele, nada muda. Erros de
  /// sessão (status 401 ou código UNAUTHORIZED/SESSION_EXPIRED) nunca passam
  /// pelo override: seguem sempre o caminho padrão deste cliente.
  Future<Map<String, dynamic>> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    AppException? Function(Map<String, dynamic> error, int? status)?
        errorOverride,
  }) async {
    AppException mapPayload(Map<String, dynamic> error, int? status) =>
        (_isSessionError(error, status)
            ? null
            : errorOverride?.call(error, status)) ??
        mapEdgeErrorPayload(error, httpStatus: status);

    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );

      final parsed = _parseBody(response.data);

      if (response.status >= 400 &&
          parsed['ok'] == false &&
          parsed['error'] is Map) {
        throw mapPayload(
          Map<String, dynamic>.from(parsed['error'] as Map),
          response.status,
        );
      }

      if (parsed['ok'] == true) {
        final data = parsed['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      }

      if (parsed['ok'] == false && parsed['error'] is Map) {
        throw mapPayload(
          Map<String, dynamic>.from(parsed['error'] as Map),
          response.status,
        );
      }

      throw AppException(
        code: AppExceptionCodes.unknown,
        message: 'Resposta inválida da API.',
        details: {'status': response.status, 'body': parsed},
      );
    } on AppException catch (ex) {
      // Quando a edge retorna 401 (JWT expirado), o Supabase Flutter não emite
      // signedOut automaticamente para chamadas de Functions — ao contrário das
      // queries PostgREST. Forçar signOut aqui dispara o evento que o
      // AuthController já ouve e redireciona para /login com a mensagem correta.
      if (ex.code == AppExceptionCodes.sessionExpired) {
        _client.auth.signOut().ignore();
      }
      rethrow;
    } catch (e) {
      if (errorOverride != null && e is FunctionException) {
        final payload = _parseBodySafe(e.details);
        if (payload['error'] is Map) {
          final error = Map<String, dynamic>.from(payload['error'] as Map);
          final custom = _isSessionError(error, e.status)
              ? null
              : errorOverride(error, e.status);
          if (custom != null) throw custom;
        }
      }
      throw mapToAppException(e);
    }
  }
}

bool _isSessionError(Map<String, dynamic> error, int? status) {
  final code = error['code']?.toString();
  return status == 401 || code == 'UNAUTHORIZED' || code == 'SESSION_EXPIRED';
}

Map<String, dynamic> _parseBodySafe(Object? data) {
  try {
    return _parseBody(data);
  } catch (_) {
    return {};
  }
}

Map<String, dynamic> _parseBody(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return {};
}
