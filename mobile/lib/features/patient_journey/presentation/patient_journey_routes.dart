import '../domain/journey_step_id.dart';

abstract final class PatientJourneyRoutes {
  static const journey = '/patient/journey';

  static String upcoming(JourneyStepId step) =>
      '/patient/journey/upcoming/${step.routeKey}';
}
