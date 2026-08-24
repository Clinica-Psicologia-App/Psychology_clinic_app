import 'coach_step.dart';

class CoachTour {
  const CoachTour({
    required this.id,
    required this.steps,
  });

  final String id;
  final List<CoachStep> steps;
}
