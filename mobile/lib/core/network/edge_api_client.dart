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

  Future<Map<String, dynamic>> invoke(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );

      final parsed = _parseBody(response.data);

      if (response.status >= 400 &&
          parsed['ok'] == false &&
          parsed['error'] is Map) {
        throw mapEdgeErrorPayload(
          Map<String, dynamic>.from(parsed['error'] as Map),
          httpStatus: response.status,
        );
      }

      if (parsed['ok'] == true) {
        final data = parsed['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      }

      if (parsed['ok'] == false && parsed['error'] is Map) {
        throw mapEdgeErrorPayload(
          Map<String, dynamic>.from(parsed['error'] as Map),
          httpStatus: response.status,
        );
      }

      throw AppException(
        code: AppExceptionCodes.unknown,
        message: 'Resposta inválida da API.',
        details: {'status': response.status, 'body': parsed},
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapToAppException(e);
    }
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
