import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../clinical_dashboard/presentation/clinical_dashboard_routes.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../patient_timeline/presentation/patient_timeline_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../results/presentation/result_routes.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../../therapy_resources/presentation/therapy_resource_routes.dart';

/// Rotas de "Ver detalhes" por seção do mapa mental.
abstract final class MentalMapNavigationTargets {
  static String clinicalDashboard({
    required ProfileRole role,
    String? patientId,
  }) {
    if (role == ProfileRole.patient) {
      return ClinicalDashboardRoutes.patientList;
    }
    if (patientId == null) {
      throw ArgumentError('patientId obrigatório para staff');
    }
    return ClinicalDashboardRoutes.staffList(role: role, patientId: patientId);
  }

  static String? questionnaireResults({
    required ProfileRole role,
    String? patientId,
  }) {
    if (role == ProfileRole.patient) {
      return QuestionnaireRoutes.list(role: ProfileRole.patient);
    }
    if (patientId == null) return null;
    return ResultRoutes.list(role: role, patientId: patientId);
  }

  static String? problems({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return PatientProblemRoutes.patientList;
    }
    if (patientId == null) return null;
    return PatientProblemRoutes.staffList(role: role, patientId: patientId);
  }

  static String? therapyGoals({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return TherapyGoalRoutes.patientList;
    }
    if (patientId == null) return null;
    return TherapyGoalRoutes.staffList(role: role, patientId: patientId);
  }

  static String? checkIns({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return PatientCheckInRoutes.patientList;
    }
    if (patientId == null) return null;
    return PatientCheckInRoutes.staffList(role: role, patientId: patientId);
  }

  static String? dailyMonitors({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return DailyMonitorRoutes.patientList;
    }
    if (patientId == null) return null;
    return DailyMonitorRoutes.staffHistory(role: role, patientId: patientId);
  }

  static String? timeline({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return PatientTimelineRoutes.patientList;
    }
    if (patientId == null) return null;
    return PatientTimelineRoutes.staffList(role: role, patientId: patientId);
  }

  static String? questionnaireResult({
    required ProfileRole role,
    String? patientId,
    String? responseId,
  }) {
    if (role == ProfileRole.patient ||
        patientId == null ||
        responseId == null) {
      return null;
    }
    return ResultRoutes.detail(
      role: role,
      patientId: patientId,
      responseId: responseId,
    );
  }

  static String? genogram({required ProfileRole role, String? patientId}) {
    if (role == ProfileRole.patient) {
      return GenogramRoutes.patientList;
    }
    if (patientId == null) return null;
    return GenogramRoutes.staffList(role: role, patientId: patientId);
  }

  static String? therapyResources({
    required ProfileRole role,
    String? patientId,
  }) {
    if (role == ProfileRole.patient) {
      return TherapyResourceRoutes.patientList;
    }
    if (patientId == null) return null;
    return TherapyResourceRoutes.staffList(role: role, patientId: patientId);
  }
}
