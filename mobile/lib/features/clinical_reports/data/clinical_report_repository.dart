import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/clinical_report_include_options.dart';
import '../domain/clinical_report_response_parser.dart';

class ClinicalReportRepository {
  ClinicalReportRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _functionName = 'generate-clinical-report';

  Future<Uint8List> generatePdf({
    required String patientId,
    required ClinicalReportIncludeOptions include,
  }) async {
    if (!include.hasAnySection) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Selecione ao menos uma seção do relatório.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: include.toRequestJson(patientId),
      );

      if (response.status >= 400) {
        throw mapClinicalReportHttpError(
          status: response.status,
          data: response.data,
        );
      }

      return parseClinicalReportPdfBytes(response.data);
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<File> savePdfToTemp({
    required Uint8List bytes,
    required String patientId,
  }) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final file = File('${dir.path}/relatorio-$patientId-$stamp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<OpenResult> openPdfFile(File file) => OpenFilex.open(file.path);
}
