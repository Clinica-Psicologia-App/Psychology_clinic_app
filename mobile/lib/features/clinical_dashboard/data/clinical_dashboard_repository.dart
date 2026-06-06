import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../results/data/results_repository.dart';
import '../domain/clinical_dashboard_builder.dart';
import '../domain/clinical_dashboard_data.dart';
import '../domain/clinical_instrument_dashboard.dart';

class ClinicalDashboardRepository {
  ClinicalDashboardRepository({
    ResultsRepository? resultsRepository,
    SupabaseClient? client,
  })  : _results = resultsRepository ?? ResultsRepository(),
        _client = client ?? SupabaseBootstrap.client;

  final ResultsRepository _results;
  final SupabaseClient _client;

  Future<String> getPatientIdForCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não encontrada.',
        );
      }

      final row = await _client
          .from('patients')
          .select('id')
          .eq('profile_id', userId)
          .maybeSingle();

      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Cadastro de paciente não encontrado para este login.',
        );
      }

      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<ClinicalDashboardData> loadForPatient(String patientId) async {
    final responses = await _results.listPatientResponses(patientId);

    ClinicalInstrumentDashboard? ysq;
    ClinicalInstrumentDashboard? yami;

    final ysqSummary =
        latestStructuredResponse(responses, ysqInstrumentMarker);
    if (ysqSummary != null) {
      final detail = await _results.getResponseDetail(ysqSummary.id);
      if (detail != null) {
        ysq = buildInstrumentDashboard(
          summary: ysqSummary,
          detail: detail,
        );
      }
    }

    final yamiSummary =
        latestStructuredResponse(responses, yamiInstrumentMarker);
    if (yamiSummary != null) {
      final detail = await _results.getResponseDetail(yamiSummary.id);
      if (detail != null) {
        yami = buildInstrumentDashboard(
          summary: yamiSummary,
          detail: detail,
        );
      }
    }

    return ClinicalDashboardData(
      ysq: ysq,
      yami: yami,
      history: buildStructuredHistory(responses),
    );
  }

  Future<ClinicalDashboardData> loadMyDashboard() async {
    final patientId = await getPatientIdForCurrentProfile();
    return loadForPatient(patientId);
  }
}
