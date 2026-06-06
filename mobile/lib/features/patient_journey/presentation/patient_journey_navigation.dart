import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../clinical_dashboard/presentation/clinical_dashboard_routes.dart';
import '../../mental_map/presentation/mental_map_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_timeline/presentation/patient_timeline_routes.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../../therapy_resources/presentation/therapy_resource_routes.dart';
import '../domain/journey_step.dart';
import '../domain/journey_step_availability.dart';
import '../domain/journey_step_id.dart';
import 'patient_journey_routes.dart';

void navigateFromJourneyStep(BuildContext context, JourneyStep step) {
  if (step.availability.opensPlaceholder) {
    context.push(PatientJourneyRoutes.upcoming(step.id));
    return;
  }

  if (!step.availability.isNavigableToModule) {
    context.push(PatientJourneyRoutes.upcoming(step.id));
    return;
  }

  switch (step.id) {
    case JourneyStepId.questionnaires:
      context.push(
        QuestionnaireRoutes.list(role: ProfileRole.patient),
      );
    case JourneyStepId.dailyMonitor:
      context.push(DailyMonitorRoutes.patientList);
    case JourneyStepId.library:
      context.push(TherapyResourceRoutes.patientList);
    case JourneyStepId.results:
      context.push(ClinicalDashboardRoutes.patientList);
    case JourneyStepId.therapyGoals:
      context.push(TherapyGoalRoutes.patientList);
    case JourneyStepId.problems:
      context.push(PatientProblemRoutes.patientList);
    case JourneyStepId.checkIn:
      context.push(PatientCheckInRoutes.patientList);
    case JourneyStepId.timeline:
      context.push(PatientTimelineRoutes.patientList);
    case JourneyStepId.genogram:
      context.push(GenogramRoutes.patientList);
    case JourneyStepId.mentalMap:
      context.push(MentalMapRoutes.patientList);
  }
}
