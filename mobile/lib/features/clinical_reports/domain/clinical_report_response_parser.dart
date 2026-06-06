import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';

/// Extrai bytes PDF da resposta da Edge Function.
Uint8List parseClinicalReportPdfBytes(dynamic data) {
  if (data == null) {
    throw AppException(
      code: AppExceptionCodes.unknown,
      message: 'Resposta vazia ao gerar o relatório.',
    );
  }

  if (data is Uint8List) {
    return data;
  }

  if (data is List<int>) {
    return Uint8List.fromList(data);
  }

  if (data is List) {
    return Uint8List.fromList(data.cast<int>());
  }

  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.startsWith('%PDF')) {
      return Uint8List.fromList(trimmed.codeUnits);
    }
    if (trimmed.startsWith('{')) {
      throw _errorFromJsonString(trimmed);
    }
    try {
      return base64Decode(trimmed);
    } catch (_) {
      return Uint8List.fromList(trimmed.codeUnits);
    }
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    if (map['ok'] == false && map['error'] is Map) {
      throw mapEdgeErrorPayload(
        Map<String, dynamic>.from(map['error'] as Map),
      );
    }
    final b64 = map['pdf_base64'] ?? map['data'];
    if (b64 is String) {
      return base64Decode(b64);
    }
  }

  throw AppException(
    code: AppExceptionCodes.unknown,
    message: 'Formato de PDF não reconhecido na resposta.',
  );
}

Never _errorFromJsonString(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is Map && decoded['error'] is Map) {
    throw mapEdgeErrorPayload(
      Map<String, dynamic>.from(decoded['error'] as Map),
      httpStatus: decoded['ok'] == false ? 400 : null,
    );
  }
  throw AppException(
    code: AppExceptionCodes.unknown,
    message: 'Não foi possível gerar o relatório.',
  );
}

AppException mapClinicalReportHttpError({
  required int status,
  dynamic data,
}) {
  if (data is String && data.trim().startsWith('{')) {
    try {
      _errorFromJsonString(data);
    } on AppException catch (e) {
      return e;
    }
  }
  if (data is Map && data['error'] is Map) {
    return mapEdgeErrorPayload(
      Map<String, dynamic>.from(data['error'] as Map),
      httpStatus: status,
    );
  }
  if (status == 401 || status == 403) {
    return AppException(
      code: status == 401
          ? AppExceptionCodes.sessionExpired
          : AppExceptionCodes.forbidden,
      message: status == 401
          ? 'Sessão expirada. Faça login novamente.'
          : 'Sem permissão para gerar relatório deste paciente.',
    );
  }
  return AppException(
    code: AppExceptionCodes.unknown,
    message: 'Falha ao gerar relatório (HTTP $status).',
  );
}
