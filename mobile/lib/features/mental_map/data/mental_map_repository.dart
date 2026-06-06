import '../../daily_monitors/data/daily_monitors_repository.dart';
import '../../genogram/data/genogram_repository.dart';
import '../../patient_check_ins/data/patient_check_ins_repository.dart';
import '../../patient_problems/data/patient_problems_repository.dart';
import '../../patient_problems/domain/patient_problem_status.dart';
import '../../patients/data/patients_repository.dart';
import '../../patient_timeline/data/patient_timeline_repository.dart';
import '../../patient_timeline/domain/patient_timeline_event_input.dart';
import '../../results/data/results_repository.dart';
import '../../therapy_goals/data/therapy_goals_repository.dart';
import '../../therapy_goals/domain/therapy_goal_status.dart';
import '../domain/mental_map_aggregator.dart';
import '../domain/mental_map_case_summary.dart';
import '../domain/mental_map_check_in_summary.dart';
import '../domain/mental_map_data.dart';
import '../domain/mental_map_genogram_summary.dart';
import '../domain/mental_map_goal_summary.dart';
import '../domain/mental_map_monitor_summary.dart';
import '../domain/mental_map_problem_summary.dart';
import '../domain/mental_map_questionnaire_block.dart';
import '../domain/mental_map_timeline_summary.dart';
import '../domain/mental_map_validation_summary.dart';

class MentalMapRepository {
  MentalMapRepository({
    ResultsRepository? resultsRepository,
    PatientProblemsRepository? problemsRepository,
    TherapyGoalsRepository? goalsRepository,
    PatientCheckInsRepository? checkInsRepository,
    DailyMonitorsRepository? monitorsRepository,
    PatientTimelineRepository? timelineRepository,
    GenogramRepository? genogramRepository,
    PatientsRepository? patientsRepository,
  })  : _results = resultsRepository ?? ResultsRepository(),
        _problems = problemsRepository ?? PatientProblemsRepository(),
        _goals = goalsRepository ?? TherapyGoalsRepository(),
        _checkIns = checkInsRepository ?? PatientCheckInsRepository(),
        _monitors = monitorsRepository ?? DailyMonitorsRepository(),
        _timeline = timelineRepository ?? PatientTimelineRepository(),
        _genogram = genogramRepository ?? GenogramRepository(),
        _patients = patientsRepository ?? PatientsRepository();

  final ResultsRepository _results;
  final PatientProblemsRepository _problems;
  final TherapyGoalsRepository _goals;
  final PatientCheckInsRepository _checkIns;
  final DailyMonitorsRepository _monitors;
  final PatientTimelineRepository _timeline;
  final GenogramRepository _genogram;
  final PatientsRepository _patients;

  Future<String> resolvePatientId({String? patientId}) async {
    if (patientId != null) return patientId;
    return _problems.getPatientIdForCurrentProfile();
  }

  Future<MentalMapData> loadForPatient(String patientId) async {
    final patient = await _patients.getPatientById(patientId);
    final responses = await _results.listPatientResponses(patientId);
    var blocks = buildQuestionnaireBlocks(responses: responses);

    final enriched = <MentalMapQuestionnaireBlock>[];
    for (final block in blocks) {
      final detail = await _results.getResponseDetail(block.responseId);
      if (detail != null) {
        enriched.add(blockWithHighlights(block, detail));
      } else {
        enriched.add(block);
      }
    }
    blocks = enriched;

    final problems = await _problems.listForPatient(patientId);
    final activeProblems = problems
        .where((p) => p.status.isOpen)
        .map(
          (p) => MentalMapProblemSummary(
            id: p.id,
            title: p.title,
            intensity: p.intensity,
            statusLabel: p.status.label,
          ),
        )
        .toList();

    final goals = await _goals.listForPatient(patientId);
    final activeGoals = goals
        .where((g) => g.status == TherapyGoalStatus.active)
        .map(
          (g) => MentalMapGoalSummary(
            id: g.id,
            title: g.title,
            statusLabel: g.status.label,
            targetDateLabel:
                g.targetDate != null ? _formatDate(g.targetDate!) : null,
          ),
        )
        .toList();

    final checkIns = await _checkIns.listForPatient(patientId);
    MentalMapCheckInSummary? recentCheckIn;
    if (checkIns.isNotEmpty) {
      final c = checkIns.first;
      recentCheckIn = MentalMapCheckInSummary(
        id: c.id,
        moodScore: c.moodScore,
        anxietyScore: c.anxietyScore,
        energyScore: c.energyScore,
        problemIntensityScore: c.problemIntensityScore,
        checkedInAt: c.checkedInAt,
      );
    }

    final monitors = await _monitors.listForPatient(patientId);
    final recentMonitors = monitors.take(3).map((m) {
      return MentalMapMonitorSummary(
        id: m.id,
        summaryLine: m.summaryLine,
        createdAt: m.createdAt,
      );
    }).toList();

    final timelineEvents = await _timeline.listForPatient(patientId);
    final sorted = sortTimelineEventsChronologically(timelineEvents);
    final recentTimeline = sorted.take(5).map((e) {
      return MentalMapTimelineSummary(
        id: e.id,
        title: e.title,
        dateLabel: e.dateLabel,
        isSensitive: e.isSensitive,
      );
    }).toList();

    final genogramData = await _genogram.loadForPatient(patientId);
    var sensitivePeople = 0;
    for (final p in genogramData.people) {
      if (p.isSensitive) sensitivePeople++;
    }
    var sensitiveRels = 0;
    for (final r in genogramData.relationships) {
      if (r.isSensitive) sensitiveRels++;
    }

    final caseSummary = patient == null
        ? MentalMapCaseSummary.empty
        : buildCaseSummary(
            patient: patient,
            questionnaires: blocks,
            activeProblems: activeProblems,
            activeGoals: activeGoals,
          );
    final validationSummary = patient == null
        ? MentalMapValidationSummary.empty
        : buildValidationSummary(
            patient: patient,
            questionnaires: blocks,
            activeProblems: activeProblems,
            activeGoals: activeGoals,
            caseSummary: caseSummary,
          );

    return MentalMapData(
      patientName: patient?.fullName ?? 'Paciente',
      caseSummary: caseSummary,
      validationSummary: validationSummary,
      questionnaires: blocks,
      activeProblems: activeProblems,
      activeGoals: activeGoals,
      recentCheckIn: recentCheckIn,
      recentMonitors: recentMonitors,
      recentTimelineEvents: recentTimeline,
      genogram: MentalMapGenogramSummary(
        peopleCount: genogramData.people.length,
        relationshipCount: genogramData.relationships.length,
        sensitivePeopleCount: sensitivePeople,
        sensitiveRelationshipCount: sensitiveRels,
      ),
    );
  }

  Future<MentalMapData> loadMyMentalMap() async {
    final patientId = await resolvePatientId();
    return loadForPatient(patientId);
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
