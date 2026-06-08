import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../patient_check_ins/data/patient_check_ins_repository.dart';
import '../../patient_problems/data/patient_problems_repository.dart';
import '../../patients/data/patients_repository.dart';
import '../../results/data/results_repository.dart';
import '../../therapy_goals/data/therapy_goals_repository.dart';
import '../../patient_timeline/data/patient_timeline_repository.dart';
import '../domain/clinical_case_summary_builder.dart';
import '../domain/clinical_dashboard_builder.dart';
import '../domain/clinical_dashboard_callouts.dart';
import '../domain/clinical_dashboard_data.dart';
import '../domain/clinical_instrument_dashboard.dart';
import '../domain/clinical_parental_dashboard.dart';
import '../domain/clinical_parental_dashboard_builder.dart';

class ClinicalDashboardRepository {
  ClinicalDashboardRepository({
    ResultsRepository? resultsRepository,
    PatientProblemsRepository? patientProblemsRepository,
    TherapyGoalsRepository? therapyGoalsRepository,
    PatientCheckInsRepository? patientCheckInsRepository,
    PatientTimelineRepository? patientTimelineRepository,
    PatientsRepository? patientsRepository,
    SupabaseClient? client,
  })  : _results = resultsRepository ?? ResultsRepository(),
        _patientProblems =
            patientProblemsRepository ?? PatientProblemsRepository(),
        _therapyGoals = therapyGoalsRepository ?? TherapyGoalsRepository(),
        _patientCheckIns =
            patientCheckInsRepository ?? PatientCheckInsRepository(),
        _patientTimeline =
            patientTimelineRepository ?? PatientTimelineRepository(),
        _patients = patientsRepository ?? PatientsRepository(),
        _client = client ?? SupabaseBootstrap.client;

  final ResultsRepository _results;
  final PatientProblemsRepository _patientProblems;
  final TherapyGoalsRepository _therapyGoals;
  final PatientCheckInsRepository _patientCheckIns;
  final PatientTimelineRepository _patientTimeline;
  final PatientsRepository _patients;
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
    final responsesFuture = _results.listPatientResponses(patientId);
    final problemsFuture = _patientProblems.listForPatient(patientId);
    final goalsFuture = _therapyGoals.listForPatient(patientId);
    final checkInsFuture = _patientCheckIns.listForPatient(patientId);
    final eventsFuture = _patientTimeline.listForPatient(patientId);
    final patientFuture = _patients.getPatientById(patientId);

    final responses = await responsesFuture;
    final problems = await problemsFuture;
    final goals = await goalsFuture;
    final checkIns = await checkInsFuture;
    final events = await eventsFuture;
    final patient = await patientFuture;
    final patientName = patient?.fullName ?? 'Paciente';

    ClinicalInstrumentDashboard? ysq;
    ClinicalInstrumentDashboard? yami;
    ClinicalInstrumentDashboard? attachment;
    ClinicalInstrumentDashboard? yci;
    ClinicalInstrumentDashboard? yrai;
    ClinicalParentalDashboard? parental;

    final ysqSummary = latestStructuredResponse(responses, ysqInstrumentMarker);
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

    final attachmentSummary = latestStructuredResponseByCode(
      responses,
      attachmentInstrumentCode,
    );
    if (attachmentSummary != null) {
      final detail = await _results.getResponseDetail(attachmentSummary.id);
      if (detail != null) {
        attachment = buildInstrumentDashboard(
          summary: attachmentSummary,
          detail: detail,
        );
      }
    }

    final yciSummary = latestStructuredResponseByCode(
      responses,
      yciInstrumentCode,
    );
    if (yciSummary != null) {
      final detail = await _results.getResponseDetail(yciSummary.id);
      if (detail != null) {
        yci = buildInstrumentDashboard(
          summary: yciSummary,
          detail: detail,
        );
      }
    }

    final yraiSummary = latestStructuredResponseByCode(
      responses,
      yraiInstrumentCode,
    );
    if (yraiSummary != null) {
      final detail = await _results.getResponseDetail(yraiSummary.id);
      if (detail != null) {
        yrai = buildInstrumentDashboard(
          summary: yraiSummary,
          detail: detail,
        );
      }
    }

    final parentalSummary = latestStructuredResponseByCode(
      responses,
      parentalInstrumentCode,
    );
    if (parentalSummary != null) {
      final detail = await _results.getResponseDetail(parentalSummary.id);
      if (detail != null) {
        parental = buildParentalDashboard(
          summary: parentalSummary,
          detail: detail,
        );
      }
    }

    final caseSummary = buildClinicalCaseSummary(
      patientName: patientName,
      responses: responses,
      ysq: ysq,
      yami: yami,
      attachment: attachment,
      yci: yci,
      yrai: yrai,
      problems: problems,
      goals: goals,
      checkIns: checkIns,
      events: events,
    );

    final callouts = buildClinicalDashboardCallouts(
      hasYsqResult: ysq != null && !ysq.isEmpty,
      hasYamiResult: yami != null && !yami.isEmpty,
      hasRecentCheckIn: hasRecentCheckIn(caseSummary.latestCheckIn?.checkedInAt),
    );

    return ClinicalDashboardData(
      patientName: patientName,
      caseSummary: caseSummary,
      callouts: callouts,
      ysq: ysq,
      yami: yami,
      attachment: attachment,
      yci: yci,
      yrai: yrai,
      parental: parental,
      history: buildStructuredHistory(responses),
    );
  }

  Future<ClinicalDashboardData> loadMyDashboard() async {
    final patientId = await getPatientIdForCurrentProfile();
    return loadForPatient(patientId);
  }
}
