import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../initial_assessment/presentation/initial_assessment_routes.dart';
import '../../life_story/presentation/life_story_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../mental_map/presentation/mental_map_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../patient_library/presentation/patient_library_routes.dart';
import '../../psychoeducation/presentation/psychoeducation_routes.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
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
    case JourneyStepId.initialAssessment:
      context.push(InitialAssessmentRoutes.patient);
    case JourneyStepId.psychoeducation:
      context.push(PsychoeducationRoutes.patient);
    case JourneyStepId.questionnaires:
      context.push(
        QuestionnaireRoutes.list(role: ProfileRole.patient),
      );
    case JourneyStepId.dailyMonitor:
      context.push(DailyMonitorRoutes.patientList);
    case JourneyStepId.library:
      context.push(PatientLibraryRoutes.patient);
    case JourneyStepId.results:
      // Lista de resultados liberados; o dashboard de gráficos é acessível
      // a partir dela.
      context.push('/patient/results');
    case JourneyStepId.therapyGoals:
      context.push(TherapyGoalRoutes.patientList);
    case JourneyStepId.problems:
      context.push(PatientProblemRoutes.patientList);
    case JourneyStepId.checkIn:
      context.push(PatientCheckInRoutes.patientList);
    case JourneyStepId.timeline:
      // Novo fluxo unificado "Minha História" (Tela 2). A tela antiga
      // (InitialAssessmentRoutes.patientHistory) segue no código, aposentada.
      context.push(LifeStoryRoutes.myHistory);
    case JourneyStepId.genogram:
      // Novo fluxo unificado "Minha Família" (Tela 3). A tela antiga
      // (InitialAssessmentRoutes.patientFamily) segue no código, aposentada.
      context.push(LifeStoryRoutes.myFamily);
    case JourneyStepId.mentalMap:
      context.push(MentalMapRoutes.patientList);
  }
}
