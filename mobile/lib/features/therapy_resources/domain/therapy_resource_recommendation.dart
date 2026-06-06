import 'patient_resource_access.dart';
import 'therapy_resource.dart';

class TherapyResourceRecommendation {
  const TherapyResourceRecommendation({
    required this.resource,
    required this.reasons,
    required this.score,
    this.activeAccess,
  });

  final TherapyResource resource;
  final List<String> reasons;
  final int score;
  final PatientResourceAccess? activeAccess;

  bool get isAlreadyAssigned => activeAccess != null;
}
